#!/usr/bin/env python3
"""Run actual entity serialization/resolution control flow against SourceMod API stubs."""
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
from test_source_observer import COMPILER, SHELL, extract_function

ROOT = Path(__file__).resolve().parents[2]


def entity_harness(template):
    function = extract_function(template, 'TraceEntityValue')
    function, count = re.subn(r'TraceLine\(source, [^\n]*sequence, key, entity, valid \? resolved : -1, valid, entref, userid, serial, generation, team, zombieClass, alive, health\);',
                             'CaptureEntity(source, sequence, key, entity, valid ? resolved : -1, valid, entref, userid, serial, generation, team, zombieClass, alive, health);', function)
    if count != 1:
        raise ValueError('expected one entity output boundary')
    return r'''native void assert_eq(any a, any b);
native void print(const char[] value);
#define MaxClients 64
#define INVALID_ENT_REFERENCE -1
#define Prop_Send 0
#define GetMaxEntities TestGetMaxEntities
#define EntRefToEntIndex TestResolve
#define EntIndexToEntRef TestReference
#define IsValidEntity TestValid
#define IsClientInGame TestInGame
#define GetClientUserId TestUserId
#define GetClientSerial TestSerial
#define GetClientTeam TestTeam
#define IsPlayerAlive TestAlive
#define GetClientHealth TestHealth
#define HasEntProp TestHasProp
#define GetEntProp TestProp
int g_ObservedGeneration[65];
int g_Raw, g_Resolved, g_Ref, g_UserId, g_Serial, g_Generation, g_Health, g_ClientReads;
bool g_Valid;
stock int TestGetMaxEntities() { return 2048; }
int TestResolve(int value) {
    if (value == -2147482648) return 1000;
    if (value == -2147483643) return 5;
    return value == 0 || value == 5 || value == 1000 || value == 3000 ? value : -1;
}
int TestReference(int index) { return index | (-2147483647 - 1); }
bool TestValid(int value) { return TestResolve(value) >= 0; }
bool TestInGame(int index) { assert_eq(index > 0, true); return index == 5; }
int TestUserId(int index) { assert_eq(index, 5); g_ClientReads++; return 505; }
int TestSerial(int index) { assert_eq(index, 5); return 5005; }
int TestTeam(int index) { assert_eq(index, 5); return 2; }
bool TestAlive(int index) { assert_eq(index, 5); return true; }
int TestHealth(int index) { assert_eq(index, 5); return 100; }
bool TestHasProp(int index, int prop, const char[] name) { assert_eq(index, 5); assert_eq(prop, 0); assert_eq(name[0], 'm'); return true; }
int TestProp(int index, int prop, const char[] name) { assert_eq(index, 5); assert_eq(prop, 0); assert_eq(name[0], 'm'); return 9; }
void CaptureEntity(int source, int seq, const char[] key, int raw, int resolved, bool valid, int ref, int userid, int serial, int generation, int team, int zombieClass, int alive, int health) {
    assert_eq(source, 1); assert_eq(seq, 7); assert_eq(key[0], 't');
    assert_eq(team >= -1 && zombieClass >= -1 && alive >= -1, true);
    g_Raw=raw; g_Resolved=resolved; g_Valid=valid; g_Ref=ref; g_UserId=userid;
    g_Serial=serial; g_Generation=generation; g_Health=health;
}
''' + function + r'''
public main() {
    TraceEntityValue(1,7,"target",-2147482648);
    assert_eq(g_Raw,-2147482648); assert_eq(g_Resolved,1000); assert_eq(g_Valid,true); assert_eq(g_Ref,-2147482648);
    TraceEntityValue(1,7,"target",-2147482647);
    assert_eq(g_Resolved,-1); assert_eq(g_Valid,false); assert_eq(g_Ref,-2147482647);
    TraceEntityValue(1,7,"target",3000);
    assert_eq(g_Resolved,3000); assert_eq(g_Valid,true); assert_eq(g_ClientReads,0);
    TraceEntityValue(1,7,"target",0);
    assert_eq(g_Resolved,0); assert_eq(g_Valid,true); assert_eq(g_Health,-1); assert_eq(g_ClientReads,0);
    TraceEntityValue(1,7,"target",-1);
    assert_eq(g_Valid,false); assert_eq(g_Ref,-1);
    g_ObservedGeneration[5]=9;
    TraceEntityValue(1,7,"target",-2147483643);
    assert_eq(g_Resolved,5); assert_eq(g_Valid,true); assert_eq(g_UserId,505); assert_eq(g_Serial,5005); assert_eq(g_Generation,9); assert_eq(g_Health,100);
    print("TRACE_ENTITY_PASS negative_live expired nonnetworked world invalid player_serial\n");
}
'''


class TraceEntityTests(unittest.TestCase):
    def test_negative_references_resolve_and_expired_references_never_alias_an_index(self):
        if not COMPILER.exists() or not SHELL.exists():
            self.skipTest('local SourcePawn compiler/VM unavailable')
        with tempfile.TemporaryDirectory(prefix='skills-entity-') as directory:
            path=Path(directory)/'entity.sp'
            path.write_text(entity_harness((ROOT/'tools/smoke/game_event_observer.sp.in').read_text()))
            prefix=Path(directory)/'empty.inc';prefix.write_text('')
            compiled=subprocess.run([str(COMPILER),'-p',str(prefix),'-o',str(path.with_suffix('.smx')),str(path)],text=True,capture_output=True)
            self.assertEqual(compiled.returncode,0,compiled.stdout+compiled.stderr)
            self.assertNotIn('warning ',compiled.stdout.lower())
            result=subprocess.run([str(SHELL),str(path.with_suffix('.smx'))],text=True,capture_output=True)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertIn('TRACE_ENTITY_PASS',result.stdout)


if __name__ == '__main__':
    unittest.main(verbosity=2)
