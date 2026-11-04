// Mode policy and lifecycle context writers; no score/skill detection.

stock PlayerSkillsRoundStartSignalType Skills_MapStatsRoundStartSignal(int signal)
{
	switch (signal)
	{
		case 2:
		{
			return PlayerSkillsRoundStartSignal_ScavengeRoundStart;
		}
		case 1:
		{
			return PlayerSkillsRoundStartSignal_GenericRoundStart;
		}
	}

	return PlayerSkillsRoundStartSignal_None;
}

stock PlayerSkillsRoundEndSignalType Skills_MapStatsRoundEndSignal(int signal)
{
	switch (signal)
	{
		case 2:
		{
			return PlayerSkillsRoundEndSignal_ScavengeRoundFinished;
		}
		case 1:
		{
			return PlayerSkillsRoundEndSignal_GenericRoundEnd;
		}
	}

	return PlayerSkillsRoundEndSignal_None;
}

stock PlayerSkillsRoundLiveSignalType Skills_MapStatsRoundLiveSignal(int signal)
{
	switch (signal)
	{
		case 1:
		{
			return PlayerSkillsRoundLiveSignal_Immediate;
		}
		case 2, 3:
		{
			return PlayerSkillsRoundLiveSignal_SafeArea;
		}
	}

	return PlayerSkillsRoundLiveSignal_None;
}

stock void Skills_RefreshRoundLiveState()
{
	if (!Skills_IsEnabled() || g_Runtime.roundClosed)
	{
		g_Runtime.roundLive = false;
		return;
	}

	if (Skills_CanUsePlayerStats())
	{
		g_Runtime.roundLive = PlayerStats_IsRoundLive();
		return;
	}

	if (g_Runtime.roundLiveSignal == PlayerSkillsRoundLiveSignal_SafeArea && g_Runtime.hasLeft4DHooks && GetFeatureStatus(FeatureType_Native, "L4D_HasAnySurvivorLeftSafeArea") != FeatureStatus_Unknown && L4D_HasAnySurvivorLeftSafeArea())
	{
		g_Runtime.roundLive = true;
		return;
	}
}

/**
 * @brief Returns the current base game mode as a typed value.
 *
 * @return               Parsed game mode, or Unknown if unavailable.
 */
stock PlayerSkillsGameMode Skills_GetCurrentGameMode()
{
	if (!g_Runtime.hasLeft4DHooks
		|| GetFeatureStatus(FeatureType_Native, "L4D_GetGameModeType") != FeatureStatus_Available)
	{
		return PlayerSkillsGameMode_Unknown;
	}

	switch (L4D_GetGameModeType())
	{
		case GAMEMODE_COOP:
		{
			return PlayerSkillsGameMode_Coop;
		}
		case GAMEMODE_VERSUS:
		{
			return PlayerSkillsGameMode_Versus;
		}
		case GAMEMODE_SURVIVAL:
		{
			return PlayerSkillsGameMode_Survival;
		}
		case GAMEMODE_SCAVENGE:
		{
			return PlayerSkillsGameMode_Scavenge;
		}
	}

	return PlayerSkillsGameMode_Unknown;
}

stock void Skills_BuildCurrentModeContext(PlayerSkillsModeContextData context)
{
	context.Reset();
	context.baseMode = Skills_GetCurrentGameMode();
	context.isVersusMode = context.baseMode == PlayerSkillsGameMode_Versus;
	context.configuredSurvivorLimit = Skills_GetConfiguredSurvivorLimit();
	context.configuredPlayerZombieLimit = Skills_GetConfiguredPlayerZombieLimit();

	if (!context.isVersusMode)
	{
		return;
	}

	context.siPoolMask = Skills_GetEnabledSiPoolMask();
	context.enabledSiClassCount = Skills_CountEnabledSiClassesFromMask(context.siPoolMask);
	context.versusTeamSize = context.configuredSurvivorLimit == context.configuredPlayerZombieLimit
		? context.configuredSurvivorLimit
		: 0;
	context.versusContext = Skills_ClassifyVersusContext(
		context.configuredSurvivorLimit,
		context.configuredPlayerZombieLimit,
		context.enabledSiClassCount);
}

stock void Skills_GetLifecyclePolicyForContext(PlayerSkillsModeContextData context, PlayerSkillsLifecyclePolicyData policy)
{
	policy.Reset();

	switch (context.baseMode)
	{
		case PlayerSkillsGameMode_Scavenge:
		{
			policy.roundStartSignal = PlayerSkillsRoundStartSignal_ScavengeRoundStart;
			policy.roundEndSignal = PlayerSkillsRoundEndSignal_ScavengeRoundFinished;
			policy.roundLiveSignal = PlayerSkillsRoundLiveSignal_Immediate;
		}
		case PlayerSkillsGameMode_Versus, PlayerSkillsGameMode_Coop:
		{
			policy.roundStartSignal = PlayerSkillsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerSkillsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerSkillsRoundLiveSignal_SafeArea;
		}
		case PlayerSkillsGameMode_Survival:
		{
			policy.roundStartSignal = PlayerSkillsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerSkillsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerSkillsRoundLiveSignal_Immediate;
		}
		default:
		{
			policy.roundStartSignal = PlayerSkillsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerSkillsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerSkillsRoundLiveSignal_Immediate;
		}
	}
}

stock void Skills_RefreshModeContextLocal()
{
	PlayerSkillsModeContextData context;
	PlayerSkillsLifecyclePolicyData policy;
	Skills_BuildCurrentModeContext(context);
	Skills_GetLifecyclePolicyForContext(context, policy);

	g_Runtime.baseMode = context.baseMode;
	g_Runtime.configuredSurvivorLimit = context.configuredSurvivorLimit;
	g_Runtime.configuredPlayerZombieLimit = context.configuredPlayerZombieLimit;
	g_Runtime.siPoolMask = context.siPoolMask;
	g_Runtime.enabledSiClassCount = context.enabledSiClassCount;
	g_Runtime.versusTeamSize = context.versusTeamSize;
	g_Runtime.versusContext = context.versusContext;
	g_Runtime.roundStartSignal = policy.roundStartSignal;
	g_Runtime.roundEndSignal = policy.roundEndSignal;
	g_Runtime.roundLiveSignal = policy.roundLiveSignal;
}

stock void Skills_RefreshModeContextFromStats()
{
	PlayerSkillsModeContextData localContext;
	PlayerSkillsLifecyclePolicyData localPolicy;
	Skills_BuildCurrentModeContext(localContext);
	Skills_GetLifecyclePolicyForContext(localContext, localPolicy);

	g_Runtime.baseMode = view_as<PlayerSkillsGameMode>(PlayerStats_GetCurrentModeProperty(StatsModeProperty_BaseMode));
	g_Runtime.enabledSiClassCount = PlayerStats_GetCurrentModeProperty(StatsModeProperty_EnabledSiClassCount);
	g_Runtime.versusTeamSize = PlayerStats_GetCurrentModeProperty(StatsModeProperty_VersusTeamSize);
	g_Runtime.roundEndSignal = Skills_MapStatsRoundEndSignal(PlayerStats_GetCurrentModeProperty(StatsModeProperty_RoundEndSignal));
	g_Runtime.roundStartSignal = localPolicy.roundStartSignal;
	g_Runtime.roundLiveSignal = Skills_MapStatsRoundLiveSignal(PlayerStats_GetCurrentModeProperty(StatsModeProperty_RoundStartSignal));

	g_Runtime.configuredSurvivorLimit = Skills_GetConfiguredSurvivorLimit();
	g_Runtime.configuredPlayerZombieLimit = Skills_GetConfiguredPlayerZombieLimit();
	g_Runtime.siPoolMask = Skills_GetEnabledSiPoolMask();
	g_Runtime.versusContext = Skills_ClassifyVersusContext(
		g_Runtime.configuredSurvivorLimit,
		g_Runtime.configuredPlayerZombieLimit,
		g_Runtime.enabledSiClassCount);
}

stock void Skills_RefreshModeContext()
{
	if (Skills_CanUsePlayerStats())
	{
		Skills_RefreshModeContextFromStats();
		return;
	}

	Skills_RefreshModeContextLocal();
}

stock bool Skills_ShouldHandleRoundStartEvent(const char[] eventName)
{
	switch (g_Runtime.roundStartSignal)
	{
		case PlayerSkillsRoundStartSignal_ScavengeRoundStart:
		{
			return StrEqual(eventName, "scavenge_round_start", false);
		}
		case PlayerSkillsRoundStartSignal_GenericRoundStart:
		{
			return StrEqual(eventName, "round_start", false);
		}
	}

	return false;
}

stock bool Skills_ShouldHandleRoundEndEvent(const char[] eventName)
{
	switch (g_Runtime.roundEndSignal)
	{
		case PlayerSkillsRoundEndSignal_ScavengeRoundFinished:
		{
			return StrEqual(eventName, "scavenge_round_finished", false);
		}
		case PlayerSkillsRoundEndSignal_GenericRoundEnd:
		{
			return StrEqual(eventName, "round_end", false);
		}
	}

	return false;
}
