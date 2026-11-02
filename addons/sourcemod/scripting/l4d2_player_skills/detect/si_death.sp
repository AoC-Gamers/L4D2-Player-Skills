// Private detector ownership: si death

void Detect_HandleNonHunterSiDeath(SkillsDeathObservation observation, int victim, int attacker, bool shouldEmitSiLifeKill)
{
	Detect_TryEmitJockeyMeleeSkeet(observation, victim, attacker, shouldEmitSiLifeKill);
	Detect_TryEmitJockeyRangedSkeet(observation, victim, attacker, shouldEmitSiLifeKill);

	if (IsValidZombieClass(victim, L4D2ZombieClass_Jockey))
	{
		Detect_ResetJockeyLeapState(victim);
	}

	bool pendingBoomerKill = IsValidZombieClass(victim, L4D2ZombieClass_Boomer)
		&& shouldEmitSiLifeKill
		&& !g_bDetectSuppressSiLifeKill[victim];
	bool pendingChargerKill = IsValidZombieClass(victim, L4D2ZombieClass_Charger)
		&& shouldEmitSiLifeKill
		&& !g_bDetectSuppressSiLifeKill[victim];
	if (pendingChargerKill && Detect_TryEmitChargerLevelFromDeath(victim, attacker))
	{
		if (Detect_ShouldAnnounceChargerClawSummary(victim))
		{
			Announce_ChargerClawSummary(victim);
		}
		Detect_ResetCharger(victim);
		Detect_ResetSiLifeKillTrack(victim);
		return;
	}
	if (pendingChargerKill)
	{
		g_DetectPendingChargerDeath[victim].queued = true;
		g_DetectPendingChargerDeath[victim].attackerUserId = GetClientUserId(attacker);
		g_DetectPendingChargerDeath[victim].headshot = Detect_ResolveHeadshot(victim, attacker, observation.headshot);
		Detect_QueueClientTimer(0.1, Detect_TimerEvaluateChargerDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	if (shouldEmitSiLifeKill && !g_bDetectSuppressSiLifeKill[victim])
	{
		Detect_EmitSiLifeKill(victim, attacker, Detect_ResolveHeadshot(victim, attacker, observation.headshot));
	}
	if (IsValidZombieClass(victim, L4D2ZombieClass_Charger) && Detect_ShouldAnnounceChargerClawSummary(victim))
	{
		Announce_ChargerClawSummary(victim);
		Detect_ResetCharger(victim);
	}
	if (!pendingBoomerKill)
	{
		Detect_ResetSiLifeKillTrack(victim);
	}
}

void Detect_HandlePlayerDeath(SkillsDeathObservation observation)
{
	int victim = observation.victim;
	int attacker = observation.attacker;
	bool shouldEmitSiLifeKill = IsValidSurvivor(attacker) && Detect_IsTrackableSiLifeKillClass(victim);
	int pinvictim = 0;
	if (IsValidSurvivor(victim))
	{
		if (g_DetectChargeVictim[victim].charger > 0 && !L4D_IsPlayerIncapacitated(victim))
		{
			g_DetectChargeVictim[victim].flags |= DCFLAG_AIRDEATH;
		}

		Detect_CheckChargerInstaKill(observation, victim);
		Detect_ClearPinStateByVictim(victim);
	}

	if (Detect_IsPinnedClass(victim))
	{
		pinvictim = Detect_GetCurrentPinnedVictim(victim);
		if (!IsValidSurvivor(pinvictim))
		{
			pinvictim = g_DetectPinRegistry.pinnedVictimByAttacker[victim];
		}

		if (!IsValidZombieClass(victim, L4D2ZombieClass_Smoker)
			&& !IsValidZombieClass(victim, L4D2ZombieClass_Charger)
			&& IsValidSurvivor(attacker)
			&& IsValidSurvivor(pinvictim)
			&& attacker != pinvictim)
		{
			Detect_EmitSpecialClear(attacker, victim, false, true, observation.headshot);
			Detect_MarkSiLifeKillSuppressed(victim);
			Detect_ClearPinStateByAttacker(victim);
		}
		else if (!IsValidZombieClass(victim, L4D2ZombieClass_Smoker)
			&& !IsValidZombieClass(victim, L4D2ZombieClass_Charger))
		{
			if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
			{
				Skills_Debug(PlayerSkillsDebug_Detect,
					"SpecialClear suppressed by kill hierarchy. pinner=%d attacker=%d class=%d pinvictim=%d",
					victim,
					attacker,
					g_DetectPinRegistry.pinnedClassByAttacker[victim],
					g_DetectPinRegistry.pinnedVictimByAttacker[victim]);
			}

			Detect_ClearPinStateByAttacker(victim);
		}
	}

	shouldEmitSiLifeKill = shouldEmitSiLifeKill && !g_bDetectSuppressSiLifeKill[victim];

	if (IsValidZombieClass(victim, L4D2ZombieClass_Smoker))
	{
		Detect_HandleSmokerDeath(observation, victim, attacker, shouldEmitSiLifeKill);
		return;
	}

	if (!IsValidZombieClass(victim, L4D2ZombieClass_Hunter))
	{
		Detect_HandleNonHunterSiDeath(observation, victim, attacker, shouldEmitSiLifeKill);
		return;
	}

	Detect_HandleHunterDeath(observation, victim, attacker, shouldEmitSiLifeKill);
}
