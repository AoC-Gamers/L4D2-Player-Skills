#if defined _l4d2_player_skills_boss_witch_sp_included
	#endinput
#endif
#define _l4d2_player_skills_boss_witch_sp_included

void Boss_OnEntityCreated(int entity, const char[] classname)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	if (StrContains(classname, "witch", false) != -1)
	{
		int sessionIndex = Boss_EnsureWitchSession(entity);
		if (sessionIndex != -1)
		{
			Boss_HookWitchDamageEntity(sessionIndex, entity);
		}
	}
}

void Boss_OnSpawnWitchPost(int entity)
{
	if (!Skills_IsEnabled() || !IsWitchEntity(entity))
	{
		return;
	}

	int sessionIndex = Boss_EnsureWitchSession(entity);
	if (sessionIndex == -1)
	{
		return;
	}

	Boss_HookWitchDamageEntity(sessionIndex, entity);
}

	void Boss_EventWitchKilled(Event event)
	{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int witch = event.GetInt("witchid");
	int killer = GetClientOfUserId(event.GetInt("userid"));
	bool oneShot = event.GetBool("oneshot");
	bool meleeOnly = event.GetBool("melee_only");

	int sessionIndex = Boss_FindWitchSessionByEntity(witch);
	if (sessionIndex == -1)
	{
		sessionIndex = Boss_EnsureWitchSession(witch);
	}

	if (sessionIndex == -1)
	{
		return;
	}

	Boss_HookWitchDamageEntity(sessionIndex, witch);

		// If the Witch session already produced a visible announce path (for example
		// the remaining-health summary triggered on incap), do not emit an additional
		// death-side announce for the same Witch lifecycle.
		if (g_BossSessions[sessionIndex].printed)
		{
			g_BossSessions[sessionIndex].lastHealth = 0;
			g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
			Boss_FinalizeSession(sessionIndex);
			return;
		}

		if (IsValidTank(killer))
		{
			Announce_WitchKilledByTank(sessionIndex, killer);
			g_BossSessions[sessionIndex].printed = true;
			g_BossSessions[sessionIndex].lastHealth = 0;
			g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
			Boss_FinalizeSession(sessionIndex);
			return;
		}

	if (!IsValidSurvivor(killer))
	{
		Announce_WitchKilledByWorld(sessionIndex);
		g_BossSessions[sessionIndex].printed = true;
		g_BossSessions[sessionIndex].lastHealth = 0;
		g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
		Boss_FinalizeSession(sessionIndex);
		return;
	}

	g_BossSessions[sessionIndex].witch.pendingKillerUserid = GetClientUserId(killer);
	g_BossSessions[sessionIndex].witch.pendingWitchOneShot = oneShot;
	g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly = meleeOnly;
	// Witch kill classification is delayed for the same reason as Hunter death:
	// shotgun pellets and the final kill event do not always arrive in a stable
	// order, so the crown decision must run on the settled session state.
	CreateTimer(0.10, Boss_TimerEvaluateWitchDeath, g_BossSessions[sessionIndex].id, TIMER_FLAG_NO_MAPCHANGE);
	Skills_Debug(PlayerSkillsDebug_Boss, "Witch death queued. session=%d killer=%d oneshot=%d melee_only=%d delay=0.10", g_BossSessions[sessionIndex].id, killer, oneShot, meleeOnly);
}

Action Boss_TimerEvaluateWitchDeath(Handle timer, any data)
{
	if (!Skills_IsRoundLive())
	{
		Skills_Debug(PlayerSkillsDebug_Boss, "Witch death discarded. session=%d reason=not_live", data);
		return Plugin_Stop;
	}

	int sessionIndex = API_GetBossSessionIndexById(data);

	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| g_BossSessions[sessionIndex].id == 0
		|| g_BossSessions[sessionIndex].type != L4D2Boss_Witch)
	{
		Skills_Debug(PlayerSkillsDebug_Boss, "Witch death discarded. session=%d reason=stale_session", data);
		return Plugin_Stop;
	}

		if (g_BossSessions[sessionIndex].printed)
		{
			Skills_Debug(PlayerSkillsDebug_Boss, "Witch death timer continuing to finalize. session=%d reason=already_printed", g_BossSessions[sessionIndex].id);
			g_BossSessions[sessionIndex].lastHealth = 0;
			g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
			g_BossSessions[sessionIndex].witch.pendingKillerUserid = 0;
			g_BossSessions[sessionIndex].witch.pendingWitchOneShot = false;
			g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly = false;
			Boss_FinalizeSession(sessionIndex);
			return Plugin_Stop;
		}

	int killer = GetClientOfUserId(g_BossSessions[sessionIndex].witch.pendingKillerUserid);
	if (IsValidSurvivor(killer))
	{
		Boss_CreateWitchDeadEvent(sessionIndex, killer);
	}

		if (g_BossSessions[sessionIndex].printed)
		{
			g_BossSessions[sessionIndex].lastHealth = 0;
			g_BossSessions[sessionIndex].witch.pendingKillerUserid = 0;
			g_BossSessions[sessionIndex].witch.pendingWitchOneShot = false;
			g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly = false;
			g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
			Boss_FinalizeSession(sessionIndex);
			return Plugin_Stop;
		}

		if (g_BossSessions[sessionIndex].witch.crownDetected)
		{
			g_BossSessions[sessionIndex].lastHealth = 0;
			g_BossSessions[sessionIndex].printed = true;
			g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
			g_BossSessions[sessionIndex].witch.pendingKillerUserid = 0;
			g_BossSessions[sessionIndex].witch.pendingWitchOneShot = false;
			g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly = false;
			Boss_FinalizeSession(sessionIndex);
			return Plugin_Stop;
		}

	g_BossSessions[sessionIndex].lastHealth = 0;
	g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
	g_BossSessions[sessionIndex].witch.pendingKillerUserid = 0;
	g_BossSessions[sessionIndex].witch.pendingWitchOneShot = false;
	g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly = false;
	Boss_FinalizeSession(sessionIndex);
	return Plugin_Stop;
}

int Boss_EnsureWitchSession(int entity)
{
	if (!IsWitchEntity(entity))
	{
		return -1;
	}

	int health = GetEntProp(entity, Prop_Data, "m_iHealth");
	if (health <= 0)
	{
		return -1;
	}

	int sessionIndex = Boss_FindWitchSessionByEntity(entity);
	if (sessionIndex != -1)
	{
		Boss_HookWitchDamageEntity(sessionIndex, entity);
		return sessionIndex;
	}

	int slot = Boss_FindFreeSession();
	if (slot == -1)
	{
		Skills_Debug(PlayerSkillsDebug_Boss, "No free boss session slot for Witch entity=%d", entity);
		return -1;
	}

	int maxHealth = Skills_GetWitchMaxHealth();
	L4D2BossSession(slot).Start(L4D2Boss_Witch, entity, 0, maxHealth);
	Boss_HookWitchDamageEntity(slot, entity);
	Skills_Debug(PlayerSkillsDebug_Boss, "Started Witch session. session=%d entity=%d maxhp=%d", g_BossSessions[slot].id, entity, maxHealth);
	return slot;
}

void Boss_HookWitchDamageEntity(int sessionIndex, int witch)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || !IsWitchEntity(witch))
	{
		return;
	}

	if (g_BossSessions[sessionIndex].witch.damageHooksAttached)
	{
		return;
	}

	SDKHook(witch, SDKHook_OnTakeDamage, Boss_OnWitchTakeDamage);
	SDKHook(witch, SDKHook_OnTakeDamagePost, Boss_OnWitchTakeDamagePost);
	g_BossSessions[sessionIndex].witch.damageHooksAttached = true;
}

void Boss_OpenWitchCrownQualityWindow(int sessionIndex)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES)
	{
		return;
	}

	g_BossSessions[sessionIndex].witch.crownQualityWindowActive = true;
	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		g_BossSessions[sessionIndex].witch.crownQualityUserids[entry] = 0;
		g_BossSessions[sessionIndex].witch.crownQualityAccountIds[entry] = 0;
		g_BossSessions[sessionIndex].witch.crownQualityBots[entry] = false;
		g_BossSessions[sessionIndex].witch.crownQualitySurvivorCharacters[entry] = L4D2Util_SurvivorCharacter_Invalid;
		g_BossSessions[sessionIndex].witch.crownQualityDamage[entry] = 0;
		g_BossSessions[sessionIndex].witch.crownQualityShots[entry] = 0;

		if (!g_BossDamage[sessionIndex][entry].active)
		{
			continue;
		}

		g_BossSessions[sessionIndex].witch.crownQualityUserids[entry] = g_BossDamage[sessionIndex][entry].player.userid;
		g_BossSessions[sessionIndex].witch.crownQualityAccountIds[entry] = g_BossDamage[sessionIndex][entry].player.accountId;
		g_BossSessions[sessionIndex].witch.crownQualityBots[entry] = g_BossDamage[sessionIndex][entry].player.bot;
		g_BossSessions[sessionIndex].witch.crownQualitySurvivorCharacters[entry] = g_BossDamage[sessionIndex][entry].player.character;
		g_BossSessions[sessionIndex].witch.crownQualityDamage[entry] = g_BossDamage[sessionIndex][entry].damage;
		g_BossSessions[sessionIndex].witch.crownQualityShots[entry] = g_BossDamage[sessionIndex][entry].shots;
	}
}

void Boss_LogWitchCrownQuality(int sessionIndex, int killer, int eventIndex, const char[] stage)
{
	if (!Skills_IsDebugEnabled(PlayerSkillsDebug_Boss)
		|| sessionIndex < 0
		|| sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| eventIndex < 0
		|| eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return;
	}

	char killerName[64];
	if (IsValidSurvivor(killer))
	{
		FormatEx(killerName, sizeof(killerName), "%N", killer);
	}
	else
	{
		strcopy(killerName, sizeof(killerName), "<none>");
	}

	int assistDamageTotal = 0;
	for (int i = 0; i < g_SkillEvents[eventIndex].assistsCount && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		assistDamageTotal += g_SkillEvents[eventIndex].assistDamage[i];
	}

	Skills_Debug(PlayerSkillsDebug_Boss,
		"Witch crown quality. session=%d killer=%d killer_name=%s stage=%s actor_damage=%d shots=%d actor_chip=%d actor_chip_shots=%d assist_damage=%d assists=%d chip=%d crown=%d perfect=%d oneshot=%d melee_only=%d",
		g_BossSessions[sessionIndex].id,
		killer,
		killerName,
		stage,
		g_SkillEvents[eventIndex].actorDamage,
		g_SkillEvents[eventIndex].shots,
		g_SkillEvents[eventIndex].actorChipDamage,
		g_SkillEvents[eventIndex].actorChipShots,
		assistDamageTotal,
		g_SkillEvents[eventIndex].assistsCount,
		g_SkillEvents[eventIndex].chipDamage,
		g_SkillEvents[eventIndex].crown ? 1 : 0,
		g_SkillEvents[eventIndex].perfect ? 1 : 0,
		g_BossSessions[sessionIndex].witch.pendingWitchOneShot ? 1 : 0,
		g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly ? 1 : 0);
}

int Boss_GetWitchCrownSnapshotDamageByAttacker(int sessionIndex, int attacker)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| !IsValidSurvivor(attacker)
		|| !g_BossSessions[sessionIndex].witch.crownQualityWindowActive)
	{
		return 0;
	}

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (Skills_IsClientMatchingIdentity(
			attacker,
			g_BossSessions[sessionIndex].witch.crownQualityAccountIds[entry],
			g_BossSessions[sessionIndex].witch.crownQualityBots[entry],
			g_BossSessions[sessionIndex].witch.crownQualitySurvivorCharacters[entry],
			g_BossSessions[sessionIndex].witch.crownQualityUserids[entry]))
		{
			return g_BossSessions[sessionIndex].witch.crownQualityDamage[entry];
		}
	}

	return 0;
}

int Boss_GetWitchCrownSnapshotShotsByAttacker(int sessionIndex, int attacker)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| !IsValidSurvivor(attacker)
		|| !g_BossSessions[sessionIndex].witch.crownQualityWindowActive)
	{
		return 0;
	}

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (Skills_IsClientMatchingIdentity(
			attacker,
			g_BossSessions[sessionIndex].witch.crownQualityAccountIds[entry],
			g_BossSessions[sessionIndex].witch.crownQualityBots[entry],
			g_BossSessions[sessionIndex].witch.crownQualitySurvivorCharacters[entry],
			g_BossSessions[sessionIndex].witch.crownQualityUserids[entry]))
		{
			return g_BossSessions[sessionIndex].witch.crownQualityShots[entry];
		}
	}

	return 0;
}

void Boss_AnnounceWitchRemainingHealth(int witch)
{
	int sessionIndex = Boss_FindWitchSessionByEntity(witch);
	if (sessionIndex == -1)
	{
		sessionIndex = Boss_EnsureWitchSession(witch);
	}

	if (sessionIndex == -1)
	{
		return;
	}

	if (IsWitchEntity(witch))
	{
		g_BossSessions[sessionIndex].lastHealth = GetEntProp(witch, Prop_Data, "m_iHealth");
	}

	Announce_WitchDamage(sessionIndex, true);
	g_BossSessions[sessionIndex].printed = true;
	g_BossSessions[sessionIndex].state = L4D2BossState_Printed;
}

void Boss_OnWitchSetHarasser(int witch, int victim)
{
	if (!Skills_IsEnabled() || !IsWitchEntity(witch))
	{
		return;
	}

	int sessionIndex = Boss_EnsureWitchSession(witch);
	if (sessionIndex == -1)
	{
		return;
	}

	Boss_HookWitchDamageEntity(sessionIndex, witch);
	g_BossSessions[sessionIndex].witch.startled = victim > 0;

	if (IsValidClient(victim))
	{
		g_BossSessions[sessionIndex].witch.harasser.Capture(victim);
	}

}

Action Boss_OnWitchTakeDamage(int witch, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!Skills_IsRoundLive() || !IsWitchEntity(witch))
	{
		return Plugin_Continue;
	}

	int sessionIndex = Boss_EnsureWitchSession(witch);
	if (sessionIndex == -1)
	{
		return Plugin_Continue;
	}

	if (g_BossSessions[sessionIndex].printed)
	{
		return Plugin_Continue;
	}

	g_BossSessions[sessionIndex].witch.lastHealthBeforeDamage = GetEntProp(witch, Prop_Data, "m_iHealth");
	g_BossSessions[sessionIndex].witch.lastShotAttacker = attacker;
	g_BossSessions[sessionIndex].witch.lastShotRawDamage = damage;
	g_BossSessions[sessionIndex].witch.lastDamageType = damagetype;
	bool shotgunBlast = (damagetype & DMG_BUCKSHOT) != 0;
	if (!shotgunBlast
		&& IsValidSurvivor(attacker)
		&& Skills_IsShotgunWeaponId(Detect_GetLastWeaponId(attacker))
		&& (GetGameTime() - Detect_GetLastWeaponFireTime(attacker)) <= L4D2_SKILLS_SHOTGUN_BLAST_TIME)
	{
		shotgunBlast = true;
	}

	g_BossSessions[sessionIndex].witch.lastShotIsShotgun = shotgunBlast;

	float now = GetGameTime();
	bool sameBlast = g_BossSessions[sessionIndex].witch.lastShotIsShotgun
		&& g_BossSessions[sessionIndex].witch.lastBlastStartTime > 0.0
		&& (now - g_BossSessions[sessionIndex].witch.lastBlastStartTime) <= L4D2_SKILLS_SHOTGUN_BLAST_TIME
		&& g_BossSessions[sessionIndex].witch.lastShotAttacker == attacker;

	if (!sameBlast)
	{
		g_BossSessions[sessionIndex].witch.lastBlastStartTime = now;
		g_BossSessions[sessionIndex].witch.lastBlastDamage = 0;
		g_BossSessions[sessionIndex].witch.lastBlastRawDamage = 0.0;
		if (shotgunBlast && IsValidSurvivor(attacker))
		{
			Boss_OpenWitchCrownQualityWindow(sessionIndex);
		}
	}

	return Plugin_Continue;
}

void Boss_OnWitchTakeDamagePost(int witch, int attacker, int inflictor, float damage, int damagetype)
{
	if (!Skills_IsRoundLive() || !IsWitchEntity(witch))
	{
		return;
	}

	int sessionIndex = Boss_EnsureWitchSession(witch);
	if (sessionIndex == -1)
	{
		return;
	}

	if (g_BossSessions[sessionIndex].printed)
	{
		return;
	}

	int roundedDamage = RoundToFloor(damage);
	if (roundedDamage <= 0)
	{
		return;
	}

	int effectiveDamage = roundedDamage;
	int maxHealth = g_BossSessions[sessionIndex].maxHealth;
	if (maxHealth > 0 && g_BossSessions[sessionIndex].totalDamage + effectiveDamage > maxHealth)
	{
		effectiveDamage = maxHealth - g_BossSessions[sessionIndex].totalDamage;
		if (effectiveDamage < 0)
		{
			effectiveDamage = 0;
		}
	}

	g_BossSessions[sessionIndex].witch.lastShotTime = GetGameTime();
	g_BossSessions[sessionIndex].witch.lastShotAttacker = attacker;
	g_BossSessions[sessionIndex].witch.lastShotDamage = effectiveDamage;
	g_BossSessions[sessionIndex].witch.lastShotRawDamage = damage;
	g_BossSessions[sessionIndex].witch.lastDamageType = damagetype;
	bool shotgunBlast = g_BossSessions[sessionIndex].witch.lastShotIsShotgun;
	if (!shotgunBlast
		&& IsValidSurvivor(attacker)
		&& Skills_IsShotgunWeaponId(Detect_GetLastWeaponId(attacker))
		&& (GetGameTime() - Detect_GetLastWeaponFireTime(attacker)) <= L4D2_SKILLS_SHOTGUN_BLAST_TIME)
	{
		shotgunBlast = true;
	}

	g_BossSessions[sessionIndex].witch.lastShotIsShotgun = shotgunBlast;
	bool countShot = !g_BossSessions[sessionIndex].witch.lastShotIsShotgun || g_BossSessions[sessionIndex].witch.lastBlastDamage <= 0;

	if (g_BossSessions[sessionIndex].witch.lastShotIsShotgun)
	{
		g_BossSessions[sessionIndex].witch.lastBlastDamage += effectiveDamage;
		g_BossSessions[sessionIndex].witch.lastBlastRawDamage += damage;
	}
	else
	{
		g_BossSessions[sessionIndex].witch.lastBlastStartTime = 0.0;
		g_BossSessions[sessionIndex].witch.lastBlastDamage = effectiveDamage;
		g_BossSessions[sessionIndex].witch.lastBlastRawDamage = damage;
	}

	if (!IsValidSurvivor(attacker))
	{
		return;
	}

	if (effectiveDamage <= 0)
	{
		return;
	}

	L4D2BossSession(sessionIndex).AddDamage(attacker, effectiveDamage, countShot);
	int health = GetEntProp(witch, Prop_Data, "m_iHealth");
	g_BossSessions[sessionIndex].lastHealth = health > 0 ? health : 0;
}

void Boss_CreateWitchDeadEvent(int sessionIndex, int killer)
{
	if (!IsValidSurvivor(killer))
	{
		return;
	}

	Boss_ConsolidateDamageEntries(sessionIndex);

	int killerTotalDamage = Boss_GetDamageEntryDamage(sessionIndex, killer);
	int killerShots = Boss_GetDamageEntryShots(sessionIndex, killer);
	int killerSnapshotDamage = Boss_GetWitchCrownSnapshotDamageByAttacker(sessionIndex, killer);
	int killerSnapshotShots = Boss_GetWitchCrownSnapshotShotsByAttacker(sessionIndex, killer);
	int actualDamage = g_BossSessions[sessionIndex].witch.lastShotIsShotgun
		? g_BossSessions[sessionIndex].witch.lastBlastDamage
		: g_BossSessions[sessionIndex].witch.lastShotDamage;
	int missingHealth = g_BossSessions[sessionIndex].maxHealth - g_BossSessions[sessionIndex].totalDamage;
	bool recoveredDamage = false;
	bool recoveredShotgunBlast = false;
	if (g_BossSessions[sessionIndex].witch.lastShotAttacker == killer
		&& missingHealth > 0)
	{
		int damageEntry = Boss_FindOrCreateDamageEntry(sessionIndex, killer);
		if (damageEntry != -1)
		{
			if (!g_BossDamage[sessionIndex][damageEntry].active)
			{
				g_BossDamage[sessionIndex][damageEntry].active = true;
				g_BossDamage[sessionIndex][damageEntry].player.Capture(killer);
			}

			g_BossDamage[sessionIndex][damageEntry].damage += missingHealth;
			g_BossSessions[sessionIndex].totalDamage += missingHealth;
			killerTotalDamage += missingHealth;
			actualDamage += missingHealth;
			recoveredDamage = true;

			if (g_BossSessions[sessionIndex].witch.lastShotIsShotgun)
			{
				if (g_BossSessions[sessionIndex].witch.lastBlastDamage <= 0)
				{
					g_BossDamage[sessionIndex][damageEntry].shots += 1;
					killerShots += 1;
					recoveredShotgunBlast = true;
				}
			}
			else if (g_BossSessions[sessionIndex].witch.lastShotDamage <= 0)
			{
				g_BossDamage[sessionIndex][damageEntry].shots += 1;
				killerShots += 1;
			}
		}
	}
	if (actualDamage <= 0 && killerTotalDamage > 0)
	{
		actualDamage = killerTotalDamage;
	}
	if (killerShots <= 0 && actualDamage > 0)
	{
		killerShots = 1;
	}
	int preBlastDamage = g_BossSessions[sessionIndex].totalDamage - actualDamage;
	if (preBlastDamage < 0)
	{
		preBlastDamage = 0;
	}
	int preBlastHealth = g_BossSessions[sessionIndex].maxHealth - preBlastDamage;
	if (preBlastHealth < 0)
	{
		preBlastHealth = 0;
	}
	bool crown = g_BossSessions[sessionIndex].witch.lastShotAttacker == killer
		&& g_BossSessions[sessionIndex].witch.lastShotIsShotgun
		&& actualDamage >= preBlastHealth;

	L4D2SkillType eventType = crown ? L4D2Skill_WitchCrown : L4D2Skill_WitchDead;
	int eventId = Skills_CreateEvent(eventType);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

		g_SkillEvents[eventIndex].actor.Capture(killer);
		g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	g_SkillEvents[eventIndex].actorDamage = actualDamage;
	g_SkillEvents[eventIndex].damage = actualDamage;
	g_SkillEvents[eventIndex].actorChipDamage = 0;
	g_SkillEvents[eventIndex].actorChipShots = 0;
	g_SkillEvents[eventIndex].shots = killerShots;
	g_SkillEvents[eventIndex].crown = crown;
	g_SkillEvents[eventIndex].startled = g_BossSessions[sessionIndex].witch.startled;
	g_SkillEvents[eventIndex].actor2 = g_BossSessions[sessionIndex].id;

	if (g_SkillEvents[eventIndex].crown)
	{
		g_SkillEvents[eventIndex].shots = killerShots - killerSnapshotShots;
		if (g_SkillEvents[eventIndex].shots < 1 && actualDamage > 0)
		{
			g_SkillEvents[eventIndex].shots = 1;
		}

		Boss_FillWitchCrownAssistData(sessionIndex, killer, eventIndex);
		g_SkillEvents[eventIndex].actorChipDamage = killerSnapshotDamage;
		g_SkillEvents[eventIndex].actorChipShots = killerSnapshotShots;
		g_SkillEvents[eventIndex].chipDamage = g_SkillEvents[eventIndex].actorChipDamage + Boss_GetSkillEventAssistDamageTotal(eventIndex);
		g_SkillEvents[eventIndex].perfect = !g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly
			&& g_SkillEvents[eventIndex].shots == 1
			&& g_SkillEvents[eventIndex].actorChipDamage == 0
			&& g_SkillEvents[eventIndex].assistsCount == 0;
	}
	else
	{
		Boss_FillWitchAssistData(sessionIndex, killer, eventIndex);
		g_SkillEvents[eventIndex].chipDamage = 0;
		g_SkillEvents[eventIndex].perfect = false;
	}

	if (g_SkillEvents[eventIndex].crown)
	{
		g_BossSessions[sessionIndex].witch.crownDetected = true;
		g_BossSessions[sessionIndex].witch.crowner.Capture(killer);
	}

	Boss_LogWitchCrownQuality(sessionIndex, killer, eventIndex, "death_emit");

	Skills_Debug(PlayerSkillsDebug_Boss,
		"Witch dead event built. session=%d killer=%d damage=%d actor_damage=%d chip=%d actor_chip=%d actor_chip_shots=%d shots=%d killer_total=%d killer_shots=%d crown=%d perfect=%d assists=%d oneshot=%d melee_only=%d recovered=%d recovered_blast=%d shotgun=%d blast=%d shot=%d",
		g_BossSessions[sessionIndex].id,
		killer,
		g_SkillEvents[eventIndex].damage,
		g_SkillEvents[eventIndex].actorDamage,
		g_SkillEvents[eventIndex].chipDamage,
		g_SkillEvents[eventIndex].actorChipDamage,
		g_SkillEvents[eventIndex].actorChipShots,
		g_SkillEvents[eventIndex].shots,
		killerTotalDamage,
		killerShots,
		g_SkillEvents[eventIndex].crown,
		g_SkillEvents[eventIndex].perfect,
		g_SkillEvents[eventIndex].assistsCount,
		g_BossSessions[sessionIndex].witch.pendingWitchOneShot,
		g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly,
		recoveredDamage,
		recoveredShotgunBlast,
		g_BossSessions[sessionIndex].witch.lastShotIsShotgun,
		g_BossSessions[sessionIndex].witch.lastBlastDamage,
		g_BossSessions[sessionIndex].witch.lastShotDamage);

	Action result = API_FireSkillDetected(eventId, eventType);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Boss_FillWitchAssistData(int sessionIndex, int killer, int eventIndex)
{
	Boss_ConsolidateDamageEntries(sessionIndex);

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active
			|| g_BossDamage[sessionIndex][entry].damage <= 0
			|| g_BossDamage[sessionIndex][entry].player.IsSamePersistentPlayer(killer))
		{
			continue;
		}

		if (g_SkillEvents[eventIndex].assistsCount < L4D2_SKILLS_MAX_EVENT_ASSISTS)
		{
			int assistIndex = g_SkillEvents[eventIndex].assistsCount;
			g_SkillEvents[eventIndex].assists[assistIndex] = g_BossDamage[sessionIndex][entry].player;
			g_SkillEvents[eventIndex].assistDamage[assistIndex] = g_BossDamage[sessionIndex][entry].damage;
			g_SkillEvents[eventIndex].assistShots[assistIndex] = g_BossDamage[sessionIndex][entry].shots > 0 ? g_BossDamage[sessionIndex][entry].shots : 1;
			g_SkillEvents[eventIndex].assistsCount++;
		}
	}

	Boss_FinalizeWitchAssistData(eventIndex);
}

void Boss_FillWitchCrownAssistData(int sessionIndex, int killer, int eventIndex)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || !g_BossSessions[sessionIndex].witch.crownQualityWindowActive)
	{
		return;
	}

	g_SkillEvents[eventIndex].assistScope = L4D2SkillAssistScope_SkillWindow;

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		int assistDamage = g_BossSessions[sessionIndex].witch.crownQualityDamage[entry];
		if (assistDamage <= 0)
		{
			continue;
		}

		if (Skills_IsClientMatchingIdentity(
			killer,
			g_BossSessions[sessionIndex].witch.crownQualityAccountIds[entry],
			g_BossSessions[sessionIndex].witch.crownQualityBots[entry],
			g_BossSessions[sessionIndex].witch.crownQualitySurvivorCharacters[entry],
			g_BossSessions[sessionIndex].witch.crownQualityUserids[entry]))
		{
			continue;
		}

		if (g_SkillEvents[eventIndex].assistsCount >= L4D2_SKILLS_MAX_EVENT_ASSISTS)
		{
			break;
		}

		L4D2PlayerRef assister;
		if (!Skills_TryBuildPlayerRefFromIdentity(
			g_BossSessions[sessionIndex].witch.crownQualityAccountIds[entry],
			g_BossSessions[sessionIndex].witch.crownQualityBots[entry],
			g_BossSessions[sessionIndex].witch.crownQualitySurvivorCharacters[entry],
			g_BossSessions[sessionIndex].witch.crownQualityUserids[entry],
			assister))
		{
			continue;
		}

		int assistIndex = g_SkillEvents[eventIndex].assistsCount;
		g_SkillEvents[eventIndex].assists[assistIndex] = assister;
		g_SkillEvents[eventIndex].assistDamage[assistIndex] = assistDamage;
		g_SkillEvents[eventIndex].assistShots[assistIndex] = g_BossSessions[sessionIndex].witch.crownQualityShots[entry] > 0
			? g_BossSessions[sessionIndex].witch.crownQualityShots[entry]
			: 1;
		g_SkillEvents[eventIndex].assistsCount++;
	}

	Boss_FinalizeWitchAssistData(eventIndex);
}

void Boss_FinalizeWitchAssistData(int eventIndex)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return;
	}

	for (int pass = 0; pass < g_SkillEvents[eventIndex].assistsCount - 1; pass++)
	{
		for (int i = 0; i < g_SkillEvents[eventIndex].assistsCount - 1 - pass; i++)
		{
			if (g_SkillEvents[eventIndex].assistDamage[i] >= g_SkillEvents[eventIndex].assistDamage[i + 1])
			{
				continue;
			}

			L4D2PlayerRef refTemp;
			refTemp = g_SkillEvents[eventIndex].assists[i];
			int damageTemp = g_SkillEvents[eventIndex].assistDamage[i];
			int shotsTemp = g_SkillEvents[eventIndex].assistShots[i];

			g_SkillEvents[eventIndex].assists[i] = g_SkillEvents[eventIndex].assists[i + 1];
			g_SkillEvents[eventIndex].assistDamage[i] = g_SkillEvents[eventIndex].assistDamage[i + 1];
			g_SkillEvents[eventIndex].assistShots[i] = g_SkillEvents[eventIndex].assistShots[i + 1];

			g_SkillEvents[eventIndex].assists[i + 1] = refTemp;
			g_SkillEvents[eventIndex].assistDamage[i + 1] = damageTemp;
			g_SkillEvents[eventIndex].assistShots[i + 1] = shotsTemp;
		}
	}

	if (g_SkillEvents[eventIndex].assistsCount > 0)
	{
		g_SkillEvents[eventIndex].assister = g_SkillEvents[eventIndex].assists[0];
		g_SkillEvents[eventIndex].assisterDamage = g_SkillEvents[eventIndex].assistDamage[0];
		g_SkillEvents[eventIndex].assisterShots = g_SkillEvents[eventIndex].assistShots[0];
	}
}

void Boss_CreateWitchIncapEvent(int sessionIndex, int witch, int victim)
{
	if (!IsValidSurvivor(victim))
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_WitchIncap);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.client = witch;
	g_SkillEvents[eventIndex].actor.userid = 0;
	g_SkillEvents[eventIndex].actor.accountId = 0;
	g_SkillEvents[eventIndex].actor.bot = true;
	strcopy(g_SkillEvents[eventIndex].actor.name, sizeof(g_SkillEvents[eventIndex].actor.name), "Witch");
	strcopy(g_SkillEvents[eventIndex].actor.auth, sizeof(g_SkillEvents[eventIndex].actor.auth), "WITCH");

	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].startled = g_BossSessions[sessionIndex].witch.startled;
	g_SkillEvents[eventIndex].actor2 = g_BossSessions[sessionIndex].id;

	if (g_BossSessions[sessionIndex].lastHealth > 0)
	{
		g_SkillEvents[eventIndex].amount = g_BossSessions[sessionIndex].lastHealth;
	}

	Action result = API_FireSkillDetected(eventId, L4D2Skill_WitchIncap);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}
