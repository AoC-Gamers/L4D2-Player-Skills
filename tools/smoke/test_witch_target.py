#!/usr/bin/env python3
"""Offline VM coverage of real target transitions, identities and detour passivity."""
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
from test_source_observer import COMPILER, SHELL, extract_function

HERE = Path(__file__).resolve().parent
SOURCE = HERE / 'witch_target_observer.sp.inc'


def harness():
    text = SOURCE.read_text()
    structure = text[text.index('enum struct SmokeWitchTarget'):text.index('ArrayList g_SmokeWitchTargets;')]
    functions = '\n'.join(extract_function(text, n) for n in ['SmokeWitch_IsSupportedActorAssignment', 'SmokeWitch_Find', 'SmokeWitch_Observe', 'SmokeWitch_GetVictimPost', 'SmokeWitch_OnEntityDestroyed', 'SmokeWitch_QueryStatus', 'SmokeWitch_Heartbeat'])
    return r'''#include <core/float>
#pragma semicolon 1
#pragma newdecls required
native void assert_eq(any a, any b);
native void print(const char[] text);
enum Address { Address_Null = 0 }
enum NumberType { NumberType_Int8 }
enum MRESReturn { MRES_Ignored = 0 }
#define INVALID_ENT_REFERENCE -1
#define TraceSource_Engine 0
#define MaxClients 4
''' + structure + r'''
int g_Rows[20][sizeof(SmokeWitchTarget)], g_Count, g_Headers, g_PreviousUser, g_PreviousSerial;
int g_WitchRef = -1000, g_User = 3, g_Serial = 100, g_Result, g_Owner = 50;
int g_Tick, g_StatusQueries;
float g_Clock, g_SmokeWitchNextHeartbeat;
int GetGameTickCount() { return ++g_Tick; }
float GetEngineTime() { return g_Clock; }
int g_Bytes[3] = {0x89, 0x5f, 0x1c};
bool g_Active = true, g_SmokeWitchVictimEnabled = true;
char g_Transition[32];
void Copy(char[] dest, int capacity, const char[] source) {
    int i; while (i < capacity-1 && source[i]) { dest[i]=source[i]; i++; } dest[i]=0;
}
int strcopy(char[] dest, int capacity, const char[] source) { Copy(dest,capacity,source); return 0; }
methodmap ArrayList __nullable__ {
    property int Length {
 public get() { return g_Count; }
 }
    public void GetArray(int row, any[] value, int size) { for (int i=0;i<size;i++) value[i]=g_Rows[row][i]; }
    public void SetArray(int row, const any[] value, int size) { for (int i=0;i<size;i++) g_Rows[row][i]=value[i]; }
    public void PushArray(const any[] value, int size) { for (int i=0;i<size;i++) g_Rows[g_Count][i]=value[i]; g_Count++; }
    public void Erase(int row) { for (int j=row;j<g_Count-1;j++) for(int i=0;i<sizeof(SmokeWitchTarget);i++) g_Rows[j][i]=g_Rows[j+1][i]; g_Count--; }
}
methodmap DHookReturn {
    property int Value {
 public get() { return g_Result; }
 }
}
ArrayList g_SmokeWitchTargets = view_as<ArrayList>(1);
void SmokeEpisodes_Query(int witch,int action,int ref,int user,int serial,int tick) { assert_eq(witch,50);assert_eq(action>0,true);assert_eq(ref!=0,true);assert_eq(user>=0,true);assert_eq(serial>=0,true);assert_eq(tick>0,true); }
bool TraceActive() { return g_Active; }
int SmokeWitch_FindOwner(Address action) { assert_eq(action != Address_Null,true); return g_Owner; }
int LoadFromAddress(Address address, NumberType size) { assert_eq(size,NumberType_Int8); return g_Bytes[view_as<int>(address)-10]; }
int EntIndexToEntRef(int entity) { return entity==50 ? g_WitchRef : -100-entity; }
bool IsValidEntity(int entity) { return entity>0 && entity<100; }
bool IsClientInGame(int client) { return client>0 && client<=4; }
int GetClientUserId(int client) { return client==2 ? g_User : 5; }
int GetClientSerial(int client) { return client==2 ? g_Serial : 200; }
int TraceBegin(int source, const char[] callback) { assert_eq(source,0); assert_eq(callback[0],'w'); return ++g_Headers; }
void TraceTextValue(int source, int seq, const char[] key, const char[] value) {
    assert_eq(source,0); assert_eq(seq,g_Headers);
    if(key[0]=='t') Copy(g_Transition,sizeof(g_Transition),value);
}
void TraceIntValue(int source, int seq, const char[] key, int value) {
    assert_eq(source,0); assert_eq(seq,g_Headers);
    if(key[0]=='p' && key[16]=='u') g_PreviousUser=value;
    if(key[0]=='p' && key[16]=='s') g_PreviousSerial=value;
    if(key[0]=='q') g_StatusQueries=value;
}
void TraceEntityValue(int source, int seq, const char[] key, int value) { assert_eq(source,0); assert_eq(seq,g_Headers); assert_eq(key[0]!=0,true); assert_eq(value>=-1,true); }
''' + functions + r'''
bool Equal(const char[] a, const char[] b) { int i; while(a[i] && a[i]==b[i]) i++; return a[i]==b[i]; }
void Expect(const char[] transition, int count) { assert_eq(Equal(g_Transition,transition),true); assert_eq(g_Headers,count); }
public int main() {
    assert_eq(SmokeWitch_IsSupportedActorAssignment(view_as<Address>(10)),true);
    for(int i=0;i<3;i++) { int old=g_Bytes[i];g_Bytes[i]=0;assert_eq(SmokeWitch_IsSupportedActorAssignment(view_as<Address>(10)),false);g_Bytes[i]=old; }
    SmokeWitch_Observe(50,1000,-1); Expect("initial_observation",1);
    SmokeWitch_Observe(50,1000,-1); assert_eq(g_Headers,1);
    SmokeWitch_Observe(50,1000,2); Expect("target_acquired",2);
    SmokeWitch_Observe(50,1000,3); Expect("target_changed",3); assert_eq(g_PreviousUser,3);assert_eq(g_PreviousSerial,100);
    SmokeWitch_Observe(50,1000,2); Expect("target_changed",4);
    g_User=73; g_Serial=300; SmokeWitch_Observe(50,1000,2); Expect("target_changed",5);assert_eq(g_PreviousUser,3);assert_eq(g_PreviousSerial,100);
    SmokeWitch_Observe(50,1000,-1); Expect("target_lost",6);assert_eq(g_PreviousUser,73);
    SmokeWitch_Observe(50,1000,-1); assert_eq(g_Headers,6);
    SmokeWitch_Observe(50,1000,2); Expect("target_acquired",7);
    SmokeWitch_Observe(50,2000,2); Expect("action_changed",8);
    SmokeWitch_Observe(50,2000,999); Expect("target_unresolved",9);
    SmokeWitch_Observe(50,2000,-1); Expect("action_changed",10);
    g_Result=3; assert_eq(SmokeWitch_GetVictimPost(view_as<Address>(2000),view_as<DHookReturn>(1)),MRES_Ignored);Expect("target_acquired",11);assert_eq(g_Result,3);
    g_Active=false; SmokeWitch_GetVictimPost(view_as<Address>(2000),view_as<DHookReturn>(1)); assert_eq(g_Headers,11);g_Active=true;
    g_Owner=-1;SmokeWitch_GetVictimPost(view_as<Address>(2000),view_as<DHookReturn>(1));assert_eq(g_Headers,12);
    SmokeWitchTarget snapshot;g_SmokeWitchTargets.GetArray(0,snapshot,sizeof(snapshot));assert_eq(snapshot.queries,13);assert_eq(snapshot.actionQueries,4);
    SmokeWitch_Heartbeat();assert_eq(g_Headers,13);assert_eq(g_StatusQueries,13);
    SmokeWitch_Heartbeat();assert_eq(g_Headers,13);
    g_Clock=2.0;SmokeWitch_Heartbeat();assert_eq(g_Headers,14);assert_eq(g_StatusQueries,13);
    SmokeWitch_Observe(50,2000,3);assert_eq(g_Headers,14);
    g_Clock=3.0;SmokeWitch_Heartbeat();assert_eq(g_Headers,15);assert_eq(g_StatusQueries,14);
    SmokeWitch_OnEntityDestroyed(50);assert_eq(g_Count,0);assert_eq(g_Headers,17);
    g_WitchRef=-2000;SmokeWitch_Observe(50,2000,2);Expect("initial_observation",18);
    SmokeWitch_OnEntityDestroyed(-2000);assert_eq(g_Count,0);
    print("WITCH_TARGET_PASS initial acquired changed lost reacquired dedup slot_reuse entity_reuse unresolved passive ABI_guard\n");
    return 0;
}
'''


class WitchTargetTests(unittest.TestCase):
    def test_real_transition_and_post_callback_in_vm(self):
        if not COMPILER.exists() or not SHELL.exists():
            self.skipTest('SourcePawn compiler/VM unavailable')
        with tempfile.TemporaryDirectory(prefix='skills-witch-target-') as d:
            p=Path(d)/'witch.sp'; p.write_text(harness())
            prefix=Path(d)/'empty.inc';prefix.write_text('')
            result=subprocess.run([str(COMPILER),'-i'+str(HERE.parent.parent.parent/'SteamIDTools/deps/sourcepawn/include'),'-p',str(prefix),'-o'+str(p.with_suffix('.smx')),str(p)],capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertNotIn('warning ',result.stdout.lower())
            result=subprocess.run([str(SHELL),str(p.with_suffix('.smx'))],capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertIn('WITCH_TARGET_PASS',result.stdout)

    def test_detour_and_lifecycle_never_modify_engine_state(self):
        text=SOURCE.read_text()
        self.assertNotRegex(text,r'result\.Value\s*=|StoreToAddress|SetEntProp|SDKCall\(')
        callback=extract_function(text,'SmokeWitch_GetVictimPost')
        self.assertNotRegex(callback,r'MRES_(Override|Supercede|Handled)')
        root=(HERE/'game_event_observer.sp.in').read_text()
        for name in ['StopTrace','OnMapEnd']:
            self.assertIn('SmokeWitch_Stop();',extract_function(root,name))
        for name in ['CommandStart','OnMapStart']:
            self.assertIn('SmokeWitch_Start();',extract_function(root,name))
        self.assertIn('Disable(Hook_Post, SmokeWitch_GetVictimPost)',text)
        self.assertIn('actor_layout_guard_failed',text)
        self.assertIn('missing_victim_signature',text)
        self.assertIn('missing_actor_signature',text)
        self.assertIn('invalid_actor_assignment_offset',text)


if __name__=='__main__':unittest.main(verbosity=2)
