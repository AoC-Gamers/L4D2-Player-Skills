// Passive POST listeners. Handler results are observations, not proof that the
// behavior manager committed a requested transition. OnEnd/OnStart add evidence.
enum struct SmokeActionTracked
{
	int address;
	int flags;
	int generation;
	char name[64];
}
ArrayList g_SmokeActions;
int g_SmokeActionSerial;

bool SmokeActions_IsWitch(int actor)
{
	if (actor <= MaxClients || !IsValidEntity(actor)) return false;
	char classname[32];
	GetEntityClassname(actor, classname, sizeof(classname));
	return StrEqual(classname, "witch") || StrEqual(classname, "witch_bride");
}

int SmokeActions_Find(int address)
{
	SmokeActionTracked tracked;
	for (int i = 0; i < g_SmokeActions.Length; i++)
	{
		g_SmokeActions.GetArray(i, tracked, sizeof(tracked));
		if (tracked.address == address) return i;
	}
	return -1;
}

void SmokeActions_Start()
{
	if (g_SmokeActions != null) return;
	g_SmokeActions = new ArrayList(sizeof(SmokeActionTracked));
	int seq = TraceBegin(TraceSource_Engine, "witch_actions_coverage");
	TraceTextValue(TraceSource_Engine, seq, "method", "actions_extension:post_listeners");
	TraceIntValue(TraceSource_Engine, seq, "provider_available", GetFeatureStatus(FeatureType_Native, "__action_setlistener") == FeatureStatus_Available);
	TraceTextValue(TraceSource_Engine, seq, "result_scope", "handler_result_not_committed_transition");
	static const char classes[][] = {"witch", "witch_bride"};
	for (int i = 0; i < sizeof(classes); i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, classes[i])) != -1)
		{
			ActionsManager.Iterator(entity, SmokeActions_Existing);
		}
	}
}

void SmokeActions_Existing(BehaviorAction action)
{
	char name[64];
	action.GetName(name, sizeof(name));
	SmokeActions_Track(action, action.Actor, name);
}

void SmokeActions_Set(BehaviorAction action, int processor, Function callback, int flag, int &flags)
{
	bool registered = __action_setlistener(action, processor, callback, true);
	int seq = TraceBegin(TraceSource_Engine, "witch_actions_listener_coverage");
	TraceIntValue(TraceSource_Engine, seq, "action_address", view_as<int>(action));
	TraceIntValue(TraceSource_Engine, seq, "listener_flag", flag);
	TraceIntValue(TraceSource_Engine, seq, "registered", registered);
	if (registered) flags |= flag;
}

void SmokeActions_Track(BehaviorAction action, int actor, const char[] name, bool created = false)
{
	if (g_SmokeActions == null) return;
	int previous = SmokeActions_Find(view_as<int>(action));
	if (previous != -1)
	{
		if (!created) return;
		// New constructor observation wins over a stale address lifetime.
		SmokeEpisodes_ActionDestroyed(view_as<int>(action), SmokeActions_Generation(view_as<int>(action)), "action_lifetime_replaced");
		g_SmokeActions.Erase(previous);
	}
	// Creation may precede actor assignment. Names identify the action family;
	// every gameplay listener later validates the actor supplied by the provider.
	SmokeActionTracked tracked;
	tracked.address = view_as<int>(action);
	tracked.generation = ++g_SmokeActionSerial;
	strcopy(tracked.name, sizeof(tracked.name), name);
	if (StrContains(name, "Witch") != 0)
	{
		g_SmokeActions.PushArray(tracked, sizeof(tracked));
		return;
	}
	int seq = TraceBegin(TraceSource_Engine, "witch_action_seen");
	TraceIntValue(TraceSource_Engine, seq, "action_address", view_as<int>(action));
	TraceEntityValue(TraceSource_Engine, seq, "actor", actor);
	TraceTextValue(TraceSource_Engine, seq, "action_name", name);
	SmokeActions_Set(action, __action_processor_OnStart, SmokeActions_OnStartPost, 1, tracked.flags);
	SmokeActions_Set(action, __action_processor_Update, SmokeActions_UpdatePost, 2, tracked.flags);
	SmokeActions_Set(action, __action_processor_OnEnd, SmokeActions_OnEndPost, 4, tracked.flags);
	SmokeActions_Set(action, __action_processor_OnSuspend, SmokeActions_OnSuspendPost, 8, tracked.flags);
	SmokeActions_Set(action, __action_processor_OnResume, SmokeActions_OnResumePost, 16, tracked.flags);
	SmokeActions_Set(action, __action_processor_OnMoveToFailure, SmokeActions_OnMoveToFailurePost, 32, tracked.flags);
	g_SmokeActions.PushArray(tracked, sizeof(tracked));
}

void SmokeActions_Stop()
{
	if (g_SmokeActions == null) return;
	if (GetFeatureStatus(FeatureType_Native, "__action_removelistener") == FeatureStatus_Available)
	{
		SmokeActionTracked tracked;
		for (int i = 0; i < g_SmokeActions.Length; i++)
		{
			g_SmokeActions.GetArray(i, tracked, sizeof(tracked));
			if (tracked.flags & 1) __action_removelistener(tracked.address, __action_processor_OnStart, SmokeActions_OnStartPost, true);
			if (tracked.flags & 2) __action_removelistener(tracked.address, __action_processor_Update, SmokeActions_UpdatePost, true);
			if (tracked.flags & 4) __action_removelistener(tracked.address, __action_processor_OnEnd, SmokeActions_OnEndPost, true);
			if (tracked.flags & 8) __action_removelistener(tracked.address, __action_processor_OnSuspend, SmokeActions_OnSuspendPost, true);
			if (tracked.flags & 16) __action_removelistener(tracked.address, __action_processor_OnResume, SmokeActions_OnResumePost, true);
			if (tracked.flags & 32) __action_removelistener(tracked.address, __action_processor_OnMoveToFailure, SmokeActions_OnMoveToFailurePost, true);
		}
	}
	delete g_SmokeActions;
}

public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
	if (!TraceActive()) return;
	SmokeActions_Track(action, actor, name, true);
}

public void OnActionDestroyed(BehaviorAction action, int actor, const char[] name)
{
	if (g_SmokeActions == null) return;
	int index = SmokeActions_Find(view_as<int>(action));
	if (index == -1) return;
	SmokeEpisodes_ActionDestroyed(view_as<int>(action), SmokeActions_Generation(view_as<int>(action)));
	SmokeActionTracked tracked;
	g_SmokeActions.GetArray(index, tracked, sizeof(tracked));
	if (tracked.flags == 0)
	{
		g_SmokeActions.Erase(index);
		return;
	}
	int seq = TraceBegin(TraceSource_Engine, "witch_action_destroyed");
	TraceIntValue(TraceSource_Engine, seq, "action_address", view_as<int>(action));
	TraceEntityValue(TraceSource_Engine, seq, "actor", actor);
	TraceTextValue(TraceSource_Engine, seq, "action_name", name);
	// The action is in its destructor. Do not call its methods/remove listeners.
	g_SmokeActions.Erase(index);
}

int SmokeActions_Generation(int address)
{
	if (g_SmokeActions == null) return 0;
	int index = SmokeActions_Find(address);
	if (index == -1) return 0;
	SmokeActionTracked tracked;
	g_SmokeActions.GetArray(index, tracked, sizeof(tracked));
	return tracked.generation;
}

bool SmokeActions_IsAttack(int address)
{
	if (g_SmokeActions == null) return false;
	int index = SmokeActions_Find(address);
	if (index == -1) return false;
	SmokeActionTracked tracked;
	g_SmokeActions.GetArray(index, tracked, sizeof(tracked));
	return StrEqual(tracked.name, "WitchAttack");
}

void SmokeActions_ActionValue(int seq, const char[] key, BehaviorAction action)
{
	int address = view_as<int>(action);
	TraceIntValue(TraceSource_Engine, seq, key, address);
	if (address == 0) return;
	char field[96];
	int index = g_SmokeActions != null ? SmokeActions_Find(address) : -1;
	FormatEx(field, sizeof(field), "%s_name_known", key);
	TraceIntValue(TraceSource_Engine, seq, field, index != -1);
	if (index == -1) return; // Never dereference a foreign/expired action pointer.
	SmokeActionTracked tracked;
	g_SmokeActions.GetArray(index, tracked, sizeof(tracked));
	FormatEx(field, sizeof(field), "%s_name", key);
	TraceTextValue(TraceSource_Engine, seq, field, tracked.name, strlen(tracked.name) == sizeof(tracked.name) - 1);
	FormatEx(field, sizeof(field), "%s_generation", key);
	TraceIntValue(TraceSource_Engine, seq, field, tracked.generation);
}

int SmokeActions_Begin(const char[] callback, BehaviorAction action, int actor)
{
	int seq = TraceBegin(TraceSource_Engine, callback);
	TraceTextValue(TraceSource_Engine, seq, "method", "actions_extension:post_listener");
	TraceEntityValue(TraceSource_Engine, seq, "witch", actor);
	SmokeActions_ActionValue(seq, "action", action);
	return seq;
}

void SmokeActions_Result(int seq, ActionResult result, int actor)
{
	int type = result.type;
	TraceIntValue(TraceSource_Engine, seq, "result_type", type);
	SmokeActions_ActionValue(seq, "result_action", result.action);
	char reason[512];
	result.GetReason(reason, sizeof(reason));
	SmokeEpisodes_Result(actor, type, reason);
	TraceTextValue(TraceSource_Engine, seq, "result_reason", reason, strlen(reason) == sizeof(reason) - 1);
	TraceTextValue(TraceSource_Engine, seq, "result_scope", "handler_result_not_committed_transition");
}

Action SmokeActions_OnStartPost(BehaviorAction action, int actor, BehaviorAction prior, ActionResult result)
{
	if (TraceActive() && SmokeActions_IsWitch(actor))
	{
		int seq = SmokeActions_Begin("witch_action_start_post", action, actor);
		if (SmokeActions_IsAttack(view_as<int>(action))) SmokeEpisodes_AttackStart(actor, view_as<int>(action), SmokeActions_Generation(view_as<int>(action)));
		SmokeActions_ActionValue(seq, "prior_action", prior);
		SmokeActions_Result(seq, result, actor);
	}
	return Plugin_Continue;
}

Action SmokeActions_UpdatePost(BehaviorAction action, int actor, float interval, ActionResult result)
{
	if (TraceActive() && SmokeActions_IsWitch(actor) && result.type != 0)
	{
		int seq = SmokeActions_Begin("witch_action_update_result", action, actor);
		TraceFloatValue(TraceSource_Engine, seq, "interval", interval);
		SmokeActions_Result(seq, result, actor);
	}
	return Plugin_Continue;
}

void SmokeActions_OnEndPost(BehaviorAction action, int actor, BehaviorAction next, ActionResult unused)
{
	#pragma unused unused
	if (!TraceActive() || !SmokeActions_IsWitch(actor)) return;
	int seq = SmokeActions_Begin("witch_action_end_post", action, actor);
	SmokeEpisodes_End(actor, view_as<int>(action), view_as<int>(next));
	SmokeActions_ActionValue(seq, "next_action", next);
	// OnEnd is void. Do not read the result argument or infer a target loss.
}

Action SmokeActions_OnSuspendPost(BehaviorAction action, int actor, BehaviorAction other, ActionResult result)
{
	if (TraceActive() && SmokeActions_IsWitch(actor))
	{
		int seq = SmokeActions_Begin("witch_action_suspend_post", action, actor);
		SmokeEpisodes_Suspended(actor, view_as<int>(action), true);
		SmokeActions_ActionValue(seq, "interrupting_action", other);
		SmokeActions_Result(seq, result, actor);
	}
	return Plugin_Continue;
}

Action SmokeActions_OnResumePost(BehaviorAction action, int actor, BehaviorAction other, ActionResult result)
{
	if (TraceActive() && SmokeActions_IsWitch(actor))
	{
		int seq = SmokeActions_Begin("witch_action_resume_post", action, actor);
		SmokeEpisodes_Suspended(actor, view_as<int>(action), false);
		SmokeActions_ActionValue(seq, "interrupting_action", other);
		SmokeActions_Result(seq, result, actor);
	}
	return Plugin_Continue;
}

Action SmokeActions_OnMoveToFailurePost(BehaviorAction action, int actor, Address path, int failure, ActionDesiredResult result)
{
	if (TraceActive() && SmokeActions_IsWitch(actor))
	{
		int seq = SmokeActions_Begin("witch_action_move_failure_post", action, actor);
		TraceIntValue(TraceSource_Engine, seq, "path_address", view_as<int>(path));
		SmokeEpisodes_Navigation(actor, view_as<int>(action), failure);
		TraceIntValue(TraceSource_Engine, seq, "failure_type_raw", failure);
		TraceIntValue(TraceSource_Engine, seq, "result_priority", result.priority);
		SmokeActions_Result(seq, result, actor);
	}
	return Plugin_Continue;
}
