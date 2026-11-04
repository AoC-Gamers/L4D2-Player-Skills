#!/usr/bin/env python3
"""Package inventory/tamper checks and isolated API probe safety checks."""
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile
import unittest

from package_standalone import ROOT, render_smoke_probe, SMOKE_LOG_PATH_FUNCTION
from verify_standalone import verify_package, EXPECTED_PLUGINS
from test_source_observer import COMPILER, SHELL, INCLUDE_DIRS, extract_function


def fixture(root):
    for name in EXPECTED_PLUGINS:
        path=root/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(b'FFPS'+b'fixture')
    (root/'README.md').write_text('Fixture, not a runtime plugin.\n')
    payload=sorted(p for p in root.rglob('*') if p.is_file())
    manifest={'kind':'l4d2-skills-smoke-standalone','core_included':False,'validation':{'runtime_srcds':'pending'},
              'files':[{'path':p.relative_to(root).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in payload]}
    (root/'manifest.json').write_text(json.dumps(manifest))
    (root/'SHA256SUMS').write_text(''.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(root).as_posix()}\n' for p in sorted(root.rglob('*')) if p.is_file()))


def path_harness(force_long=False):
    pre=r'''native void assert_eq(any a, any b);
native void print(const char[] value);
#define Path_SM 0
#define SKILLS_LOGDIR "logs/l4d2_skills_smoke/api"
#define GetGameTickCount FakeTick
#define GetTime FakeTime
#define BuildPath FakeBuild
#define FileExists FakeExists
#define ThrowError FakeError
int g_iSmokeLogSerial, g_LastSerial, g_ExistingThrough=2;
bool g_ForceLong=FORCE_LONG;
int FakeTick() { return 1234; }
int FakeTime() { return 1234567; }
int FakeBuild(int type, char[] path, int maxlen, const char[] format, const char[] base, const char[] subdir, int timestamp, int tick, int serial) {
    assert_eq(type,0);assert_eq(maxlen,64);assert_eq(format[0],'%');assert_eq(base[0],'l');assert_eq(subdir[0],'s');assert_eq(timestamp,1234567);assert_eq(tick,1234);
    g_LastSerial=serial;path[0]='0'+serial;path[1]=0;
    return g_ForceLong ? 63 : 1;
}
bool FakeExists(const char[] path) { assert_eq(path[0],'0'+g_LastSerial);return g_LastSerial<=g_ExistingThrough; }
void FakeError(const char[] message) { assert_eq(message[0],'S');assert_eq(1,0); }
void Debug(const char[] fmt, const char[] subdir, const char[] type, const char[] path) { assert_eq(fmt[0],'B');assert_eq(subdir[0],'s');assert_eq(type[0],'t');assert_eq(path[0],'0'+g_LastSerial); }
'''.replace('FORCE_LONG','true' if force_long else 'false')
    return pre+SMOKE_LOG_PATH_FUNCTION+r'''
public main() {
    char first[64],second[64],afterReload[64];
    BuildLogPath("skills/event_detected","type",first,sizeof(first));
    BuildLogPath("skills/event_detected","type",second,sizeof(second));
    assert_eq(first[0],'3');assert_eq(second[0],'4');assert_eq(g_iSmokeLogSerial,4);
    g_iSmokeLogSerial=0;g_ExistingThrough=4;
    BuildLogPath("skills/event_detected","type",afterReload,sizeof(afterReload));
    assert_eq(afterReload[0],'5');
    print("SMOKE_API_PATH_PASS same_tick_unique reload_collision_preserved\n");
}
'''


class StandalonePackageTests(unittest.TestCase):
    def test_verifier_accepts_exact_inventory_and_detects_tampering_and_extra_core(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);fixture(root)
            self.assertTrue(verify_package(root)['valid'])
            original=(root/'README.md').read_bytes();(root/'README.md').write_text('tampered')
            self.assertFalse(verify_package(root)['valid'])
            (root/'README.md').write_bytes(original)
            (root/'plugins/l4d2_player_skills.smx').write_bytes(b'FFPS')
            self.assertFalse(verify_package(root)['valid'])

    def test_probe_is_isolated_and_public_forward_bodies_are_preserved(self):
        source=(ROOT/'addons/sourcemod/scripting/l4d2_player_skills_api.sp').read_text()
        probe=render_smoke_probe(source)
        self.assertIn('"sm_skills_smoke_api_debug"',probe)
        self.assertNotIn('"sm_skills_api_debug"',probe)
        self.assertIn('logs/l4d2_skills_smoke/api',probe)
        for name in ['PlayerSkills_OnSkillDetected','PlayerSkills_OnKillDetected','PlayerSkills_OnBossEventDetected',
                     'PlayerSkills_OnBossSessionFinalized','PlayerSkills_OnTankSessionClosed',
                     'PlayerSkills_OnSkillSummaryFinalized','PlayerSkills_OnKillSummaryFinalized']:
            self.assertEqual(extract_function(source,name),extract_function(probe,name))
        with self.assertRaises(ValueError):render_smoke_probe(source.replace('ConVar g_cvDebug;','ConVar other;'))
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'api_smoke.sp';path.write_text(probe)
            command=[str(COMPILER),str(path),'-o'+str(path.with_suffix('.smx'))]
            command += ['-i'+str(p) for p in INCLUDE_DIRS]
            result=subprocess.run(command,text=True,capture_output=True)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertNotIn('warning ',result.stdout.lower())

    def test_probe_path_collision_and_length_guard_execute_in_vm(self):
        if not SHELL.exists():self.skipTest('local spshell unavailable')
        for too_long in [False,True]:
            with self.subTest(too_long=too_long),tempfile.TemporaryDirectory() as directory:
                path=Path(directory)/'path.sp';path.write_text(path_harness(too_long))
                prefix=Path(directory)/'empty.inc';prefix.write_text('')
                compiled=subprocess.run([str(COMPILER),'-p',str(prefix),str(path),'-o'+str(path.with_suffix('.smx'))],text=True,capture_output=True)
                self.assertEqual(compiled.returncode,0,compiled.stdout+compiled.stderr)
                self.assertNotIn('warning ',compiled.stdout.lower())
                result=subprocess.run([str(SHELL),str(path.with_suffix('.smx'))],text=True,capture_output=True)
                if too_long:
                    self.assertNotEqual(result.returncode,0,result.stdout+result.stderr)
                    self.assertIn("FakeError",result.stdout+result.stderr)
                else:
                    self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                    self.assertIn('SMOKE_API_PATH_PASS',result.stdout)


if __name__=='__main__':unittest.main(verbosity=2)
