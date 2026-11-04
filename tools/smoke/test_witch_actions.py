"""Execute real Actions POST callbacks with immutable simulated provider results."""
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
from test_source_observer import COMPILER,SHELL,extract_function

HERE=Path(__file__).resolve().parent
SOURCE=HERE/'witch_actions_observer.sp.inc'
NAMES=['SmokeActions_Find','SmokeActions_Generation','SmokeActions_IsAttack','SmokeActions_ActionValue','SmokeActions_Begin','SmokeActions_Result','SmokeActions_OnStartPost','SmokeActions_UpdatePost','SmokeActions_OnEndPost','SmokeActions_OnSuspendPost','SmokeActions_OnResumePost','SmokeActions_OnMoveToFailurePost']


def harness():
    text=SOURCE.read_text()
    structure=text[text.index('enum struct SmokeActionTracked'):text.index('ArrayList g_SmokeActions;')]
    functions='\n'.join(extract_function(text,name) for name in NAMES)
    return r'''#pragma semicolon 1
#pragma newdecls required
native void assert_eq(any a, any b);
native void print(const char[] text);
enum Address { Address_Null=0 }
enum Action { Plugin_Continue=0 }
#define TraceSource_Engine 0
''' + structure + r'''
int g_Rows[2][sizeof(SmokeActionTracked)];
int g_Count=2;
methodmap ArrayList __nullable__ {
 property int Length {
  public get(){return g_Count;}
 }
 public void GetArray(int row,any[] value,int size){for(int i=0;i<size;i++)value[i]=g_Rows[row][i];}
}
ArrayList g_SmokeActions=view_as<ArrayList>(1);
bool StrEqual(const char[] a,const char[] b){int i;while(a[i] && a[i]==b[i])i++;return a[i]==b[i];}
void CacheSet(int row,const any[] value,int size){for(int i=0;i<size;i++)g_Rows[row][i]=value[i];}
void SmokeEpisodes_Result(int actor,int type,const char[] reason){assert_eq(actor,50);assert_eq(type>=0,true);assert_eq(reason[0],'n');}
void SmokeEpisodes_AttackStart(int actor,int action,int generation){assert_eq(actor,50);assert_eq(action,1001);assert_eq(generation,10);}
void SmokeEpisodes_End(int actor,int action,int next){assert_eq(actor,50);assert_eq(action,1001);assert_eq(next,213808128);}
void SmokeEpisodes_Suspended(int actor,int action,bool value){assert_eq(actor,50);assert_eq(action,1001);assert_eq(value==true || value==false,true);}
void SmokeEpisodes_Navigation(int actor,int action,int failure){assert_eq(actor,50);assert_eq(action,1001);assert_eq(failure,2);}
int g_Type=1,g_Next=2002,g_Headers,g_ReasonReads,g_TypeReads,g_RawFailure,g_Priority,g_ResultType,g_NameReads;
bool g_Active=true;
char g_Reason[64]="navigation failed";
void Copy(char[] output,int capacity,const char[] text) { int i;while(i<capacity-1 && text[i]){output[i]=text[i];i++;}output[i]=0; }
int strlen(const char[] text) { int i;while(text[i])i++;return i; }
methodmap BehaviorAction {
 public int GetName(char[] output,int capacity) { assert_eq(false,true); Copy(output,capacity,view_as<int>(this)==1001 ? "WitchAttack":"WitchRetreat");g_NameReads++;return 0; }
}
methodmap ActionResult {
 public void GetReason(char[] output,int capacity) { assert_eq(view_as<int>(this),10);Copy(output,capacity,g_Reason);g_ReasonReads++; }
 property int type {
  public get(){assert_eq(view_as<int>(this),10);g_TypeReads++;return g_Type;}
 }
 property BehaviorAction action {
  public get(){assert_eq(view_as<int>(this),10);return view_as<BehaviorAction>(g_Next);}
 }
}
methodmap ActionDesiredResult < ActionResult {
 property int priority {
  public get(){assert_eq(view_as<int>(this),10);return 3;}
 }
}
bool TraceActive(){return g_Active;}
bool SmokeActions_IsWitch(int actor){return actor==50;}
int TraceBegin(int source,const char[] callback){assert_eq(source,0);assert_eq(callback[0],'w');return ++g_Headers;}
void TraceTextValue(int source,int seq,const char[] key,const char[] text,bool possible=false){assert_eq(source,0);assert_eq(seq,g_Headers);assert_eq(key[0]!=0,true);assert_eq(text[0]!=0,true);assert_eq(possible,false);}
void TraceIntValue(int source,int seq,const char[] key,int value){assert_eq(source,0);assert_eq(seq,g_Headers);if(key[0]=='f')g_RawFailure=value;if(key[0]=='r' && key[7]=='p')g_Priority=value;if(key[0]=='r' && key[7]=='t')g_ResultType=value;}
void TraceEntityValue(int source,int seq,const char[] key,int entity){assert_eq(source,0);assert_eq(seq,g_Headers);assert_eq(key[0],'w');assert_eq(entity,50);}
void TraceFloatValue(int source,int seq,const char[] key,float value){assert_eq(source,0);assert_eq(seq,g_Headers);assert_eq(key[0],'i');assert_eq(view_as<int>(value),view_as<int>(0.25));}
void FormatEx(char[] output,int capacity,const char[] format,const char[] key){assert_eq(format[0],'%');Copy(output,capacity,key);}
''' + functions + r'''
public int main(){
 SmokeActionTracked cached;cached.address=1001;cached.generation=10;Copy(cached.name,sizeof(cached.name),"WitchAttack");CacheSet(0,cached,sizeof(cached));
 cached.address=2002;cached.generation=11;Copy(cached.name,sizeof(cached.name),"WitchRetreat");CacheSet(1,cached,sizeof(cached));
 BehaviorAction a=view_as<BehaviorAction>(1001),b=view_as<BehaviorAction>(2002),none=view_as<BehaviorAction>(0);
 ActionResult result=view_as<ActionResult>(10);
 assert_eq(SmokeActions_OnStartPost(a,50,none,result),Plugin_Continue);assert_eq(g_Headers,1);assert_eq(g_ResultType,1);
 g_Type=0;assert_eq(SmokeActions_UpdatePost(a,50,0.25,result),Plugin_Continue);assert_eq(g_Headers,1);
 g_Type=1;assert_eq(SmokeActions_UpdatePost(a,50,0.25,result),Plugin_Continue);assert_eq(g_Headers,2);
 int before=g_ReasonReads,typeBefore=g_TypeReads;
 SmokeActions_OnEndPost(a,50,view_as<BehaviorAction>(213808128),view_as<ActionResult>(999));assert_eq(g_Headers,3);assert_eq(g_ReasonReads,before);assert_eq(g_TypeReads,typeBefore);
 assert_eq(SmokeActions_OnSuspendPost(a,50,b,result),Plugin_Continue);assert_eq(g_Headers,4);
 assert_eq(SmokeActions_OnResumePost(a,50,view_as<BehaviorAction>(213808128),result),Plugin_Continue);assert_eq(g_Headers,5);
 assert_eq(SmokeActions_OnMoveToFailurePost(a,50,view_as<Address>(1234),2,view_as<ActionDesiredResult>(10)),Plugin_Continue);assert_eq(g_Headers,6);assert_eq(g_RawFailure,2);assert_eq(g_Priority,3);
 assert_eq(SmokeActions_OnStartPost(a,0,none,result),Plugin_Continue);assert_eq(g_Headers,6);
 g_Active=false;SmokeActions_OnMoveToFailurePost(a,50,view_as<Address>(1234),2,view_as<ActionDesiredResult>(999));assert_eq(g_Headers,6);
 assert_eq(g_Type,1);assert_eq(g_Next,2002);assert_eq(g_Reason[0],'n');assert_eq(g_ReasonReads,5);assert_eq(g_NameReads,0);
 print("WITCH_ACTIONS_PASS post_callbacks_passive result_unchanged void_result_not_read inactive_guard raw_navigation_reason\n");return 0;
}
'''


class WitchActionTests(unittest.TestCase):
    def test_real_post_callbacks_are_passive_in_vm(self):
        if not COMPILER.exists() or not SHELL.exists():self.skipTest('SourcePawn compiler/VM unavailable')
        with tempfile.TemporaryDirectory(prefix='skills-actions-') as d:
            p=Path(d)/'actions.sp';p.write_text(harness());prefix=Path(d)/'empty.inc';prefix.write_text('')
            r=subprocess.run([str(COMPILER),'-p',str(prefix),'-o'+str(p.with_suffix('.smx')),str(p)],capture_output=True,text=True)
            self.assertEqual(r.returncode,0,r.stdout+r.stderr);self.assertNotIn('warning ',r.stdout.lower())
            r=subprocess.run([str(SHELL),str(p.with_suffix('.smx'))],capture_output=True,text=True)
            self.assertEqual(r.returncode,0,r.stdout+r.stderr);self.assertIn('WITCH_ACTIONS_PASS',r.stdout)

    def test_registration_and_teardown_are_scoped_to_own_post_listeners(self):
        text=SOURCE.read_text()
        self.assertNotRegex(text,r'result\.(type|action)\s*=|SetReason\(|StoreToAddress|SetEntProp|SDKCall\(')
        self.assertIn('__action_setlistener(action, processor, callback, true)',text)
        for name in NAMES:
            function=extract_function(text,name)
            if name in ['SmokeActions_OnStartPost','SmokeActions_UpdatePost','SmokeActions_OnSuspendPost','SmokeActions_OnResumePost','SmokeActions_OnMoveToFailurePost']:
                self.assertIn('return Plugin_Continue;',function)
        self.assertEqual(extract_function(text,'SmokeActions_Stop').count('__action_removelistener('),6)
        self.assertNotIn('__action_removelistener',extract_function(text,'OnActionDestroyed'))
        self.assertNotIn('result.',extract_function(text,'SmokeActions_OnEndPost'))
        self.assertIn('handler_result_not_committed_transition',text)
        self.assertNotIn('.GetName(',extract_function(text,'SmokeActions_ActionValue'))
        self.assertEqual(text.count('.GetName('),1)

if __name__=='__main__':unittest.main(verbosity=2)
