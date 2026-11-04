// Private detector ownership: inputs

void Detect_OnClientPutInServer(int client)
{
	if (client <= 0 || client > MaxClients)
	{
		return;
	}

	g_iDetectClientLifeGeneration[client]++;

	if (!g_bDetectClientDamageHooked[client])
	{
		SDKHook(client, SDKHook_OnTakeDamage, Detect_OnTakeDamage_Client);
		SDKHook(client, SDKHook_OnTakeDamagePost, Detect_OnTakeDamagePost_Client);
		g_bDetectClientDamageHooked[client] = true;
	}

	Detect_ResetBoomer(client);
	Detect_ResetBHop(client);
	Detect_ResetHunter(client);
	Detect_ResetJockeyLeapState(client);
	Detect_ResetCharger(client);
	Detect_ResetChargeTrack(client);
	Detect_ResetSiLifeKillTrack(client);
	Detect_ResetSmoker(client);
	Detect_ClearSmokerVictim(client);

	for (int victim = 1; victim <= MaxClients; victim++)
	{
		int lifeSlot = Detect_FindSiLifeSlot(victim, client);
		if (lifeSlot != -1)
		{
			g_DetectSiLife[victim].entries[lifeSlot].shotCounted = false;
		}
		Detect_ResetShoveWindowEntryByAttacker(g_DetectHunterLastShove[victim], client);
		Detect_ResetShoveWindowEntryByAttacker(g_DetectJockeyLastShove[victim], client);
		Detect_ResetHunterShotWindowEntryByAttacker(victim, client);
	}
}

void Detect_OnClientDisconnect(int client)
{
	if (client > 0 && client <= MaxClients)
	{
		g_iDetectClientLifeGeneration[client]++;
	}

	if (client > 0 && client <= MaxClients && g_bDetectClientDamageHooked[client])
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, Detect_OnTakeDamage_Client);
		SDKUnhook(client, SDKHook_OnTakeDamagePost, Detect_OnTakeDamagePost_Client);
		g_bDetectClientDamageHooked[client] = false;
	}

	Detect_ClearPinStateByAttacker(client);
	Detect_ClearPinStateByVictim(client);
	Detect_ResetBoomer(client);
	Detect_ResetBHop(client);
	Detect_ResetHunter(client);
	Detect_ResetJockeyLeapState(client);
	Detect_ResetCharger(client);
	Detect_ResetChargeTrack(client);
	Detect_ResetSiLifeKillTrack(client);
	Detect_ResetSmoker(client);
	Detect_ClearSmokerVictim(client);

	for (int victim = 1; victim <= MaxClients; victim++)
	{
		Detect_DetachSiLifeEntryByAttacker(victim, client);
		Detect_ResetShoveWindowEntryByAttacker(g_DetectHunterLastShove[victim], client);
		Detect_ResetShoveWindowEntryByAttacker(g_DetectJockeyLastShove[victim], client);
		Detect_ResetHunterShotWindowEntryByAttacker(victim, client);
	}
}

void Detect_OnEntityCreated(int entity, const char[] classname)
{
	if (entity <= MaxClients)
	{
		return;
	}

	if (StrEqual(classname, "prop_car_alarm"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, Detect_OnTakeDamage_CarAlarm);
		SDKHook(entity, SDKHook_Touch, Detect_OnTouch_CarAlarm);
		SDKHook(entity, SDKHook_Spawn, Detect_OnSpawn_CarAlarm);
		return;
	}

	if (StrEqual(classname, "prop_car_glass"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, Detect_OnTakeDamage_CarGlass);
		SDKHook(entity, SDKHook_Touch, Detect_OnTouch_CarGlass);
		SDKHook(entity, SDKHook_Spawn, Detect_OnSpawn_CarGlass);
	}
}

void Detect_OnGrabWithTonguePost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(victim) || !IsValidZombieClass(attacker, L4D2ZombieClass_Smoker))
	{
		return;
	}

	Detect_ResetSmoker(attacker);
	Detect_ClearSmokerVictim(victim);

	g_DetectSmoker[attacker].victim = victim;
	g_DetectPinRegistry.smokerOwnerByVictim[victim] = attacker;
	g_DetectSmoker[attacker].reached = false;
	g_DetectSmoker[attacker].shoved = false;
	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Smoker, -1.0, GetGameTime());

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear tongue_grab hook. smoker=%d victim=%d",
			attacker,
			victim);
	}
}

void Detect_OnPouncedOnSurvivorPost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Hunter) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Hunter, -1.0, -1.0);

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear lunge_pounce hook. hunter=%d victim=%d",
			attacker,
			victim);
	}

	float height = Detect_GetLeapHeight(attacker, victim);
	float threshold = g_cvHunterHighPounceHeight != null ? g_cvHunterHighPounceHeight.FloatValue : L4D2_SKILLS_DEFAULT_HUNTER_HIGH_POUNCE_HEIGHT;
	float distance = Detect_GetLeapDistance(attacker, victim);
	float calculatedDamage = Detect_CalculateHunterPounceDamage(distance);
	bool incapped = L4D_IsPlayerIncapacitated(victim);
	if (incapped)
	{
		if (height >= threshold)
		{
			Announce_HunterIncapPounce(attacker, victim, RoundToFloor(calculatedDamage), height);
		}
		Detect_SetHunterPouncing(attacker, false);
		g_DetectLeap[attacker].Reset();
		return;
	}
	bool reportedHigh = height >= threshold;

	if (reportedHigh)
	{
		int eventId = Skills_CreateEvent(L4D2Skill_HunterHighPounce);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(attacker);
			g_SkillEvents[eventIndex].victim.Capture(victim);
			g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
			g_SkillEvents[eventIndex].damage = RoundToFloor(calculatedDamage);
			g_SkillEvents[eventIndex].actorDamage = g_SkillEvents[eventIndex].damage;
			g_SkillEvents[eventIndex].calculatedDamage = calculatedDamage;
			g_SkillEvents[eventIndex].distance = distance;
			g_SkillEvents[eventIndex].height = height;
			g_SkillEvents[eventIndex].reportedHigh = true;
			g_SkillEvents[eventIndex].incapped = incapped;
			Detect_AttachPinnedInfectedAssistToEvent(eventIndex, attacker, victim);

			Action result = API_FireSkillDetected(eventId, L4D2Skill_HunterHighPounce);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}

	Detect_SetHunterPouncing(attacker, false);
	g_DetectLeap[attacker].Reset();
}

void Detect_OnJockeyRidePost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Jockey) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Jockey, -1.0, -1.0);

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear jockey_ride hook. jockey=%d victim=%d",
			attacker,
			victim);
	}
}

void Detect_OnStartCarryingVictimPost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Charger) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_RecordChargeVictim(attacker, victim, true);
	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Charger, -1.0, GetGameTime());

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear charger_carry_start hook. charger=%d victim=%d",
			attacker,
			victim);
	}
}

void Detect_OnSlammedSurvivorPost(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge)
{
	if (bWallSlam)
	{
		// Wall slams do not currently change the emitted skill classification.
	}

	if (!Skills_IsEnabled() || !IsValidSurvivor(victim) || !IsValidZombieClass(attacker, L4D2ZombieClass_Charger))
	{
		return;
	}

	if (g_DetectChargeVictim[victim].charger != attacker)
	{
		return;
	}

	g_DetectChargeVictim[victim].slamResolved = true;

	if (bDeadlyCharge)
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_DEADLY;
	}

	Detect_TryEmitPendingChargerDeathSetup(victim);
}

void Detect_OnFatalFalling(int client)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_DetectChargeVictim[client].charger <= 0)
	{
		return;
	}

	g_DetectChargeVictim[client].flags |= DCFLAG_FALL;
}

void Detect_OnFalling(int client)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_DetectChargeVictim[client].charger <= 0)
	{
		return;
	}

	g_DetectChargeVictim[client].flags |= DCFLAG_FALL;
}

void Detect_OnLedgeGrabbedPost(int client)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_DetectChargeVictim[client].charger <= 0)
	{
		return;
	}

	g_DetectChargeVictim[client].flags |= DCFLAG_LEDGE;
}

void Detect_EventPlayerLedgeGrab(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(victim))
	{
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidInfected(attacker))
	{
		attacker = Detect_GetCurrentPinnedAttacker(victim);
		if (!IsValidInfected(attacker))
		{
			attacker = Detect_FindSmokerByVictim(victim);
		}
	}

	if (g_DetectChargeVictim[victim].charger > 0)
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_LEDGE;
		Detect_EmitChargerLedgeHang(victim);
		return;
	}

	if (IsValidZombieClass(attacker, L4D2ZombieClass_Smoker))
	{
		Detect_EmitGenericLedgeHang(L4D2Skill_SmokerLedgeHang, attacker, victim, L4D2ZombieClass_Smoker);
		return;
	}

	if (IsValidZombieClass(attacker, L4D2ZombieClass_Jockey))
	{
		Detect_EmitGenericLedgeHang(L4D2Skill_JockeyLedgeHang, attacker, victim, L4D2ZombieClass_Jockey);
		return;
	}

	if (IsValidTank(attacker))
	{
		Boss_RecordTankLedgeHang(attacker);
		Detect_EmitGenericLedgeHang(L4D2Skill_TankLedgeHang, attacker, victim, L4D2ZombieClass_Tank);
	}
}

void Detect_OnIncapacitatedPost(int client, int attacker, int damagetype)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_DetectChargeVictim[client].charger <= 0)
	{
		return;
	}

	if (attacker > 0 && attacker != g_DetectChargeVictim[client].charger)
	{
		return;
	}

	g_DetectChargeVictim[client].flags |= DCFLAG_INCAP;
	g_DetectChargeVictim[client].incapTime = GetGameTime();

	if (damagetype & DMG_FALL)
	{
		g_DetectChargeVictim[client].flags |= DCFLAG_FALL;
	}

	if (L4D_IsPlayerHangingFromLedge(client))
	{
		g_DetectChargeVictim[client].flags |= DCFLAG_LEDGE;
		Detect_EmitChargerLedgeHang(client);
	}
	Detect_TryEmitPendingChargerDeathSetup(client);
}

void Detect_EventPlayerIncapacitatedStart(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(victim) || g_DetectChargeVictim[victim].charger <= 0)
	{
		return;
	}

	g_DetectChargeVictim[victim].flags |= DCFLAG_INCAP;
	g_DetectChargeVictim[victim].incapTime = GetGameTime();

	if (L4D_IsPlayerHangingFromLedge(victim))
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_LEDGE;
		Detect_EmitChargerLedgeHang(victim);
	}
	Detect_TryEmitPendingChargerDeathSetup(victim);
}

void Detect_OnPummelVictimPost(int attacker, int victim)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Charger) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_DisableChargerClawSummaryByPin(attacker, "pummel_post");

	if (Detect_GetCurrentPinnedVictim(attacker) != victim)
	{
		Detect_SetPinState(attacker, victim, L4D2ZombieClass_Charger, GetGameTime(), GetGameTime());
		return;
	}

	g_fDetectSpecialClearTimeA[attacker] = GetGameTime();
	if (g_fDetectSpecialClearTimeB[attacker] < 0.0)
	{
		g_fDetectSpecialClearTimeB[attacker] = GetGameTime();
	}

	if (g_DetectChargeVictim[victim].charger == attacker)
	{
		g_DetectChargeVictim[victim].slamResolved = true;
		Detect_TryEmitPendingChargerDeathSetup(victim);
	}
}

void Detect_EventChargerImpact(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int charger = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger) || !IsValidSurvivor(victim))
	{
		return;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger impact event. charger=%d victim=%d state_charging=%d effective_charging=%d",
			charger,
			victim,
			Detect_IsChargerCharging(charger) ? 1 : 0,
			Detect_IsChargerEffectivelyCharging(charger) ? 1 : 0);
	}

	bool countedBowlImpact = Detect_RecordChargerBowlImpact(charger, victim);
	if (countedBowlImpact && Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger bowl impact recorded. charger=%d victim=%d impacted=%d",
			charger,
			victim,
			g_DetectChargerBowl[charger].impactedCount);
	}

	Detect_RecordChargeVictim(charger, victim, false);
}

void Detect_EventChargerCarryEnd(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int charger = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		return;
	}

	int victim = Detect_GetCurrentPinnedVictim(charger);
	if (!IsValidSurvivor(victim))
	{
		return;
	}

	g_fDetectSpecialClearTimeB[charger] = GetGameTime();

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear charger_carry_end event. charger=%d victim=%d timeB=%.3f pin_victim=%d",
			charger,
			victim,
			g_fDetectSpecialClearTimeB[charger],
			Detect_GetCurrentPinnedVictim(charger));
	}
}

void Detect_EventChargerPummelStart(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int charger = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear charger_pummel_start event. charger=%d victim=%d pin_victim=%d timeA=%.3f timeB=%.3f",
			charger,
			victim,
			charger >= 1 && charger <= MaxClients ? g_DetectPinRegistry.pinnedVictimByAttacker[charger] : 0,
			charger >= 1 && charger <= MaxClients ? g_fDetectSpecialClearTimeA[charger] : -1.0,
			charger >= 1 && charger <= MaxClients ? g_fDetectSpecialClearTimeB[charger] : -1.0);
	}

	Detect_CheckChargerBowl(charger);
}

void Detect_EventChargerPummelEnd(Event event)
{
	int eventRef = view_as<int>(event);
	if (!Skills_IsEnabled())
	{
		return;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear charger_pummel_end event. eventref=%d",
			eventRef);
	}
}

void Detect_OnEntityShovedPost(int client, int entity, int weapon, const float vecDir[3], bool bIsHighPounce)
{
	if (weapon < 0 || vecDir[0] > 999999.0)
	{
		return;
	}

	if (!Skills_IsEnabled() || !IsValidSurvivor(client))
	{
		return;
	}

	Announce_ShoveAttempt(client, entity);

	if (IsValidZombieClass(entity, L4D2ZombieClass_Jockey))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Jockey jump-stop check. jockey=%d attacker=%d leaping=%d",
			entity,
			client,
			Detect_IsJockeyEffectivelyLeaping(entity) ? 1 : 0);

		if (!Detect_IsJockeyEffectivelyLeaping(entity))
		{
			return;
		}

		float now = GetGameTime();
		if (now - Detect_GetLastShoveTime(g_DetectJockeyLastShove[entity], client) <= L4D2_SKILLS_DEADSTOP_DOUBLE_TIME)
		{
			return;
		}

		Detect_SetLastShoveTime(g_DetectJockeyLastShove[entity], client, now);
		Detect_SetJockeyLeaping(entity, false);

		int eventId = Skills_CreateEvent(L4D2Skill_JockeyJumpStop);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex == -1)
		{
			return;
		}

		g_SkillEvents[eventIndex].actor.Capture(client);
		g_SkillEvents[eventIndex].victim.Capture(entity);
		g_SkillEvents[eventIndex].withShove = true;

		Action result = API_FireSkillDetected(eventId, L4D2Skill_JockeyJumpStop);
		if (result < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
		return;
	}

	if (!IsValidZombieClass(entity, L4D2ZombieClass_Hunter))
	{
		return;
	}

	if (!Detect_IsHunterEffectivelyPouncing(entity) && !bIsHighPounce)
	{
		return;
	}

	float now = GetGameTime();
	if (now - Detect_GetLastShoveTime(g_DetectHunterLastShove[entity], client) <= L4D2_SKILLS_DEADSTOP_DOUBLE_TIME)
	{
		return;
	}

	Detect_SetLastShoveTime(g_DetectHunterLastShove[entity], client, now);
	Detect_SetHunterPouncing(entity, false);

	int eventId = Skills_CreateEvent(L4D2Skill_HunterDeadstop);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(client);
	g_SkillEvents[eventIndex].victim.Capture(entity);
	g_SkillEvents[eventIndex].withShove = true;
	g_SkillEvents[eventIndex].reportedHigh = bIsHighPounce;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_HunterDeadstop);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_OnEntityDestroyed(int entity)
{
	Detect_RemoveCarAlarmTracking(entity);
	Detect_QueueRockFinalize(entity);
}

void Detect_EventPlayerHurt(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	SkillsDamageObservation observation;
	Detect_CaptureDamageObservation(event, observation);
	Detect_HandlePlayerHurt(observation);
}

void Detect_EventPlayerDeath(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	SkillsDeathObservation observation;
	Detect_CaptureDeathObservation(event, observation);
	Detect_HandlePlayerDeath(observation);
}

void Detect_EventPlayerSpawn(Event event)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && client <= MaxClients)
	{
		g_iDetectClientLifeGeneration[client]++;
		Detect_CancelPendingBoomerKill(client, "new_life");
		Detect_ResetBoomer(client);
	}

	if (!Skills_IsEnabled())
	{
		return;
	}

	if (!IsValidZombieClass(client, L4D2ZombieClass_Boomer))
	{
		if (IsValidSurvivor(client))
		{
			Detect_ResetBHop(client);
		}

		if (IsValidZombieClass(client, L4D2ZombieClass_Hunter))
		{
			Detect_ResetHunter(client);
			g_iDetectHunterSpawnHealth[client] = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Hunter);
			g_DetectHunterDamageSnapshot[client].lastHealth = g_iDetectHunterSpawnHealth[client];
			Skills_Debug(PlayerSkillsDebug_Detect,
				"Hunter spawn baseline set. hunter=%d spawn_health=%d",
				client,
				g_iDetectHunterSpawnHealth[client]);
		}
		else if (IsValidZombieClass(client, L4D2ZombieClass_Charger))
		{
			g_DetectChargerDamageSnapshot[client].lastHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Charger);
		}

		if (IsValidInfected(client))
		{
			Detect_ResetSiLifeKillTrack(client);
		}

		return;
	}

	Detect_ResetSiLifeKillTrack(client);
	g_DetectBoomer[client].spawnTime = GetGameTime();
	g_DetectBoomer[client].hitSomebody = false;
	g_DetectBoomer[client].shoveCount = 0;
	g_DetectBoomer[client].vomitHits = 0;
}

void Detect_EventPlayerShoved(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker) || !IsValidInfected(victim))
	{
		return;
	}

	bool shouldDebugShove = IsValidZombieClass(victim, L4D2ZombieClass_Hunter)
		|| IsValidZombieClass(victim, L4D2ZombieClass_Jockey)
		|| IsValidZombieClass(victim, L4D2ZombieClass_Smoker);
	if (shouldDebugShove && Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear player_shoved event. attacker=%d victim=%d pinnedClass=%d pinvictim=%d pinnerByVictim=%d",
			attacker,
			victim,
			g_DetectPinRegistry.pinnedClassByAttacker[victim],
			g_DetectPinRegistry.pinnedVictimByAttacker[victim],
			g_DetectPinRegistry.pinnerByVictim[victim]);
	}

	if (IsValidZombieClass(victim, L4D2ZombieClass_Boomer))
	{
		g_DetectBoomer[victim].shoveCount++;
	}
	else if (Detect_IsPinnedClass(victim)
		&& !IsValidZombieClass(victim, L4D2ZombieClass_Charger)
		&& !IsValidZombieClass(victim, L4D2ZombieClass_Smoker)
		&& Detect_IsValidTeamClear(attacker, victim))
	{
		Detect_EmitSpecialClear(attacker, victim, true);
	}
	else if (IsValidZombieClass(victim, L4D2ZombieClass_Smoker)
		&& Detect_GetSmokerVictimFromState(victim) == attacker)
	{
		g_DetectSmoker[victim].shoved = true;
	}
}

void Detect_EventWeaponFire(Event event)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(attacker))
	{
		return;
	}

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	g_iDetectLastWeaponId[attacker] = Skills_GetWeaponIdFromEventName(weapon);
	g_fDetectLastWeaponFireTime[attacker] = GetGameTime();

	// Reset per-shot gates on weapon_fire rather than player_hurt so multi-pellet
	// weapons and splash ticks can still collapse into one logical shot.
	for (int victim = 1; victim <= MaxClients; victim++)
	{
		int lifeSlot = Detect_FindSiLifeSlot(victim, attacker);
		if (lifeSlot != -1)
		{
			g_DetectSiLife[victim].entries[lifeSlot].shotCounted = false;
		}
		int slot = Detect_FindHunterShotWindowSlot(victim, attacker);
		if (slot != -1)
		{
			g_DetectHunterShotWindow[victim].entries[slot].shotCounted = false;
		}
	}
}

int Detect_GetLastWeaponId(int client)
{
	return (client > 0 && client <= MaxClients) ? g_iDetectLastWeaponId[client] : WEPID_NONE;
}

float Detect_GetLastWeaponFireTime(int client)
{
	return (client > 0 && client <= MaxClients) ? g_fDetectLastWeaponFireTime[client] : 0.0;
}

Action Detect_OnTakeDamage_Client(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	bool roundLive = Skills_IsRoundLive();
	bool validInfected = IsValidInfected(victim);
	bool debugDamageHook = roundLive || validInfected;
	if (debugDamageHook && Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		int team = IsValidClient(victim) ? GetClientTeam(victim) : -1;
		int zombieClass = IsValidClient(victim) ? view_as<int>(L4D2_GetPlayerZombieClass(victim)) : -1;
		Skills_Debug(PlayerSkillsDebug_Detect,
			"OnTakeDamage enter. victim=%d attacker=%d inflictor=%d damage=%.1f damagetype=%d round_live=%d valid_infected=%d team=%d zombie_class=%d alive=%d",
			victim,
			attacker,
			inflictor,
			damage,
			damagetype,
			roundLive ? 1 : 0,
			validInfected ? 1 : 0,
			team,
			zombieClass,
			(IsValidClient(victim) && IsPlayerAlive(victim)) ? 1 : 0);
	}

	if (!roundLive || !validInfected)
	{
		return Plugin_Continue;
	}

	L4D2ZombieClassType zombieClass = L4D2_GetPlayerZombieClass(victim);
	if (zombieClass == L4D2ZombieClass_Hunter)
	{
		g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage = GetClientHealth(victim);
		g_DetectHunterDamageSnapshot[victim].lastAttacker = attacker;
		g_DetectHunterDamageSnapshot[victim].lastDamageType = damagetype;
		g_DetectHunterDamageSnapshot[victim].lastRawDamage = damage;
		if (g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage > 0
			&& RoundToFloor(damage) >= g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage
			&& Detect_IsHunterSkeetWindowActive(victim))
		{
			g_DetectHunterDamageSnapshot[victim].killedAirbornePouncing = true;
		}
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"Hunter pre-damage snapshot. hunter=%d attacker=%d current_health=%d raw=%.1f damagetype=%d spawn_health=%d last_health=%d lethal_airborne=%d",
				victim,
				attacker,
				g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage,
				damage,
				damagetype,
				g_iDetectHunterSpawnHealth[victim],
				g_DetectHunterDamageSnapshot[victim].lastHealth,
				g_DetectHunterDamageSnapshot[victim].killedAirbornePouncing ? 1 : 0);
		}
	}
	else if (zombieClass == L4D2ZombieClass_Charger)
	{
		g_DetectChargerDamageSnapshot[victim].lastHealthBeforeDamage = GetClientHealth(victim);
		g_DetectChargerDamageSnapshot[victim].lastAttacker = attacker;
		g_DetectChargerDamageSnapshot[victim].lastDamageType = damagetype;
		g_DetectChargerDamageSnapshot[victim].lastRawDamage = damage;
	}
	else if (zombieClass == L4D2ZombieClass_Jockey)
	{
		int healthBeforeDamage = GetClientHealth(victim);
		if (healthBeforeDamage > 0
			&& RoundToFloor(damage) >= healthBeforeDamage
			&& Detect_IsJockeySkeetWindowActive(victim))
		{
			g_bDetectJockeyKilledAirborneLeaping[victim] = true;
		}
	}

	return Plugin_Continue;
}

void Detect_OnTakeDamagePost_Client(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	bool roundLive = Skills_IsRoundLive();
	bool validInfected = IsValidInfected(victim);
	bool debugDamageHook = roundLive || validInfected;
	if (debugDamageHook && Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		int team = IsValidClient(victim) ? GetClientTeam(victim) : -1;
		int zombieClass = IsValidClient(victim) ? view_as<int>(L4D2_GetPlayerZombieClass(victim)) : -1;
		Skills_Debug(PlayerSkillsDebug_Detect,
			"OnTakeDamagePost enter. victim=%d attacker=%d inflictor=%d damage=%.1f damagetype=%d round_live=%d valid_infected=%d team=%d zombie_class=%d alive=%d",
			victim,
			attacker,
			inflictor,
			damage,
			damagetype,
			roundLive ? 1 : 0,
			validInfected ? 1 : 0,
			team,
			zombieClass,
			(IsValidClient(victim) && IsPlayerAlive(victim)) ? 1 : 0);
	}

	if (!roundLive || !validInfected)
	{
		return;
	}

	L4D2ZombieClassType zombieClass = L4D2_GetPlayerZombieClass(victim);
	if (zombieClass == L4D2ZombieClass_Hunter)
	{
		Detect_HandleHunterDamagePost(victim, attacker, damage, damagetype);
	}
	else if (zombieClass == L4D2ZombieClass_Charger)
	{
		g_DetectChargerDamageSnapshot[victim].lastAttacker = attacker;
		g_DetectChargerDamageSnapshot[victim].lastDamageType = damagetype;
		g_DetectChargerDamageSnapshot[victim].lastRawDamage = damage;

		if (!IsValidSurvivor(attacker))
		{
			return;
		}

		int appliedDamage = RoundToFloor(damage);
		int postHealth = GetClientHealth(victim);
		Detect_HandleChargerHurt(victim, attacker, damagetype, appliedDamage, postHealth);
	}
}

void Detect_CaptureDamageObservation(Event event, SkillsDamageObservation observation)
{
	observation.victim = GetClientOfUserId(event.GetInt("userid"));
	observation.attacker = GetClientOfUserId(event.GetInt("attacker"));
	observation.damage = event.GetInt("dmg_health");
	observation.damageType = event.GetInt("type");
	observation.hitgroup = event.GetInt("hitgroup");
	event.GetString("weapon", observation.weapon, sizeof(observation.weapon));
	observation.weaponId = Skills_GetWeaponIdFromEventName(observation.weapon);
	observation.entityId = event.GetInt("entityid");
}

void Detect_CaptureDeathObservation(Event event, SkillsDeathObservation observation)
{
	observation.victim = GetClientOfUserId(event.GetInt("userid"));
	observation.attacker = GetClientOfUserId(event.GetInt("attacker"));
	observation.damage = event.GetInt("dmg_health");
	event.GetString("weapon", observation.weapon, sizeof(observation.weapon));
	observation.headshot = event.GetBool("headshot");
}
