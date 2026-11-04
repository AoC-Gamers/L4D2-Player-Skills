// Private detector ownership: boomer

Action Detect_TimerAnnounceBoomerKill(Handle timer, any context)
{
	int userid = Detect_ReadDeferredClientUserId(view_as<DataPack>(context));
	if (userid <= 0)
	{
		return Plugin_Stop;
	}

	// BoomerPop is decided in boomer_exploded, while the generic kill summary is
	// built from player_death. Delay publication as well as announce so Pop can absorb it.
	if (!Skills_IsRoundLive())
	{
		Detect_CancelPendingBoomerKill(GetClientOfUserId(userid), "not_live");
		return Plugin_Stop;
	}

	int boomer = GetClientOfUserId(userid);
	if (boomer < 1 || boomer > MaxClients)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Boomer kill timer aborted. userid=%d boomer=%d reason=invalid_client",
			userid,
			boomer);
		return Plugin_Stop;
	}

	// The identity reader consumed round/userid/life; the final cell binds this timer to its event.
	DataPack pack = view_as<DataPack>(context);
	int eventId = pack.ReadCell();
	if (g_iDetectPendingBoomerKillEvent[boomer] != eventId)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Boomer kill discarded. event=%d reason=stale_event", eventId);
		return Plugin_Stop;
	}

	if (eventId <= 0)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Boomer kill timer aborted. boomer=%d event=%d pending=%d",
			boomer,
			eventId,
			g_iDetectPendingBoomerKillEvent[boomer]);
		return Plugin_Stop;
	}

	g_DetectBoomer[boomer].killDelayElapsed = true;
	if (!g_DetectBoomer[boomer].explosionResolved && !g_DetectBoomer[boomer].hitSomebody)
	{
		// An unknown spawn time still qualifies as timeAlive=0 in the Pop detector.
		// Only an explosion or a lifecycle boundary can resolve that case safely.
		if (g_DetectBoomer[boomer].spawnTime <= 0.0)
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"Boomer kill awaiting explosion. event=%d reason=unknown_spawn", eventId);
			return Plugin_Stop;
		}
		float timeAlive = GetGameTime() - g_DetectBoomer[boomer].spawnTime;
		if (timeAlive <= L4D2_SKILLS_COMPETITIVE_POP_MAX_TIME)
		{
			// Recheck the same strict bound used by Pop; 100 ms is not a verdict.
			float delay = L4D2_SKILLS_COMPETITIVE_POP_MAX_TIME - timeAlive + 0.10;
			Detect_QueueClientTimer(delay, Detect_TimerAnnounceBoomerKill, userid, TIMER_FLAG_NO_MAPCHANGE, eventId);
			Skills_Debug(PlayerSkillsDebug_Detect,
				"Boomer kill awaiting classification. event=%d time_alive=%.2f", eventId, timeAlive);
			return Plugin_Stop;
		}
	}

	Detect_PublishPendingBoomerKill(boomer);
	return Plugin_Stop;
}

void Detect_PublishPendingBoomerKill(int boomer)
{
	if (boomer < 1 || boomer > MaxClients || !IsValidClient(boomer) || !Skills_IsRoundLive())
	{
		Detect_CancelPendingBoomerKill(boomer, "not_live_or_invalid_client");
		return;
	}
	int eventId = g_iDetectPendingBoomerKillEvent[boomer];
	if (eventId <= 0 || g_DetectBoomer[boomer].deathCommitted)
	{
		return;
	}
	int userid = GetClientUserId(boomer);
	int roundGeneration = g_iDetectRoundGeneration;
	int lifeGeneration = g_iDetectClientLifeGeneration[boomer];
	int lifecycleEpoch = g_Runtime.lifecycleEpoch;

	g_iDetectPendingBoomerKillEvent[boomer] = 0;
	g_DetectBoomer[boomer].deathCommitted = true;
	Skills_Debug(PlayerSkillsDebug_Detect,
		"Boomer kill timer firing. boomer=%d event=%d valid=%d",
		boomer,
		eventId,
		Skills_IsEventValid(eventId) ? 1 : 0);

	if (Skills_IsEventValid(eventId))
	{
		Skills_SetEventPendingPublication(eventId, false);
		Action result = API_FireSkillDetected(eventId, L4D2Skill_BoomerKill);
		if (roundGeneration != g_iDetectRoundGeneration
			|| lifecycleEpoch != g_Runtime.lifecycleEpoch
			|| !IsValidClient(boomer)
			|| GetClientUserId(boomer) != userid
			|| lifeGeneration != g_iDetectClientLifeGeneration[boomer])
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"Boomer kill completion discarded. event=%d reason=reentrant_lifecycle", eventId);
			return;
		}
		if (result < Plugin_Handled && Skills_IsRoundLive() && Skills_IsEventValid(eventId))
		{
			Announce_Skill(eventId);
		}
	}

	// A consumer may synchronously queue another death; never reset that new operation.
	if (g_iDetectPendingBoomerKillEvent[boomer] == 0)
	{
		Detect_ResetSiLifeKillTrack(boomer);
	}
}

void Detect_EventPlayerNowIt(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!event.GetBool("by_boomer") || !IsValidZombieClass(attacker, L4D2ZombieClass_Boomer))
	{
		return;
	}

	g_DetectBoomer[attacker].hitSomebody = true;

	if (!event.GetBool("exploded"))
	{
		if (g_DetectBoomer[attacker].vomitHits == 0)
		{
			Detect_QueueClientTimer(L4D2_SKILLS_BOOMER_VOMIT_WINDOW, Detect_TimerBoomerVomitCheck, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
		}

		g_DetectBoomer[attacker].vomitHits++;
	}
}

void Detect_EventBoomerExploded(Event event)
{
	if (!Skills_IsEnabled() || g_Runtime.roundClosed)
	{
		return;
	}

	int boomer = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(boomer, L4D2ZombieClass_Boomer))
	{
		return;
	}
	if (g_DetectBoomer[boomer].explosionResolved)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Boomer explosion discarded. boomer=%d reason=already_resolved", boomer);
		return;
	}

	if (event.GetBool("splashedbile") || g_DetectBoomer[boomer].hitSomebody)
	{
		int amount = g_DetectBoomer[boomer].vomitHits;
		int userid = GetClientUserId(boomer);
		int lifeGeneration = g_iDetectClientLifeGeneration[boomer];
		int roundGeneration = g_iDetectRoundGeneration;
		int lifecycleEpoch = g_Runtime.lifecycleEpoch;
		g_DetectBoomer[boomer].explosionResolved = true;
		if (amount > 0)
		{
			Detect_EmitBoomerVomitLanded(boomer, amount);
		}
		if (GetClientOfUserId(userid) == boomer
			&& lifeGeneration == g_iDetectClientLifeGeneration[boomer]
			&& roundGeneration == g_iDetectRoundGeneration
			&& lifecycleEpoch == g_Runtime.lifecycleEpoch)
		{
			Detect_ResolveBoomerNoPop(boomer);
		}
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker))
	{
		Detect_ResolveBoomerNoPop(boomer);
		return;
	}

	float timeAlive = g_DetectBoomer[boomer].spawnTime > 0.0 ? (GetGameTime() - g_DetectBoomer[boomer].spawnTime) : 0.0;
	if (timeAlive > L4D2_SKILLS_COMPETITIVE_POP_MAX_TIME)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Ignoring boomer pop outside allowed window. boomer=%d attacker=%d time_alive=%.2f max=%.2f",
			boomer, attacker, timeAlive, L4D2_SKILLS_COMPETITIVE_POP_MAX_TIME);
		Detect_ResolveBoomerNoPop(boomer);
		return;
	}

	if (g_DetectBoomer[boomer].deathCommitted)
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_BoomerPop);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(attacker);
	g_SkillEvents[eventIndex].victim.Capture(boomer);
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	g_SkillEvents[eventIndex].shoveCount = g_DetectBoomer[boomer].shoveCount;
	g_SkillEvents[eventIndex].timeA = timeAlive;
	g_SkillEvents[eventIndex].headshot = Detect_ResolveHeadshot(boomer, attacker, event.GetBool("headshot"));
	Detect_WriteSiTrackAssistsToEventAsSkillWindow(eventIndex, boomer, attacker);

	int boomerUserid = GetClientUserId(boomer);
	int lifeGeneration = g_iDetectClientLifeGeneration[boomer];
	int roundGeneration = g_iDetectRoundGeneration;
	int lifecycleEpoch = g_Runtime.lifecycleEpoch;
	// Reserve this life before invoking consumers; reentrant death/explosion cannot publish twice.
	g_DetectBoomer[boomer].explosionResolved = true;
	g_DetectBoomer[boomer].deathCommitted = true;
	Detect_MarkSiLifeKillSuppressed(boomer);
	Action result = API_FireSkillDetected(eventId, L4D2Skill_BoomerPop);
	if (GetClientOfUserId(boomerUserid) != boomer
		|| lifeGeneration != g_iDetectClientLifeGeneration[boomer]
		|| roundGeneration != g_iDetectRoundGeneration
		|| lifecycleEpoch != g_Runtime.lifecycleEpoch)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Boomer pop completion discarded. event=%d reason=reentrant_lifecycle", eventId);
		return;
	}
	if (result < Plugin_Handled && Skills_IsRoundLive() && Skills_IsEventValid(eventId))
	{
		Announce_Skill(eventId);
	}
}

void Detect_ResolveBoomerNoPop(int boomer)
{
	bool delayElapsed = g_DetectBoomer[boomer].killDelayElapsed;
	bool committed = g_DetectBoomer[boomer].deathCommitted;
	Detect_ResetBoomer(boomer);
	g_DetectBoomer[boomer].explosionResolved = true;
	g_DetectBoomer[boomer].killDelayElapsed = delayElapsed;
	g_DetectBoomer[boomer].deathCommitted = committed;
	if (delayElapsed)
	{
		Detect_PublishPendingBoomerKill(boomer);
	}
}

Action Detect_TimerBoomerVomitCheck(Handle timer, any context)
{
	int userid = Detect_ReadDeferredClientUserId(view_as<DataPack>(context));
	if (userid <= 0)
	{
		return Plugin_Stop;
	}

	if (!Skills_IsRoundLive())
	{
		return Plugin_Stop;
	}

	int boomer = GetClientOfUserId(userid);
	if (!IsValidZombieClass(boomer, L4D2ZombieClass_Boomer))
	{
		return Plugin_Stop;
	}

	int amount = g_DetectBoomer[boomer].vomitHits;
	g_DetectBoomer[boomer].vomitHits = 0;
	if (amount <= 0)
	{
		return Plugin_Stop;
	}

	Detect_EmitBoomerVomitLanded(boomer, amount);
	return Plugin_Stop;
}

void Detect_ResetBoomer(int boomer)
{
	if (boomer < 1 || boomer > MaxClients)
	{
		return;
	}

	g_DetectBoomer[boomer].Reset();
}

void Detect_EmitBoomerVomitLanded(int boomer, int amount)
{
	if (!IsValidZombieClass(boomer, L4D2ZombieClass_Boomer) || amount <= 0)
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_BoomerVomitLanded);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(boomer);
	g_SkillEvents[eventIndex].amount = amount;
	int survivorLimit = Skills_GetConfiguredSurvivorLimit();
	g_SkillEvents[eventIndex].perfect = (survivorLimit > 0 && amount >= survivorLimit);

	Action result = API_FireSkillDetected(eventId, L4D2Skill_BoomerVomitLanded);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_CancelPendingBoomerKill(int client, const char[] reason = "life_reset")
{
	if (client < 1 || client > MaxClients)
	{
		return;
	}

	int eventId = g_iDetectPendingBoomerKillEvent[client];
	g_iDetectPendingBoomerKillEvent[client] = 0;
	if (eventId > 0)
	{
		Skills_DiscardPendingEvent(eventId);
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Boomer provisional kill discarded. event=%d reason=%s", eventId, reason);
	}
}
