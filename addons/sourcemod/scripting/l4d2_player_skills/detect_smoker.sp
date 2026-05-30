#if defined _l4d2_player_skills_detect_smoker_included
	#endinput
#endif
#define _l4d2_player_skills_detect_smoker_included

int Detect_GetSmokerVictimFromState(int smoker)
{
	if (!IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		return 0;
	}

	int victim = GetInfectedVictim(smoker);
	if (IsValidSurvivor(victim))
	{
		return victim;
	}

	victim = g_DetectSmoker[smoker].victim;
	return IsValidSurvivor(victim) ? victim : 0;
}

int Detect_FindSmokerByVictim(int victim)
{
	if (!IsValidSurvivor(victim))
	{
		return 0;
	}

	int smoker = Detect_GetCurrentPinnedAttacker(victim);
	if (IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) && Detect_GetSmokerVictimFromState(smoker) == victim)
	{
		return smoker;
	}

	smoker = g_DetectPinRegistry.smokerOwnerByVictim[victim];
	if (IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) && Detect_GetSmokerVictimFromState(smoker) == victim)
	{
		return smoker;
	}

	smoker = L4D_GetAttackerSmoker(victim);
	if (IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) && Detect_GetSmokerVictimFromState(smoker) == victim)
	{
		return smoker;
	}

	return 0;
}

void Detect_EventChokeStart(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int smoker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) || !IsValidSurvivor(victim))
	{
		return;
	}

	g_DetectSmoker[smoker].victim = victim;
	g_DetectPinRegistry.smokerOwnerByVictim[victim] = smoker;
	g_DetectSmoker[smoker].reached = true;
	g_fDetectSpecialClearTimeA[smoker] = GetGameTime();

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear choke_start. smoker=%d victim=%d pin_victim=%d timeA=%.3f",
			smoker,
			victim,
			g_DetectPinRegistry.pinnedVictimByAttacker[smoker],
			g_fDetectSpecialClearTimeA[smoker]);
	}
}

void Detect_EventChokeStopped(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int stopper = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	int smoker = GetClientOfUserId(event.GetInt("smoker"));
	if (!IsValidSurvivor(victim) || !IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		return;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear choke_stopped. stopper=%d victim=%d smoker=%d pin_victim=%d timeA=%.3f",
			stopper,
			victim,
			smoker,
			g_DetectPinRegistry.pinnedVictimByAttacker[smoker],
			g_fDetectSpecialClearTimeA[smoker]);
	}

	if (stopper != victim && IsValidSurvivor(stopper))
	{
		float now = GetGameTime();
		int eventId = Skills_CreateEvent(L4D2Skill_SpecialPinClear);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(stopper);
			g_SkillEvents[eventIndex].victim.Capture(smoker);
			g_SkillEvents[eventIndex].zombieClass = L4D2ZombieClass_Smoker;
			g_SkillEvents[eventIndex].timeA = g_fDetectSpecialClearTimeA[smoker] >= 0.0 ? (now - g_fDetectSpecialClearTimeA[smoker]) : -1.0;
			g_SkillEvents[eventIndex].timeB = g_fDetectSpecialClearTimeB[smoker] >= 0.0 ? (now - g_fDetectSpecialClearTimeB[smoker]) : -1.0;
			g_SkillEvents[eventIndex].withShove = false;
			g_SkillEvents[eventIndex].pinVictim.Capture(victim);

			Skills_Debug(PlayerSkillsDebug_Detect,
				"SpecialClear emit payload. clearer=%d pinner=%d class=%d pinvictim=%d withShove=0 timeA=%.3f timeB=%.3f source=choke_stopped",
				stopper,
				smoker,
				L4D2ZombieClass_Smoker,
				victim,
				g_SkillEvents[eventIndex].timeA,
				g_SkillEvents[eventIndex].timeB);

			Action clearResult = API_FireSkillDetected(eventId, L4D2Skill_SpecialPinClear);
			if (clearResult < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}

	Detect_ClearPinStateByAttacker(smoker);
	Detect_ResetSmoker(smoker);
	Detect_ClearSmokerVictim(victim);
}

void Detect_EventTonguePullStopped(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int stopper = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!IsValidSurvivor(victim))
	{
		return;
	}

	int smoker = Detect_FindSmokerByVictim(victim);

	bool hasReachedSmoker = false;
	if (IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		hasReachedSmoker = g_DetectSmoker[smoker].reached || L4D_HasReachedSmoker(victim);
		if (hasReachedSmoker)
		{
			g_DetectSmoker[smoker].reached = true;
		}
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear tongue_pull_stopped. stopper=%d victim=%d smoker=%d reached=%d shoved=%d pinvictim=%d pinnerByVictim=%d",
			stopper,
			victim,
			smoker,
			hasReachedSmoker ? 1 : 0,
			IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) && g_DetectSmoker[smoker].shoved ? 1 : 0,
			IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) ? g_DetectPinRegistry.pinnedVictimByAttacker[smoker] : 0,
			g_DetectPinRegistry.pinnerByVictim[victim]);
	}

	if (stopper == victim && IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) && !hasReachedSmoker)
	{
		int eventId = Skills_CreateEvent(L4D2Skill_SmokerTongueCut);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(victim);
			g_SkillEvents[eventIndex].victim.Capture(smoker);

			Action result = API_FireSkillDetected(eventId, L4D2Skill_SmokerTongueCut);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}
	else if (stopper != victim && IsValidSurvivor(stopper) && IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		float now = GetGameTime();
		int eventId = Skills_CreateEvent(L4D2Skill_SpecialPinClear);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(stopper);
			g_SkillEvents[eventIndex].victim.Capture(smoker);
			g_SkillEvents[eventIndex].zombieClass = L4D2ZombieClass_Smoker;
			g_SkillEvents[eventIndex].timeA = g_fDetectSpecialClearTimeA[smoker] >= 0.0 ? (now - g_fDetectSpecialClearTimeA[smoker]) : -1.0;
			g_SkillEvents[eventIndex].timeB = g_fDetectSpecialClearTimeB[smoker] >= 0.0 ? (now - g_fDetectSpecialClearTimeB[smoker]) : -1.0;
			g_SkillEvents[eventIndex].withShove = false;
			g_SkillEvents[eventIndex].pinVictim.Capture(victim);

			Action clearResult = API_FireSkillDetected(eventId, L4D2Skill_SpecialPinClear);
			if (clearResult < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}
	else if (stopper == victim && IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) && hasReachedSmoker && g_DetectSmoker[smoker].shoved)
	{
		int eventId = Skills_CreateEvent(L4D2Skill_SmokerSelfClear);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(victim);
			g_SkillEvents[eventIndex].victim.Capture(smoker);
			g_SkillEvents[eventIndex].withShove = true;
			g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
			Detect_WriteSiTrackAssistsToEventAsSkillWindow(eventIndex, smoker, victim);

			Action result = API_FireSkillDetected(eventId, L4D2Skill_SmokerSelfClear);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}

	if (IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		Detect_ClearPinStateByAttacker(smoker);
		Detect_ResetSmoker(smoker);
	}
	Detect_ClearSmokerVictim(victim);
}

void Detect_ResetSmoker(int smoker)
{
	if (smoker < 1 || smoker > MaxClients)
	{
		return;
	}

	int victim = Detect_GetSmokerVictimFromState(smoker);
	g_DetectSmoker[smoker].Reset();

	if (victim > 0 && victim <= MaxClients && g_DetectPinRegistry.smokerOwnerByVictim[victim] == smoker)
	{
		g_DetectPinRegistry.smokerOwnerByVictim[victim] = 0;
	}
}

void Detect_ClearSmokerVictim(int victim)
{
	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	int smoker = g_DetectPinRegistry.smokerOwnerByVictim[victim];
	g_DetectPinRegistry.smokerOwnerByVictim[victim] = 0;

	if (smoker > 0 && smoker <= MaxClients && g_DetectSmoker[smoker].victim == victim)
	{
		g_DetectSmoker[smoker].victim = 0;
		g_DetectSmoker[smoker].reached = false;
	}
}

void Detect_SetPinState(int attacker, int victim, int zombieClass, float timeA, float timeB)
{
	if (attacker < 1 || attacker > MaxClients || victim < 1 || victim > MaxClients)
	{
		return;
	}

	Detect_ClearPinStateByAttacker(attacker);
	Detect_ClearPinStateByVictim(victim);

	g_DetectPinRegistry.pinnedVictimByAttacker[attacker] = victim;
	g_DetectPinRegistry.pinnerByVictim[victim] = attacker;
	g_DetectPinRegistry.pinnedClassByAttacker[attacker] = zombieClass;
	g_fDetectSpecialClearTimeA[attacker] = timeA;
	g_fDetectSpecialClearTimeB[attacker] = timeB;

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear pin state set. attacker=%d victim=%d class=%d timeA=%.3f timeB=%.3f",
			attacker,
			victim,
			zombieClass,
			timeA,
			timeB);
	}
}

void Detect_ClearPinStateByAttacker(int attacker)
{
	if (attacker < 1 || attacker > MaxClients)
	{
		return;
	}

	int victim = g_DetectPinRegistry.pinnedVictimByAttacker[attacker];
	g_DetectPinRegistry.pinnedVictimByAttacker[attacker] = 0;
	g_DetectPinRegistry.pinnedClassByAttacker[attacker] = 0;
	g_fDetectSpecialClearTimeA[attacker] = -1.0;
	g_fDetectSpecialClearTimeB[attacker] = -1.0;

	if (victim > 0 && victim <= MaxClients && g_DetectPinRegistry.pinnerByVictim[victim] == attacker)
	{
		g_DetectPinRegistry.pinnerByVictim[victim] = 0;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear pin state cleared by attacker. attacker=%d victim=%d",
			attacker,
			victim);
	}
}

void Detect_ClearPinStateByVictim(int victim)
{
	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	int attacker = g_DetectPinRegistry.pinnerByVictim[victim];
	g_DetectPinRegistry.pinnerByVictim[victim] = 0;

	if (attacker > 0 && attacker <= MaxClients && g_DetectPinRegistry.pinnedVictimByAttacker[attacker] == victim)
	{
		g_DetectPinRegistry.pinnedVictimByAttacker[attacker] = 0;
		g_DetectPinRegistry.pinnedClassByAttacker[attacker] = 0;
		g_fDetectSpecialClearTimeA[attacker] = -1.0;
		g_fDetectSpecialClearTimeB[attacker] = -1.0;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear pin state cleared by victim. victim=%d attacker=%d",
			victim,
			attacker);
	}
}

bool Detect_IsPinnedClass(int infected)
{
	return infected > 0 && infected <= MaxClients
		&& g_DetectPinRegistry.pinnedVictimByAttacker[infected] > 0
		&& g_DetectPinRegistry.pinnedClassByAttacker[infected] >= view_as<int>(L4D2ZombieClass_Smoker)
		&& g_DetectPinRegistry.pinnedClassByAttacker[infected] <= view_as<int>(L4D2ZombieClass_Charger);
}

bool Detect_IsStillPinning(int infected, int victim)
{
	if (!IsValidInfected(infected) || !IsValidSurvivor(victim))
	{
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"SpecialClear still pinning check. infected=%d victim=%d result=0 reason=invalid",
				infected,
				victim);
		}
		return false;
	}

	if (L4D2_GetSpecialInfectedDominatingMe(victim) == infected)
	{
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"SpecialClear still pinning check. infected=%d victim=%d result=1 reason=dominating",
				infected,
				victim);
		}
		return true;
	}

	int currentVictim = Detect_GetCurrentPinnedVictim(infected);
	if (currentVictim == victim)
	{
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"SpecialClear still pinning check. infected=%d victim=%d result=1 reason=survivor_victim",
				infected,
				victim);
		}
		return true;
	}

	bool queuedPummel = IsValidZombieClass(infected, L4D2ZombieClass_Charger)
		&& L4D2_IsInQueuedPummel(infected)
		&& L4D2_GetQueuedPummelVictim(infected) == victim;

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear still pinning check. infected=%d victim=%d result=%d reason=queued_pummel",
			infected,
			victim,
			queuedPummel ? 1 : 0);
	}

	return queuedPummel;
}

bool Detect_IsValidTeamClear(int clearer, int pinner)
{
	if (!IsValidSurvivor(clearer) || !Detect_IsPinnedClass(pinner))
	{
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"SpecialClear valid clear check. clearer=%d pinner=%d result=0 reason=invalid_inputs pinnedClass=%d pinvictim=%d",
				clearer,
				pinner,
				pinner >= 1 && pinner <= MaxClients ? g_DetectPinRegistry.pinnedClassByAttacker[pinner] : 0,
				pinner >= 1 && pinner <= MaxClients ? g_DetectPinRegistry.pinnedVictimByAttacker[pinner] : 0);
		}
		return false;
	}

	int pinvictim = Detect_GetCurrentPinnedVictim(pinner);
	if (!IsValidSurvivor(pinvictim))
	{
		return false;
	}

	if (pinvictim != g_DetectPinRegistry.pinnedVictimByAttacker[pinner])
	{
		Detect_SetPinState(pinner, pinvictim, GetClientZombieClass(pinner), g_fDetectSpecialClearTimeA[pinner], g_fDetectSpecialClearTimeB[pinner]);
	}

	if (!IsValidSurvivor(pinvictim) || clearer == pinvictim)
	{
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"SpecialClear valid clear check. clearer=%d pinner=%d pinvictim=%d result=0 reason=bad_pinvictim",
				clearer,
				pinner,
				pinvictim);
		}
		return false;
	}

	if (!Detect_IsStillPinning(pinner, pinvictim))
	{
		Detect_ClearPinStateByAttacker(pinner);
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"SpecialClear valid clear check. clearer=%d pinner=%d pinvictim=%d result=0 reason=not_still_pinning",
				clearer,
				pinner,
				pinvictim);
		}
		return false;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear valid clear check. clearer=%d pinner=%d pinvictim=%d class=%d timeA=%.3f timeB=%.3f result=1",
			clearer,
			pinner,
			pinvictim,
			g_DetectPinRegistry.pinnedClassByAttacker[pinner],
			g_fDetectSpecialClearTimeA[pinner],
			g_fDetectSpecialClearTimeB[pinner]);
	}

	return true;
}

void Detect_EmitSpecialClear(int clearer, int pinner, bool withShove)
{
	if (!Detect_IsPinnedClass(pinner))
	{
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"SpecialClear emit aborted. clearer=%d pinner=%d withShove=%d reason=not_pinned_class",
				clearer,
				pinner,
				withShove ? 1 : 0);
		}
		return;
	}

	int pinvictim = Detect_GetCurrentPinnedVictim(pinner);
	if (!IsValidSurvivor(pinvictim))
	{
		Detect_ClearPinStateByAttacker(pinner);
		return;
	}

	if (pinvictim != g_DetectPinRegistry.pinnedVictimByAttacker[pinner])
	{
		Detect_SetPinState(pinner, pinvictim, GetClientZombieClass(pinner), g_fDetectSpecialClearTimeA[pinner], g_fDetectSpecialClearTimeB[pinner]);
	}

	if (!IsValidSurvivor(clearer) || !IsValidSurvivor(pinvictim))
	{
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"SpecialClear emit aborted. clearer=%d pinner=%d pinvictim=%d withShove=%d reason=invalid_targets",
				clearer,
				pinner,
				pinvictim,
				withShove ? 1 : 0);
		}
		Detect_ClearPinStateByAttacker(pinner);
		return;
	}

	float now = GetGameTime();
	int eventId = Skills_CreateEvent(L4D2Skill_SpecialPinClear);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"SpecialClear emit aborted. clearer=%d pinner=%d pinvictim=%d withShove=%d reason=no_event_slot",
				clearer,
				pinner,
				pinvictim,
				withShove ? 1 : 0);
		}
		Detect_ClearPinStateByAttacker(pinner);
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(clearer);
	g_SkillEvents[eventIndex].victim.Capture(pinner);
	g_SkillEvents[eventIndex].zombieClass = g_DetectPinRegistry.pinnedClassByAttacker[pinner];
	g_SkillEvents[eventIndex].timeA = g_fDetectSpecialClearTimeA[pinner] >= 0.0 ? (now - g_fDetectSpecialClearTimeA[pinner]) : -1.0;
	g_SkillEvents[eventIndex].timeB = g_fDetectSpecialClearTimeB[pinner] >= 0.0 ? (now - g_fDetectSpecialClearTimeB[pinner]) : -1.0;
	g_SkillEvents[eventIndex].withShove = withShove;
	g_SkillEvents[eventIndex].pinVictim.Capture(pinvictim);

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear emit payload. clearer=%d pinner=%d class=%d pinvictim=%d withShove=%d timeA=%.3f timeB=%.3f",
			clearer,
			pinner,
			g_DetectPinRegistry.pinnedClassByAttacker[pinner],
			pinvictim,
			withShove ? 1 : 0,
			g_SkillEvents[eventIndex].timeA,
			g_SkillEvents[eventIndex].timeB);
	}

	Action result = API_FireSkillDetected(eventId, L4D2Skill_SpecialPinClear);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	Detect_ClearPinStateByAttacker(pinner);
}
