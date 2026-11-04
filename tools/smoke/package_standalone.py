#!/usr/bin/env python3
"""Build a smoke-only ZIP. Does not install, change the core, or publish anything."""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

from verify_standalone import verify_package

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def extract_function(source, name):
    match = re.search(rf'(?m)^void {re.escape(name)}\([^;]*?\)\s*\{{', source)
    if match is None:
        raise ValueError(f'function missing: {name}')
    start, depth, quoted, escaped = match.start(), 0, False, False
    for i in range(source.index('{', match.start()), len(source)):
        char = source[i]
        if quoted:
            if escaped: escaped = False
            elif char == '\\': escaped = True
            elif char == '"': quoted = False
        elif char == '"': quoted = True
        elif char == '{': depth += 1
        elif char == '}':
            depth -= 1
            if depth == 0: return source[start:i+1]
    raise ValueError(f'unterminated function: {name}')


SMOKE_LOG_PATH_FUNCTION = r'''void BuildLogPath(const char[] subdir, const char[] typeName, char[] path, int maxlen)
{
	int tick = GetGameTickCount();
	int timestamp = GetTime();
	do
	{
		g_iSmokeLogSerial++;
		int written = BuildPath(Path_SM, path, maxlen, "%s/%s/%d_%d_%d.cfg",
			SKILLS_LOGDIR, subdir, timestamp, tick, g_iSmokeLogSerial);
		if (written >= maxlen - 1)
		{
			ThrowError("Smoke API log path exceeds buffer; payload was not exported.");
		}
	} while (FileExists(path));
	Debug("BuildLogPath subdir=%s type=%s path=%s", subdir, typeName, path);
}'''


def render_smoke_probe(source):
    replacements = {
        '#define SKILLS_LOGDIR "logs/l4d2_player_skills"': '#define SKILLS_LOGDIR "logs/l4d2_skills_smoke/api"',
        '#define SKILLS_LOG_PREFIX "[Player Skills API]"': '#define SKILLS_LOG_PREFIX "[Player Skills Smoke API]"',
        'ConVar g_cvDebug;': 'ConVar g_cvDebug;\nint g_iSmokeLogSerial;',
        'name = "L4D2 Player Skills API"': 'name = "L4D2 Player Skills Smoke API"',
        'version = "1.0.0"': 'version = "1.0.1-smoke"',
        '"sm_skills_api_debug"': '"sm_skills_smoke_api_debug"',
    }
    for old, new in replacements.items():
        if source.count(old) != 1:
            raise ValueError(f'API source changed; review smoke derivation: {old}')
        source = source.replace(old, new, 1)
    old = extract_function(source, 'BuildLogPath')
    return source.replace(old, SMOKE_LOG_PATH_FUNCTION, 1)


def copy_file(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)


def run(command, log, cwd=ROOT):
    result = subprocess.run([str(x) for x in command], cwd=cwd, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    log.parent.mkdir(parents=True, exist_ok=True)
    log.write_text(result.stdout)
    if result.returncode or 'warning ' in result.stdout.lower():
        raise RuntimeError(f'command failed or warned: {command}; see {log}\n{result.stdout}')
    return result.stdout


def build_package(output_dir):
    compiler = ROOT/'deps/sourcemod-linux/addons/sourcemod/scripting/spcomp'
    if not compiler.is_file():
        raise RuntimeError('SourceMod compiler missing; run make deps-smx first.')
    work = ROOT/'.build/smoke'
    work.mkdir(parents=True, exist_ok=True)
    package = Path(tempfile.mkdtemp(prefix='standalone-', dir=work))
    generated = work/'game-events'
    run([sys.executable, HERE/'generate_game_event_observer.py'], package/'validation/generate.log')
    template = (HERE/'game_event_observer.sp.in').read_text()
    version = re.search(r'version\s*=\s*"([^"]+)"', template).group(1)
    copy_file(generated/'l4d2_skills_game_event_observer.sp', package/'source/l4d2_skills_game_event_observer.sp')
    original = ROOT/'addons/sourcemod/scripting/l4d2_player_skills_api.sp'
    probe = package/'source/l4d2_player_skills_api_smoke.sp'
    probe.write_text(render_smoke_probe(original.read_text()))
    copy_file(ROOT/'addons/sourcemod/scripting/include/l4d2_player_skills.inc', package/'source/include/l4d2_player_skills.inc')
    includes = ['-i'+str(ROOT/'addons/sourcemod/scripting/include'),
                '-i'+str(ROOT/'deps/sourcemod-linux/addons/sourcemod/scripting/include')]
    plugins = package/'plugins'; plugins.mkdir()
    for stem in ['l4d2_skills_game_event_observer', 'l4d2_player_skills_api_smoke']:
        run([compiler, package/f'source/{stem}.sp', *includes, '-o'+str(plugins/f'{stem}.smx')],
            package/f'validation/{stem}.compile.log')
    copy_file(HERE/'gamedata/l4d2_skills_smoke_witch.txt', package/'gamedata/l4d2_skills_smoke_witch.txt')
    copy_file(HERE/'validate_smoke_trace.py', package/'tools/validate_smoke_trace.py')
    copy_file(HERE/'verify_standalone.py', package/'tools/verify_standalone.py')
    copy_file(HERE/'validate_witch_tracking_binary.py', package/'tools/validate_witch_tracking_binary.py')
    copy_file(generated/'catalog-manifest.json', package/'catalog/catalog-manifest.json')
    copy_file(ROOT/'docs/l4d2_game_events.json', package/'catalog/l4d2_game_events.json')
    for document in sorted((ROOT/'docs').rglob('*.md')):
        copy_file(document, package/'docs'/document.relative_to(ROOT/'docs'))
    copy_file(HERE/'README.md', package/'docs/observer-source-guide.md')
    guide = (HERE/'standalone-guide.md').read_text().replace('@OBSERVER_VERSION@', version)
    (package/'README.md').write_text(guide)
    source_tests = run([sys.executable, '-m', 'unittest', 'discover', '-s', str(HERE), '-p', 'test_*.py', '-v'],
                       package/'validation/local-tests.log')
    count = int(re.search(r'Ran (\d+) tests?', source_tests).group(1))
    skipped = bool(re.search(r'\.\.\. skipped|OK \(skipped=', source_tests))
    catalog = json.loads((package/'catalog/catalog-manifest.json').read_text())
    compiler_version = re.search(r'SourcePawn Compiler ([^\n]+)',
                                (package/'validation/l4d2_skills_game_event_observer.compile.log').read_text()).group(1)
    core = ROOT/'.build/smx/addons/sourcemod/plugins/l4d2_player_skills.smx'
    validation = {'local_tests': count, 'some_tests_skipped': skipped, 'compile_warnings': 0,
                  'runtime_srcds': 'pending', 'installed': False, 'published': False}
    (package/'validation/summary.json').write_text(json.dumps(validation, indent=2)+'\n')
    payload = sorted(p for p in package.rglob('*') if p.is_file())
    manifest = {
        'kind': 'l4d2-skills-smoke-standalone', 'observer_version': version,
        'smoke_api_version': '1.0.1-smoke', 'core_included': False,
        'created_utc': datetime.now(timezone.utc).isoformat(),
        'source_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'source_worktree_dirty': bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT)),
        'compiler': compiler_version, 'catalog_sha256': catalog['catalog_sha256'],
        'core_reference_sha256': digest(core) if core.exists() else None,
        'original_api_source_sha256': digest(original),
        'external_build_include_sha256': {p.relative_to(ROOT).as_posix(): digest(p) for pattern in ['left4dhooks*.inc', 'l4d2util*.inc', 'l4d2_player_stats.inc', 'l4d_tank_control_eq.inc'] for p in sorted((ROOT/'addons/sourcemod/scripting/include').glob(pattern))},
        'api_derivation': 'isolated name/log dir/debug cvar; short serial filenames with collision and length checks; forwards and KeyValues unchanged',
        'requirements': {'game': 'Left 4 Dead 2', 'sourcemod': '1.12 toolchain used',
                         'sdktools': 'required by observer',
                         'dhooks': 'required by observer for passive WitchAttack::GetVictim post detour; Linux x86 guarded gamedata supplied',
                         'actions': 'required by observer 1.4.0 for Witch lifecycle/navigation POST listeners; consumed read/listener ABI inlined, provider not included',
                         'sdkhooks': 'required for SDKHooks coverage; observer reports absence',
                         'left4dhooks': 'required for Left4DHooks coverage; observer supports absence',
                         'player_skills': 'existing compatible core required for API payloads; not supplied',
                         'player_stats_and_tank_control': 'optional, record availability',
                         'validator': 'Python 3.10+ standard library only; may run off-server'},
        'validation': validation,
        'file_inventory_scope': 'all payload files except manifest.json and SHA256SUMS; SHA256SUMS also covers manifest.json',
        'files': [{'path': p.relative_to(package).as_posix(), 'sha256': digest(p), 'bytes': p.stat().st_size} for p in payload],
    }
    (package/'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=True)+'\n')
    files = sorted(p for p in package.rglob('*') if p.is_file())
    (package/'SHA256SUMS').write_text(''.join(f'{digest(p)}  {p.relative_to(package).as_posix()}\n' for p in files))
    report = verify_package(package)
    if not report['valid']:
        raise RuntimeError(json.dumps(report))
    # Distinct smoke destination; product release/build mappings are untouched.
    output_dir.mkdir(parents=True, exist_ok=True)
    suffix = digest(package/'SHA256SUMS')[:12]
    archive = output_dir/f'l4d2-skills-smoke-standalone-{version}-{suffix}.zip'
    if archive.exists():
        raise FileExistsError(f'archive already exists; preserve it: {archive}')
    with ZipFile(archive, 'w', compression=ZIP_DEFLATED, compresslevel=9) as zipped:
        for p in sorted(p for p in package.rglob('*') if p.is_file()):
            info = ZipInfo(p.relative_to(package).as_posix(), date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            zipped.writestr(info, p.read_bytes())
    Path(str(archive)+'.sha256').write_text(f'{digest(archive)}  {archive.name}\n')
    return {'package_dir': str(package), 'archive': str(archive), 'archive_sha256': digest(archive),
            'verification': report, 'validation': validation}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=ROOT/'dist/smoke')
    args = parser.parse_args()
    print(json.dumps(build_package(args.output_dir.resolve()), indent=2))


if __name__ == '__main__':
    main()
