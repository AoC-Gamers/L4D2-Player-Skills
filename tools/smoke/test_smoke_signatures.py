#!/usr/bin/env python3
"""Keep the standalone Left4DHooks observer aligned with provider forwards."""

from __future__ import annotations

import re
import unittest
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "addons/sourcemod/scripting"
ENTRYPOINT = SOURCE_DIR / "l4d2_player_skills.sp"
OBSERVER = ROOT / "tools/smoke/left4dhooks_observer.sp.inc"
INCLUDES = sorted((SOURCE_DIR / "include").glob("left4dhooks*.inc"))


@dataclass(frozen=True)
class Parameter:
    const: bool
    type_name: str
    by_reference: bool
    array_size: str | None


@dataclass(frozen=True)
class Signature:
    return_type: str
    parameters: tuple[Parameter, ...]


PARAMETER_RE = re.compile(
    r"^(?:(const)\s+)?([A-Za-z_]\w*)\s*(?:\[\s*(\d*)\s*\])?"
    r"(\s*&\s*|\s+)([A-Za-z_]\w*)\s*(?:\[\s*(\d*)\s*\])?$"
)
FORWARD_RE = re.compile(
    r"\bforward\s+(Action|void)\s+(L4D\w+)\s*\(([^)]*)\)\s*;",
    re.MULTILINE,
)
HANDLER_RE = re.compile(
    r"(?m)^\s*public\s+(Action|void)\s+(L4D\w+)\s*\(([^)]*)\)\s*\{"
)
PRODUCT_CALLBACK_RE = re.compile(r"\bpublic\s+\w+\s+(L4D\w+)\s*\(")


def strip_comments(source: str) -> str:
    """Remove comments while preserving quoted strings and line structure."""
    source = re.sub(r"/\*.*?\*/", lambda match: "\n" * match.group(0).count("\n"), source, flags=re.S)
    return re.sub(r"(?m)//[^\n]*", "", source)


def parse_parameters(text: str, context: str) -> tuple[Parameter, ...]:
    if not text.strip():
        return ()
    parsed = []
    for declaration in text.split(","):
        match = PARAMETER_RE.fullmatch(declaration.strip())
        if match is None:
            raise AssertionError(f"unsupported parameter syntax in {context}: {declaration!r}")
        const, type_name, type_array, separator, _name, parameter_array = match.groups()
        array_size = type_array if type_array is not None else parameter_array
        if type_array is not None and parameter_array is not None:
            raise AssertionError(f"array declared on both type and parameter in {context}: {declaration!r}")
        parsed.append(Parameter(bool(const), type_name, "&" in separator, array_size))
    return tuple(parsed)


def signature(return_type: str, parameters: str, context: str) -> Signature:
    return Signature(return_type, parse_parameters(parameters, context))


def extract_body(source: str, start: int, name: str) -> str:
    opening = source.find("{", start)
    depth = 0
    in_string = False
    escaped = False
    for position in range(opening, len(source)):
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
                return source[opening + 1 : position]
    raise AssertionError(f"unterminated observer callback {name}")


def provider_forwards(wanted_names: set[str]) -> dict[str, Signature]:
    forwards: dict[str, Signature] = {}
    for path in INCLUDES:
        source = strip_comments(path.read_text(encoding="utf-8"))
        for match in FORWARD_RE.finditer(source):
            return_type, name, parameters = match.groups()
            if name not in wanted_names:
                continue
            if name in forwards:
                raise AssertionError(f"duplicate Left4DHooks forward declaration: {name}")
            forwards[name] = signature(return_type, parameters, f"{path.name}:{name}")
    return forwards


def observer_handlers() -> dict[str, tuple[Signature, str]]:
    source = strip_comments(OBSERVER.read_text(encoding="utf-8"))
    handlers: dict[str, tuple[Signature, str]] = {}
    for match in HANDLER_RE.finditer(source):
        return_type, name, parameters = match.groups()
        if name in handlers:
            raise AssertionError(f"duplicate observer callback: {name}")
        handlers[name] = (
            signature(return_type, parameters, f"{OBSERVER.name}:{name}"),
            extract_body(source, match.start(), name),
        )
    return handlers


class Left4DHooksObserverSignatureTests(unittest.TestCase):
    def test_all_product_callbacks_match_provider_forwards_and_log_every_argument(self) -> None:
        product_source = strip_comments(ENTRYPOINT.read_text(encoding="utf-8"))
        product_callbacks = set(PRODUCT_CALLBACK_RE.findall(product_source))
        forwards = provider_forwards(product_callbacks)
        handlers = observer_handlers()

        self.assertEqual(len(product_callbacks), 26, "update this gate if the product callback set changes")
        self.assertEqual(set(handlers), product_callbacks, "observer handlers must cover exactly the current product callbacks")
        self.assertTrue(product_callbacks <= set(forwards), "every product callback must have a provider include forward")

        for name in sorted(product_callbacks):
            with self.subTest(callback=name):
                handler_signature, body = handlers[name]
                self.assertEqual(handler_signature, forwards[name], "return type and parameter qualifiers/order/types/arrays must match")
                self.assertRegex(body, rf'TraceBegin\(TraceSource_Left4DHooks,\s*"{re.escape(name)}"\)')

                # Parse names independently from normalized signatures; names may differ
                # between the provider forward and observer implementation.
                source = strip_comments(OBSERVER.read_text(encoding="utf-8"))
                match = next(item for item in HANDLER_RE.finditer(source) if item.group(2) == name)
                parameter_names = []
                for declaration in match.group(3).split(",") if match.group(3).strip() else []:
                    parsed = PARAMETER_RE.fullmatch(declaration.strip())
                    self.assertIsNotNone(parsed, declaration)
                    parameter_names.append(parsed.group(5))

                for argument in parameter_names:
                    self.assertRegex(
                        body,
                        rf"Trace\w+Value\([^;]*\b{re.escape(argument)}\b[^;]*\);",
                        f"callback argument {argument} is not serialized by a Trace*Value call",
                    )


if __name__ == "__main__":
    unittest.main(verbosity=2)
