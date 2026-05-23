#if defined _l4d2_player_skills_detect_smoker_included
	#endinput
#endif
#define _l4d2_player_skills_detect_smoker_included

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
	g_iDetectSmokerOwnerByVictim[victim] = smoker;
	g_DetectSmoker[smoker].reached = true;
	g_fDetectSpecialClearTimeA[smoker] = GetGameTime();
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

	int smoker = g_iDetectSmokerOwnerByVictim[victim];
	if (!IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		smoker = L4D_GetAttackerSmoker(victim);
	}

	bool hasReachedSmoker = false;
	if (IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		hasReachedSmoker = g_DetectSmoker[smoker].reached || L4D_HasReachedSmoker(victim);
		if (hasReachedSmoker)
		{
			g_DetectSmoker[smoker].reached = true;
		}
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

	int victim = g_DetectSmoker[smoker].victim;
	g_DetectSmoker[smoker].Reset();

	if (victim > 0 && victim <= MaxClients && g_iDetectSmokerOwnerByVictim[victim] == smoker)
	{
		g_iDetectSmokerOwnerByVictim[victim] = 0;
	}
}

void Detect_ClearSmokerVictim(int victim)
{
	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	int smoker = g_iDetectSmokerOwnerByVictim[victim];
	g_iDetectSmokerOwnerByVictim[victim] = 0;

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

	g_iDetectPinnedVictim[attacker] = victim;
	g_iDetectPinnerByVictim[victim] = attacker;
	g_iDetectPinnedClass[attacker] = zombieClass;
	g_fDetectSpecialClearTimeA[attacker] = timeA;
	g_fDetectSpecialClearTimeB[attacker] = timeB;
}

void Detect_ClearPinStateByAttacker(int attacker)
{
	if (attacker < 1 || attacker > MaxClients)
	{
		return;
	}

	int victim = g_iDetectPinnedVictim[attacker];
	g_iDetectPinnedVictim[attacker] = 0;
	g_iDetectPinnedClass[attacker] = 0;
	g_fDetectSpecialClearTimeA[attacker] = -1.0;
	g_fDetectSpecialClearTimeB[attacker] = -1.0;

	if (victim > 0 && victim <= MaxClients && g_iDetectPinnerByVictim[victim] == attacker)
	{
		g_iDetectPinnerByVictim[victim] = 0;
	}
}

void Detect_ClearPinStateByVictim(int victim)
{
	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	int attacker = g_iDetectPinnerByVictim[victim];
	g_iDetectPinnerByVictim[victim] = 0;

	if (attacker > 0 && attacker <= MaxClients && g_iDetectPinnedVictim[attacker] == victim)
	{
		g_iDetectPinnedVictim[attacker] = 0;
		g_iDetectPinnedClass[attacker] = 0;
		g_fDetectSpecialClearTimeA[attacker] = -1.0;
		g_fDetectSpecialClearTimeB[attacker] = -1.0;
	}
}

bool Detect_IsPinnedClass(int infected)
{
	return infected > 0 && infected <= MaxClients
		&& g_iDetectPinnedVictim[infected] > 0
		&& g_iDetectPinnedClass[infected] >= view_as<int>(L4D2ZombieClass_Smoker)
		&& g_iDetectPinnedClass[infected] <= view_as<int>(L4D2ZombieClass_Charger);
}

bool Detect_IsStillPinning(int infected, int victim)
{
	if (!IsValidInfected(infected) || !IsValidSurvivor(victim))
	{
		return false;
	}

	if (L4D2_GetSpecialInfectedDominatingMe(victim) == infected)
	{
		return true;
	}

	int currentVictim = L4D2_GetSurvivorVictim(infected);
	if (currentVictim == victim)
	{
		return true;
	}

	return IsValidZombieClass(infected, L4D2ZombieClass_Charger)
		&& L4D2_IsInQueuedPummel(infected)
		&& L4D2_GetQueuedPummelVictim(infected) == victim;
}

bool Detect_IsValidTeamClear(int clearer, int pinner)
{
	if (!IsValidSurvivor(clearer) || !Detect_IsPinnedClass(pinner))
	{
		return false;
	}

	int pinvictim = g_iDetectPinnedVictim[pinner];
	if (!IsValidSurvivor(pinvictim))
	{
		pinvictim = L4D2_GetSurvivorVictim(pinner);
		if (!IsValidSurvivor(pinvictim)
			&& IsValidZombieClass(pinner, L4D2ZombieClass_Charger)
			&& L4D2_IsInQueuedPummel(pinner))
		{
			pinvictim = L4D2_GetQueuedPummelVictim(pinner);
		}

		if (IsValidSurvivor(pinvictim))
		{
			Detect_SetPinState(pinner, pinvictim, GetClientZombieClass(pinner), g_fDetectSpecialClearTimeA[pinner], g_fDetectSpecialClearTimeB[pinner]);
		}
	}

	if (!IsValidSurvivor(pinvictim) || clearer == pinvictim)
	{
		return false;
	}

	if (!Detect_IsStillPinning(pinner, pinvictim))
	{
		Detect_ClearPinStateByAttacker(pinner);
		return false;
	}

	return true;
}

void Detect_EmitSpecialClear(int clearer, int pinner, bool withShove)
{
	if (!Detect_IsPinnedClass(pinner))
	{
		return;
	}

	int pinvictim = g_iDetectPinnedVictim[pinner];
	if (!IsValidSurvivor(pinvictim))
	{
		pinvictim = L4D2_GetSurvivorVictim(pinner);
		if (!IsValidSurvivor(pinvictim)
			&& IsValidZombieClass(pinner, L4D2ZombieClass_Charger)
			&& L4D2_IsInQueuedPummel(pinner))
		{
			pinvictim = L4D2_GetQueuedPummelVictim(pinner);
		}

		if (IsValidSurvivor(pinvictim))
		{
			Detect_SetPinState(pinner, pinvictim, GetClientZombieClass(pinner), g_fDetectSpecialClearTimeA[pinner], g_fDetectSpecialClearTimeB[pinner]);
		}
	}

	if (!IsValidSurvivor(clearer) || !IsValidSurvivor(pinvictim))
	{
		Detect_ClearPinStateByAttacker(pinner);
		return;
	}

	float now = GetGameTime();
	int eventId = Skills_CreateEvent(L4D2Skill_SpecialPinClear);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		Detect_ClearPinStateByAttacker(pinner);
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(clearer);
	g_SkillEvents[eventIndex].victim.Capture(pinner);
	g_SkillEvents[eventIndex].zombieClass = g_iDetectPinnedClass[pinner];
	g_SkillEvents[eventIndex].timeA = g_fDetectSpecialClearTimeA[pinner] >= 0.0 ? (now - g_fDetectSpecialClearTimeA[pinner]) : -1.0;
	g_SkillEvents[eventIndex].timeB = g_fDetectSpecialClearTimeB[pinner] >= 0.0 ? (now - g_fDetectSpecialClearTimeB[pinner]) : -1.0;
	g_SkillEvents[eventIndex].withShove = withShove;
	g_SkillEvents[eventIndex].pinVictim.Capture(pinvictim);

	Action result = API_FireSkillDetected(eventId, L4D2Skill_SpecialPinClear);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	Detect_ClearPinStateByAttacker(pinner);
}
