"""Execute the real episode ledger: confirmed/context closes and action reuse."""
from pathlib import Path
import subprocess
import tempfile
import unittest
from test_source_observer import COMPILER,SHELL

HERE=Path(__file__).resolve().parent
SOURCE=HERE/'witch_episodes.sp.inc'


def harness():
    text=SOURCE.read_text()
    split=text.index('ArrayList g_SmokeEpisodes;')
    structure=text[:split]
    return r'''#include <core/float>
#pragma semicolon 1
#pragma newdecls required
native void assert_eq(any a,any b);
native void print(const char[] text);
enum Handle { INVALID_HANDLE=0 }
methodmap Handle __nullable__ {
 public native ~Handle();
};
enum BehaviorAction { INVALID_ACTION=0 }
#define INVALID_ENT_REFERENCE -1
#define TraceSource_Engine 0
''' + structure + r'''
int g_Rows[30][sizeof(SmokeWitchEpisode)],g_Count,g_SmokeEpisodeSerial;
methodmap ArrayList < Handle {
 public ArrayList(int size){assert_eq(size,sizeof(SmokeWitchEpisode));g_Count=0;return view_as<ArrayList>(10);}
 property int Length {
  public get(){return g_Count;}
 }
 public void GetArray(int row,any[] value,int size){for(int i=0;i<size;i++)value[i]=g_Rows[row][i];}
 public void SetArray(int row,const any[] value,int size){for(int i=0;i<size;i++)g_Rows[row][i]=value[i];}
 public int PushArray(const any[] value,int size){for(int i=0;i<size;i++)g_Rows[g_Count][i]=value[i];return g_Count++;}
}
int g_Tick=1000,g_WitchRef=-1000,g_Generation=10,g_Headers,g_Opened,g_Closed,g_Confirmed;
int g_EndObserved,g_ContextClosed,g_LastUser,g_NavObserved,g_NavRaw,g_ContextOnly,g_QueryCount,g_NextAction;
float g_Time=10.0;
char g_ClosedBy[64];
bool StrEqual(const char[] a,const char[] b){int i;while(a[i] && a[i]==b[i])i++;return a[i]==b[i];}
int strcopy(char[] out,int capacity,const char[] text){int i;while(i<capacity-1 && text[i]){out[i]=text[i];i++;}out[i]=0;return i;}
int strlen(const char[] text){int i;while(text[i])i++;return i;}
int EntIndexToEntRef(int entity){return entity==50 ? g_WitchRef:-5000;}
int GetGameTickCount(){return g_Tick;}
float GetEngineTime(){return g_Time;}
int SmokeActions_Generation(int action){return action==1001 ? g_Generation:20;}
void SmokeActions_ActionValue(int seq,const char[] key,BehaviorAction action){assert_eq(seq,g_Headers);assert_eq(StrEqual(key,"next_action"),true);g_NextAction=view_as<int>(action);}
int TraceBegin(int source,const char[] callback){assert_eq(source,0);if(StrEqual(callback,"witch_attack_episode_open"))g_Opened++;if(StrEqual(callback,"witch_attack_episode_closed"))g_Closed++;if(StrEqual(callback,"witch_attack_episode_start_confirmed"))g_Confirmed++;return ++g_Headers;}
void TraceIntValue(int source,int seq,const char[] key,int value){assert_eq(source,0);assert_eq(seq,g_Headers);
 if(StrEqual(key,"end_observed"))g_EndObserved=value;if(StrEqual(key,"context_closed"))g_ContextClosed=value;
 if(StrEqual(key,"last_target_userid"))g_LastUser=value;if(StrEqual(key,"navigation_observed"))g_NavObserved=value;
 if(StrEqual(key,"navigation_type_raw"))g_NavRaw=value;if(StrEqual(key,"navigation_context_only"))g_ContextOnly=value;
 if(StrEqual(key,"queries"))g_QueryCount=value;
}
void TraceTextValue(int source,int seq,const char[] key,const char[] value,bool truncated=false){assert_eq(source,0);assert_eq(seq,g_Headers);assert_eq(truncated,false);if(StrEqual(key,"cause"))assert_eq(StrEqual(value,"unknown"),true);if(StrEqual(key,"closed_by"))strcopy(g_ClosedBy,sizeof(g_ClosedBy),value);}
void TraceFloatValue(int source,int seq,const char[] key,float value){assert_eq(source,0);assert_eq(seq,g_Headers);assert_eq(StrEqual(key,"observed_duration"),true);assert_eq(value>=0.0,true);}
''' + text[split:] + r'''
public int main(){
 SmokeEpisodes_Start();SmokeEpisodes_AttackStart(50,1001,10);SmokeEpisodes_AttackStart(50,1001,10);assert_eq(g_Opened,1);
 SmokeEpisodes_Query(50,1001,-102,3,100,1000);SmokeEpisodes_Query(50,1001,-102,73,300,1001);
 SmokeEpisodes_Suspended(50,1001,true);SmokeEpisodes_Navigation(50,2002,99);SmokeEpisodes_Result(50,1,"ignored suspended context");
 SmokeWitchEpisode snapshot;g_SmokeEpisodes.GetArray(0,snapshot,sizeof(snapshot));assert_eq(snapshot.open,true);assert_eq(snapshot.navigationObserved,false);
 SmokeEpisodes_Suspended(50,1001,false);g_Tick=1001;SmokeEpisodes_Navigation(50,2002,0);SmokeEpisodes_Result(50,3,"navigation context");
 g_Tick=1002;g_Time=12.0;SmokeEpisodes_End(50,1001,213808128);assert_eq(g_Closed,1);assert_eq(g_EndObserved,1);assert_eq(g_ContextClosed,0);assert_eq(g_LastUser,73);assert_eq(g_NavObserved,1);assert_eq(g_NavRaw,0);assert_eq(g_ContextOnly,1);assert_eq(g_QueryCount,2);assert_eq(g_NextAction,213808128);
 SmokeEpisodes_End(50,1001,213808128);SmokeEpisodes_EntityDestroyed(50);SmokeEpisodes_Stop("capture_stopped");assert_eq(g_Closed,1);
 SmokeEpisodes_Start();g_WitchRef=-2000;g_Generation=11;SmokeEpisodes_Query(50,1001,-102,3,100,1003);assert_eq(g_Opened,2);
 SmokeEpisodes_AttackStart(50,1001,11);SmokeEpisodes_AttackStart(50,1001,11);assert_eq(g_Confirmed,1);assert_eq(g_Opened,2);
 SmokeEpisodes_End(50,1001,0);assert_eq(g_Closed,2);SmokeEpisodes_Query(50,1001,-102,3,100,1004);assert_eq(g_Opened,2);
 SmokeEpisodes_ActionDestroyed(1001,11);assert_eq(g_Closed,2);
 g_Generation=12;SmokeEpisodes_Query(50,1001,-102,3,100,1005);assert_eq(g_Opened,3);SmokeEpisodes_EntityDestroyed(-2000);assert_eq(g_Closed,3);assert_eq(g_EndObserved,0);assert_eq(g_ContextClosed,1);assert_eq(StrEqual(g_ClosedBy,"entity_destroyed"),true);
 SmokeEpisodes_End(50,1001,0);assert_eq(g_Closed,3);
 SmokeEpisodes_AttackStart(50,1001,12);assert_eq(g_Opened,4);SmokeEpisodes_ActionDestroyed(1001,12);assert_eq(g_Closed,4);assert_eq(StrEqual(g_ClosedBy,"action_destroyed_without_end"),true);
 g_Generation=13;SmokeEpisodes_AttackStart(50,1001,13);SmokeEpisodes_Stop("map_end");assert_eq(g_Closed,5);assert_eq(StrEqual(g_ClosedBy,"map_end"),true);
 SmokeEpisodes_Start();g_Generation=14;SmokeEpisodes_AttackStart(50,1001,14);SmokeEpisodes_AttackStart(51,2002,20);assert_eq(g_Opened,7);
 SmokeEpisodes_Navigation(50,1001,7);SmokeEpisodes_End(51,2002,0);assert_eq(g_Closed,6);assert_eq(g_NavObserved,0);
 SmokeEpisodes_Stop("capture_stopped");assert_eq(g_Closed,7);assert_eq(g_NavObserved,1);assert_eq(g_NavRaw,7);
 print("WITCH_EPISODES_PASS close_once unknown_cause nav_context suspended target_snapshot pointer_reuse late_attach context_close independent_witches\n");return 0;
}
'''


class WitchEpisodeTests(unittest.TestCase):
    def test_real_episode_lifecycle_in_sourcepawn_vm(self):
        if not COMPILER.exists() or not SHELL.exists():self.skipTest('SourcePawn compiler/VM unavailable')
        with tempfile.TemporaryDirectory(prefix='skills-episodes-') as d:
            p=Path(d)/'episodes.sp';p.write_text(harness());prefix=Path(d)/'empty.inc';prefix.write_text('')
            include=HERE.parent.parent.parent/'SteamIDTools/deps/sourcepawn/include'
            r=subprocess.run([str(COMPILER),'-i'+str(include),'-p',str(prefix),'-o'+str(p.with_suffix('.smx')),str(p)],capture_output=True,text=True)
            self.assertEqual(r.returncode,0,r.stdout+r.stderr);self.assertNotIn('warning ',r.stdout.lower())
            r=subprocess.run([str(SHELL),str(p.with_suffix('.smx'))],capture_output=True,text=True)
            self.assertEqual(r.returncode,0,r.stdout+r.stderr);self.assertIn('WITCH_EPISODES_PASS',r.stdout)

if __name__=='__main__':unittest.main(verbosity=2)
