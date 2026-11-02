#!/usr/bin/env python3
"""Offline lifecycle checks for SDKHooks library reconciliation."""

from __future__ import annotations

import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "tools/smoke/game_event_observer.sp.in"
SDK_MODULE = ROOT / "tools/smoke/sdkhooks_observer.sp.inc"
COMPILER = ROOT / "deps/sourcemod-linux/addons/sourcemod/scripting/spcomp"
SHELL = ROOT.parent / "SteamIDTools/deps/sourcepawn/objdir/spshell/linux-x86_64/spshell"


def extract_function(source: str, name: str) -> str:
    """Extract a complete SourcePawn function body without rewriting it."""
    match = re.search(
        rf"(?m)^[\t ]*(?:(?:public|static|stock)\s+)*(?:Action|void|int|bool|float|any)\s+{re.escape(name)}\s*\([^;]*?\)\s*\{{",
        source,
    )
    if match is None:
        raise AssertionError(f"function {name} not found in current observer source")

    start = match.start()
    brace = source.find("{", match.start(), match.end())
    depth = 0
    in_string = False
    escaped = False
    for position in range(brace, len(source)):
        char = source[position]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start : position + 1]
    raise AssertionError(f"unterminated function {name}")


def lifecycle_harness() -> str:
    template = TEMPLATE.read_text(encoding="utf-8")
    sdk = SDK_MODULE.read_text(encoding="utf-8")
    callbacks = [extract_function(template, name) for name in ("OnLibraryAdded", "OnLibraryRemoved")]
    callbacks.append(extract_function(template, "OnGameFrame"))
    reconcile = extract_function(sdk, "SmokeSDK_Reconcile")
    reconcile, delete_count = re.subn(
        r"\bdelete\s+g_SmokeSDKTrackedEntities\s*;",
        "g_SmokeSDKTrackedEntities = null;",
        reconcile,
    )
    if delete_count != 1:
        raise AssertionError("could not isolate the real reconciliation ledger invalidation")
    deferred = extract_function(sdk, "SmokeSDK_HookDeferred")
    deferred, pack_count = re.subn(
        r"DataPack pack = view_as<DataPack>\(data\);\s*pack\.Reset\(\);\s*"
        r"int entRef = pack\.ReadCell\(\);\s*int generation = pack\.ReadCell\(\);\s*delete pack;",
        "int entRef, generation;\n\tSDKTest_ReadPack(data, entRef, generation);",
        deferred,
    )
    if pack_count != 1:
        raise AssertionError("could not isolate the deferred-frame payload decode")
    deferred = deferred.replace("EntRefToEntIndex(entRef)", "SDKTest_EntRefToEntIndex(entRef)")
    deferred = deferred.replace("IsValidEntity(entity)", "SDKTest_IsValidEntity(entity)")

    return r'''#pragma semicolon 1
#pragma newdecls required

#define ArrayList Handle
#define TraceSource_Engine 0
#define TraceSource_SDKHooks 1
#define LIBRARY_L4D2PLAYERSTATS "l4d2_player_stats"
#define LIBRARY_L4D_TANK_CONTROL_EQ "l4d_tank_control_eq"
native void printf(const char[] format, any ...);

enum struct SmokeRuntimeState
{
	bool hasSDKHooks;
	bool hasLeft4DHooks;
	bool hasPlayerStats;
	bool hasTankControl;
	bool configsReady;
	bool sdkHooksNeedsSync;
	bool sdkHooksResetPending;

	void Reset()
	{
		this.hasSDKHooks = false;
		this.hasLeft4DHooks = false;
		this.hasPlayerStats = false;
		this.hasTankControl = false;
		this.configsReady = false;
		this.sdkHooksNeedsSync = false;
		this.sdkHooksResetPending = false;
	}
}

SmokeRuntimeState g_Runtime;
ArrayList g_SmokeSDKTrackedEntities;
int g_SmokeSDKGeneration;
bool g_CaptureActive;
bool g_SDKHookNativeAvailable;
int g_StartCalls;
int g_ReconstructionCalls;
int g_UnhookCalls;
int g_TraceCalls;
int g_DeferredHookCalls;
int g_EntRefReads;
int g_EntityValidityReads;
int g_ResolvedEntity;
bool g_ResolvedEntityValid;
int g_PackEntRef;
int g_PackGeneration;

void SmokeWitch_Heartbeat() {}

bool TraceActive() { return g_CaptureActive; }
int TraceBegin(int source, const char[] callback) { g_TraceCalls += source + strlen(callback); return 1; }
void TraceTextValue(int source, int sequence, const char[] key, const char[] value) { g_TraceCalls += source + sequence + strlen(key) + strlen(value); }

int SDKTest_EntRefToEntIndex(int entRef)
{
	g_EntRefReads++;
	return entRef == g_PackEntRef ? g_ResolvedEntity : -1;
}

void SDKTest_ReadPack(any data, int &entRef, int &generation)
{
	g_TraceCalls += data;
	entRef = g_PackEntRef;
	generation = g_PackGeneration;
}

bool SDKTest_IsValidEntity(int entity)
{
	g_EntityValidityReads++;
	return entity == g_ResolvedEntity && g_ResolvedEntityValid;
}

// Mock only the provider-facing start operation. The production reconciliation
// body, library callbacks and frame dispatch are extracted verbatim above.
void SmokeSDK_Start()
{
	g_StartCalls++;
	if (g_SmokeSDKTrackedEntities != null) return;
	g_SmokeSDKGeneration++;
	g_Runtime.hasSDKHooks = g_SDKHookNativeAvailable;
	if (g_Runtime.hasSDKHooks)
	{
		g_SmokeSDKTrackedEntities = view_as<Handle>(1);
		g_ReconstructionCalls++;
	}
}

void SmokeSDK_HookEntity(int entity) { g_DeferredHookCalls += entity > 0 ? 1 : 0; }

bool g_Failed;
void Assert(bool condition, const char[] label)
{
	if (!condition)
	{
		g_Failed = true;
		printf("FAIL %s\n", label);
	}
}

''' + "\n\n".join(callbacks) + "\n\n" + reconcile + "\n\n" + deferred + r'''

void ResetHarness()
{
	g_SmokeSDKTrackedEntities = null;
	g_Runtime.Reset();
	g_SmokeSDKGeneration = 10;
	g_CaptureActive = true;
	g_SDKHookNativeAvailable = true;
	g_StartCalls = 0;
	g_ReconstructionCalls = 0;
	g_UnhookCalls = 0;
	g_TraceCalls = 0;
	g_DeferredHookCalls = 0;
	g_EntRefReads = 0;
	g_EntityValidityReads = 0;
}

void TestMissingSDKHooksThenAdded()
{
	ResetHarness();
	// Capture has started without SDKHooks. No hook inventory exists yet.
	g_SDKHookNativeAvailable = false;
	SmokeSDK_Start();
	Assert(!g_Runtime.hasSDKHooks && g_SmokeSDKTrackedEntities == null, "missing provider start leaves no hook inventory");
	int startsBeforeAdd = g_StartCalls;
	g_SDKHookNativeAvailable = true; // The provider bound its natives before the library notification.
	OnLibraryAdded("sdkhooks");
	Assert(g_StartCalls == startsBeforeAdd, "library callback only marks reconciliation; it does not start SDKHooks");
	OnGameFrame();
	Assert(g_Runtime.hasSDKHooks && g_SmokeSDKTrackedEntities != null, "provider add reconciles and creates tracking inventory");
	Assert(g_StartCalls == startsBeforeAdd + 1 && g_ReconstructionCalls == 1, "provider add reconstructs existing entities once");
	Assert(g_TraceCalls > 0, "library and frame trace callbacks remain callable during reconciliation");
	Assert(g_SmokeSDKGeneration > 10, "provider start advances generation before scheduling entity frames");
	g_SmokeSDKTrackedEntities = null;
}

void TestRemoveAddCoalescesAndInvalidatesOldFrame()
{
	ResetHarness();
	g_Runtime.hasSDKHooks = true;
	g_SmokeSDKTrackedEntities = view_as<Handle>(1);
	g_PackEntRef = 9001;
	g_PackGeneration = g_SmokeSDKGeneration;
	int generationBefore = g_SmokeSDKGeneration;

	OnLibraryRemoved("sdkhooks");
	Assert(!g_Runtime.hasSDKHooks && g_Runtime.sdkHooksNeedsSync && g_Runtime.sdkHooksResetPending, "provider removal invalidates state and queues reset");
	OnLibraryAdded("sdkhooks");
	Assert(!g_Runtime.hasSDKHooks && g_Runtime.sdkHooksNeedsSync && g_Runtime.sdkHooksResetPending, "same-frame add coalesces while retaining reset until reconciliation");
	Assert(g_StartCalls == 0 && g_UnhookCalls == 0, "library callbacks neither start nor unhook provider hooks");

	OnGameFrame();
	Assert(g_StartCalls == 1 && g_ReconstructionCalls == 1, "remove/add reconciles once and rebuilds once");
	Assert(g_SmokeSDKGeneration > generationBefore, "removal reset and restart invalidate prior deferred generation");
	Assert(g_UnhookCalls == 0, "removed provider ledger is forgotten without unhooking rebound indices");
	Assert(!g_Runtime.sdkHooksNeedsSync && !g_Runtime.sdkHooksResetPending, "reconcile consumes both pending flags");

	g_ResolvedEntity = 75;
	g_ResolvedEntityValid = true;
	SmokeSDK_HookDeferred(0);
	Assert(g_DeferredHookCalls == 0 && g_EntRefReads == 0 && g_EntityValidityReads == 0, "old-generation frame is rejected before entity resolution");

	g_PackEntRef = 9002;
	g_PackGeneration = g_SmokeSDKGeneration;
	g_ResolvedEntity = 75;
	g_ResolvedEntityValid = true;
	SmokeSDK_HookDeferred(0);
	Assert(g_DeferredHookCalls == 1 && g_EntRefReads == 1 && g_EntityValidityReads == 1, "current-generation frame resolves and hooks a valid entity");
	g_SmokeSDKTrackedEntities = null;
}

void TestInactiveCaptureDefersReconciliation()
{
	ResetHarness();
	g_CaptureActive = false;
	OnLibraryAdded("sdkhooks");
	Assert(g_Runtime.sdkHooksNeedsSync && g_StartCalls == 0, "inactive library callback only records pending sync");
	OnGameFrame();
	Assert(g_Runtime.sdkHooksNeedsSync && g_StartCalls == 0, "inactive frame retains flags without starting hooks");
	g_CaptureActive = true;
	OnGameFrame();
	Assert(!g_Runtime.sdkHooksNeedsSync && g_StartCalls == 1 && g_ReconstructionCalls == 1, "active capture consumes pending sync and reconstructs once");
	g_SmokeSDKTrackedEntities = null;
}

public int main()
{
	TestMissingSDKHooksThenAdded();
	TestRemoveAddCoalescesAndInvalidatesOldFrame();
	TestInactiveCaptureDefersReconciliation();
	printf("SDK_RECONCILE_VM scenarios=3 failures=%d\n", g_Failed);
	return g_Failed ? 1 : 0;
}
'''


class SDKReconcileTests(unittest.TestCase):
    def test_library_callbacks_defer_work_and_reset_never_unhooks_old_ledger(self) -> None:
        template = TEMPLATE.read_text(encoding="utf-8")
        sdk = SDK_MODULE.read_text(encoding="utf-8")
        added = extract_function(template, "OnLibraryAdded")
        removed = extract_function(template, "OnLibraryRemoved")
        reconcile = extract_function(sdk, "SmokeSDK_Reconcile")

        for callback in (added, removed):
            self.assertNotRegex(callback, r"\b(?:SmokeSDK_Start|SmokeSDK_Reconcile|SDKHookEx|SDKUnhook|GetFeatureStatus)\s*\(")
        self.assertRegex(added, r"sdkHooksNeedsSync\s*=\s*true")
        self.assertRegex(removed, r"sdkHooksNeedsSync\s*=\s*true")
        self.assertRegex(removed, r"sdkHooksResetPending\s*=\s*true")
        self.assertNotRegex(reconcile, r"\bSmokeSDK_UnhookFlags\s*\(")

    def test_harness_does_not_erase_a_failure_from_an_earlier_scenario(self) -> None:
        if not COMPILER.is_file() or not SHELL.is_file():
            self.skipTest("offline SourcePawn compiler/VM unavailable")
        source_text = lifecycle_harness().replace(
            "void TestMissingSDKHooksThenAdded()\n{",
            'void TestMissingSDKHooksThenAdded()\n{\n\tAssert(false, "injected_first_failure");', 1)
        with tempfile.TemporaryDirectory(prefix="skills-sdk-fault-") as directory:
            source = Path(directory) / "sdk_fault.sp"
            binary = source.with_suffix('.smx')
            source.write_text(source_text)
            compiled = subprocess.run([str(COMPILER), '-o', str(binary), str(source)], text=True, capture_output=True)
            self.assertEqual(compiled.returncode, 0, compiled.stdout + compiled.stderr)
            self.assertNotIn('warning ', compiled.stdout.lower())
            run = subprocess.run([str(SHELL), str(binary)], text=True, capture_output=True)
            self.assertNotEqual(run.returncode, 0, run.stdout + run.stderr)
            self.assertIn('FAIL injected_first_failure', run.stdout)
            self.assertIn('scenarios=3 failures=1', run.stdout)

    def test_actual_library_callbacks_and_reconcile_run_in_sourcepawn_vm(self) -> None:
        if not COMPILER.is_file() or not SHELL.is_file():
            self.skipTest("offline SourcePawn compiler/VM is unavailable; use sibling SteamIDTools VM build")

        with tempfile.TemporaryDirectory(prefix="skills-sdk-reconcile-vm-") as directory:
            temp = Path(directory)
            source = temp / "sdk_reconcile_test.sp"
            binary = temp / "sdk_reconcile_test.smx"
            source.write_text(lifecycle_harness(), encoding="utf-8")
            compiled = subprocess.run(
                [str(COMPILER), "-o", str(binary), str(source)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(compiled.returncode, 0, msg=f"spcomp failed\n{compiled.stdout}\n{compiled.stderr}")
            self.assertNotIn("warning ", compiled.stdout.lower())
            run = subprocess.run([str(SHELL), str(binary)], text=True, capture_output=True, check=False)
            self.assertEqual(run.returncode, 0, msg=f"spshell failed\n{run.stdout}\n{run.stderr}")
            self.assertNotIn("FAIL ", run.stdout)
            self.assertIn("SDK_RECONCILE_VM scenarios=3 failures=0", run.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
