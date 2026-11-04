// Consumed read/listener subset of the installed Actions extension API.
// Matches actions.inc/actions_processors.inc; no action constructors or mutators.
// Provider headers remain external to the standalone source distribution.
methodmap BehaviorAction
{
	public native int GetName(char[] destination, int maxlength = 32);
	property int Actor {
		public native get();
	}
}
methodmap ActionResult
{
	public native void GetReason(char[] destination, int maxlength);
	property int type {
		public native get();
	}
	property BehaviorAction action {
		public native get();
	}
}
methodmap ActionDesiredResult < ActionResult
{
	property int priority {
		public native get();
	}
}
typedef SmokeActionsIterator = function void(BehaviorAction action);
methodmap ActionsManager
{
	public static native int Iterator(int entity, SmokeActionsIterator callback);
}
native bool __action_setlistener(any action, any processor, Function callback, bool post);
native bool __action_removelistener(any action, any processor, Function callback, bool post);
public int __action_processor_OnStart;
public int __action_processor_Update;
public int __action_processor_OnEnd;
public int __action_processor_OnSuspend;
public int __action_processor_OnResume;
public int __action_processor_OnMoveToFailure;

// Required for this observer version: the installed provider owns ABI and hooks.
// SourceMod manages dependency unload; Stop also tolerates native unavailability.
public Extension __ext_actions =
{
	name = "Actions",
	file = "actions.ext",
	autoload = 1,
	required = 1
};
