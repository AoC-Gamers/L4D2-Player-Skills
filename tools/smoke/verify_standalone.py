#!/usr/bin/env python3
"""Verify the inventory and hashes of an extracted Skills smoke-only bundle."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re

EXPECTED_PLUGINS = {
    'plugins/l4d2_skills_game_event_observer.smx',
    'plugins/l4d2_player_skills_api_smoke.smx',
}


def verify_package(root: Path) -> dict:
    root = root.resolve()
    errors, expected = [], {}
    sums = root / 'SHA256SUMS'
    if not sums.is_file():
        return {'valid': False, 'errors': ['SHA256SUMS missing'], 'verified_files': 0}
    for line in sums.read_text().splitlines():
        match = re.fullmatch(r'([0-9a-f]{64})  (.+)', line)
        if not match:
            errors.append('malformed SHA256SUMS line')
            continue
        digest, name = match.groups()
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or name in expected or path.as_posix() != name:
            errors.append(f'invalid or duplicate inventory path: {name}')
            continue
        expected[name] = digest
        target = root / path
        if not target.resolve().is_relative_to(root) or target.is_symlink():
            errors.append(f'non-local inventory path: {name}')
        elif not target.is_file():
            errors.append(f'missing file: {name}')
        elif hashlib.sha256(target.read_bytes()).hexdigest() != digest:
            errors.append(f'hash mismatch: {name}')
    actual = {p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file() and p != sums}
    if actual != set(expected):
        errors.append(f'inventory differs: extra={sorted(actual-set(expected))}, missing={sorted(set(expected)-actual)}')
    plugins = {name for name in actual if name.endswith('.smx')}
    if plugins != EXPECTED_PLUGINS:
        errors.append(f'expected exactly the two smoke plugins, found {sorted(plugins)}')
    for name in plugins & EXPECTED_PLUGINS:
        if (root/name).is_symlink() or not (root/name).resolve().is_relative_to(root):
            continue
        if (root/name).read_bytes()[:4] != b'FFPS':
            errors.append(f'invalid SMX magic: {name}')
    manifest = {}
    try:
        manifest_path = root/'manifest.json'
        if manifest_path.is_symlink() or not manifest_path.resolve().is_relative_to(root):
            raise ValueError('manifest must be a local regular file')
        manifest = json.loads(manifest_path.read_text())
        if not isinstance(manifest, dict) or not isinstance(manifest.get('files'), list):
            raise ValueError('manifest must contain a files list')
        if manifest.get('kind') != 'l4d2-skills-smoke-standalone' or manifest.get('core_included') is not False:
            errors.append('unexpected bundle kind or core inclusion')
        seen = set()
        for row in manifest['files']:
            if not isinstance(row, dict) or not isinstance(row.get('path'), str) or row['path'] not in expected or row['path'] in seen:
                raise ValueError('invalid or duplicate manifest file entry')
            seen.add(row['path'])
            if expected.get(row['path']) != row['sha256']:
                errors.append(f'manifest hash mismatch: {row["path"]}')
            file = root/row['path']
            if file.is_file() and file.stat().st_size != row['bytes']:
                errors.append(f'manifest size mismatch: {row["path"]}')
        listed = {row['path'] for row in manifest['files']}
        if listed != actual-{'manifest.json'}:
            errors.append('manifest payload inventory differs')
    except (OSError, ValueError, KeyError, TypeError) as exc:
        errors.append(f'invalid manifest: {exc}')
        manifest = {}
    return {'valid': not errors, 'errors': errors, 'verified_files': len(expected),
            'plugins': sorted(plugins), 'observer_version': manifest.get('observer_version'),
            'runtime_srcds': manifest.get('validation', {}).get('runtime_srcds', 'pending')}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    result = verify_package(args.root)
    print(json.dumps(result, indent=2, ensure_ascii=True))
    return 0 if result['valid'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
