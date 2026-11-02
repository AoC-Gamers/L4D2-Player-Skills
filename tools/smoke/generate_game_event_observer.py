#!/usr/bin/env python3
"""Generate a standalone, non-packaged observer from the checked-in event catalog."""
import argparse
import hashlib
import json
import re
from pathlib import Path

TYPES = {'short', 'long', 'byte', 'bool', 'float', 'string'}
ROOT = Path(__file__).resolve().parents[2]


def load_catalog(path):
    catalog = json.loads(Path(path).read_text())
    events = catalog['events']
    if catalog['count'] != len(events):
        raise ValueError('catalog count does not match events')
    result, names, ids = [], set(), set()
    for event in events:
        name, ident = event['name'], event['id']
        if not re.fullmatch(r'[A-Za-z0-9_]+', name) or name in names or ident in ids:
            raise ValueError(f'invalid or duplicate event: {name}')
        names.add(name)
        ids.add(ident)
        fields, keys = [], set()
        for argument in event['arguments']:
            # This catalog stores the field key in "type" and its type in "name".
            key, kind = argument['type'], argument['name']
            if (key.lower(), kind.lower()) in {('none', 'none'), ('local', '1'), ('reliable', '1')}:
                continue
            if kind not in TYPES or not re.fullmatch(r'[A-Za-z0-9_]+', key) or key in keys:
                raise ValueError(f'invalid field: {name}.{key} ({kind})')
            keys.add(key)
            description = argument.get('description', '').lower()
            userid = key == 'userid' or bool(re.match(r'(?:the )?user[ -]?id\b', description))
            # Entity fields may mention userid as a fallback in their description.
            if 'entid' in key.lower() or 'entity' in key.lower():
                userid = False
            if name == 'boomer_exploded' and key == 'attacker':
                userid = True
            fields.append({'key': key, 'type': kind, 'is_userid': userid and kind in {'short', 'long', 'byte'}})
        result.append({'name': name, 'fields': fields, 'source': 'catalog'})
    # SourceMod/engine common event used by Skills but absent from this catalog.
    if 'player_spawn' not in names:
        result.append({'name': 'player_spawn', 'fields': [{'key': 'userid', 'type': 'short', 'is_userid': True}], 'source': 'supplemental'})
    return result


def source_inventory():
    source_dir = ROOT / 'addons/sourcemod/scripting'
    paths = [source_dir / 'l4d2_player_skills.sp'] + sorted(p for p in (source_dir / 'l4d2_player_skills').rglob('*') if p.suffix in {'.sp', '.inc'})
    texts = {str(p.relative_to(ROOT)): re.sub(r'/\*.*?\*/|//[^\n]*', '', p.read_text(), flags=re.S) for p in paths}
    main = texts['addons/sourcemod/scripting/l4d2_player_skills.sp']
    callbacks = sorted(set(re.findall(r'public\s+\w+\s+(L4D\w+)\s*\(', main)))
    hooks = []
    for path, text in texts.items():
        for target, hook, callback in re.findall(r'\bSDKHook\(\s*([^,]+),\s*(SDKHook_\w+),\s*(\w+)\s*\)', text):
            hooks.append({'target_expression': target.strip(), 'type': hook, 'callback': callback, 'file': path})
    queries = sorted(set(re.findall(r'\b(L4D_\w+|L4D2_\w+)\s*\(', '\n'.join(texts.values()))) - set(callbacks))
    # Include-local stock wrappers are state reads, not extension forwards.
    declarations = {}
    for inc in sorted((source_dir / 'include').glob('left4dhooks*.inc')):
        for kind, name in re.findall(r'\b(native|stock)\s+[^;{\n]*?\b(L4D_\w+|L4D2_\w+)\s*\(', inc.read_text()):
            declarations[name] = kind
    queries = [{'name': name, 'implementation': declarations.get(name, 'stock_or_helper')} for name in queries]
    other = sorted(set(re.findall(r'public\s+\w+\s+((?:PlayerStats_|TankControl_|On)\w+)\s*\(', main)))
    props = sorted(set(re.findall(r'\bGetEntProp(?:Ent|Float|Vector|String)?\([^;]*?"(m_\w+)"', '\n'.join(texts.values()))))
    return {'engine_hooks_in_skills': sorted(set(re.findall(r'\bHookEvent\(\s*"([^"\n]+)"', main))),
            'sdkhooks_global_callbacks': ['OnEntityCreated', 'OnEntityDestroyed'],
            'sdkhooks': hooks, 'sdkhook_types': sorted({h['type'] for h in hooks}),
            'left4dhooks_callbacks': callbacks, 'left4dhooks_queries': queries,
            'auxiliary_inputs': [name for name in other if name not in {'OnEntityCreated', 'OnEntityDestroyed'}], 'direct_properties': props,
            'state_read_observation': 'manual samples; not interception of reads executed by Skills'}


def render(events, digest):
    declarations = '\n'.join(f'\t"{e["name"]}",' for e in events)
    cases = []
    for index, event in enumerate(events):
        lines = [f'\t\tcase {index}:', '\t\t{']
        for field in event['fields']:
            key, kind = field['key'], field['type']
            method = {'short': 'Int', 'long': 'Int', 'byte': 'Int', 'bool': 'Bool', 'float': 'Float', 'string': 'String'}[kind]
            lines.append(f'\t\t\tTrace{method}(event, sequence, "{key}");')
            if field['is_userid']:
                lines.append(f'\t\t\tTraceUserId(sequence, "{key}", event.GetInt("{key}"));')
        lines.append('\t\t}')
        cases.append('\n'.join(lines))
    template = (Path(__file__).with_name('game_event_observer.sp.in')).read_text()
    inventory = source_inventory()
    rendered = template.replace('@CATALOG_SHA256@', digest).replace('@EVENT_NAMES@', declarations).replace('@PAYLOAD_CASES@', '\n'.join(cases))
    modules = {'@SDKHOOKS_MODULE@': 'sdkhooks_observer.sp.inc', '@LEFT4DHOOKS_MODULE@': 'left4dhooks_observer.sp.inc', '@LEFT4DHOOKS_SAMPLES@': 'left4dhooks_samples.sp.inc', '@AUXILIARY_MODULE@': 'auxiliary_observer.sp.inc', '@WITCH_TARGET_MODULE@': 'witch_target_observer.sp.inc', '@WITCH_ACTIONS_MODULE@': 'witch_actions_observer.sp.inc', '@WITCH_EPISODES_MODULE@': 'witch_episodes.sp.inc', '@ACTIONS_ABI@': 'actions_smoke_abi.sp.inc'}
    for marker, filename in modules.items():
        rendered = rendered.replace(marker, Path(__file__).with_name(filename).read_text())
    coverage = '\n'.join('\tTraceLine(TraceSource_Left4DHooks, "{\\\"kind\\\":\\\"coverage\\\",\\\"callback\\\":\\\"' + name + '\\\",\\\"listener_declared\\\":1,\\\"detour_verified\\\":0}");' for name in inventory['left4dhooks_callbacks'])
    return rendered.replace('@LEFT4DHOOKS_COVERAGE@', coverage)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--catalog', type=Path, default=ROOT / 'docs/l4d2_game_events.json')
    parser.add_argument('--output-dir', type=Path, default=ROOT / '.build/smoke/game-events')
    args = parser.parse_args()
    events = load_catalog(args.catalog)
    digest = hashlib.sha256(args.catalog.read_bytes()).hexdigest()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / 'l4d2_skills_game_event_observer.sp').write_text(render(events, digest))
    (args.output_dir / 'catalog-manifest.json').write_text(json.dumps({'catalog_sha256': digest, 'catalog_events': sum(e['source'] == 'catalog' for e in events), 'observed_names': len(events), 'events': events, 'skills_sources': source_inventory()}, indent=2) + '\n')
    print(f'Generated {len(events)} names, pre/post hooks and typed payloads in {args.output_dir}')


if __name__ == '__main__':
    main()
