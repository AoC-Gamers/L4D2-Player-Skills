// Observer-local pursuit episodes, independent of Skills boss sessions/API.
// End of attack is a fact; preceding navigation/handler results are context.
enum struct SmokeWitchEpisode
{
	int id;
	int witchRef;
	int witchIndex;
	int action;
	int generation;
	bool open;
	bool startObserved;
	bool suspended;
	int startTick;
	float startTime;
	int queries;
	int lastQueryTick;
	int targetRef;
	int targetUserid;
	int targetSerial;
	bool navigationObserved;
	int navigationTick;
	int navigationType;
	int navigationAction;
	int navigationGeneration;
	int resultType;
	char resultReason[512];
}
ArrayList g_SmokeEpisodes;


void SmokeEpisodes_Start()
{
	if (g_SmokeEpisodes == null) g_SmokeEpisodes = new ArrayList(sizeof(SmokeWitchEpisode));
}

int SmokeEpisodes_Find(int witchRef, int action, int generation)
{
	if (g_SmokeEpisodes == null) return -1;
	SmokeWitchEpisode episode;
	for (int i = g_SmokeEpisodes.Length - 1; i >= 0; i--)
	{
		g_SmokeEpisodes.GetArray(i, episode, sizeof(episode));
		if (episode.witchRef == witchRef && episode.action == action && episode.generation == generation) return i;
	}
	return -1;
}

int SmokeEpisodes_Open(int witch, int action, int generation, bool startObserved)
{
	SmokeWitchEpisode episode;
	episode.id = ++g_SmokeEpisodeSerial;
	episode.witchRef = EntIndexToEntRef(witch);
	episode.witchIndex = witch;
	episode.action = action;
	episode.generation = generation;
	episode.open = true;
	episode.startObserved = startObserved;
	episode.startTick = GetGameTickCount();
	episode.startTime = GetEngineTime();
	episode.targetRef = INVALID_ENT_REFERENCE;
	int index = g_SmokeEpisodes.PushArray(episode, sizeof(episode));
	int seq = TraceBegin(TraceSource_Engine, "witch_attack_episode_open");
	TraceIntValue(TraceSource_Engine, seq, "episode_id", episode.id);
	TraceIntValue(TraceSource_Engine, seq, "witch_entref", episode.witchRef);
	TraceIntValue(TraceSource_Engine, seq, "action_address", action);
	TraceIntValue(TraceSource_Engine, seq, "action_generation", generation);
	TraceIntValue(TraceSource_Engine, seq, "start_observed", startObserved);
	TraceTextValue(TraceSource_Engine, seq, "opened_by", startObserved ? "OnStart" : "first_observed_query");
	return index;
}

void SmokeEpisodes_AttackStart(int witch, int action, int generation)
{
	if (g_SmokeEpisodes == null || generation == 0) return;
	int index = SmokeEpisodes_Find(EntIndexToEntRef(witch), action, generation);
	SmokeWitchEpisode episode;
	if (index != -1)
	{
		g_SmokeEpisodes.GetArray(index, episode, sizeof(episode));
		if (episode.open)
		{
			if (!episode.startObserved)
			{
				episode.startObserved = true;
				g_SmokeEpisodes.SetArray(index, episode, sizeof(episode));
				int seq = TraceBegin(TraceSource_Engine, "witch_attack_episode_start_confirmed");
				TraceIntValue(TraceSource_Engine, seq, "episode_id", episode.id);
			}
			return;
		}
	}
	SmokeEpisodes_Open(witch, action, generation, true);
}

void SmokeEpisodes_Query(int witch, int action, int targetRef, int userid, int serial, int tick)
{
	if (g_SmokeEpisodes == null) return;
	int generation = SmokeActions_Generation(action);
	if (generation == 0) return; // No reliable action lifetime identity.
	int index = SmokeEpisodes_Find(EntIndexToEntRef(witch), action, generation);
	if (index == -1) index = SmokeEpisodes_Open(witch, action, generation, false);
	SmokeWitchEpisode episode;
	g_SmokeEpisodes.GetArray(index, episode, sizeof(episode));
	if (!episode.open) return; // A query alone cannot resurrect a closed episode.
	episode.queries++;
	episode.lastQueryTick = tick;
	episode.targetRef = targetRef;
	episode.targetUserid = userid;
	episode.targetSerial = serial;
	g_SmokeEpisodes.SetArray(index, episode, sizeof(episode));
}

void SmokeEpisodes_Result(int witch, int type, const char[] reason)
{
	if (g_SmokeEpisodes == null) return;
	SmokeWitchEpisode episode;
	int ref = EntIndexToEntRef(witch);
	for (int i = 0; i < g_SmokeEpisodes.Length; i++)
	{
		g_SmokeEpisodes.GetArray(i, episode, sizeof(episode));
		if (!episode.open || episode.suspended || episode.witchRef != ref) continue;
		episode.resultType = type;
		if (reason[0] != '\0') strcopy(episode.resultReason, sizeof(episode.resultReason), reason);
		g_SmokeEpisodes.SetArray(i, episode, sizeof(episode));
	}
}

void SmokeEpisodes_Navigation(int witch, int sourceAction, int failure)
{
	if (g_SmokeEpisodes == null) return;
	SmokeWitchEpisode episode;
	int ref = EntIndexToEntRef(witch);
	for (int i = 0; i < g_SmokeEpisodes.Length; i++)
	{
		g_SmokeEpisodes.GetArray(i, episode, sizeof(episode));
		if (!episode.open || episode.suspended || episode.witchRef != ref) continue;
		episode.navigationObserved = true;
		episode.navigationTick = GetGameTickCount();
		episode.navigationType = failure;
		episode.navigationAction = sourceAction;
		episode.navigationGeneration = SmokeActions_Generation(sourceAction);
		g_SmokeEpisodes.SetArray(i, episode, sizeof(episode));
	}
}

void SmokeEpisodes_Suspended(int witch, int action, bool suspended)
{
	int index = SmokeEpisodes_Find(EntIndexToEntRef(witch), action, SmokeActions_Generation(action));
	if (index == -1) return;
	SmokeWitchEpisode episode;
	g_SmokeEpisodes.GetArray(index, episode, sizeof(episode));
	if (!episode.open) return;
	episode.suspended = suspended;
	g_SmokeEpisodes.SetArray(index, episode, sizeof(episode));
}

void SmokeEpisodes_Close(int index, bool endObserved, const char[] closedBy, int nextAction)
{
	SmokeWitchEpisode episode;
	g_SmokeEpisodes.GetArray(index, episode, sizeof(episode));
	if (!episode.open) return;
	// Commit before logging to make repeated/reentrant close calls idempotent.
	episode.open = false;
	g_SmokeEpisodes.SetArray(index, episode, sizeof(episode));
	int seq = TraceBegin(TraceSource_Engine, "witch_attack_episode_closed");
	TraceIntValue(TraceSource_Engine, seq, "episode_id", episode.id);
	TraceIntValue(TraceSource_Engine, seq, "witch_entref", episode.witchRef);
	TraceIntValue(TraceSource_Engine, seq, "action_address", episode.action);
	TraceIntValue(TraceSource_Engine, seq, "action_generation", episode.generation);
	TraceIntValue(TraceSource_Engine, seq, "start_observed", episode.startObserved);
	TraceIntValue(TraceSource_Engine, seq, "start_tick", episode.startTick);
	TraceFloatValue(TraceSource_Engine, seq, "observed_duration", GetEngineTime() - episode.startTime);
	TraceIntValue(TraceSource_Engine, seq, "end_observed", endObserved);
	TraceIntValue(TraceSource_Engine, seq, "context_closed", !endObserved);
	TraceTextValue(TraceSource_Engine, seq, "closed_by", closedBy);
	TraceTextValue(TraceSource_Engine, seq, "cause", "unknown");
	TraceIntValue(TraceSource_Engine, seq, "suspended_at_close", episode.suspended);
	TraceIntValue(TraceSource_Engine, seq, "queries", episode.queries);
	TraceIntValue(TraceSource_Engine, seq, "last_query_tick", episode.lastQueryTick);
	TraceIntValue(TraceSource_Engine, seq, "last_target_entref", episode.targetRef);
	TraceIntValue(TraceSource_Engine, seq, "last_target_userid", episode.targetUserid);
	TraceIntValue(TraceSource_Engine, seq, "last_target_serial", episode.targetSerial);
	SmokeActions_ActionValue(seq, "next_action", view_as<BehaviorAction>(nextAction));
	TraceIntValue(TraceSource_Engine, seq, "navigation_observed", episode.navigationObserved);
	if (episode.navigationObserved)
	{
		TraceIntValue(TraceSource_Engine, seq, "navigation_tick", episode.navigationTick);
		TraceIntValue(TraceSource_Engine, seq, "navigation_type_raw", episode.navigationType);
		TraceIntValue(TraceSource_Engine, seq, "navigation_source_action", episode.navigationAction);
		TraceIntValue(TraceSource_Engine, seq, "navigation_source_generation", episode.navigationGeneration);
		TraceIntValue(TraceSource_Engine, seq, "navigation_context_only", 1);
	}
	TraceIntValue(TraceSource_Engine, seq, "observed_handler_result_type", episode.resultType);
	TraceTextValue(TraceSource_Engine, seq, "observed_handler_reason", episode.resultReason, strlen(episode.resultReason) == sizeof(episode.resultReason) - 1);
}

void SmokeEpisodes_End(int witch, int action, int nextAction)
{
	int index = SmokeEpisodes_Find(EntIndexToEntRef(witch), action, SmokeActions_Generation(action));
	if (index != -1) SmokeEpisodes_Close(index, true, "OnEnd", nextAction);
}

void SmokeEpisodes_ActionDestroyed(int action, int generation, const char[] reason = "action_destroyed_without_end")
{
	if (g_SmokeEpisodes == null) return;
	SmokeWitchEpisode episode;
	for (int i = 0; i < g_SmokeEpisodes.Length; i++)
	{
		g_SmokeEpisodes.GetArray(i, episode, sizeof(episode));
		if (episode.action == action && episode.generation == generation) SmokeEpisodes_Close(i, false, reason, 0);
	}
}

void SmokeEpisodes_EntityDestroyed(int entity)
{
	if (g_SmokeEpisodes == null) return;
	SmokeWitchEpisode episode;
	for (int i = 0; i < g_SmokeEpisodes.Length; i++)
	{
		g_SmokeEpisodes.GetArray(i, episode, sizeof(episode));
		if (episode.witchRef == entity || episode.witchIndex == entity) SmokeEpisodes_Close(i, false, "entity_destroyed", 0);
	}
}

void SmokeEpisodes_Stop(const char[] reason)
{
	if (g_SmokeEpisodes == null) return;
	for (int i = 0; i < g_SmokeEpisodes.Length; i++) SmokeEpisodes_Close(i, false, reason, 0);
	delete g_SmokeEpisodes;
}
