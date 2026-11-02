#!/usr/bin/env python3
"""Local generator and SourcePawn compile checks for the game-event observer."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SMOKE = ROOT / "tools" / "smoke"
CATALOG = ROOT / "docs" / "l4d2_game_events.json"
PLUGIN_SOURCE = ROOT / "addons" / "sourcemod" / "scripting" / "l4d2_player_skills.sp"
COMPILER = ROOT / "deps" / "sourcemod-linux" / "addons" / "sourcemod" / "scripting" / "spcomp"
INCLUDES = [
    ROOT / "deps" / "sourcemod-linux" / "addons" / "sourcemod" / "scripting" / "include",
    ROOT / "addons" / "sourcemod" / "scripting" / "include",
]

SPEC = importlib.util.spec_from_file_location(
    "generate_game_event_observer", SMOKE / "generate_game_event_observer.py"
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("cannot import tools/smoke/generate_game_event_observer.py")
generator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(generator)


class GameEventObserverGeneratorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog = generator.load_catalog(CATALOG)
        cls.digest = hashlib.sha256(CATALOG.read_bytes()).hexdigest()

    def test_catalog_has_301_unique_events_plus_player_spawn(self) -> None:
        raw = json.loads(CATALOG.read_text(encoding="utf-8"))
        names = [event["name"] for event in self.catalog]
        ids = [event["id"] for event in raw["events"]]

        self.assertEqual(raw["count"], 301)
        self.assertEqual(len(raw["events"]), 301)
        self.assertEqual(len(names), 302)
        self.assertEqual(len(set(names)), 302)
        self.assertEqual(len(set(ids)), 301)
        self.assertIn("player_death", names)
        self.assertIn("player_spawn", names)

        spawn = next(event for event in self.catalog if event["name"] == "player_spawn")
        self.assertEqual(spawn["fields"], [{"key": "userid", "type": "short", "is_userid": True}])

    def test_every_normalized_field_is_typed_and_userid_is_marked(self) -> None:
        allowed_types = {"short", "long", "string", "bool", "byte", "float"}
        userid_fields = []
        for event in self.catalog:
            self.assertTrue(event["name"])
            self.assertIsInstance(event["fields"], list)
            for field in event["fields"]:
                self.assertIsInstance(field["key"], str)
                self.assertTrue(field["key"])
                self.assertIsInstance(field["type"], str)
                self.assertIn(field["type"], allowed_types)
                self.assertIsInstance(field["is_userid"], bool)
                if field["key"] == "userid":
                    userid_fields.append(field)
                    self.assertTrue(field["is_userid"])
        self.assertTrue(userid_fields)

    def test_entity_indices_are_never_resolved_as_userids(self) -> None:
        for event_name in ['player_death', 'player_hurt', 'player_hurt_concise']:
            event = next(item for item in self.catalog if item['name'] == event_name)
            for field in event['fields']:
                if 'entid' in field['key'] or 'entity' in field['key']:
                    self.assertFalse(field['is_userid'], (event_name, field['key']))
        death = next(item for item in self.catalog if item['name'] == 'player_death')
        self.assertTrue(next(field for field in death['fields'] if field['key'] == 'attacker')['is_userid'])

    def test_current_plugin_hooks_are_covered(self) -> None:
        source = PLUGIN_SOURCE.read_text(encoding="utf-8")
        hook_names = re.findall(r'\bHookEvent\s*\(\s*"([^"]+)"', source)
        self.assertEqual(len(hook_names), 38)
        self.assertEqual(len(set(hook_names)), 38)
        observer_names = {event["name"] for event in self.catalog}
        self.assertLessEqual(set(hook_names), observer_names)

    def test_metadata_fields_are_skipped(self) -> None:
        fixture = {
            "count": 1,
            "events": [
                {
                    "id": 1,
                    "name": "fixture_event",
                    "arguments": [
                        {"type": "userid", "name": "short"},
                        {"type": "None", "name": "None"},
                        {"type": "none", "name": "none"},
                        {"type": "local", "name": "1"},
                        {"type": "reliable", "name": "1"},
                    ],
                }
            ],
        }
        with tempfile.TemporaryDirectory(prefix="skills-event-catalog-") as directory:
            path = Path(directory) / "catalog.json"
            path.write_text(json.dumps(fixture), encoding="utf-8")
            events = generator.load_catalog(path)
        fixture_event = next(event for event in events if event["name"] == "fixture_event")
        self.assertEqual(fixture_event["fields"], [{"key": "userid", "type": "short", "is_userid": True}])

    def test_duplicate_event_name_is_rejected(self) -> None:
        raw = json.loads(CATALOG.read_text(encoding="utf-8"))
        duplicate = dict(raw["events"][0])
        duplicate["id"] = max(event["id"] for event in raw["events"]) + 1
        raw["events"].append(duplicate)
        raw["count"] = len(raw["events"])
        with tempfile.TemporaryDirectory(prefix="skills-event-catalog-duplicate-") as directory:
            path = Path(directory) / "catalog.json"
            path.write_text(json.dumps(raw), encoding="utf-8")
            with self.assertRaises((ValueError, RuntimeError)):
                generator.load_catalog(path)

    def test_unknown_field_type_is_rejected(self) -> None:
        raw = json.loads(CATALOG.read_text(encoding="utf-8"))
        event = {
            "id": max(item["id"] for item in raw["events"]) + 1,
            "name": "codex_unknown_type_fixture",
            "arguments": [{"type": "fixture_key", "name": "made_up_type"}],
        }
        raw["events"].append(event)
        raw["count"] = len(raw["events"])
        with tempfile.TemporaryDirectory(prefix="skills-event-catalog-type-") as directory:
            path = Path(directory) / "catalog.json"
            path.write_text(json.dumps(raw), encoding="utf-8")
            with self.assertRaises((ValueError, RuntimeError)):
                generator.load_catalog(path)

    def test_render_is_deterministic_and_compiles(self) -> None:
        source = generator.render(self.catalog, self.digest)
        self.assertEqual(source, generator.render(self.catalog, self.digest))
        self.assertIn("player_death", source)

        with tempfile.TemporaryDirectory(prefix="skills-event-observer-compile-") as directory:
            temp = Path(directory)
            source_path = temp / "game_event_observer.sp"
            output_path = temp / "game_event_observer.smx"
            source_path.write_text(source, encoding="utf-8")
            command = [str(COMPILER)]
            for include in INCLUDES:
                command.extend(["-i", str(include)])
            command.extend(["-o", str(output_path), str(source_path)])
            completed = subprocess.run(command, text=True, capture_output=True, check=False)
            self.assertEqual(
                completed.returncode,
                0,
                msg=f"spcomp failed\nstdout:\n{completed.stdout}\nstderr:\n{completed.stderr}",
            )
            self.assertNotIn("warning ", completed.stdout.lower())
            self.assertTrue(output_path.is_file())
            self.assertGreater(output_path.stat().st_size, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
