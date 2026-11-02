// Close the live gate before callbacks; publish bosses, summaries, then invalidate detection.

void Lifecycle_CloseRound()
{
	if (g_Runtime.roundClosed)
	{
		return;
	}

	g_Runtime.roundClosed = true;
	g_Runtime.roundLive = false;
	g_Runtime.closeInProgress = true;
	int epoch = g_Runtime.lifecycleEpoch;
	Boss_OnRoundEnd();
	if (epoch != g_Runtime.lifecycleEpoch)
	{
		return;
	}

	API_FinalizeSummaryFromCurrentState();
	if (epoch != g_Runtime.lifecycleEpoch)
	{
		return;
	}

	Detect_OnRoundEnd();
	g_Runtime.closeInProgress = false;
	if (g_Runtime.mapEnding)
	{
		Lifecycle_FinishMapEnd();
		return;
	}

	// A consumer may request the next round inside a closing forward. Finish
	// both old snapshots before allowing that boundary to reset their buffer.
	bool pendingStart = g_Runtime.pendingRoundStart;
	bool pendingLive = g_Runtime.pendingStatsLive;
	int pendingRoundId = g_Runtime.pendingStatsRoundId;
	Lifecycle_ResetPendingBoundaries();
	if (pendingStart)
	{
		Lifecycle_BeginRound();
	}
	if (pendingLive)
	{
		Lifecycle_PlayerStats_OnRoundLive(pendingRoundId);
	}
}

void Lifecycle_ResetPendingBoundaries()
{
	g_Runtime.closeInProgress = false;
	g_Runtime.pendingRoundStart = false;
	g_Runtime.pendingStatsLive = false;
	g_Runtime.pendingStatsRoundId = 0;
}

void Skills_RefreshExternalLifecycleAvailability()
{
	g_Runtime.usesExternalLifecycle = Skills_CanUsePlayerStats();
}

void Skills_SyncLifecycleState()
{
	if (!g_Runtime.librariesReady || !g_Runtime.configsReady)
	{
		return;
	}

	Skills_RefreshExternalLifecycleAvailability();
	Skills_RefreshModeContext();
	Skills_RefreshRoundLiveState();
	g_Runtime.left4DHooksNeedsSync = false;
	g_Runtime.playerStatsNeedsSync = false;
}

void Lifecycle_ReconcilePending()
{
	if (g_Runtime.librariesReady && g_Runtime.configsReady && g_Runtime.NeedsLifecycleSync())
	{
		Skills_SyncLifecycleState();
	}
}

void Lifecycle_OnAllPluginsLoaded()
{
	g_Runtime.DetectLibraries();
}

void Lifecycle_OnLibraryAdded(const char[] name)
{
	g_Runtime.SetLibraryAvailability(name, true);
}

void Lifecycle_OnLibraryRemoved(const char[] name)
{
	g_Runtime.SetLibraryAvailability(name, false);
}

void Lifecycle_OnMapStart()
{
	Lifecycle_ResetPendingBoundaries();
	g_Runtime.mapEnding = false;
	g_Runtime.mapEnded = false;
	g_Runtime.activeStatsRoundId = 0;
	g_Runtime.lifecycleEpoch++;
	g_Runtime.roundClosed = false;
	g_Runtime.configsReady = false;
	g_Runtime.left4DHooksNeedsSync = true;
	g_Runtime.playerStatsNeedsSync = true;
	g_Runtime.roundLive = false;
	Skills_ResetIdentityCache();
	API_ResetRoundSummaryState();
	Boss_ResetAll();
	Detect_ResetAll();
}

void Lifecycle_OnMapEnd()
{
	if (g_Runtime.mapEnding || g_Runtime.mapEnded)
	{
		return;
	}

	// MapEnd is the last close opportunity even when Player-Stats is absent or
	// runs its own MapEnd later. Keep the old epoch/buffers until publication.
	g_Runtime.mapEnding = true;
	g_Runtime.configsReady = false;
	if (g_Runtime.activeStatsRoundId > g_Runtime.lastClosedStatsRoundId)
	{
		g_Runtime.lastClosedStatsRoundId = g_Runtime.activeStatsRoundId;
	}
	if (g_Runtime.pendingStatsRoundId > g_Runtime.lastClosedStatsRoundId)
	{
		g_Runtime.lastClosedStatsRoundId = g_Runtime.pendingStatsRoundId;
	}
	g_Runtime.pendingRoundStart = false;
	g_Runtime.pendingStatsLive = false;
	g_Runtime.pendingStatsRoundId = 0;
	if (g_Runtime.closeInProgress)
	{
		return;
	}

	int epoch = g_Runtime.lifecycleEpoch;
	Lifecycle_CloseRound();
	if (epoch == g_Runtime.lifecycleEpoch && g_Runtime.mapEnding)
	{
		Lifecycle_FinishMapEnd();
	}
}

void Lifecycle_FinishMapEnd()
{
	Lifecycle_ResetPendingBoundaries();
	g_Runtime.mapEnding = false;
	g_Runtime.mapEnded = true;
	g_Runtime.activeStatsRoundId = 0;
	g_Runtime.lifecycleEpoch++;
	g_Runtime.roundClosed = true;
	g_Runtime.configsReady = false;
	g_Runtime.left4DHooksNeedsSync = true;
	g_Runtime.playerStatsNeedsSync = true;
	g_Runtime.roundLive = false;
	Skills_ResetIdentityCache();
	Skills_ResetEvents();
	Boss_ResetAll();
	Detect_ResetAll();
}

void Lifecycle_OnConfigsExecuted()
{
	if (g_Runtime.mapEnding || g_Runtime.mapEnded)
	{
		return;
	}
	g_Runtime.configsReady = true;
	Skills_SyncLifecycleState();
}

void Lifecycle_L4D_OnGameModeChange(int gamemode)
{
	g_Runtime.left4DHooksNeedsSync = true;
	Skills_Debug(PlayerSkillsDebug_Event, "[L4D_OnGameModeChange] gamemode=%d", gamemode);
}

void Lifecycle_OnPluginEnd()
{
	Lifecycle_ResetPendingBoundaries();
	g_Runtime.mapEnding = false;
	g_Runtime.mapEnded = true;
	g_Runtime.lifecycleEpoch++;
	g_Runtime.roundClosed = true;
	g_Runtime.configsReady = false;
	g_Runtime.roundLive = false;
	Boss_Shutdown();
	Detect_Shutdown();
}

void Lifecycle_L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	Skills_Debug(PlayerSkillsDebug_Event, "[L4D_OnFirstSurvivorLeftSafeArea_Post] client=%d", client);

	if (!Skills_IsEnabled() || g_Runtime.roundClosed || Skills_UsesExternalLifecycle() || g_Runtime.roundLive || g_Runtime.roundLiveSignal != PlayerSkillsRoundLiveSignal_SafeArea)
	{
		return;
	}

	g_Runtime.roundLive = true;
}

void Lifecycle_PlayerStats_OnRoundLive(int roundId)
{
	if (g_Runtime.mapEnding || g_Runtime.mapEnded || roundId <= 0
		|| roundId <= g_Runtime.lastClosedStatsRoundId)
	{
		Skills_Debug(PlayerSkillsDebug_Event, "Stats live discarded. round=%d reason=closed_map_or_round", roundId);
		return;
	}
	// Receipt confirms provider availability even when applying live must wait.
	g_Runtime.hasPlayerStats = true;
	g_Runtime.usesExternalLifecycle = true;
	g_Runtime.playerStatsNeedsSync = true;
	if (g_Runtime.closeInProgress)
	{
		g_Runtime.pendingStatsLive = true;
		g_Runtime.pendingStatsRoundId = roundId;
		return;
	}
	if (g_Runtime.roundClosed)
	{
		g_Runtime.lifecycleEpoch++;
	}
	g_Runtime.roundClosed = false;
	g_Runtime.activeStatsRoundId = roundId;

	Skills_Debug(PlayerSkillsDebug_Event, "[PlayerStats_OnRoundLive] round=%d", roundId);
	g_Runtime.roundLive = true;
}

void Lifecycle_PlayerStats_OnRoundEnded(int roundId, StatsEndType endType, int endReason)
{
	if (roundId <= 0)
	{
		return;
	}
	if (g_Runtime.mapEnding || g_Runtime.mapEnded)
	{
		// A late callback can identify a map-end fallback closed before its ID was known.
		if (roundId > g_Runtime.lastClosedStatsRoundId)
		{
			g_Runtime.lastClosedStatsRoundId = roundId;
		}
		return;
	}
	if (roundId <= g_Runtime.lastClosedStatsRoundId
		|| (g_Runtime.activeStatsRoundId > 0 && roundId != g_Runtime.activeStatsRoundId))
	{
		Skills_Debug(PlayerSkillsDebug_Event, "Stats close discarded. round=%d active=%d reason=stale_round",
			roundId, g_Runtime.activeStatsRoundId);
		return;
	}
	g_Runtime.lastClosedStatsRoundId = roundId;
	g_Runtime.activeStatsRoundId = 0;
	// A direct provider forward is authoritative even before the next reconciliation.
	g_Runtime.hasPlayerStats = true;
	g_Runtime.usesExternalLifecycle = true;
	g_Runtime.playerStatsNeedsSync = true;

	Skills_Debug(PlayerSkillsDebug_Event, "[PlayerStats_OnRoundEnded] round=%d type=%d reason=%d", roundId, endType, endReason);
	Lifecycle_CloseRound();
}

void Lifecycle_Event_RoundStart(Event event, const char[] name)
{
	char objective[64];
	event.GetString("objective", objective, sizeof(objective));
	Skills_Debug(PlayerSkillsDebug_Event, "[%s] timelimit=%d fraglimit=%d objective=%s",
		name,
		event.GetInt("timelimit"),
		event.GetInt("fraglimit"),
		objective);

	if (!Skills_ShouldHandleRoundStartEvent(name))
	{
		return;
	}
	if (g_Runtime.mapEnding || g_Runtime.mapEnded)
	{
		return;
	}

	if (g_Runtime.closeInProgress)
	{
		g_Runtime.pendingRoundStart = true;
		// A later start supersedes an earlier live signal, just as an immediate reset would.
		g_Runtime.pendingStatsLive = false;
		g_Runtime.pendingStatsRoundId = 0;
		return;
	}
	Lifecycle_BeginRound();
}

void Lifecycle_BeginRound()
{
	g_Runtime.lifecycleEpoch++;
	g_Runtime.activeStatsRoundId = 0;
	g_Runtime.roundClosed = false;
	API_ResetRoundSummaryState();
	g_Runtime.roundLive = false;
	Boss_OnRoundStart();
	Detect_OnRoundStart();

	if (!Skills_UsesExternalLifecycle() && g_Runtime.roundLiveSignal == PlayerSkillsRoundLiveSignal_Immediate)
	{
		g_Runtime.roundLive = true;
	}
}

void Lifecycle_Event_RoundEnd(Event event, const char[] name)
{
	char message[128];
	event.GetString("message", message, sizeof(message));
	Skills_Debug(PlayerSkillsDebug_Event, "[%s] winner=%d reason=%d message=%s time=%.1f", name, event.GetInt("winner"), event.GetInt("reason"), message, event.GetFloat("time"));

	if (g_Runtime.baseMode == PlayerSkillsGameMode_Versus)
	{
		return;
	}

	if (Skills_UsesExternalLifecycle())
	{
		return;
	}

	if (!Skills_ShouldHandleRoundEndEvent(name))
	{
		return;
	}

	Lifecycle_CloseRound();
}

void Lifecycle_L4D2_OnEndVersusModeRound_Post()
{
	Skills_Debug(PlayerSkillsDebug_Event, "[L4D2_OnEndVersusModeRound_Post]");

	if (g_Runtime.baseMode != PlayerSkillsGameMode_Versus || Skills_UsesExternalLifecycle())
	{
		return;
	}

	Lifecycle_CloseRound();
}

void Lifecycle_Event_ScavengeRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Skills_Debug(PlayerSkillsDebug_Event, "[%s] round=%d firsthalf=%d",
		name,
		event.GetInt("round"),
		event.GetBool("firsthalf"));
	Event_RoundStart(event, name, dontBroadcast);
}

void Lifecycle_Event_ScavengeRoundFinished(Event event, const char[] name, bool dontBroadcast)
{
	Skills_Debug(PlayerSkillsDebug_Event, "[%s]", name);
	Event_RoundEnd(event, name, dontBroadcast);
}
