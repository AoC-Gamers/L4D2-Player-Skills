// Private detector ownership: hunter

void Detect_LogHunterSkeetDecision(int hunter, int attacker, const char[] stage, const char[] detail)
{
	if (!Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		return;
	}

	char hunterName[64];
	char attackerName[64];
	if (IsValidClient(hunter))
	{
		if (IsFakeClient(hunter))
		{
			strcopy(hunterName, sizeof(hunterName), "Hunter (IA)");
		}
		else
		{
			FormatEx(hunterName, sizeof(hunterName), "Hunter (%N)", hunter);
		}
	}
	else
	{
		strcopy(hunterName, sizeof(hunterName), "Hunter");
	}
	if (IsValidClient(attacker))
	{
		FormatEx(attackerName, sizeof(attackerName), "%N", attacker);
	}
	else
	{
		strcopy(attackerName, sizeof(attackerName), "<none>");
	}

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Hunter skeet decision. hunter=%d hunter_name=%s attacker=%d attacker_name=%s stage=%s %s",
		hunter,
		hunterName,
		attacker,
		attackerName,
		stage,
		detail);
}

void Detect_TryEmitHunterSkeetMelee(int hunter, int attacker, bool headshot, int hunterHealthBeforeDamage)
{
	Detect_LogHunterSkeetDecision(hunter, attacker, "melee", "classified_as=HunterSkeetMelee");
	int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeetMelee);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		g_SkillEvents[eventIndex].actor.Capture(attacker);
		g_SkillEvents[eventIndex].victim.Capture(hunter);
		g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
		g_SkillEvents[eventIndex].damage = hunterHealthBeforeDamage;
		g_SkillEvents[eventIndex].actorDamage = hunterHealthBeforeDamage;
		g_SkillEvents[eventIndex].shots = 1;
		int meleeAssistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, hunter, attacker);
		g_SkillEvents[eventIndex].perfect = (g_SkillEvents[eventIndex].chipDamage == 0) && meleeAssistsFound == 0;
		g_SkillEvents[eventIndex].headshot = headshot;
		Detect_LogSkeetQuality(hunter, attacker, "HunterSkeetMelee", "melee_emit", eventIndex);

		Action meleeResult = API_FireSkillDetected(eventId, L4D2Skill_HunterSkeetMelee);
		if (meleeResult < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
	}

	Detect_MarkSiLifeKillSuppressed(hunter);
}

void Detect_TryEmitHunterSkeetRanged(int hunter, int attacker, bool headshot, const char[] weapon, int hunterHealthBeforeDamage, int hunterBaselineHealth, float rawDamage)
{
	bool sniperSkeet = headshot && Detect_IsSkeetWeaponSniper(weapon);
	bool glSkeet = Detect_IsSkeetWeaponGL(weapon);
	L4D2WeaponId rangedWeaponId = view_as<L4D2WeaponId>(Skills_GetWeaponIdFromEventName(weapon));
	bool qualifiesAtBaseline = rawDamage >= float(hunterBaselineHealth);
	char hunterDecision[256];
	FormatEx(hunterDecision, sizeof(hunterDecision),
		"sniper=%d gl=%d qualifies_at_baseline=%d raw=%.1f baseline=%d",
		sniperSkeet ? 1 : 0,
		glSkeet ? 1 : 0,
		qualifiesAtBaseline ? 1 : 0,
		rawDamage,
		hunterBaselineHealth);
	Detect_LogHunterSkeetDecision(hunter, attacker, "ranged", hunterDecision);
	if (!qualifiesAtBaseline)
	{
		return;
	}

	Detect_LogHunterSkeetDecision(hunter, attacker, "ranged", "classified_as=HunterSkeet");
	int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeet);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		g_SkillEvents[eventIndex].actor.Capture(attacker);
		g_SkillEvents[eventIndex].victim.Capture(hunter);
		g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
		g_SkillEvents[eventIndex].damage = hunterHealthBeforeDamage;
		g_SkillEvents[eventIndex].actorDamage = hunterHealthBeforeDamage;
		g_SkillEvents[eventIndex].actorWeaponId = rangedWeaponId;
		g_SkillEvents[eventIndex].shots = 1;
		g_SkillEvents[eventIndex].headshot = headshot;
		g_SkillEvents[eventIndex].sniper = sniperSkeet;
		g_SkillEvents[eventIndex].grenadeLauncher = glSkeet;
		int pounceAssistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, hunter, attacker);
		g_SkillEvents[eventIndex].perfect = (g_SkillEvents[eventIndex].chipDamage == 0) && pounceAssistsFound == 0;
		Detect_LogSkeetQuality(hunter, attacker, "HunterSkeet", "ranged_emit", eventIndex);

		Action rangedResult = API_FireSkillDetected(eventId, L4D2Skill_HunterSkeet);
		if (rangedResult < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
	}

	Detect_MarkSiLifeKillSuppressed(hunter);
}

void Detect_TryEmitHunterSkeetShotgun(int hunter, int attacker, bool headshot)
{
	int interruptDamage = g_cvDetectHunterSkeetShotgunInterrupt != null ? g_cvDetectHunterSkeetShotgunInterrupt.IntValue : 0;
	int killerDamage = Detect_GetHunterBlastDamageByAttacker(hunter, attacker);
	int teamDamage = g_DetectHunterShotWindow[hunter].teamBlastDamage;
	int shots = Detect_GetHunterShotCountByAttacker(hunter, attacker);
	int overkillDamage = g_DetectHunterShotWindow[hunter].overkillDamage;
	int potentialKillerDamage = killerDamage + overkillDamage;
	int potentialTeamDamage = teamDamage + overkillDamage;
	bool interruptDisabled = interruptDamage <= 0;
	bool isSingleSkeet = interruptDisabled || potentialKillerDamage >= interruptDamage;
	bool isTeamSkeet = !interruptDisabled && potentialTeamDamage > potentialKillerDamage && potentialTeamDamage >= interruptDamage;
	char hunterDecision[256];
	FormatEx(hunterDecision, sizeof(hunterDecision),
		"interrupt=%d disabled=%d killer_damage=%d team_damage=%d overkill=%d potential_killer=%d potential_team=%d single=%d team=%d",
		interruptDamage,
		interruptDisabled ? 1 : 0,
		killerDamage,
		teamDamage,
		overkillDamage,
		potentialKillerDamage,
		potentialTeamDamage,
		isSingleSkeet ? 1 : 0,
		isTeamSkeet ? 1 : 0);
	Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun", hunterDecision);

	if (!(isSingleSkeet || isTeamSkeet))
	{
		Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun", "classified_as=none");
		return;
	}

	Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun", isTeamSkeet ? "classified_as=HunterSkeet(team)" : "classified_as=HunterSkeet(single)");
	int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeet);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		g_SkillEvents[eventIndex].actor.Capture(attacker);
		g_SkillEvents[eventIndex].victim.Capture(hunter);
		g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
		g_SkillEvents[eventIndex].damage = isTeamSkeet ? potentialTeamDamage : potentialKillerDamage;
		g_SkillEvents[eventIndex].actorDamage = potentialKillerDamage;
		g_SkillEvents[eventIndex].actorWeaponId = Detect_GetLastWeaponId(attacker);
		g_SkillEvents[eventIndex].shots = shots;
		g_SkillEvents[eventIndex].headshot = headshot;
		int pounceAssistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, hunter, attacker);
		g_SkillEvents[eventIndex].perfect = shots == 1
			&& g_SkillEvents[eventIndex].chipDamage == 0
			&& pounceAssistsFound == 0
			&& !isTeamSkeet;
		Detect_LogSkeetQuality(hunter, attacker, "HunterSkeet", isTeamSkeet ? "shotgun_team_emit" : "shotgun_emit", eventIndex);

		Action result = API_FireSkillDetected(eventId, g_SkillEvents[eventIndex].type);
		if (result < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
	}

	Detect_MarkSiLifeKillSuppressed(hunter);
}

void Detect_TryEmitHunterSkeetShotgunFallback(int hunter, int attacker, bool headshot, int hunterHealthBeforeDamage)
{
	// Some shotgun kills land entirely through life-kill accounting without a
	// stable blast window. Keep this fallback so single-shot skeets survive
	// event ordering differences instead of degrading to HunterKill.
	int interruptDamage = g_cvDetectHunterSkeetShotgunInterrupt != null ? g_cvDetectHunterSkeetShotgunInterrupt.IntValue : 0;
	int killerLifeDamage = Detect_GetSiLifeDamageByAttacker(hunter, attacker);
	int killerLifeShots = Detect_GetSiLifeShotsByAttacker(hunter, attacker);
	bool interruptDisabled = interruptDamage <= 0;
	char hunterDecision[256];
	FormatEx(hunterDecision, sizeof(hunterDecision),
		"fallback_shotgun life_damage=%d life_shots=%d interrupt=%d disabled=%d",
		killerLifeDamage,
		killerLifeShots,
		interruptDamage,
		interruptDisabled ? 1 : 0);
	Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun_fallback", hunterDecision);

	if (!(killerLifeShots == 1 && (interruptDisabled || killerLifeDamage >= interruptDamage)))
	{
		return;
	}

	Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun_fallback", "classified_as=HunterSkeet(single_lifekill)");
	int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeet);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		int fallbackEffectiveDamage = hunterHealthBeforeDamage > 0
			? hunterHealthBeforeDamage
			: Skills_GetSpecialMaxHealth(L4D2ZombieClass_Hunter);
		g_SkillEvents[eventIndex].actor.Capture(attacker);
		g_SkillEvents[eventIndex].victim.Capture(hunter);
		g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
		g_SkillEvents[eventIndex].damage = fallbackEffectiveDamage;
		g_SkillEvents[eventIndex].actorDamage = fallbackEffectiveDamage;
		g_SkillEvents[eventIndex].actorWeaponId = Detect_GetSiLifeWeaponIdByAttacker(hunter, attacker);
		g_SkillEvents[eventIndex].shots = killerLifeShots;
		g_SkillEvents[eventIndex].headshot = headshot;
		int pounceAssistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, hunter, attacker);
		g_SkillEvents[eventIndex].perfect = killerLifeShots == 1
			&& g_SkillEvents[eventIndex].chipDamage == 0
			&& pounceAssistsFound == 0;
		Detect_LogSkeetQuality(hunter, attacker, "HunterSkeet", "shotgun_fallback_emit", eventIndex);

		Action fallbackResult = API_FireSkillDetected(eventId, L4D2Skill_HunterSkeet);
		if (fallbackResult < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
	}

	Detect_MarkSiLifeKillSuppressed(hunter);
}

Action Detect_TimerEvaluateHunterDeath(Handle timer, any context)
{
	int userid = Detect_ReadDeferredClientUserId(view_as<DataPack>(context));
	if (userid <= 0)
	{
		return Plugin_Stop;
	}

	// Hunter death is evaluated out-of-frame because shotgun pellets, pounce-end
	// state and player_death ordering are not stable in the same tick.
	if (!Skills_IsRoundLive())
	{
		return Plugin_Stop;
	}

	int hunter = GetClientOfUserId(userid);
	if (hunter < 1 || hunter > MaxClients)
	{
		return Plugin_Stop;
	}

	if (!g_DetectPendingHunterDeath[hunter].queued)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter death timer aborted. hunter=%d userid=%d reason=not_pending",
			hunter,
			userid);
		return Plugin_Stop;
	}

	g_DetectPendingHunterDeath[hunter].queued = false;
	bool headshot = Detect_ResolveHeadshot(
		hunter,
		GetClientOfUserId(g_DetectPendingHunterDeath[hunter].attackerUserId),
		g_DetectPendingHunterDeath[hunter].headshot);
	g_DetectPendingHunterDeath[hunter].headshot = false;

	int attacker = GetClientOfUserId(g_DetectPendingHunterDeath[hunter].attackerUserId);
	g_DetectPendingHunterDeath[hunter].attackerUserId = 0;
	char weapon[64];
	strcopy(weapon, sizeof(weapon), g_DetectPendingHunterDeath[hunter].weapon);
	g_DetectPendingHunterDeath[hunter].weapon[0] = '\0';

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Hunter death timer firing. hunter=%d attacker=%d pending=%d",
		hunter,
		attacker,
		g_DetectPendingHunterDeath[hunter].queued ? 1 : 0);

	if (!IsValidZombieClass(hunter, L4D2ZombieClass_Hunter))
	{
		Detect_ResetHunter(hunter);
		Detect_ResetSiLifeKillTrack(hunter);
		return Plugin_Stop;
	}

	bool shouldEmitSiLifeKill = IsValidSurvivor(attacker) && Detect_IsTrackableSiLifeKillClass(hunter);
	int hunterHealthBeforeDamage = 0;
	bool hunterWasPouncingAtDeath = false;

	if (shouldEmitSiLifeKill)
	{
		hunterHealthBeforeDamage = g_DetectHunterDamageSnapshot[hunter].lastHealthBeforeDamage > 0
			? g_DetectHunterDamageSnapshot[hunter].lastHealthBeforeDamage
			: g_DetectHunterDamageSnapshot[hunter].lastHealth;
		int hunterBaselineHealth = g_iDetectHunterSpawnHealth[hunter] > 0
			? g_iDetectHunterSpawnHealth[hunter]
			: hunterHealthBeforeDamage;
		if (hunterBaselineHealth <= 0)
		{
			hunterBaselineHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Hunter);
		}
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter decision source. hunter=%d attacker=%d lastHealthBefore=%d lastHealth=%d spawnHealth=%d chosenHealthBefore=%d chosenBaseline=%d",
			hunter,
			attacker,
			g_DetectHunterDamageSnapshot[hunter].lastHealthBeforeDamage,
			g_DetectHunterDamageSnapshot[hunter].lastHealth,
			g_iDetectHunterSpawnHealth[hunter],
			hunterHealthBeforeDamage,
			hunterBaselineHealth);
		int legacyChipDamage = hunterBaselineHealth - hunterHealthBeforeDamage;
		if (legacyChipDamage < 0)
		{
			legacyChipDamage = 0;
		}
		int snapshotChipDamage = Detect_GetSkeetQualitySnapshotDamageByAttacker(hunter, attacker);
		int snapshotChipShots = Detect_GetSkeetQualitySnapshotShotsByAttacker(hunter, attacker);

		float rawDamage = g_DetectHunterDamageSnapshot[hunter].lastRawDamage;
		if (g_DetectHunterDamageSnapshot[hunter].lastAttacker != attacker)
		{
			rawDamage = float(hunterHealthBeforeDamage);
		}

		bool killedPouncing = g_DetectHunterDamageSnapshot[hunter].killedAirbornePouncing
			|| g_DetectHunterShotWindow[hunter].killedPouncing
			|| Detect_IsHunterSkeetWindowActive(hunter);
		hunterWasPouncingAtDeath = killedPouncing;
		char hunterDecision[256];
		FormatEx(hunterDecision, sizeof(hunterDecision),
			"weapon=%s headshot=%d killedPouncing=%d health_before=%d baseline=%d legacy_chip=%d snapshot_chip=%d snapshot_shots=%d raw=%.1f team_shot=%d killer_shot=%d shots=%d",
			weapon,
			headshot ? 1 : 0,
			killedPouncing ? 1 : 0,
			hunterHealthBeforeDamage,
			hunterBaselineHealth,
			legacyChipDamage,
			snapshotChipDamage,
			snapshotChipShots,
			rawDamage,
			g_DetectHunterShotWindow[hunter].teamBlastDamage,
			Detect_GetHunterBlastDamageByAttacker(hunter, attacker),
			Detect_GetHunterShotCountByAttacker(hunter, attacker));
		Detect_LogHunterSkeetDecision(hunter, attacker, "start", hunterDecision);

		if (killedPouncing && Detect_IsSkeetWeaponMelee(weapon))
		{
			Detect_TryEmitHunterSkeetMelee(hunter, attacker, headshot, hunterHealthBeforeDamage);
		}

		bool sniperSkeet = killedPouncing && headshot && Detect_IsSkeetWeaponSniper(weapon);
		bool glSkeet = killedPouncing && Detect_IsSkeetWeaponGL(weapon);
		if (!g_bDetectSuppressSiLifeKill[hunter] && (sniperSkeet || glSkeet))
		{
			Detect_TryEmitHunterSkeetRanged(hunter, attacker, headshot, weapon, hunterHealthBeforeDamage, hunterBaselineHealth, rawDamage);
		}

		if (!g_bDetectSuppressSiLifeKill[hunter] && hunterWasPouncingAtDeath && g_DetectHunterShotWindow[hunter].teamBlastDamage > 0)
		{
			Detect_TryEmitHunterSkeetShotgun(hunter, attacker, headshot);
		}

		if (!g_bDetectSuppressSiLifeKill[hunter]
			&& killedPouncing
			&& Skills_IsShotgunWeaponId(Skills_GetWeaponIdFromEventName(weapon))
			&& g_DetectHunterShotWindow[hunter].teamBlastDamage == 0)
		{
			Detect_TryEmitHunterSkeetShotgunFallback(hunter, attacker, headshot, hunterHealthBeforeDamage);
		}

		Detect_LogHunterSkeetDecision(hunter, attacker, "fallback", g_bDetectSuppressSiLifeKill[hunter] ? "classified_as=suppressed" : "classified_as=HunterKill");
		if (!g_bDetectSuppressSiLifeKill[hunter])
		{
			Detect_EmitHunterLifeKill(
				hunter,
				attacker,
				hunterHealthBeforeDamage > 0 ? hunterHealthBeforeDamage : Skills_GetSpecialMaxHealth(L4D2ZombieClass_Hunter),
				headshot);
		}
	}

	Detect_ResetHunter(hunter);
	Detect_ResetSiLifeKillTrack(hunter);
	return Plugin_Stop;
}

void Detect_EventPounceStopped(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int clearer = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	int hunter = Detect_GetCurrentPinnedAttacker(victim);
	if (!IsValidZombieClass(hunter, L4D2ZombieClass_Hunter))
	{
		return;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear pounce_stopped event. clearer=%d victim=%d pin_pinner=%d pin_victim=%d",
			clearer,
			victim,
			Detect_GetCurrentPinnedAttacker(victim),
			Detect_GetCurrentPinnedVictim(hunter));
	}
}

void Detect_EventPounceEnd(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int hunter = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	bool trackedHunter = IsValidZombieClass(hunter, L4D2ZombieClass_Hunter);
	if (!trackedHunter && IsValidSurvivor(victim))
	{
		int pinner = Detect_GetCurrentPinnedAttacker(victim);
		trackedHunter = IsValidZombieClass(pinner, L4D2ZombieClass_Hunter);
	}

	if (!trackedHunter)
	{
		return;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear pounce_end event. hunter=%d victim=%d pin_victim=%d",
			hunter,
			victim,
			Detect_GetCurrentPinnedVictim(hunter));
	}
}

void Detect_HandleHunterDeath(SkillsDeathObservation observation, int victim, int attacker, bool shouldEmitSiLifeKill)
{
	if (shouldEmitSiLifeKill)
	{
		char weapon[64];
		strcopy(weapon, sizeof(weapon), observation.weapon);
		g_DetectPendingHunterDeath[victim].queued = true;
		g_DetectPendingHunterDeath[victim].headshot = Detect_ResolveHeadshot(victim, attacker, observation.headshot);
		g_DetectPendingHunterDeath[victim].attackerUserId = GetClientUserId(attacker);
		strcopy(g_DetectPendingHunterDeath[victim].weapon, sizeof(g_DetectPendingHunterDeath[].weapon), weapon);
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter death queued. hunter=%d attacker=%d delay=0.10 weapon=%s headshot=%d team_shot=%d killer_shot=%d",
			victim,
			attacker,
			weapon,
			g_DetectPendingHunterDeath[victim].headshot ? 1 : 0,
			g_DetectHunterShotWindow[victim].teamBlastDamage,
			Detect_GetHunterBlastDamageByAttacker(victim, attacker));
		Detect_QueueClientTimer(0.1, Detect_TimerEvaluateHunterDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	Detect_ResetHunter(victim);
	Detect_ResetSiLifeKillTrack(victim);
}

void Detect_HandleHunterDamagePost(int victim, int attacker, float damage, int damagetype)
{
	g_DetectHunterDamageSnapshot[victim].lastAttacker = attacker;
	g_DetectHunterDamageSnapshot[victim].lastDamageType = damagetype;
	g_DetectHunterDamageSnapshot[victim].lastRawDamage = damage;

	if (!IsValidSurvivor(attacker))
	{
		return;
	}

	int appliedDamage = RoundToFloor(damage);
	if (appliedDamage <= 0)
	{
		return;
	}

	int slot = Detect_FindOrCreateHunterShotWindowSlot(victim, attacker);
	if (slot == -1)
	{
		return;
	}

	if (!g_DetectHunterShotWindow[victim].entries[slot].shotCounted)
	{
		g_DetectHunterShotWindow[victim].entries[slot].cumulativeShots++;
		g_DetectHunterShotWindow[victim].entries[slot].shotCounted = true;
	}

	int healthBeforeDamage = g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage > 0
		? g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage
		: g_DetectHunterDamageSnapshot[victim].lastHealth;
	if (healthBeforeDamage > 0 && appliedDamage > healthBeforeDamage)
	{
		g_DetectHunterShotWindow[victim].overkillDamage = appliedDamage - healthBeforeDamage;
		appliedDamage = healthBeforeDamage;
	}

	if (g_DetectHunterShotWindow[victim].entries[slot].activeBlastDamage > 0
		&& (GetGameTime() - g_DetectHunterShotWindow[victim].entries[slot].activeBlastStart) > DETECT_SHOTGUN_BLAST_TIME)
	{
		g_DetectHunterShotWindow[victim].entries[slot].activeBlastDamage = 0;
		g_DetectHunterShotWindow[victim].entries[slot].activeBlastStart = 0.0;
	}

	int postHealth = GetClientHealth(victim);
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		bool airbornePouncing = Detect_IsHunterSkeetWindowActive(victim);
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter post-damage snapshot. hunter=%d attacker=%d applied=%d pre=%d post=%d raw=%.1f pouncing=%d effective_pouncing=%d airborne_pouncing=%d team_shot=%d killer_shot=%d",
			victim,
			attacker,
			appliedDamage,
			healthBeforeDamage,
			postHealth,
			damage,
			g_bDetectHunterPouncing[victim] ? 1 : 0,
			Detect_IsHunterEffectivelyPouncing(victim) ? 1 : 0,
			airbornePouncing ? 1 : 0,
			g_DetectHunterShotWindow[victim].teamBlastDamage,
			g_DetectHunterShotWindow[victim].entries[slot].activeBlastDamage);
	}

	bool airbornePouncing = Detect_IsHunterSkeetWindowActive(victim);
	if (postHealth <= 0 && airbornePouncing)
	{
		g_DetectHunterDamageSnapshot[victim].killedAirbornePouncing = true;
	}

	bool shotgunBlast = (damagetype & DMG_BUCKSHOT) != 0;
	if (!shotgunBlast
		&& IsValidSurvivor(attacker)
		&& Skills_IsShotgunWeaponId(g_iDetectLastWeaponId[attacker])
		&& (GetGameTime() - g_fDetectLastWeaponFireTime[attacker]) <= DETECT_SHOTGUN_BLAST_TIME)
	{
		shotgunBlast = true;
	}

	if (airbornePouncing && shotgunBlast)
	{
		if (g_DetectHunterShotWindow[victim].entries[slot].activeBlastStart == 0.0)
		{
			g_DetectHunterShotWindow[victim].entries[slot].activeBlastStart = GetGameTime();
		}

		g_DetectHunterShotWindow[victim].entries[slot].activeBlastDamage += appliedDamage;
		g_DetectHunterShotWindow[victim].teamBlastDamage += appliedDamage;

		if (postHealth <= 0)
		{
			g_DetectHunterShotWindow[victim].killedPouncing = true;
		}
	}

	g_DetectHunterShotWindow[victim].entries[slot].cumulativeDamage += appliedDamage;
	g_DetectHunterDamageSnapshot[victim].lastHealth = postHealth > 0 ? postHealth : 0;
}

void Detect_SetHunterPouncing(int hunter, bool state)
{
	g_bDetectHunterPouncing[hunter] = state;
	if (state)
	{
		g_fDetectHunterPounceSeenAt[hunter] = GetGameTime();
	}
}

bool Detect_IsHunterEffectivelyPouncing(int hunter)
{
	if (g_bDetectHunterPouncing[hunter])
	{
		g_fDetectHunterPounceSeenAt[hunter] = GetGameTime();
		return true;
	}

	return g_fDetectHunterPounceSeenAt[hunter] > 0.0
		&& (GetGameTime() - g_fDetectHunterPounceSeenAt[hunter]) <= L4D2_SKILLS_HUNTER_POUNCE_GRACE_TIME;
}

bool Detect_IsHunterAirborneForSkeet(int hunter)
{
	return hunter > 0
		&& hunter <= MaxClients
		&& IsClientInGame(hunter)
		&& IsPlayerAlive(hunter)
		&& !(GetEntityFlags(hunter) & FL_ONGROUND);
}

bool Detect_IsHunterSkeetWindowActive(int hunter)
{
	return Detect_IsHunterEffectivelyPouncing(hunter)
		&& Detect_IsHunterAirborneForSkeet(hunter);
}

void Detect_ResetHunterPounceState(int hunter)
{
	g_bDetectHunterPouncing[hunter] = false;
	g_fDetectHunterPounceSeenAt[hunter] = 0.0;
	g_DetectHunterShotWindow[hunter].teamBlastDamage = 0;
	g_DetectHunterShotWindow[hunter].overkillDamage = 0;
	g_DetectHunterShotWindow[hunter].killedPouncing = false;
	Detect_CloseSkeetQualityWindow(hunter);

	for (int attacker = 1; attacker <= MaxClients; attacker++)
	{
		int lifeSlot = Detect_FindSiLifeSlot(hunter, attacker);
		if (lifeSlot != -1)
		{
			g_DetectSiLife[hunter].entries[lifeSlot].shotCounted = false;
		}
		Detect_ResetShoveWindowEntryByAttacker(g_DetectHunterLastShove[hunter], attacker);
		Detect_ResetHunterShotWindowEntryByAttacker(hunter, attacker);
	}
}

void Detect_ResetHunter(int hunter)
{
	Detect_ResetHunterPounceState(hunter);
	g_DetectLeap[hunter].Reset();
	g_DetectPendingHunterDeath[hunter].Reset();
	g_iDetectHunterSpawnHealth[hunter] = 0;
	g_DetectHunterDamageSnapshot[hunter].Reset();
}

float Detect_GetLeapHeight(int attacker, int victim)
{
	float attackerOrigin[3];
	float victimOrigin[3];

	if (g_DetectLeap[attacker].originSet)
	{
		attackerOrigin[0] = g_DetectLeap[attacker].origin[0];
		attackerOrigin[1] = g_DetectLeap[attacker].origin[1];
		attackerOrigin[2] = g_DetectLeap[attacker].origin[2];
	}
	else
	{
		GetClientAbsOrigin(attacker, attackerOrigin);
	}

	GetClientAbsOrigin(victim, victimOrigin);

	float height = attackerOrigin[2] - victimOrigin[2];
	return height > 0.0 ? height : 0.0;
}

float Detect_GetLeapDistance(int attacker, int victim)
{
	float attackerOrigin[3];
	float victimOrigin[3];

	if (g_DetectLeap[attacker].originSet)
	{
		attackerOrigin[0] = g_DetectLeap[attacker].origin[0];
		attackerOrigin[1] = g_DetectLeap[attacker].origin[1];
		attackerOrigin[2] = g_DetectLeap[attacker].origin[2];
	}
	else
	{
		GetClientAbsOrigin(attacker, attackerOrigin);
	}

	GetClientAbsOrigin(victim, victimOrigin);
	return GetVectorDistance(attackerOrigin, victimOrigin);
}

float Detect_CalculateHunterPounceDamage(float distance)
{
	float minDistance = g_cvDetectMinPounceDistance != null ? g_cvDetectMinPounceDistance.FloatValue : 300.0;
	float maxDistance = g_cvDetectMaxPounceDistance != null ? g_cvDetectMaxPounceDistance.FloatValue : 1000.0;
	float maxBonusDamage = Skills_GetHunterMaxPounceBonusDamage();

	if (distance <= minDistance)
	{
		return 1.0;
	}

	if (distance >= maxDistance || maxDistance <= minDistance)
	{
		return 1.0 + maxBonusDamage;
	}

	float ratio = (distance - minDistance) / (maxDistance - minDistance);
	return 1.0 + (ratio * maxBonusDamage);
}

bool Detect_IsSkeetWeaponMelee(const char[] weapon)
{
	L4D2WeaponId weaponId = view_as<L4D2WeaponId>(Skills_GetWeaponIdFromEventName(weapon));
	return weaponId == L4D2WeaponId_Melee || weaponId == L4D2WeaponId_Chainsaw || StrEqual(weapon, "melee");
}

bool Detect_IsSkeetWeaponSniper(const char[] weapon)
{
	L4D2WeaponId weaponId = view_as<L4D2WeaponId>(Skills_GetWeaponIdFromEventName(weapon));
	return weaponId == L4D2WeaponId_HuntingRifle
		|| weaponId == L4D2WeaponId_SniperMilitary
		|| weaponId == L4D2WeaponId_SniperAWP
		|| weaponId == L4D2WeaponId_SniperScout
		|| weaponId == L4D2WeaponId_PistolMagnum;
}

bool Detect_IsSkeetWeaponGL(const char[] weapon)
{
	L4D2WeaponId weaponId = view_as<L4D2WeaponId>(Skills_GetWeaponIdFromEventName(weapon));
	return weaponId == L4D2WeaponId_GrenadeLauncher;
}

Action Timer_DetectHunterGroundedCheck(Handle timer, any context)
{
	int userid = Detect_ReadDeferredClientUserId(view_as<DataPack>(context));
	if (userid <= 0)
	{
		return Plugin_Stop;
	}

	int client = GetClientOfUserId(userid);
	if (client > 0 && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		return Plugin_Continue;
	}

	if (client > 0)
	{
		Detect_SetHunterPouncing(client, false);
	}

	return Plugin_Stop;
}
