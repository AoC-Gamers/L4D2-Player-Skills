// Engine-side observation, not a Left4DHooks forward or a fabricated game event.
// Only observe calls made by the engine. Never call GetVictim ourselves.
// Linux x86 layout is guarded by the actor-assignment instruction in the binary.
enum struct SmokeWitchTarget
{
	int witchRef;
	int witchIndex;
	int actionAddress;
	int rawTarget;
	int targetRef;
	int userid;
	int serial;
	int queries;
	int actionQueries;
	int firstQueryTick;
	int lastQueryTick;
}
ArrayList g_SmokeWitchTargets;
DynamicDetour g_SmokeWitchVictimDetour;
bool g_SmokeWitchVictimEnabled;
int g_SmokeWitchActorOffset;
float g_SmokeWitchNextHeartbeat;

void SmokeWitch_Start()
{
	if (g_SmokeWitchTargets != null) return;
	g_SmokeWitchNextHeartbeat = 0.0;
	g_SmokeWitchTargets = new ArrayList(sizeof(SmokeWitchTarget));
	int seq = TraceBegin(TraceSource_Engine, "witch_target_tracking_coverage");
	TraceTextValue(TraceSource_Engine, seq, "method", "engine_detour:WitchAttack::GetVictim:post");
	GameData data = new GameData("l4d2_skills_smoke_witch");
	if (data == null)
	{
		TraceTextValue(TraceSource_Engine, seq, "unavailable_reason", "missing_gamedata");
		return;
	}
	Address victim = data.GetMemSig("WitchAttack::GetVictim");
	Address start = data.GetMemSig("Action<Infected>::InvokeOnStart");
	int instruction = data.GetOffset("ActorAssignmentInstruction");
	delete data;
	TraceIntValue(TraceSource_Engine, seq, "victim_signature_found", victim != Address_Null);
	TraceIntValue(TraceSource_Engine, seq, "actor_signature_found", start != Address_Null);
	TraceIntValue(TraceSource_Engine, seq, "actor_assignment_instruction", instruction);
	if (victim == Address_Null)
	{
		TraceTextValue(TraceSource_Engine, seq, "unavailable_reason", "missing_victim_signature");
		return;
	}
	if (start == Address_Null)
	{
		TraceTextValue(TraceSource_Engine, seq, "unavailable_reason", "missing_actor_signature");
		return;
	}
	if (instruction < 0 || instruction > 4096)
	{
		TraceTextValue(TraceSource_Engine, seq, "unavailable_reason", "invalid_actor_assignment_offset");
		return;
	}
	// Fail closed on other compiler layouts; never use a guessed field offset.
	Address assignment = start + view_as<Address>(instruction);
	for (int i = 0; i < 3; i++)
	{
		char key[32];
		FormatEx(key, sizeof(key), "actor_layout_byte_%d", i);
		TraceIntValue(TraceSource_Engine, seq, key, LoadFromAddress(assignment + view_as<Address>(i), NumberType_Int8));
	}
	if (!SmokeWitch_IsSupportedActorAssignment(assignment))
	{
		TraceTextValue(TraceSource_Engine, seq, "unavailable_reason", "actor_layout_guard_failed");
		return;
	}
	g_SmokeWitchActorOffset = 0x1c;
	g_SmokeWitchVictimDetour = new DynamicDetour(victim, CallConv_THISCALL, ReturnType_CBaseEntity, ThisPointer_Address);
	g_SmokeWitchVictimEnabled = g_SmokeWitchVictimDetour.Enable(Hook_Post, SmokeWitch_GetVictimPost);
	TraceIntValue(TraceSource_Engine, seq, "detour_enabled", g_SmokeWitchVictimEnabled);
	TraceIntValue(TraceSource_Engine, seq, "actor_offset", g_SmokeWitchActorOffset);
}

bool SmokeWitch_IsSupportedActorAssignment(Address assignment)
{
	return LoadFromAddress(assignment, NumberType_Int8) == 0x89
		&& LoadFromAddress(assignment + view_as<Address>(1), NumberType_Int8) == 0x5f
		&& LoadFromAddress(assignment + view_as<Address>(2), NumberType_Int8) == 0x1c;
}

void SmokeWitch_Stop()
{
	if (g_SmokeWitchTargets != null)
	{
		SmokeWitchTarget state;
		for (int i = 0; i < g_SmokeWitchTargets.Length; i++)
		{
			g_SmokeWitchTargets.GetArray(i, state, sizeof(state));
			SmokeWitch_QueryStatus(state, "capture_or_map_end");
		}
	}
	if (g_SmokeWitchVictimEnabled)
	{
		g_SmokeWitchVictimDetour.Disable(Hook_Post, SmokeWitch_GetVictimPost);
		g_SmokeWitchVictimEnabled = false;
	}
	delete g_SmokeWitchVictimDetour;
	delete g_SmokeWitchTargets;
}

int SmokeWitch_FindOwner(Address action)
{
	Address actor = view_as<Address>(LoadFromAddress(action + view_as<Address>(g_SmokeWitchActorOffset), NumberType_Int32));
	if (actor == Address_Null) return -1;
	static const char classes[][] = {"witch", "witch_bride"};
	for (int i = 0; i < sizeof(classes); i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, classes[i])) != -1)
		{
			if (IsValidEntity(entity) && GetEntityAddress(entity) == actor) return entity;
		}
	}
	return -1;
}

public MRESReturn SmokeWitch_GetVictimPost(Address action, DHookReturn result)
{
	if (!TraceActive() || !g_SmokeWitchVictimEnabled || action == Address_Null) return MRES_Ignored;
	int witch = SmokeWitch_FindOwner(action);
	if (witch > 0) SmokeWitch_Observe(witch, view_as<int>(action), result.Value);
	else
	{
		int seq = TraceBegin(TraceSource_Engine, "witch_target_owner_unresolved");
		TraceIntValue(TraceSource_Engine, seq, "action_address", view_as<int>(action));
		TraceIntValue(TraceSource_Engine, seq, "returned_target", result.Value);
	}
	return MRES_Ignored;
}

int SmokeWitch_Find(int witchRef)
{
	SmokeWitchTarget state;
	for (int i = 0; i < g_SmokeWitchTargets.Length; i++)
	{
		g_SmokeWitchTargets.GetArray(i, state, sizeof(state));
		if (state.witchRef == witchRef) return i;
	}
	return -1;
}

void SmokeWitch_Observe(int witch, int actionAddress, int target)
{
	SmokeWitchTarget current;
	current.witchRef = EntIndexToEntRef(witch);
	current.witchIndex = witch;
	current.actionAddress = actionAddress;
	current.rawTarget = target;
	current.targetRef = INVALID_ENT_REFERENCE;
	if (target > 0 && IsValidEntity(target))
	{
		current.targetRef = EntIndexToEntRef(target);
		if (target <= MaxClients && IsClientInGame(target))
		{
			current.userid = GetClientUserId(target);
			current.serial = GetClientSerial(target);
		}
	}
	int index = SmokeWitch_Find(current.witchRef);
	SmokeWitchTarget previous;
	current.queries = 1;
	current.actionQueries = 1;
	current.firstQueryTick = GetGameTickCount();
	current.lastQueryTick = current.firstQueryTick;
	SmokeEpisodes_Query(witch, actionAddress, current.targetRef, current.userid, current.serial, current.lastQueryTick);
	if (index != -1)
	{
		g_SmokeWitchTargets.GetArray(index, previous, sizeof(previous));
		current.queries = previous.queries + 1;
		current.actionQueries = previous.actionAddress == actionAddress ? previous.actionQueries + 1 : 1;
		current.firstQueryTick = previous.firstQueryTick;
		if (current.actionAddress == previous.actionAddress && current.rawTarget == previous.rawTarget
			&& current.targetRef == previous.targetRef && current.userid == previous.userid && current.serial == previous.serial)
		{
			g_SmokeWitchTargets.SetArray(index, current, sizeof(current));
			return;
		}
	}
	char transition[32];
	if (index == -1) strcopy(transition, sizeof(transition), "initial_observation");
	else if (target <= 0 && previous.targetRef != INVALID_ENT_REFERENCE) strcopy(transition, sizeof(transition), "target_lost");
	else if (target > 0 && current.targetRef == INVALID_ENT_REFERENCE) strcopy(transition, sizeof(transition), "target_unresolved");
	else if (target > 0 && previous.rawTarget <= 0) strcopy(transition, sizeof(transition), "target_acquired");
	else if (current.targetRef != previous.targetRef || current.userid != previous.userid || current.serial != previous.serial) strcopy(transition, sizeof(transition), "target_changed");
	else strcopy(transition, sizeof(transition), "action_changed");

	int seq = TraceBegin(TraceSource_Engine, "witch_target_observation");
	TraceTextValue(TraceSource_Engine, seq, "transition", transition);
	TraceTextValue(TraceSource_Engine, seq, "method", "engine_detour:WitchAttack::GetVictim:post");
	TraceEntityValue(TraceSource_Engine, seq, "witch", witch);
	TraceIntValue(TraceSource_Engine, seq, "action_address", actionAddress);
	TraceIntValue(TraceSource_Engine, seq, "returned_target", target);
	TraceEntityValue(TraceSource_Engine, seq, "target", target);
	TraceIntValue(TraceSource_Engine, seq, "target_valid", current.targetRef != INVALID_ENT_REFERENCE);
	TraceIntValue(TraceSource_Engine, seq, "target_userid", current.userid);
	TraceIntValue(TraceSource_Engine, seq, "target_serial", current.serial);
	// Preserve old identity as captured, never resolve an old client slot anew.
	TraceIntValue(TraceSource_Engine, seq, "previous_observed", index != -1);
	TraceIntValue(TraceSource_Engine, seq, "previous_target_entref", index != -1 ? previous.targetRef : INVALID_ENT_REFERENCE);
	TraceIntValue(TraceSource_Engine, seq, "previous_target_userid", previous.userid);
	TraceIntValue(TraceSource_Engine, seq, "previous_target_serial", previous.serial);
	if (index == -1) g_SmokeWitchTargets.PushArray(current, sizeof(current));
	else g_SmokeWitchTargets.SetArray(index, current, sizeof(current));
}

void SmokeWitch_OnEntityDestroyed(int entity)
{
	if (g_SmokeWitchTargets == null) return;
	SmokeWitchTarget state;
	for (int i = g_SmokeWitchTargets.Length - 1; i >= 0; i--)
	{
		g_SmokeWitchTargets.GetArray(i, state, sizeof(state));
		// OnEntityDestroyed can pass a reference; never dereference a reused index.
		if (state.witchRef != entity && state.witchIndex != entity) continue;
		SmokeWitch_QueryStatus(state, "entity_destroyed");
		int seq = TraceBegin(TraceSource_Engine, "witch_target_tracking_end");
		TraceIntValue(TraceSource_Engine, seq, "witch_entref", state.witchRef);
		TraceTextValue(TraceSource_Engine, seq, "reason", "entity_destroyed");
		g_SmokeWitchTargets.Erase(i);
	}
}

void SmokeWitch_QueryStatus(SmokeWitchTarget state, const char[] reason)
{
	int seq = TraceBegin(TraceSource_Engine, "witch_target_query_status");
	TraceTextValue(TraceSource_Engine, seq, "reason", reason);
	TraceIntValue(TraceSource_Engine, seq, "witch_entref", state.witchRef);
	TraceIntValue(TraceSource_Engine, seq, "action_address", state.actionAddress);
	TraceIntValue(TraceSource_Engine, seq, "queries", state.queries);
	TraceIntValue(TraceSource_Engine, seq, "action_queries", state.actionQueries);
	TraceIntValue(TraceSource_Engine, seq, "first_query_tick", state.firstQueryTick);
	TraceIntValue(TraceSource_Engine, seq, "last_query_tick", state.lastQueryTick);
	TraceIntValue(TraceSource_Engine, seq, "last_target_entref", state.targetRef);
	TraceIntValue(TraceSource_Engine, seq, "last_target_userid", state.userid);
	TraceIntValue(TraceSource_Engine, seq, "last_target_serial", state.serial);
}

void SmokeWitch_Heartbeat()
{
	if (g_SmokeWitchTargets == null || GetEngineTime() < g_SmokeWitchNextHeartbeat) return;
	g_SmokeWitchNextHeartbeat = GetEngineTime() + 1.0;
	SmokeWitchTarget state;
	for (int i = 0; i < g_SmokeWitchTargets.Length; i++)
	{
		g_SmokeWitchTargets.GetArray(i, state, sizeof(state));
		SmokeWitch_QueryStatus(state, "heartbeat");
	}
}
