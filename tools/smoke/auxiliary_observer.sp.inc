// Auxiliary inputs are labeled separately inside the engine timeline, not disguised as engine events.
public void PlayerStats_OnRoundLive(int roundId)
{
	int seq = TraceBegin(TraceSource_Engine, "PlayerStats_OnRoundLive");
	TraceIntValue(TraceSource_Engine, seq, "roundId", roundId);
}

public void PlayerStats_OnRoundEnded(int roundId, StatsEndType endType, int endReason)
{
	int seq = TraceBegin(TraceSource_Engine, "PlayerStats_OnRoundEnded");
	TraceIntValue(TraceSource_Engine, seq, "roundId", roundId);
	TraceIntValue(TraceSource_Engine, seq, "endType", view_as<int>(endType));
	TraceIntValue(TraceSource_Engine, seq, "endReason", endReason);
}

public void TankControl_OnTankStarted(int tankId, int client, bool isBot)
{
	int seq = TraceBegin(TraceSource_Engine, "TankControl_OnTankStarted");
	TraceIntValue(TraceSource_Engine, seq, "tankId", tankId);
	TraceEntityValue(TraceSource_Engine, seq, "client", client);
	TraceIntValue(TraceSource_Engine, seq, "isBot", isBot);
}

public void TankControl_OnTankStartedEx(int tankId, int client, bool isBot, TankControlStartReason startReason, int parentTankId)
{
	int seq = TraceBegin(TraceSource_Engine, "TankControl_OnTankStartedEx");
	TraceIntValue(TraceSource_Engine, seq, "tankId", tankId);
	TraceEntityValue(TraceSource_Engine, seq, "client", client);
	TraceIntValue(TraceSource_Engine, seq, "isBot", isBot);
	TraceIntValue(TraceSource_Engine, seq, "startReason", view_as<int>(startReason));
	TraceIntValue(TraceSource_Engine, seq, "parentTankId", parentTankId);
}

public void TankControl_OnTankControlChanged(int tankId, int oldClient, int newClient, bool oldWasBot, bool newWasBot)
{
	int seq = TraceBegin(TraceSource_Engine, "TankControl_OnTankControlChanged");
	TraceIntValue(TraceSource_Engine, seq, "tankId", tankId);
	TraceEntityValue(TraceSource_Engine, seq, "oldClient", oldClient);
	TraceEntityValue(TraceSource_Engine, seq, "newClient", newClient);
	TraceIntValue(TraceSource_Engine, seq, "oldWasBot", oldWasBot);
	TraceIntValue(TraceSource_Engine, seq, "newWasBot", newWasBot);
}

public void OnClientSettingsChanged(int client)
{
	int seq = TraceBegin(TraceSource_Engine, "OnClientSettingsChanged");
	TraceEntityValue(TraceSource_Engine, seq, "client", client);
}

public void OnClientTeam(int client, int oldTeam, int newTeam)
{
	int seq = TraceBegin(TraceSource_Engine, "OnClientTeam");
	TraceEntityValue(TraceSource_Engine, seq, "client", client);
	TraceIntValue(TraceSource_Engine, seq, "oldTeam", oldTeam);
	TraceIntValue(TraceSource_Engine, seq, "newTeam", newTeam);
}

public void OnEntityDestroyed(int entity)
{
	int seq = TraceBegin(TraceSource_SDKHooks, "OnEntityDestroyed");
	TraceEntityValue(TraceSource_SDKHooks, seq, "entity", entity);
	SmokeSDK_OnEntityDestroyed(entity);
	SmokeEpisodes_EntityDestroyed(entity);
	SmokeWitch_OnEntityDestroyed(entity);
}

void SmokeAux_Sample()
{
	int seq = TraceBegin(TraceSource_Engine, "manual_external_state_sample");
	TraceIntValue(TraceSource_Engine, seq, "playerstats_present", g_Runtime.hasPlayerStats);
	TraceIntValue(TraceSource_Engine, seq, "tankcontrol_present", g_Runtime.hasTankControl);
	TraceIntValue(TraceSource_Engine, seq, "configs_ready", g_Runtime.configsReady);
	if (!g_Runtime.configsReady) return;
	bool statsQueries = g_Runtime.hasPlayerStats
		&& GetFeatureStatus(FeatureType_Native, "PlayerStats_IsRoundLive") == FeatureStatus_Available
		&& GetFeatureStatus(FeatureType_Native, "PlayerStats_GetCurrentModeProperty") == FeatureStatus_Available;
	TraceIntValue(TraceSource_Engine, seq, "playerstats_queries_available", statsQueries);
	if (statsQueries)
	{
		TraceIntValue(TraceSource_Engine, seq, "PlayerStats_IsRoundLive", PlayerStats_IsRoundLive());
		TraceIntValue(TraceSource_Engine, seq, "PlayerStats_BaseMode", PlayerStats_GetCurrentModeProperty(StatsModeProperty_BaseMode));
		TraceIntValue(TraceSource_Engine, seq, "PlayerStats_EnabledSiClassCount", PlayerStats_GetCurrentModeProperty(StatsModeProperty_EnabledSiClassCount));
		TraceIntValue(TraceSource_Engine, seq, "PlayerStats_VersusTeamSize", PlayerStats_GetCurrentModeProperty(StatsModeProperty_VersusTeamSize));
		TraceIntValue(TraceSource_Engine, seq, "PlayerStats_RoundEndSignal", PlayerStats_GetCurrentModeProperty(StatsModeProperty_RoundEndSignal));
		TraceIntValue(TraceSource_Engine, seq, "PlayerStats_RoundStartSignal", PlayerStats_GetCurrentModeProperty(StatsModeProperty_RoundStartSignal));
	}
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		int playerSeq = TraceBegin(TraceSource_Engine, "manual_client_state_sample");
		TraceEntityValue(TraceSource_Engine, playerSeq, "client", client);
		TraceIntValue(TraceSource_Engine, playerSeq, "GetClientHealth", GetClientHealth(client));
		TraceIntValue(TraceSource_Engine, playerSeq, "IsPlayerAlive", IsPlayerAlive(client));
		float position[3];
		GetClientAbsOrigin(client, position);
		TraceVectorValue(TraceSource_Engine, playerSeq, "GetClientAbsOrigin", position);
		if (HasEntProp(client, Prop_Data, "m_vecVelocity"))
		{
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", position);
			TraceVectorValue(TraceSource_Engine, playerSeq, "m_vecVelocity", position);
		}
		if (HasEntProp(client, Prop_Send, "m_hGroundEntity")) TraceEntityValue(TraceSource_Engine, playerSeq, "m_hGroundEntity", GetEntPropEnt(client, Prop_Send, "m_hGroundEntity"));
		if (HasEntProp(client, Prop_Send, "m_survivorCharacter")) TraceIntValue(TraceSource_Engine, playerSeq, "m_survivorCharacter", GetEntProp(client, Prop_Send, "m_survivorCharacter"));
		if (!g_Runtime.hasTankControl || GetClientTeam(client) != 3
			|| !HasEntProp(client, Prop_Send, "m_zombieClass") || GetEntProp(client, Prop_Send, "m_zombieClass") != 8) continue;
		int tankId = TankControl_GetClientTankId(client);
		TraceIntValue(TraceSource_Engine, playerSeq, "TankControl_GetClientTankId", tankId);
		if (tankId > 0 && GetFeatureStatus(FeatureType_Native, "TankControl_GetTankStartReason") == FeatureStatus_Available)
		{
			TraceIntValue(TraceSource_Engine, playerSeq, "TankControl_GetTankStartReason", view_as<int>(TankControl_GetTankStartReason(tankId)));
			TraceIntValue(TraceSource_Engine, playerSeq, "TankControl_GetParentTankId", TankControl_GetParentTankId(tankId));
			TraceIntValue(TraceSource_Engine, playerSeq, "TankControl_IsSubstituteTank", TankControl_IsSubstituteTank(tankId));
		}
	}
}
