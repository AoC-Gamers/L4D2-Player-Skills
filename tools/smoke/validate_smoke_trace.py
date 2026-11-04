#!/usr/bin/env python3
"""Validate one complete three-source Skills smoke capture (JSONL only)."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

SOURCES = ("engine", "sdkhooks", "left4dhooks")
HEADER_KINDS = {"callback", "event", "marker", "publication"}
EVENT_PAYLOAD_KINDS = {
    "broadcast", "entity", "field", "identity", "string", "string_chunk", "value"
}
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")


def _error(errors: list[str], source: str, line: int | str, message: str) -> None:
    errors.append(f"{source}:{line}: {message}")


def _reject_nonfinite_json(token: str) -> None:
    raise ValueError(f"non-standard JSON number: {token}")


def _read_file(path: Path, expected_source: str, errors: list[str]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    if not path.is_file():
        _error(errors, expected_source, "-", "missing or partial source file")
        return records
    try:
        raw_lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as exc:
        _error(errors, expected_source, "-", f"cannot read file: {exc}")
        return records
    if not raw_lines:
        _error(errors, expected_source, "-", "empty source file")
        return records
    for line_number, raw in enumerate(raw_lines, 1):
        if not raw:
            _error(errors, expected_source, line_number, "blank JSONL line")
            continue
        try:
            record = json.loads(raw, parse_constant=_reject_nonfinite_json)
        except ValueError as exc:
            _error(errors, expected_source, line_number, f"unparseable JSONL: {exc}")
            continue
        if not isinstance(record, dict):
            _error(errors, expected_source, line_number, "JSONL record must be an object")
            continue
        record["_line"] = line_number
        kind = record.get("kind")
        if not isinstance(kind, str):
            _error(errors, expected_source, line_number, "record kind must be a string")
            kind = "<invalid-kind>"
        record["_kind"] = kind
        seq = record.get("seq")
        if "seq" in record and type(seq) is not int:
            _error(errors, expected_source, line_number, "seq must be an integer")
        record["_safe_seq"] = seq if type(seq) is int else None
        key = record.get("key")
        if "key" in record and not isinstance(key, str):
            _error(errors, expected_source, line_number, "key must be a string")
        record["_safe_key"] = key if isinstance(key, str) else None
        records.append(record)
    return records


def _value_to_byte_string(value: str) -> bytes | None:
    # The observer writes source bytes as JSON U+00XX escapes.  Python's JSON
    # decoder returns those as Unicode characters; only this range is reversible.
    if any(ord(char) > 0xFF for char in value):
        return None
    return bytes(ord(char) for char in value)


def _validate_strings(records: list[dict[str, Any]], source: str, errors: list[str]) -> int:
    headers: dict[tuple[Any, Any], dict[str, Any]] = {}
    chunks: dict[tuple[Any, Any], list[dict[str, Any]]] = defaultdict(list)
    for record in records:
        kind = record["_kind"]
        key = (record["_safe_seq"], record["_safe_key"])
        if kind == "string":
            if key in headers:
                _error(errors, source, record["_line"], f"duplicate string header for seq/key {key}")
            headers[key] = record
            if record.get("possible_truncation") != 0:
                _error(errors, source, record["_line"], "string getter reports possible truncation")
            if not isinstance(record.get("length"), int) or record["length"] < 0:
                _error(errors, source, record["_line"], "string length must be a non-negative integer")
        elif kind == "string_chunk":
            chunks[key].append(record)

    for key, chunk_records in chunks.items():
        if key not in headers:
            _error(errors, source, chunk_records[0]["_line"], f"orphan string chunks for seq/key {key}")

    string_bytes = 0
    for key, header in headers.items():
        chunk_records = chunks.get(key, [])
        expected_offset = 0
        pieces: list[bytes] = []
        for chunk in chunk_records:
            offset = chunk.get("offset")
            if offset != expected_offset:
                _error(errors, source, chunk["_line"], f"chunk offset {offset!r} does not match expected {expected_offset}")
            value = chunk.get("value")
            if not isinstance(value, str):
                _error(errors, source, chunk["_line"], "string chunk value must be a string")
                continue
            piece = _value_to_byte_string(value)
            if piece is None:
                _error(errors, source, chunk["_line"], "chunk contains code point above U+00FF; source bytes cannot be reconstructed")
                continue
            if len(piece) > 128:
                _error(errors, source, chunk["_line"], "string chunk exceeds 128 source bytes")
            pieces.append(piece)
            expected_offset += len(piece)
        reconstructed = b"".join(pieces)
        declared = header.get("length")
        if isinstance(declared, int) and len(reconstructed) != declared:
            _error(errors, source, header["_line"], f"string chunks reconstruct {len(reconstructed)} bytes, header declares {declared}")
        string_bytes += len(reconstructed)
    return string_bytes


def validate_trace_paths(paths: dict[str, Path]) -> dict[str, Any]:
    """Return a machine-readable validation report for engine/SDK/LH JSONL paths."""
    errors: list[str] = []
    per_source: dict[str, dict[str, Any]] = {}
    catalogs: dict[str, dict[str, Any]] = {}
    all_header_seqs: dict[int, tuple[str, int]] = {}
    global_headers: list[tuple[int, str, dict[str, Any]]] = []
    counts: Counter[str] = Counter()
    total_string_bytes = 0

    for source in SOURCES:
        path = paths.get(source)
        if path is None:
            _error(errors, source, "-", "source path was not provided")
            per_source[source] = {"records": 0, "headers": 0, "strings_bytes": 0}
            continue
        records = _read_file(Path(path), source, errors)
        per_source[source] = {"records": len(records), "headers": 0, "strings_bytes": 0}
        counts.update(record["_kind"] for record in records)

        catalog_rows = [record for record in records if record["_kind"] == "catalog"]
        if len(catalog_rows) != 1:
            _error(errors, source, "-", f"expected exactly one catalog header, found {len(catalog_rows)}")
        elif catalog_rows:
            catalog = catalog_rows[0]
            catalogs[source] = catalog
            if catalog.get("source") != source:
                _error(errors, source, catalog["_line"], f"catalog source is {catalog.get('source')!r}")
            if not isinstance(catalog.get("run_id"), str) or not catalog["run_id"]:
                _error(errors, source, catalog["_line"], "catalog run_id must be non-empty")
            if not isinstance(catalog.get("sha256"), str) or not SHA256_RE.fullmatch(catalog["sha256"]):
                _error(errors, source, catalog["_line"], "catalog sha256 must be 64 lowercase hexadecimal characters")

        headers: dict[int, dict[str, Any]] = {}
        last_header_seq = 0
        source_header_rows: list[dict[str, Any]] = []
        for record in records:
            line = record["_line"]
            kind = record["_kind"]
            if kind in HEADER_KINDS:
                seq = record["_safe_seq"]
                if seq is None or seq <= 0:
                    _error(errors, source, line, f"{kind} header seq must be a positive integer")
                    continue
                per_source[source]["headers"] += 1
                if seq in all_header_seqs:
                    prior_source, prior_line = all_header_seqs[seq]
                    _error(errors, source, line, f"global header seq {seq} duplicates {prior_source}:{prior_line}")
                else:
                    all_header_seqs[seq] = (source, line)
                global_headers.append((seq, source, record))
                if seq <= last_header_seq:
                    _error(errors, source, line, f"header seq {seq} is not increasing within file")
                last_header_seq = max(last_header_seq, seq)
                headers[seq] = record
                source_header_rows.append(record)
            if "seq" in record and kind not in HEADER_KINDS:
                seq = record["_safe_seq"]
                if seq is None or seq <= 0:
                    _error(errors, source, line, f"{kind} seq must be a positive integer")
                elif seq not in headers:
                    _error(errors, source, line, f"{kind} seq {seq} has no earlier header in this file")

            if kind == "value" and record.get("type") == "float":
                if not isinstance(record.get("text"), str) or not isinstance(record.get("bits"), int):
                    _error(errors, source, line, "float value requires textual representation and integer bits")

        # Any child record carrying seq must point to a same-file earlier header.
        # The online pass above ensures ordering as well as ownership.
        events = {
            record["_safe_seq"]: record
            for record in records
            if record["_kind"] == "event" and record["_safe_seq"] is not None
        }
        event_ends: Counter[int] = Counter(
            record["_safe_seq"]
            for record in records
            if record["_kind"] == "event_end" and record["_safe_seq"] is not None
        )
        for event_end in (record for record in records if record["_kind"] == "event_end"):
            seq = event_end["_safe_seq"]
            if seq is None or seq not in events:
                _error(errors, source, event_end["_line"], f"event_end seq {seq!r} has no event header")
            elif event_ends[seq] > 1:
                prior_end = next(
                    (
                        row
                        for row in records
                        if row["_kind"] == "event_end"
                        and row["_safe_seq"] == seq
                        and row["_line"] < event_end["_line"]
                    ),
                    None,
                )
                if prior_end is not None:
                    _error(errors, source, event_end["_line"], f"duplicate event_end for seq {seq}")
        payload_by_seq: dict[Any, list[dict[str, Any]]] = defaultdict(list)
        for record in records:
            if record["_kind"] in EVENT_PAYLOAD_KINDS and record["_safe_seq"] is not None:
                payload_by_seq[record["_safe_seq"]].append(record)
        for seq, event in events.items():
            if event.get("valid") == 1:
                if event_ends[seq] == 0:
                    _error(errors, source, event["_line"], f"valid event seq {seq} has no event_end")
                elif event_ends[seq] > 1:
                    _error(errors, source, event["_line"], f"valid event seq {seq} has duplicate event_end")
            elif event.get("valid") == 0:
                payload = payload_by_seq.get(seq, [])
                if payload:
                    _error(errors, source, event["_line"], f"invalid event seq {seq} has payload records")
                if event_ends[seq]:
                    _error(errors, source, event["_line"], f"invalid event seq {seq} unexpectedly has event_end")
            else:
                _error(errors, source, event["_line"], f"event seq {seq} valid must be 0 or 1")

        string_bytes = _validate_strings(records, source, errors)
        per_source[source]["strings_bytes"] = string_bytes
        total_string_bytes += string_bytes

        callbacks = [record for record in records if record["_kind"] == "callback"]
        callback_names = [record.get("callback") for record in callbacks]
        for marker in ("capture_start", "capture_stop"):
            found = callback_names.count(marker)
            if found != 1:
                _error(errors, source, "-", f"expected one {marker}, found {found}")
        health = [record for record in records if record["_kind"] == "health"]
        if len(health) != 1:
            _error(errors, source, "-", f"expected exactly one health record, found {len(health)}")
        else:
            row = health[0]
            if row.get("scope") != "through_payload_flush":
                _error(errors, source, row["_line"], "health scope must be through_payload_flush")
            if row.get("write_failures") != 0 or row.get("truncated_lines") != 0:
                _error(errors, source, row["_line"], "health reports write failures or truncated lines")
            stop = next((item for item in callbacks if item.get("callback") == "capture_stop"), None)
            if stop is not None and row["_line"] <= stop["_line"]:
                _error(errors, source, row["_line"], "health must follow capture_stop")
            if records and row["_line"] != records[-1]["_line"]:
                _error(errors, source, row["_line"], "health must be the final JSONL record")

        if records and records[0]["_kind"] != "catalog":
            _error(errors, source, records[0]["_line"], "catalog must be the first JSONL record")
        if source_header_rows:
            if source_header_rows[0]["_kind"] != "callback" or source_header_rows[0].get("callback") != "capture_start":
                _error(errors, source, source_header_rows[0]["_line"], "capture_start must be the first header")
            if source_header_rows[-1]["_kind"] != "callback" or source_header_rows[-1].get("callback") != "capture_stop":
                _error(errors, source, source_header_rows[-1]["_line"], "capture_stop must be the last header")

    ordered_headers = sorted(global_headers, key=lambda item: item[0])
    observed_seqs = [seq for seq, _, _ in ordered_headers]
    if observed_seqs != list(range(1, len(observed_seqs) + 1)):
        errors.append("global headers: seq values must be unique and contiguous from 1")

    last_epoch: int | None = None
    last_tick_in_epoch: int | None = None
    for seq, source, record in ordered_headers:
        epoch, tick = record.get("map_epoch"), record.get("tick")
        if type(epoch) is not int or type(tick) is not int:
            _error(errors, source, record["_line"], f"header seq {seq} requires integer map_epoch and tick")
            continue
        if last_epoch is not None and epoch < last_epoch:
            _error(errors, source, record["_line"], f"map_epoch regressed globally: {epoch} < {last_epoch}")
        if epoch != last_epoch:
            last_epoch = epoch
            last_tick_in_epoch = tick
        elif last_tick_in_epoch is not None and tick < last_tick_in_epoch:
            _error(errors, source, record["_line"], f"global tick regressed in map_epoch {epoch}: {tick} < {last_tick_in_epoch} at seq order")
        else:
            last_tick_in_epoch = tick

    if len(catalogs) == len(SOURCES):
        run_ids = [row.get("run_id") for row in catalogs.values() if isinstance(row.get("run_id"), str)]
        hashes = [row.get("sha256") for row in catalogs.values() if isinstance(row.get("sha256"), str)]
        if len(run_ids) == len(SOURCES) and len(set(run_ids)) != 1:
            errors.append("catalog headers: run_id differs across sources")
        if len(hashes) == len(SOURCES) and len(set(hashes)) != 1:
            errors.append("catalog headers: sha256 differs across sources")

    return {
        "valid": not errors,
        "errors": errors,
        "run_id": next((row.get("run_id") for row in catalogs.values() if isinstance(row.get("run_id"), str)), None),
        "catalog_sha256": next((row.get("sha256") for row in catalogs.values() if isinstance(row.get("sha256"), str)), None),
        "sources": per_source,
        "record_counts": dict(sorted(counts.items())),
        "global_headers": len(all_header_seqs),
        "reconstructed_string_bytes": total_string_bytes,
        "interpretation": "Structural integrity only; seq/tick order does not establish causal correlation or baseline equivalence.",
    }


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("engine", type=Path, help="engine JSONL path")
    parser.add_argument("sdkhooks", type=Path, help="SDKHooks JSONL path")
    parser.add_argument("left4dhooks", type=Path, help="Left4DHooks JSONL path")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    report = validate_trace_paths({source: getattr(args, source) for source in SOURCES})
    print(json.dumps(report, ensure_ascii=True, sort_keys=True, indent=2))
    return 0 if report["valid"] else 1


if __name__ == "__main__":
    sys.exit(main())
