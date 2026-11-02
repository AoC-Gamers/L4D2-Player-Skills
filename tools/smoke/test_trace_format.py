#!/usr/bin/env python3
"""Unit and SourcePawn VM checks for smoke trace structure and string encoding."""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
import unittest
from pathlib import Path
from typing import Any

from validate_smoke_trace import SOURCES, validate_trace_paths

ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "tools/smoke/game_event_observer.sp.in"
VALIDATOR = ROOT / "tools/smoke/validate_smoke_trace.py"
COMPILER = ROOT / "deps/sourcemod-linux/addons/sourcemod/scripting/spcomp"
SHELL = ROOT.parent / "SteamIDTools/deps/sourcepawn/objdir/spshell/linux-x86_64/spshell"
SHA = "a" * 64


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.write_text("".join(json.dumps(row, ensure_ascii=True) + "\n" for row in rows), encoding="utf-8")


def base_capture() -> dict[str, list[dict[str, Any]]]:
    files = {
        source: [{"kind": "catalog", "source": source, "run_id": "run-fixture", "sha256": SHA, "names": 302}]
        for source in SOURCES
    }
    next_seq = 0

    def header(source: str, kind: str, tick: int, epoch: int, **fields: Any) -> int:
        nonlocal next_seq
        next_seq += 1
        files[source].append({
            "kind": kind,
            "seq": next_seq,
            "tick": tick,
            "game_time": float(tick) / 10,
            "engine_time": float(next_seq),
            "map_epoch": epoch,
            "map": "c1m1" if epoch == 0 else "c1m2",
            **fields,
        })
        return next_seq

    header("engine", "callback", 10, 0, callback="capture_start")
    header("sdkhooks", "callback", 10, 0, callback="capture_start")
    header("left4dhooks", "callback", 10, 0, callback="capture_start")
    event_seq = header("engine", "event", 11, 0, name="player_death", phase="pre", valid=1)
    files["engine"] += [
        {"kind": "value", "seq": event_seq, "key": "damage_nan", "type": "float", "text": "nan", "bits": 2143289344},
        {"kind": "value", "seq": event_seq, "key": "damage_neg_inf", "type": "float", "text": "-inf", "bits": -8388608},
        {"kind": "string", "seq": event_seq, "key": "weapon", "length": 3, "possible_truncation": 0},
        {"kind": "string_chunk", "seq": event_seq, "key": "weapon", "offset": 0, "value": "gun"},
        {"kind": "event_end", "seq": event_seq},
    ]
    header("sdkhooks", "callback", 11, 0, callback="coverage")
    header("left4dhooks", "callback", 11, 0, callback="coverage")
    post_seq = header("engine", "event", 11, 0, name="player_death", phase="post", valid=1)
    files["engine"].append({"kind": "event_end", "seq": post_seq})
    header("engine", "event", 12, 0, name="fixture_null", phase="pre", valid=0)
    header("engine", "marker", 12, 0, marker="map_end", userid=0)
    header("engine", "callback", 0, 1, callback="map_start")
    header("engine", "publication", 0, 1, family="skill_event", id=1, type=1)
    header("engine", "callback", 20, 1, callback="capture_stop")
    header("sdkhooks", "callback", 20, 1, callback="capture_stop")
    header("left4dhooks", "callback", 20, 1, callback="capture_stop")
    for source in SOURCES:
        files[source].append({"kind": "health", "write_failures": 0, "truncated_lines": 0, "scope": "through_payload_flush"})
    return files


def persist_capture(directory: Path, files: dict[str, list[dict[str, Any]]]) -> dict[str, Path]:
    paths: dict[str, Path] = {}
    for source in SOURCES:
        path = directory / f"run-fixture.{source}.jsonl"
        write_jsonl(path, files[source])
        paths[source] = path
    return paths


def extract_function(source: str, name: str) -> str:
    match = re.search(rf"(?m)^void\s+{re.escape(name)}\s*\([^)]*\)\s*\{{", source)
    if not match:
        raise AssertionError(f"function {name} not found")
    start = match.start()
    brace = source.find("{", match.start(), match.end())
    depth = 0
    quote = ""
    escaped = False
    for position in range(brace, len(source)):
        char = source[position]
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = ""
            continue
        if char in {'"', "'"}:
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start : position + 1]
    raise AssertionError(f"unterminated function {name}")


def sourcepawn_string_harness() -> str:
    template = TEMPLATE.read_text(encoding="utf-8")
    function = extract_function(template, "TraceTextValue")
    replacements = [
        (
            r'TraceLine(source, "{\"kind\":\"string\",\"seq\":%d,\"key\":\"%s\",\"length\":%d,\"possible_truncation\":%d}", sequence, key, length, possibleTruncation);',
            "EmitHeader(source, sequence, key, length, possibleTruncation);",
        ),
        (
            r'TraceLine(source, "{\"kind\":\"string_chunk\",\"seq\":%d,\"key\":\"%s\",\"offset\":%d,\"value\":\"%s\"}", sequence, key, offset, escaped);',
            "EmitChunk(source, sequence, key, offset, escaped);",
        ),
        (
            r'FormatEx(escaped[out], sizeof(escaped) - out, "\\u%04x", c)',
            "SmokeTest_EncodeByte(escaped[out], sizeof(escaped) - out, c)",
        ),
    ]
    for original, replacement in replacements:
        count = function.count(original)
        if count != 1:
            raise AssertionError(f"expected one source-only serializer substitution, got {count}: {original}")
        function = function.replace(original, replacement)

    prefix = r'''#pragma semicolon 1
#pragma newdecls required

enum TraceSource { TraceSource_Engine = 0 }
native void printf(const char[] format, any ...);

int SmokeTest_EncodeByte(char[] output, int capacity, int value)
{
	static const char hex[] = "0123456789abcdef";
	if (capacity < 7) return 0;
	output[0] = '\\'; output[1] = 'u'; output[2] = '0'; output[3] = '0';
	output[4] = hex[(value >> 4) & 15]; output[5] = hex[value & 15]; output[6] = '\0';
	return 6;
}

void EmitHeader(int source, int sequence, const char[] key, int length, bool truncation)
{
	printf("{\"kind\":\"string\",\"source\":%d,\"seq\":%d,\"key\":\"%s\",\"length\":%d,\"possible_truncation\":%d}\n", view_as<int>(source), sequence, key, length, truncation);
}

void EmitChunk(int source, int sequence, const char[] key, int offset, const char[] escaped)
{
	printf("{\"kind\":\"string_chunk\",\"source\":%d,\"seq\":%d,\"key\":\"%s\",\"offset\":%d,\"value\":\"%s\"}\n", view_as<int>(source), sequence, key, offset, escaped);
}

'''
    suffix = r'''

void RunSmallCases()
{
	char empty[1]; empty[0] = '\0';
	TraceTextValue(TraceSource_Engine, 1, "empty", empty, false);

	char boundary[260];
	for (int i = 0; i < sizeof(boundary) - 1; i++) boundary[i] = 'A' + (i % 26);
	boundary[126] = '"'; boundary[127] = 0xC3; boundary[128] = 0xA9;
	boundary[129] = '\\'; boundary[130] = 0x01; boundary[131] = '\n';
	boundary[sizeof(boundary) - 1] = '\0';
	TraceTextValue(TraceSource_Engine, 2, "boundary", boundary, false);
}

void RunTruncatedLimitCase()
{
	char maximum[4096];
	for (int i = 0; i < sizeof(maximum) - 1; i++) maximum[i] = (i % 3 == 0) ? '"' : ((i % 3 == 1) ? '\\' : 0x7F);
	maximum[sizeof(maximum) - 1] = '\0';
	TraceTextValue(TraceSource_Engine, 3, "maximum", maximum, true);
}

public int main()
{
	RunSmallCases();
	RunTruncatedLimitCase();
	return 0;
}
'''
    return prefix + function + suffix


def collect_vm_output() -> list[dict[str, Any]]:
    if not COMPILER.is_file() or not SHELL.is_file():
        raise unittest.SkipTest("SourcePawn compiler or spshell is unavailable")
    with tempfile.TemporaryDirectory(prefix="skills-trace-format-vm-") as temporary:
        temp = Path(temporary)
        source = temp / "trace_format_vm.sp"
        binary = temp / "trace_format_vm.smx"
        source.write_text(sourcepawn_string_harness(), encoding="utf-8")
        compiled = subprocess.run([str(COMPILER), "-o", str(binary), str(source)], text=True, capture_output=True, check=False)
        if compiled.returncode != 0 or "warning " in compiled.stdout.lower():
            raise AssertionError(f"SourcePawn compile failed or warned:\n{compiled.stdout}\n{compiled.stderr}")
        run = subprocess.run([str(SHELL), str(binary)], text=True, capture_output=True, check=False)
        if run.returncode != 0:
            raise AssertionError(f"SourcePawn VM failed:\n{run.stdout}\n{run.stderr}")
        rows = []
        for line in run.stdout.splitlines():
            if line.startswith("{"):
                rows.append(json.loads(line))
        return rows


def reconstruct(rows: list[dict[str, Any]], sequence: int) -> bytes:
    header = next(row for row in rows if row.get("kind") == "string" and row.get("seq") == sequence)
    chunks = sorted((row for row in rows if row.get("kind") == "string_chunk" and row.get("seq") == sequence), key=lambda row: row["offset"])
    raw = bytearray()
    for chunk in chunks:
        assert chunk["offset"] == len(raw)
        assert all(ord(char) <= 255 for char in chunk["value"])
        raw.extend(ord(char) for char in chunk["value"])
    assert len(raw) == header["length"]
    return bytes(raw)


class TraceStructureTests(unittest.TestCase):
    def test_three_source_session_and_structural_metadata(self) -> None:
        with tempfile.TemporaryDirectory(prefix="skills-trace-valid-") as directory:
            paths = persist_capture(Path(directory), base_capture())
            report = validate_trace_paths(paths)
        self.assertTrue(report["valid"], report["errors"])
        self.assertEqual(report["run_id"], "run-fixture")
        self.assertEqual(report["global_headers"], 14)
        self.assertEqual(report["record_counts"]["event"], 3)
        self.assertEqual(report["record_counts"]["health"], 3)
        self.assertIn("does not establish causal correlation", report["interpretation"])

    def test_catalog_mismatch_duplicate_seq_and_incomplete_session_fail(self) -> None:
        files = base_capture()
        files["sdkhooks"][0]["run_id"] = "different-run"
        # Reuse the first engine header seq in SDKHooks.
        files["sdkhooks"][1]["seq"] = files["engine"][1]["seq"]
        files["left4dhooks"] = [row for row in files["left4dhooks"] if not (row.get("kind") == "health")]
        with tempfile.TemporaryDirectory(prefix="skills-trace-invalid-") as directory:
            report = validate_trace_paths(persist_capture(Path(directory), files))
        self.assertFalse(report["valid"])
        self.assertTrue(any("run_id differs" in error for error in report["errors"]))
        self.assertTrue(any("duplicates" in error for error in report["errors"]))
        self.assertTrue(any("health record" in error for error in report["errors"]))

    def test_string_chunk_integrity_health_scope_and_ticks_are_enforced(self) -> None:
        files = base_capture()
        engine = files["engine"]
        header = next(row for row in engine if row.get("kind") == "string")
        header["length"] = 9
        health = next(row for row in engine if row.get("kind") == "health")
        health["scope"] = "before_payload_flush"
        # A same-epoch regression is rejected; a new epoch reset above is accepted.
        event = next(row for row in engine if row.get("kind") == "event" and row.get("phase") == "post")
        event["tick"] = 1
        with tempfile.TemporaryDirectory(prefix="skills-trace-integrity-") as directory:
            report = validate_trace_paths(persist_capture(Path(directory), files))
        self.assertFalse(report["valid"])
        self.assertTrue(any("reconstruct" in error for error in report["errors"]))
        self.assertTrue(any("scope must be through_payload_flush" in error for error in report["errors"]))
        self.assertTrue(any("tick regressed" in error for error in report["errors"]))

    def test_health_requires_zero_counters_and_final_payload_flush_scope(self) -> None:
        files = base_capture()
        health = next(row for row in files["sdkhooks"] if row.get("kind") == "health")
        health["write_failures"] = 1
        files["left4dhooks"].append({"kind": "late_marker_without_seq"})
        with tempfile.TemporaryDirectory(prefix="skills-trace-health-") as directory:
            report = validate_trace_paths(persist_capture(Path(directory), files))
        self.assertFalse(report["valid"])
        self.assertTrue(any("write failures" in error for error in report["errors"]))
        self.assertTrue(any("final JSONL record" in error for error in report["errors"]))

    def test_global_ticks_and_epoch_order_follow_merged_sequence(self) -> None:
        files = base_capture()
        sdk_coverage = next(row for row in files["sdkhooks"] if row.get("callback") == "coverage")
        lh_coverage = next(row for row in files["left4dhooks"] if row.get("callback") == "coverage")
        sdk_coverage["tick"] = 100
        lh_coverage["tick"] = 99
        with tempfile.TemporaryDirectory(prefix="skills-trace-global-tick-") as directory:
            report = validate_trace_paths(persist_capture(Path(directory), files))
        self.assertFalse(report["valid"])
        self.assertTrue(any("global tick regressed" in error for error in report["errors"]))

        files = base_capture()
        lh_start = next(row for row in files["left4dhooks"] if row.get("callback") == "capture_start")
        engine_event = next(row for row in files["engine"] if row.get("kind") == "event")
        lh_start["map_epoch"] = 1
        engine_event["map_epoch"] = 0
        with tempfile.TemporaryDirectory(prefix="skills-trace-global-epoch-") as directory:
            report = validate_trace_paths(persist_capture(Path(directory), files))
        self.assertTrue(any("map_epoch regressed globally" in error for error in report["errors"]))

    def test_global_sequence_must_be_contiguous_and_event_end_must_be_unique(self) -> None:
        files = base_capture()
        coverage = next(row for row in files["sdkhooks"] if row.get("callback") == "coverage")
        coverage["seq"] = 55
        engine = files["engine"]
        event_seq = next(row["seq"] for row in engine if row.get("kind") == "event" and row.get("phase") == "pre")
        engine.extend([{"kind": "event_end", "seq": event_seq}, {"kind": "event_end", "seq": 1}])
        with tempfile.TemporaryDirectory(prefix="skills-trace-global-seq-") as directory:
            report = validate_trace_paths(persist_capture(Path(directory), files))
        self.assertFalse(report["valid"])
        self.assertTrue(any("contiguous from 1" in error for error in report["errors"]))
        self.assertTrue(any("duplicate event_end" in error for error in report["errors"]))
        self.assertTrue(any("has no event header" in error for error in report["errors"]))

    def test_catalog_capture_start_and_capture_stop_order_is_enforced(self) -> None:
        files = base_capture()
        engine = files["engine"]
        capture_start = engine.pop(1)
        engine.insert(2, capture_start)
        catalog = engine.pop(0)
        engine.insert(1, catalog)
        capture_stop = next(row for row in files["sdkhooks"] if row.get("callback") == "capture_stop")
        files["sdkhooks"].insert(-1, {
            "kind": "callback",
            "seq": capture_stop["seq"] + 1,
            "tick": 21,
            "game_time": 2.1,
            "engine_time": 99.0,
            "map_epoch": 1,
            "map": "c1m2",
            "callback": "late_callback",
        })
        with tempfile.TemporaryDirectory(prefix="skills-trace-boundaries-") as directory:
            report = validate_trace_paths(persist_capture(Path(directory), files))
        self.assertFalse(report["valid"])
        self.assertTrue(any("catalog must be the first" in error for error in report["errors"]))
        self.assertTrue(any("capture_start must be the first header" in error for error in report["errors"]))
        self.assertTrue(any("capture_stop must be the last header" in error for error in report["errors"]))

    def test_malformed_kind_seq_key_and_run_id_types_return_errors_not_exceptions(self) -> None:
        files = base_capture()
        files["engine"][0]["run_id"] = {"bad": "id"}
        event = next(row for row in files["engine"] if row.get("kind") == "event")
        event["kind"] = ["event"]
        files["sdkhooks"][1]["seq"] = [2]
        string_header = next(row for row in files["engine"] if row.get("kind") == "string")
        string_header["key"] = ["weapon"]
        with tempfile.TemporaryDirectory(prefix="skills-trace-malformed-fields-") as directory:
            report = validate_trace_paths(persist_capture(Path(directory), files))
        self.assertFalse(report["valid"])
        self.assertTrue(any("kind must be a string" in error for error in report["errors"]))
        self.assertTrue(any("seq must be an integer" in error for error in report["errors"]))
        self.assertTrue(any("key must be a string" in error for error in report["errors"]))
        self.assertTrue(any("run_id must be non-empty" in error for error in report["errors"]))

    def test_nonstandard_json_numbers_are_not_accepted_as_numeric_tokens(self) -> None:
        files = base_capture()
        files['engine'][0]['wall_time'] = float('nan')
        with tempfile.TemporaryDirectory(prefix='skills-nonstandard-json-') as directory:
            paths = persist_capture(Path(directory), files)
            report = validate_trace_paths(paths)
        self.assertFalse(report['valid'])
        self.assertTrue(any('non-standard JSON number' in message for message in report['errors']))

    def test_parser_rejects_partial_or_unparseable_files(self) -> None:
        with tempfile.TemporaryDirectory(prefix="skills-trace-partial-") as directory:
            paths = persist_capture(Path(directory), base_capture())
            paths["sdkhooks"].write_text('{"kind":"catalog"\n', encoding="utf-8")
            paths["left4dhooks"].unlink()
            report = validate_trace_paths(paths)
        self.assertFalse(report["valid"])
        self.assertTrue(any("unparseable JSONL" in error for error in report["errors"]))
        self.assertTrue(any("missing or partial" in error for error in report["errors"]))

    def test_cli_prints_json_and_returns_nonzero_for_invalid_capture(self) -> None:
        with tempfile.TemporaryDirectory(prefix="skills-trace-cli-") as directory:
            files = base_capture()
            files["engine"] = [row for row in files["engine"] if row.get("kind") != "health"]
            paths = persist_capture(Path(directory), files)
            result = subprocess.run(
                ["python3", str(VALIDATOR), *(str(paths[source]) for source in SOURCES)],
                text=True,
                capture_output=True,
                check=False,
            )
        self.assertEqual(result.returncode, 1)
        self.assertTrue(json.loads(result.stdout)["errors"])

    def test_nonfinite_float_values_remain_valid_json_text_plus_bits(self) -> None:
        with tempfile.TemporaryDirectory(prefix="skills-trace-floats-") as directory:
            paths = persist_capture(Path(directory), base_capture())
            report = validate_trace_paths(paths)
            self.assertTrue(report["valid"], report["errors"])
            rows = [json.loads(line) for line in paths["engine"].read_text(encoding="utf-8").splitlines()]
            floats = [row for row in rows if row.get("kind") == "value" and row.get("type") == "float"]
            self.assertEqual([(row["text"], row["bits"]) for row in floats], [("nan", 2143289344), ("-inf", -8388608)])


class TraceTextValueSourcePawnTests(unittest.TestCase):
    def test_real_sourcepawn_escape_loop_emits_reversible_json_chunks(self) -> None:
        rows = collect_vm_output()
        for sequence in (1, 2, 3):
            self.assertTrue(rows, "VM emitted no JSON records")
            self.assertEqual(len(reconstruct(rows, sequence)), next(row["length"] for row in rows if row.get("kind") == "string" and row.get("seq") == sequence))

        self.assertEqual(reconstruct(rows, 1), b"")
        boundary = reconstruct(rows, 2)
        self.assertEqual(boundary[126:132], b'"\xc3\xa9\\\x01\n')
        self.assertEqual(len([row for row in rows if row.get("kind") == "string_chunk" and row.get("seq") == 2]), 3)
        maximum = reconstruct(rows, 3)
        self.assertEqual(len(maximum), 4095)
        max_header = next(row for row in rows if row.get("kind") == "string" and row.get("seq") == 3)
        self.assertEqual(max_header["possible_truncation"], 1)
        self.assertTrue(all(len(row["value"]) <= 128 for row in rows if row.get("kind") == "string_chunk"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
