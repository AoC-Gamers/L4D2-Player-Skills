#!/usr/bin/env python3
"""Generator coverage and offline passivity checks for the source observer."""

from __future__ import annotations

import hashlib
import importlib.util
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SMOKE = ROOT / "tools" / "smoke"
PLUGIN = ROOT / "addons/sourcemod/scripting/l4d2_player_skills.sp"
CATALOG = ROOT / "docs/l4d2_game_events.json"
SDK_MODULE = SMOKE / "sdkhooks_observer.sp.inc"
LH_MODULE = SMOKE / "left4dhooks_observer.sp.inc"
COMPILER = ROOT / "deps/sourcemod-linux/addons/sourcemod/scripting/spcomp"
SHELL = ROOT.parent / "SteamIDTools/deps/sourcepawn/objdir/spshell/linux-x86_64/spshell"
INCLUDE_DIRS = [
    ROOT / "deps/sourcemod-linux/addons/sourcemod/scripting/include",
    ROOT / "addons/sourcemod/scripting/include",
]

EXPECTED_SDK_TYPES = {
    "SDKHook_OnTakeDamage",
    "SDKHook_OnTakeDamagePost",
    "SDKHook_TraceAttack",
    "SDKHook_Touch",
    "SDKHook_Spawn",
}
EXPECTED_LH_CALLBACKS = {
    "L4D_OnGameModeChange",
    "L4D_OnFirstSurvivorLeftSafeArea_Post",
    "L4D_OnWitchSetHarasser",
    "L4D_OnSpawnWitch_Post",
    "L4D2_OnSpawnWitchBride_Post",
    "L4D_OnGrabWithTongue_Post",
    "L4D_OnPouncedOnSurvivor_Post",
    "L4D2_OnJockeyRide_Post",
    "L4D2_OnStartCarryingVictim_Post",
    "L4D2_OnSlammedSurvivor_Post",
    "L4D_OnFatalFalling",
    "L4D_OnFalling",
    "L4D_OnLedgeGrabbed_Post",
    "L4D_OnIncapacitated_Post",
    "L4D2_OnPummelVictim_Post",
    "L4D_OnReplaceTank",
    "L4D_OnTryOfferingTankBot",
    "L4D_OnTryOfferingTankBot_Post",
    "L4D_OnTryOfferingTankBot_PostHandled",
    "L4D_OnEnterStasis",
    "L4D_OnLeaveStasis",
    "L4D2_OnEntityShoved_Post",
    "L4D_TankRock_OnRelease_Post",
    "L4D_TankRock_BounceTouch_Post",
    "L4D_TankRock_OnDetonate",
    "L4D2_OnEndVersusModeRound_Post",
}

SPEC = importlib.util.spec_from_file_location(
    "generate_game_event_observer", SMOKE / "generate_game_event_observer.py"
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("cannot import the smoke observer generator")
generator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(generator)


def extract_function(source: str, name: str) -> str:
    """Return one complete SourcePawn function without rewriting its body."""
    match = re.search(
        rf"(?m)^[\t ]*(?:(?:public|static|stock)\s+)*(?:Action|MRESReturn|void|int|bool|float|any)\s+{re.escape(name)}\s*\([^;]*?\)\s*\{{",
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


def standalone_vm_harness() -> str:
    sdk = SDK_MODULE.read_text(encoding="utf-8")
    left4dhooks = LH_MODULE.read_text(encoding="utf-8")
    deferred = extract_function(sdk, "SmokeSDK_HookDeferred")
    deferred_pack_block, replacements = re.subn(
        r"DataPack pack = view_as<DataPack>\(data\);\s*pack\.Reset\(\);\s*"
        r"int entRef = pack\.ReadCell\(\);\s*int generation = pack\.ReadCell\(\);\s*delete pack;",
        "int entRef, generation;\n\tSmokeTest_ReadPack(data, entRef, generation);",
        deferred,
    )
    if replacements != 1:
        raise AssertionError("could not isolate the current DataPack decode block")
    deferred = deferred_pack_block
    names = [
        "SmokeSDK_OnTakeDamage",
        "SmokeSDK_OnTakeDamagePost",
        "SmokeSDK_OnTraceAttack",
        "SmokeSDK_OnTouch",
        "SmokeSDK_OnSpawn",
        "SmokeSDK_BeginCallback",
        "SmokeSDK_RecordDamage",
        "SmokeSDK_RecordEntity",
        "L4D_OnFatalFalling",
        "L4D_OnTryOfferingTankBot",
    ]
    functions = []
    for name in names:
        source = left4dhooks if name.startswith("L4D_") else sdk
        functions.append(extract_function(source, name))
    functions.append(deferred)

    return r'''#pragma semicolon 1
#pragma newdecls required

enum TraceSource { TraceSource_SDKHooks = 1, TraceSource_Left4DHooks = 2 }
native void printf(const char[] format, any ...);

#define IsClientInGame SmokeTest_IsClientInGame
#define GetClientUserId SmokeTest_GetClientUserId
#define Format SmokeTest_Format
#define ArrayList Handle
#define EntRefToEntIndex SmokeTest_EntRefToEntIndex
#define IsValidEntity SmokeTest_IsValidEntity

int g_Failures;
int g_TraceCalls;
int g_Sequence = 100;
int g_CurrentTick = 9876;
int g_LastTick;
int g_LastSource;
int g_ObservedAttacker;
int g_ObservedDamageType;
int g_ObservedListenerAction;
int g_ObservedStasis;
int g_ObservedOther;
int g_ObservedFloatDamage;
float g_ObservedVector[3];
char g_LastCallback[64];
Handle g_SmokeSDKTrackedEntities;
int g_SmokeSDKGeneration;
int g_PackEntRef;
int g_PackGeneration;
int g_PackReads;
int g_EntRefReads;
int g_ValidityReads;
int g_DeferredHookCalls;
int g_DeferredHookEntity;
int g_ResolvedEntity;
bool g_EntityIsValid;
int g_LifecycleFailures;

int TraceBegin(TraceSource source, const char[] callback)
{
	g_TraceCalls++;
	g_LastSource = view_as<int>(source);
	g_LastTick = g_CurrentTick;
	strcopy(g_LastCallback, sizeof(g_LastCallback), callback);
	return ++g_Sequence;
}
void TraceEntityValue(TraceSource source, int sequence, const char[] key, int value)
{
	g_TraceCalls++;
	if ((source != TraceSource_SDKHooks && source != TraceSource_Left4DHooks) || sequence < 0 || key[0] == '\0' || value == -2147483647) g_Failures++;
	if (StrEqual(key, "attacker")) g_ObservedAttacker = value;
	if (StrEqual(key, "other")) g_ObservedOther = value;
}
void TraceIntValue(TraceSource source, int sequence, const char[] key, int value)
{
	g_TraceCalls++;
	if ((source != TraceSource_SDKHooks && source != TraceSource_Left4DHooks) || sequence < 0 || key[0] == '\0' || value == -2147483647) g_Failures++;
	if (StrEqual(key, "damagetype")) g_ObservedDamageType = value;
	if (StrEqual(key, "listener_action")) g_ObservedListenerAction = value;
	if (StrEqual(key, "enterStasis")) g_ObservedStasis = value;
}
void TraceFloatValue(TraceSource source, int sequence, const char[] key, float value)
{
	g_TraceCalls++;
	if ((source != TraceSource_SDKHooks && source != TraceSource_Left4DHooks) || sequence < 0 || key[0] == '\0' || value == view_as<float>(-2147483647)) g_Failures++;
	if (StrEqual(key, "damage")) g_ObservedFloatDamage = view_as<int>(value);
}
void TraceVectorValue(TraceSource source, int sequence, const char[] key, const float value[3])
{
	g_TraceCalls++;
	if ((source != TraceSource_SDKHooks && source != TraceSource_Left4DHooks) || sequence < 0 || key[0] == '\0' || value[0] == view_as<float>(-2147483647)) g_Failures++;
	for (int i = 0; i < 3; i++) g_ObservedVector[i] = value[i];
}
bool SmokeTest_IsClientInGame(int client) { return client > 0 && client <= 64; }
int SmokeTest_GetClientUserId(int client) { return client + 1000; }
void SmokeTest_Format(char[] buffer, int maxlength, const char[] format, any ...) { g_TraceCalls++; if (format[0] == '\0') g_Failures++; strcopy(buffer, maxlength, "entity_userid"); }
void SmokeTest_ReadPack(any data, int &entRef, int &generation)
{
	g_PackReads++;
	if (data == -2147483647) g_LifecycleFailures++;
	entRef = g_PackEntRef;
	generation = g_PackGeneration;
}
int SmokeTest_EntRefToEntIndex(int entRef) { g_EntRefReads++; return entRef == g_PackEntRef ? g_ResolvedEntity : -1; }
bool SmokeTest_IsValidEntity(int entity) { g_ValidityReads++; return g_EntityIsValid && entity == g_ResolvedEntity; }
void SmokeSDK_HookEntity(int entity) { g_DeferredHookCalls++; g_DeferredHookEntity = entity; }

void Check(bool condition, const char[] label)
{
	if (!condition)
	{
		g_Failures++;
		printf("FAIL %s\n", label);
	}
}

void LifecycleCheck(bool condition, const char[] label)
{
	if (!condition)
	{
		g_LifecycleFailures++;
		printf("FAIL lifecycle %s\n", label);
	}
}

void ResetDeferredCase(int generation, bool captureOpen, int packGeneration, int entRef, int resolvedEntity, bool entityValid)
{
	g_SmokeSDKGeneration = generation;
	g_SmokeSDKTrackedEntities = captureOpen ? view_as<Handle>(1) : null;
	g_PackGeneration = packGeneration;
	g_PackEntRef = entRef;
	g_ResolvedEntity = resolvedEntity;
	g_EntityIsValid = entityValid;
	g_PackReads = 0;
	g_EntRefReads = 0;
	g_ValidityReads = 0;
	g_DeferredHookCalls = 0;
	g_DeferredHookEntity = -1;
}

void RunDeferredLifecycleChecks()
{
	// A frame queued in generation 1 must not hook after Stop (2) then Start (3).
	ResetDeferredCase(3, true, 1, 7001, 70, true);
	SmokeSDK_HookDeferred(0);
	LifecycleCheck(g_PackReads == 1 && g_EntRefReads == 0 && g_ValidityReads == 0 && g_DeferredHookCalls == 0,
		"stale frame rejected after Stop then Start");

	ResetDeferredCase(3, false, 3, 7002, 71, true);
	SmokeSDK_HookDeferred(0);
	LifecycleCheck(g_PackReads == 1 && g_EntRefReads == 0 && g_DeferredHookCalls == 0,
		"closed capture rejects deferred frame");

	ResetDeferredCase(3, true, 3, 7003, INVALID_ENT_REFERENCE, true);
	SmokeSDK_HookDeferred(0);
	LifecycleCheck(g_EntRefReads == 1 && g_ValidityReads == 0 && g_DeferredHookCalls == 0,
		"invalid entref rejects deferred frame");

	ResetDeferredCase(3, true, 3, 7004, 74, false);
	SmokeSDK_HookDeferred(0);
	LifecycleCheck(g_EntRefReads == 1 && g_ValidityReads == 1 && g_DeferredHookCalls == 0,
		"invalid entity rejects deferred frame");

	ResetDeferredCase(3, true, 3, 7005, 75, true);
	SmokeSDK_HookDeferred(0);
	LifecycleCheck(g_EntRefReads == 1 && g_ValidityReads == 1 && g_DeferredHookCalls == 1 && g_DeferredHookEntity == 75,
		"current generation hooks valid entity once");
}

''' + "\n\n".join(functions) + r'''

public int main()
{
	int attacker = 23, inflictor = 24, damageType = 25, weapon = 26;
	float damage = 41.5;
	float force[3] = {1.25, -2.5, 3.75};
	float position[3] = {-4.5, 5.25, 6.0};
	Action action = SmokeSDK_OnTakeDamage(7, attacker, inflictor, damage, damageType, weapon, force, position);
	Check(action == Plugin_Continue, "OnTakeDamage returns Continue");
	Check(attacker == 23 && inflictor == 24 && damageType == 25 && weapon == 26, "OnTakeDamage leaves byref cells untouched");
	Check(view_as<int>(damage) == view_as<int>(41.5), "OnTakeDamage leaves damage untouched");
	Check(view_as<int>(force[0]) == view_as<int>(1.25) && view_as<int>(force[1]) == view_as<int>(-2.5) && view_as<int>(force[2]) == view_as<int>(3.75), "OnTakeDamage leaves force untouched");
	Check(view_as<int>(position[0]) == view_as<int>(-4.5) && view_as<int>(position[1]) == view_as<int>(5.25) && view_as<int>(position[2]) == view_as<int>(6.0), "OnTakeDamage leaves position untouched");
	Check(g_ObservedAttacker == 23 && g_ObservedDamageType == 25 && g_ObservedFloatDamage == view_as<int>(41.5), "OnTakeDamage logs received fields");
	Check(view_as<int>(g_ObservedVector[0]) == view_as<int>(-4.5) && view_as<int>(g_ObservedVector[1]) == view_as<int>(5.25) && view_as<int>(g_ObservedVector[2]) == view_as<int>(6.0), "OnTakeDamage logs received position");
	Check(g_LastTick == 9876 && g_LastSource == view_as<int>(TraceSource_SDKHooks) && StrEqual(g_LastCallback, "OnTakeDamage"), "OnTakeDamage trace identifies source and tick");

	int preTrace = g_TraceCalls;
	SmokeSDK_OnTakeDamagePost(7, 33, 34, 19.75, 35, 36, force, position);
	Check(g_TraceCalls > preTrace && StrEqual(g_LastCallback, "OnTakeDamagePost"), "OnTakeDamagePost is observed separately");
	Check(g_ObservedAttacker == 33 && g_ObservedFloatDamage == view_as<int>(19.75) && g_ObservedDamageType == 35, "OnTakeDamagePost logs its own by-value sample");

	int ammo = 28, traceDamageType = 29;
	damage = 31.25;
	action = SmokeSDK_OnTraceAttack(7, attacker, inflictor, damage, traceDamageType, ammo, 30, 31);
	Check(action == Plugin_Continue, "TraceAttack returns Continue");
	Check(attacker == 23 && inflictor == 24 && traceDamageType == 29 && ammo == 28, "TraceAttack leaves byref cells untouched");
	Check(view_as<int>(damage) == view_as<int>(31.25), "TraceAttack leaves damage untouched");
	Check(g_ObservedAttacker == 23 && g_ObservedDamageType == 29 && g_ObservedFloatDamage == view_as<int>(31.25), "TraceAttack logs received fields");

	action = SmokeSDK_OnTouch(41, 42);
	Check(action == Plugin_Continue && StrEqual(g_LastCallback, "Touch"), "Touch returns Continue and records callback");
	Check(g_ObservedOther == 42 && g_ObservedListenerAction == view_as<int>(Plugin_Continue), "Touch logs received target and returned action");
	action = SmokeSDK_OnSpawn(43);
	Check(action == Plugin_Continue && StrEqual(g_LastCallback, "Spawn"), "Spawn returns Continue and records callback");
	Check(g_ObservedListenerAction == view_as<int>(Plugin_Continue), "Spawn logs returned action");

	bool enterStasis = true;
	action = L4D_OnTryOfferingTankBot(44, enterStasis);
	Check(action == Plugin_Continue, "TryOfferingTankBot returns Continue");
	Check(enterStasis == true, "TryOfferingTankBot leaves byref bool untouched");
	Check(g_ObservedStasis == 1 && g_ObservedListenerAction == view_as<int>(Plugin_Continue), "TryOfferingTankBot logs received bool and returned action");
	action = L4D_OnFatalFalling(45, 46);
	Check(action == Plugin_Continue, "FatalFalling returns Continue");
	Check(g_Failures == 0, "all observer passivity checks pass");
	printf("SOURCE_OBSERVER_VM checks=23 failures=%d\n", g_Failures);
	RunDeferredLifecycleChecks();
	printf("SDK_LIFECYCLE_VM checks=5 failures=%d\n", g_LifecycleFailures);
	return g_Failures == 0 && g_LifecycleFailures == 0 ? 0 : 1;
}
'''


class SourceObserverTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.events = generator.load_catalog(CATALOG)
        cls.digest = hashlib.sha256(CATALOG.read_bytes()).hexdigest()
        cls.rendered = generator.render(cls.events, cls.digest)

    def test_generator_inlines_observers_and_covers_current_product_inventory(self) -> None:
        plugin = PLUGIN.read_text(encoding="utf-8")
        inventory = generator.source_inventory()
        hook_events = inventory["engine_hooks_in_skills"]
        product_sdk_types = set(inventory["sdkhook_types"])
        product_left4dhooks = set(inventory["left4dhooks_callbacks"])

        self.assertEqual(len(hook_events), 38)
        self.assertEqual(len(set(hook_events)), 38)
        self.assertEqual(product_sdk_types, EXPECTED_SDK_TYPES)
        self.assertEqual(product_left4dhooks, EXPECTED_LH_CALLBACKS)
        self.assertEqual(len(product_left4dhooks), 26)
        self.assertEqual(inventory["state_read_observation"], "manual samples; not interception of reads executed by Skills")
        for hook in hook_events:
            self.assertIn(f'"{hook}"', self.rendered)
        for hook_type in EXPECTED_SDK_TYPES:
            self.assertIn(hook_type, self.rendered)
        for callback in EXPECTED_LH_CALLBACKS:
            self.assertRegex(self.rendered, rf"(?m)^public\s+(?:Action|void)\s+{re.escape(callback)}\s*\(")

    def test_real_observer_callbacks_execute_passively_in_sourcepawn_vm(self) -> None:
        if not COMPILER.is_file() or not SHELL.is_file():
            self.skipTest("offline SourcePawn compiler/VM is unavailable; use sibling SteamIDTools VM build")

        with tempfile.TemporaryDirectory(prefix="skills-source-observer-vm-") as directory:
            temp = Path(directory)
            source = temp / "source_observer_test.sp"
            binary = temp / "source_observer_test.smx"
            source.write_text(standalone_vm_harness(), encoding="utf-8")
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
            self.assertIn("SOURCE_OBSERVER_VM checks=23 failures=0", run.stdout)
            self.assertIn("SDK_LIFECYCLE_VM checks=5 failures=0", run.stdout)

    def test_deferred_callback_generation_is_invalidated_by_start_and_stop(self) -> None:
        sdk = SDK_MODULE.read_text(encoding="utf-8")
        self.assertRegex(extract_function(sdk, "SmokeSDK_Start"), r"g_SmokeSDKGeneration\+\+\s*;")
        self.assertRegex(extract_function(sdk, "SmokeSDK_Stop"), r"g_SmokeSDKGeneration\+\+\s*;")
        deferred = extract_function(sdk, "SmokeSDK_HookDeferred")
        self.assertRegex(deferred, r"generation\s*!=\s*g_SmokeSDKGeneration\s*\|\|\s*g_SmokeSDKTrackedEntities\s*==\s*null")
        self.assertRegex(deferred, r"entity\s*==\s*INVALID_ENT_REFERENCE\s*\|\|\s*!IsValidEntity\(entity\)")

    def test_rendered_observer_compiles_without_warnings(self) -> None:
        if not COMPILER.is_file():
            self.skipTest("offline SourcePawn compiler is unavailable")
        with tempfile.TemporaryDirectory(prefix="skills-source-observer-compile-") as directory:
            temp = Path(directory)
            source = temp / "l4d2_skills_source_observer.sp"
            binary = temp / "l4d2_skills_source_observer.smx"
            source.write_text(self.rendered, encoding="utf-8")
            command = [str(COMPILER)]
            for include in INCLUDE_DIRS:
                command.extend(["-i", str(include)])
            command.extend(["-o", str(binary), str(source)])
            compiled = subprocess.run(command, text=True, capture_output=True, check=False)
            self.assertEqual(compiled.returncode, 0, msg=f"spcomp failed\n{compiled.stdout}\n{compiled.stderr}")
            self.assertNotIn("warning ", compiled.stdout.lower())
            self.assertTrue(binary.is_file())
            self.assertGreater(binary.stat().st_size, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
