// Private detector ownership: life kill

int Detect_GetSiAssistSlotCount()
{
	return Skills_GetTrackedSurvivorEntryCapacity();
}

int Detect_GetSiLifeSlotCount()
{
	return Skills_GetTrackedSurvivorEntryCapacity();
}

int Detect_GetShoveWindowSlotCount()
{
	return Skills_GetTrackedSurvivorEntryCapacity();
}

int Detect_FindShoveWindowSlot(DetectShoveWindowState state, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slotCount = Detect_GetShoveWindowSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (state.entries[i].attackerClient == attacker)
		{
			return i;
		}
	}

	return -1;
}

int Detect_FindOrCreateShoveWindowSlot(DetectShoveWindowState state, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slot = Detect_FindShoveWindowSlot(state, attacker);
	if (slot != -1)
	{
		return slot;
	}

	int slotCount = Detect_GetShoveWindowSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (state.entries[i].attackerClient == 0)
		{
			state.entries[i].attackerClient = attacker;
			state.entries[i].shovedAt = 0.0;
			return i;
		}
	}

	return -1;
}

void Detect_ResetShoveWindowEntryByAttacker(DetectShoveWindowState state, int attacker)
{
	int slot = Detect_FindShoveWindowSlot(state, attacker);
	if (slot == -1)
	{
		return;
	}

	state.entries[slot].Reset();
}

float Detect_GetLastShoveTime(DetectShoveWindowState state, int attacker)
{
	int slot = Detect_FindShoveWindowSlot(state, attacker);
	return slot == -1 ? 0.0 : state.entries[slot].shovedAt;
}

void Detect_SetLastShoveTime(DetectShoveWindowState state, int attacker, float shovedAt)
{
	int slot = Detect_FindOrCreateShoveWindowSlot(state, attacker);
	if (slot == -1)
	{
		return;
	}

	state.entries[slot].shovedAt = shovedAt;
}

int Detect_FindSiLifeSlot(int victim, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slotCount = Detect_GetSiLifeSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (g_DetectSiLife[victim].attackerClients[i] == attacker)
		{
			return i;
		}
	}

	return -1;
}

int Detect_FindOrCreateSiLifeSlot(int victim, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slot = Detect_FindSiLifeSlot(victim, attacker);
	if (slot != -1)
	{
		return slot;
	}

	int slotCount = Detect_GetSiLifeSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (g_DetectSiLife[victim].attackerClients[i] == 0
			&& g_DetectSiLife[victim].attackerUserids[i] == 0
			&& g_DetectSiLife[victim].attackerAccountIds[i] == 0
			&& !g_DetectSiLife[victim].attackerBots[i]
			&& g_DetectSiLife[victim].attackerSurvivorCharacters[i] == L4D2Util_SurvivorCharacter_Invalid)
		{
			g_DetectSiLife[victim].attackerClients[i] = attacker;
			g_DetectSiLife[victim].entries[i].Reset();
			return i;
		}
	}

	return -1;
}

void Detect_DetachSiLifeEntryByAttacker(int victim, int attacker)
{
	int slot = Detect_FindSiLifeSlot(victim, attacker);
	if (slot == -1)
	{
		return;
	}

	g_DetectSiLife[victim].attackerClients[slot] = 0;
	g_DetectSiLife[victim].entries[slot].shotCounted = false;
}

int Detect_GetHunterShotSlotCount()
{
	return Skills_GetTrackedSurvivorEntryCapacity();
}

int Detect_FindHunterShotWindowSlot(int victim, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slotCount = Detect_GetHunterShotSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (g_DetectHunterShotWindow[victim].attackerClients[i] == attacker)
		{
			return i;
		}
	}

	return -1;
}

int Detect_FindOrCreateHunterShotWindowSlot(int victim, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slot = Detect_FindHunterShotWindowSlot(victim, attacker);
	if (slot != -1)
	{
		return slot;
	}

	int slotCount = Detect_GetHunterShotSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (g_DetectHunterShotWindow[victim].attackerClients[i] == 0)
		{
			g_DetectHunterShotWindow[victim].attackerClients[i] = attacker;
			g_DetectHunterShotWindow[victim].entries[i].Reset();
			return i;
		}
	}

	return -1;
}

void Detect_ResetHunterShotWindowEntryByAttacker(int victim, int attacker)
{
	int slot = Detect_FindHunterShotWindowSlot(victim, attacker);
	if (slot == -1)
	{
		return;
	}

	g_DetectHunterShotWindow[victim].attackerClients[slot] = 0;
	g_DetectHunterShotWindow[victim].entries[slot].Reset();
}

bool Detect_IsTrackableSiLifeKillClass(int client)
{
	if (!IsValidInfected(client))
	{
		return false;
	}

	switch (GetClientZombieClass(client))
	{
		case L4D2ZombieClass_Smoker, L4D2ZombieClass_Boomer, L4D2ZombieClass_Hunter, L4D2ZombieClass_Spitter, L4D2ZombieClass_Jockey, L4D2ZombieClass_Charger:
		{
			return true;
		}
	}

	return false;
}

bool Detect_DidSiLifeLastShotHitHead(int victim, int attacker)
{
	int slot = Detect_FindSiLifeSlot(victim, attacker);
	if (slot == -1)
	{
		return false;
	}

	return g_DetectSiLife[victim].entries[slot].lastShotHitHead;
}

bool Detect_CanUseSiLifeHeadshotFallback(int victim, int attacker)
{
	int slot = Detect_FindSiLifeSlot(victim, attacker);
	if (slot == -1)
	{
		return false;
	}

	// The hitgroup fallback is only trustworthy for real shot weapons. Fire,
	// splash and other continuous damage paths may report head hitgroups without
	// meaning "headshot" semantically.
	return Skills_IsRangedShotWeaponId(g_DetectSiLife[victim].entries[slot].weaponId);
}

bool Detect_ResolveHeadshot(int victim, int attacker, bool eventHeadshot)
{
	if (eventHeadshot)
	{
		return true;
	}

	return Detect_CanUseSiLifeHeadshotFallback(victim, attacker)
		&& Detect_DidSiLifeLastShotHitHead(victim, attacker);
}

void Detect_ResetSiLifeKillTrack(int infected)
{
	if (infected < 1 || infected > MaxClients)
	{
		return;
	}

	g_DetectSiAssist[infected].Reset();
	g_DetectSiLife[infected].Reset();
	g_bDetectSuppressSiLifeKill[infected] = false;
	Detect_CancelPendingBoomerKill(infected);
}

void Detect_MarkSiLifeKillSuppressed(int infected)
{
	if (infected < 1 || infected > MaxClients)
	{
		return;
	}

	g_bDetectSuppressSiLifeKill[infected] = true;
	Detect_CancelPendingBoomerKill(infected, "absorbed_by_skill");
}

void Detect_CaptureSiLifeAttackerIdentity(int victim, int attacker)
{
	if (victim < 1 || victim > MaxClients || !IsValidSurvivor(attacker))
	{
		return;
	}

	int slot = Detect_FindOrCreateSiLifeSlot(victim, attacker);
	if (slot == -1)
	{
		return;
	}

	Skills_CaptureIdentityForClient(attacker);
	g_DetectSiLife[victim].attackerClients[slot] = attacker;
	g_DetectSiLife[victim].attackerUserids[slot] = GetClientUserId(attacker);
	g_DetectSiLife[victim].attackerAccountIds[slot] = IsFakeClient(attacker) ? 0 : GetSteamAccountID(attacker);
	g_DetectSiLife[victim].attackerBots[slot] = IsFakeClient(attacker);
	g_DetectSiLife[victim].attackerSurvivorCharacters[slot] = Skills_GetClientSurvivorCharacter(attacker);
}

int Detect_BuildSiLifeContributorSnapshot(int victim, L4D2ZombieClassType zombieClass, int killer, DetectSiLifeContributorEntry entries[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES], int &killerEntry)
{
	killerEntry = -1;
	for (int i = 0; i < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES; i++)
	{
		entries[i].Reset();
	}

	int count = 0;
	int maxHealth = Skills_GetSpecialMaxHealth(zombieClass);
	int remainingHealth = maxHealth > 0 ? maxHealth : 0;
	int killerSlot = Detect_FindSiLifeSlot(victim, killer);
	int slotCount = Detect_GetSiLifeSlotCount();

	for (int slot = 0; slot < slotCount && count < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES; slot++)
	{
		if (slot == killerSlot)
		{
			continue;
		}

		int rawDamage = g_DetectSiLife[victim].entries[slot].damage;
		if (rawDamage <= 0)
		{
			continue;
		}

		int effectiveDamage = rawDamage;
		if (maxHealth > 0)
		{
			if (remainingHealth <= 0)
			{
				continue;
			}

			if (effectiveDamage > remainingHealth)
			{
				effectiveDamage = remainingHealth;
			}
			remainingHealth -= effectiveDamage;
		}

		if (!Skills_TryBuildPlayerRefFromIdentity(
			g_DetectSiLife[victim].attackerAccountIds[slot],
			g_DetectSiLife[victim].attackerBots[slot],
			g_DetectSiLife[victim].attackerSurvivorCharacters[slot],
			g_DetectSiLife[victim].attackerUserids[slot],
			entries[count].player))
		{
			continue;
		}

		entries[count].effectiveDamage = effectiveDamage;
		entries[count].rawDamage = rawDamage;
		entries[count].shots = g_DetectSiLife[victim].entries[slot].shots;
		entries[count].weaponId = g_DetectSiLife[victim].entries[slot].weaponId;
		count++;
	}

	if (killerSlot != -1 && count < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES)
	{
		int rawDamage = g_DetectSiLife[victim].entries[killerSlot].damage;
		if (rawDamage > 0)
		{
			int effectiveDamage = rawDamage;
			if (maxHealth > 0)
			{
				if (remainingHealth < 0)
				{
					remainingHealth = 0;
				}

				if (effectiveDamage > remainingHealth)
				{
					effectiveDamage = remainingHealth;
				}
			}

			if (Skills_TryBuildPlayerRefFromIdentity(
				g_DetectSiLife[victim].attackerAccountIds[killerSlot],
				g_DetectSiLife[victim].attackerBots[killerSlot],
				g_DetectSiLife[victim].attackerSurvivorCharacters[killerSlot],
				g_DetectSiLife[victim].attackerUserids[killerSlot],
				entries[count].player))
			{
				entries[count].effectiveDamage = effectiveDamage;
				entries[count].rawDamage = rawDamage;
				entries[count].shots = g_DetectSiLife[victim].entries[killerSlot].shots;
				entries[count].weaponId = g_DetectSiLife[victim].entries[killerSlot].weaponId;
				killerEntry = count;
				count++;
			}
		}
	}

	return count;
}

void Detect_FindSiAssistSlots(int victim, int attacker, int &slot, int &emptySlot, int &weakestSlot)
{
	slot = -1;
	emptySlot = -1;
	weakestSlot = 0;

	int slotCount = Detect_GetSiAssistSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (Skills_IsClientMatchingIdentity(
			attacker,
			g_DetectSiAssist[victim].attackerAccountIds[i],
			g_DetectSiAssist[victim].attackerBots[i],
			g_DetectSiAssist[victim].attackerSurvivorCharacters[i],
			g_DetectSiAssist[victim].attackerUserids[i]))
		{
			slot = i;
			break;
		}

		if (g_DetectSiAssist[victim].attackerUserids[i] == 0
			&& g_DetectSiAssist[victim].attackerAccountIds[i] == 0
			&& !g_DetectSiAssist[victim].attackerBots[i]
			&& g_DetectSiAssist[victim].attackerSurvivorCharacters[i] == L4D2Util_SurvivorCharacter_Invalid)
		{
			if (emptySlot == -1)
			{
				emptySlot = i;
			}
			continue;
		}

		if (g_DetectSiAssist[victim].damage[i] < g_DetectSiAssist[victim].damage[weakestSlot])
		{
			weakestSlot = i;
		}
	}
}

void Detect_ApplySiLifeShot(int victim, int attacker, int hitgroup, bool countRealShots, int &assistShots)
{
	int slot = Detect_FindSiLifeSlot(victim, attacker);
	if (slot == -1)
	{
		return;
	}

	if (countRealShots)
	{
		g_DetectSiLife[victim].entries[slot].lastShotHitHead = (hitgroup == HITGROUP_HEAD);

		if (!g_DetectSiLife[victim].entries[slot].shotCounted)
		{
			g_DetectSiLife[victim].entries[slot].previousShots = g_DetectSiLife[victim].entries[slot].shots;
			g_DetectSiLife[victim].entries[slot].shots++;
			assistShots++;
			g_DetectSiLife[victim].entries[slot].shotCounted = true;
		}
		else if (hitgroup == HITGROUP_HEAD)
		{
			g_DetectSiLife[victim].entries[slot].lastShotHitHead = true;
		}

		return;
	}

	// Non-shot damage sources (fire, bleed-like ticks, splash follow-up) may
	// still report a head hitgroup, but they should not promote Headshot as a
	// kill property. Clear the fallback flag so only real shot events survive.
	g_DetectSiLife[victim].entries[slot].lastShotHitHead = false;
	g_DetectSiLife[victim].entries[slot].previousShots = g_DetectSiLife[victim].entries[slot].shots;
	g_DetectSiLife[victim].entries[slot].shots++;
	assistShots++;
}

void Detect_InitSiAssistSlot(int victim, int slot, int attacker, int damage, int weaponId, float now)
{
	Skills_CaptureIdentityForClient(attacker);
	g_DetectSiAssist[victim].attackerUserids[slot] = GetClientUserId(attacker);
	g_DetectSiAssist[victim].attackerAccountIds[slot] = IsFakeClient(attacker) ? 0 : GetSteamAccountID(attacker);
	g_DetectSiAssist[victim].attackerBots[slot] = IsFakeClient(attacker);
	g_DetectSiAssist[victim].attackerSurvivorCharacters[slot] = Skills_GetClientSurvivorCharacter(attacker);
	g_DetectSiAssist[victim].damage[slot] = damage;
	g_DetectSiAssist[victim].shots[slot] = 0;
	g_DetectSiAssist[victim].weaponId[slot] = weaponId;
	g_DetectSiAssist[victim].time[slot] = now;
	g_DetectSiAssist[victim].lastShotTime[slot] = 0.0;
}

void Detect_SortSiAssistSlotsByDamage(int victim)
{
	int slotCount = Detect_GetSiAssistSlotCount();
	for (int pass = 0; pass < slotCount - 1; pass++)
	{
		for (int i = 0; i < slotCount - 1 - pass; i++)
		{
			if (g_DetectSiAssist[victim].damage[i + 1] <= g_DetectSiAssist[victim].damage[i])
			{
				continue;
			}

			int attackerUserIdTemp = g_DetectSiAssist[victim].attackerUserids[i];
			int attackerAccountIdTemp = g_DetectSiAssist[victim].attackerAccountIds[i];
			bool attackerBotTemp = g_DetectSiAssist[victim].attackerBots[i];
			int attackerCharacterTemp = g_DetectSiAssist[victim].attackerSurvivorCharacters[i];
			int damageTemp = g_DetectSiAssist[victim].damage[i];
			int shotsTemp = g_DetectSiAssist[victim].shots[i];
			int weaponIdTemp = g_DetectSiAssist[victim].weaponId[i];
			float timeTemp = g_DetectSiAssist[victim].time[i];
			float lastShotTimeTemp = g_DetectSiAssist[victim].lastShotTime[i];

			g_DetectSiAssist[victim].attackerUserids[i] = g_DetectSiAssist[victim].attackerUserids[i + 1];
			g_DetectSiAssist[victim].attackerAccountIds[i] = g_DetectSiAssist[victim].attackerAccountIds[i + 1];
			g_DetectSiAssist[victim].attackerBots[i] = g_DetectSiAssist[victim].attackerBots[i + 1];
			g_DetectSiAssist[victim].attackerSurvivorCharacters[i] = g_DetectSiAssist[victim].attackerSurvivorCharacters[i + 1];
			g_DetectSiAssist[victim].damage[i] = g_DetectSiAssist[victim].damage[i + 1];
			g_DetectSiAssist[victim].shots[i] = g_DetectSiAssist[victim].shots[i + 1];
			g_DetectSiAssist[victim].weaponId[i] = g_DetectSiAssist[victim].weaponId[i + 1];
			g_DetectSiAssist[victim].time[i] = g_DetectSiAssist[victim].time[i + 1];
			g_DetectSiAssist[victim].lastShotTime[i] = g_DetectSiAssist[victim].lastShotTime[i + 1];

			g_DetectSiAssist[victim].attackerUserids[i + 1] = attackerUserIdTemp;
			g_DetectSiAssist[victim].attackerAccountIds[i + 1] = attackerAccountIdTemp;
			g_DetectSiAssist[victim].attackerBots[i + 1] = attackerBotTemp;
			g_DetectSiAssist[victim].attackerSurvivorCharacters[i + 1] = attackerCharacterTemp;
			g_DetectSiAssist[victim].damage[i + 1] = damageTemp;
			g_DetectSiAssist[victim].shots[i + 1] = shotsTemp;
			g_DetectSiAssist[victim].weaponId[i + 1] = weaponIdTemp;
			g_DetectSiAssist[victim].time[i + 1] = timeTemp;
			g_DetectSiAssist[victim].lastShotTime[i + 1] = lastShotTimeTemp;
		}
	}
}

void Detect_RecordSiLifeKillDamage(int victim, int attacker, int damage, int weaponId, int damageType, int hitgroup = HITGROUP_GENERIC)
{
	if (!Detect_IsTrackableSiLifeKillClass(victim) || !IsValidSurvivor(attacker) || damage <= 0)
	{
		return;
	}

	Detect_CaptureSiLifeAttackerIdentity(victim, attacker);
	int lifeSlot = Detect_FindSiLifeSlot(victim, attacker);
	if (lifeSlot == -1)
	{
		return;
	}

	bool countRealShots = Skills_IsRangedShotWeaponId(weaponId)
		|| (damageType & DMG_BUCKSHOT) != 0
		|| (damageType & DMG_BULLET) != 0;
	bool startingLogicalHit = countRealShots
		? !g_DetectSiLife[victim].entries[lifeSlot].shotCounted
		: true;

	if (startingLogicalHit)
	{
		g_DetectSiLife[victim].entries[lifeSlot].previousDamage = g_DetectSiLife[victim].entries[lifeSlot].damage;
	}

	g_DetectSiLife[victim].entries[lifeSlot].damage += damage;
	g_DetectSiLife[victim].entries[lifeSlot].weaponId = weaponId;

	float now = GetGameTime();

	int slot;
	int emptySlot;
	int weakestSlot;
	Detect_FindSiAssistSlots(victim, attacker, slot, emptySlot, weakestSlot);
	int slotCount = Detect_GetSiAssistSlotCount();

	if (slot != -1)
	{
		g_DetectSiAssist[victim].damage[slot] += damage;
		Detect_ApplySiLifeShot(victim, attacker, hitgroup, countRealShots, g_DetectSiAssist[victim].shots[slot]);
		g_DetectSiAssist[victim].weaponId[slot] = weaponId;
		g_DetectSiAssist[victim].time[slot] = now;
	}
	else if (emptySlot != -1)
	{
		Detect_InitSiAssistSlot(victim, emptySlot, attacker, damage, weaponId, now);
		Detect_ApplySiLifeShot(victim, attacker, hitgroup, countRealShots, g_DetectSiAssist[victim].shots[emptySlot]);
	}
	else if (damage > g_DetectSiAssist[victim].damage[weakestSlot])
	{
		Detect_InitSiAssistSlot(victim, weakestSlot, attacker, damage, weaponId, now);
		Detect_ApplySiLifeShot(victim, attacker, hitgroup, countRealShots, g_DetectSiAssist[victim].shots[weakestSlot]);
	}

	Detect_SortSiAssistSlotsByDamage(victim);

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		char hitgroupName[32];
		Skills_GetHitgroupName(hitgroup, hitgroupName, sizeof(hitgroupName));
		char summary[256];
		summary[0] = '\0';
		for (int i = 0; i < slotCount; i++)
		{
			if (g_DetectSiAssist[victim].attackerUserids[i] == 0
				&& g_DetectSiAssist[victim].attackerAccountIds[i] == 0
				&& !g_DetectSiAssist[victim].attackerBots[i]
				&& g_DetectSiAssist[victim].attackerSurvivorCharacters[i] == L4D2Util_SurvivorCharacter_Invalid)
			{
				continue;
			}

			char segment[64];
			FormatEx(segment, sizeof(segment), "%s%s%d:%d/%d",
				summary[0] == '\0' ? "" : " ",
				g_DetectSiAssist[victim].attackerAccountIds[i] > 0 ? "a:" :
					(g_DetectSiAssist[victim].attackerBots[i] ? "b:" : "u:"),
				g_DetectSiAssist[victim].attackerAccountIds[i] > 0
					? g_DetectSiAssist[victim].attackerAccountIds[i]
					: (g_DetectSiAssist[victim].attackerBots[i]
						? g_DetectSiAssist[victim].attackerSurvivorCharacters[i]
						: g_DetectSiAssist[victim].attackerUserids[i]),
				g_DetectSiAssist[victim].damage[i],
				g_DetectSiAssist[victim].shots[i]);
			StrCat(summary, sizeof(summary), segment);
		}

		Skills_Debug(PlayerSkillsDebug_Detect,
			"SI life kill damage recorded. victim=%d attacker=%d damage=%d weapon=%d damagetype=%d hitgroup=%d(%s) counted=%d summary=%s",
			victim,
			attacker,
			damage,
			weaponId,
			damageType,
			hitgroup,
			hitgroupName,
			g_DetectSiLife[victim].entries[lifeSlot].shotCounted ? 1 : 0,
			summary);
	}
}

L4D2SkillType Detect_GetSiLifeKillSkillType(L4D2ZombieClassType zombieClass)
{
	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker: return L4D2Skill_SmokerKill;
		case L4D2ZombieClass_Boomer: return L4D2Skill_BoomerKill;
		case L4D2ZombieClass_Hunter: return L4D2Skill_HunterKill;
		case L4D2ZombieClass_Spitter: return L4D2Skill_SpitterKill;
		case L4D2ZombieClass_Jockey: return L4D2Skill_JockeyKill;
		case L4D2ZombieClass_Charger: return L4D2Skill_ChargerKill;
	}

	return L4D2Skill_None;
}

int Detect_GetSiLifeDamageByAttacker(int victim, int client)
{
	int slot = Detect_FindSiLifeSlot(victim, client);
	if (slot == -1)
	{
		return 0;
	}

	return g_DetectSiLife[victim].entries[slot].damage;
}

int Detect_GetSiLifeShotsByAttacker(int victim, int client)
{
	int slot = Detect_FindSiLifeSlot(victim, client);
	if (slot == -1)
	{
		return 0;
	}

	return g_DetectSiLife[victim].entries[slot].shots;
}

bool Detect_GetNormalizedSiLifeContributionByAttacker(int victim, L4D2ZombieClassType zombieClass, int client, int &damage, int &shots, int &weaponId)
{
	damage = 0;
	shots = 0;
	weaponId = L4D2WeaponId_None;

	DetectSiLifeContributorEntry contributors[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int killerEntry = -1;
	int contributorCount = Detect_BuildSiLifeContributorSnapshot(victim, zombieClass, client, contributors, killerEntry);
	if (killerEntry == -1 || contributorCount <= 0)
	{
		return false;
	}

	damage = contributors[killerEntry].effectiveDamage;
	shots = contributors[killerEntry].shots;
	weaponId = contributors[killerEntry].weaponId;
	return true;
}

int Detect_GetSiLifePreviousDamageByAttacker(int victim, int client)
{
	int slot = Detect_FindSiLifeSlot(victim, client);
	if (slot == -1)
	{
		return 0;
	}

	return g_DetectSiLife[victim].entries[slot].previousDamage;
}

int Detect_GetSiLifePreviousShotsByAttacker(int victim, int client)
{
	int slot = Detect_FindSiLifeSlot(victim, client);
	if (slot == -1)
	{
		return 0;
	}

	return g_DetectSiLife[victim].entries[slot].previousShots;
}

int Detect_GetSiLifeWeaponIdByAttacker(int victim, int client)
{
	int slot = Detect_FindSiLifeSlot(victim, client);
	if (slot == -1)
	{
		return WEPID_NONE;
	}

	return g_DetectSiLife[victim].entries[slot].weaponId;
}

int Detect_GetHunterBlastDamageByAttacker(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	int slot = Detect_FindHunterShotWindowSlot(victim, client);
	return slot != -1 ? g_DetectHunterShotWindow[victim].entries[slot].activeBlastDamage : 0;
}

int Detect_GetHunterShotCountByAttacker(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	int slot = Detect_FindHunterShotWindowSlot(victim, client);
	return slot != -1 ? g_DetectHunterShotWindow[victim].entries[slot].cumulativeShots : 0;
}

int Detect_WriteSiTrackAssistsToEventAsSkillWindow(int eventIndex, int victim, int actor)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return 0;
	}

	int assistsFound = 0;
	int maxAssists = L4D2_SKILLS_MAX_EVENT_ASSISTS;
	if (g_cvSurvivorLimit != null && g_cvSurvivorLimit.IntValue > 1 && g_cvSurvivorLimit.IntValue - 1 < maxAssists)
	{
		maxAssists = g_cvSurvivorLimit.IntValue - 1;
	}
	int slotCount = Detect_GetSiAssistSlotCount();

	for (int i = 0; i < slotCount && assistsFound < maxAssists; i++)
	{
		if (g_DetectSiAssist[victim].attackerUserids[i] == 0
			&& g_DetectSiAssist[victim].attackerAccountIds[i] == 0
			&& !g_DetectSiAssist[victim].attackerBots[i]
			&& g_DetectSiAssist[victim].attackerSurvivorCharacters[i] == L4D2Util_SurvivorCharacter_Invalid)
		{
			continue;
		}

		if (Skills_IsClientMatchingIdentity(
			actor,
			g_DetectSiAssist[victim].attackerAccountIds[i],
			g_DetectSiAssist[victim].attackerBots[i],
			g_DetectSiAssist[victim].attackerSurvivorCharacters[i],
			g_DetectSiAssist[victim].attackerUserids[i]))
		{
			continue;
		}

		int assistDamage = g_DetectSiAssist[victim].damage[i];
		if (assistDamage <= 0)
		{
			continue;
		}

		if (!Skills_TryBuildPlayerRefFromIdentity(
			g_DetectSiAssist[victim].attackerAccountIds[i],
			g_DetectSiAssist[victim].attackerBots[i],
			g_DetectSiAssist[victim].attackerSurvivorCharacters[i],
			g_DetectSiAssist[victim].attackerUserids[i],
			g_SkillEvents[eventIndex].assists[assistsFound]))
		{
			continue;
		}

		g_SkillEvents[eventIndex].assistDamage[assistsFound] = assistDamage;
		g_SkillEvents[eventIndex].assistShots[assistsFound] = g_DetectSiAssist[victim].shots[i];
		g_SkillEvents[eventIndex].assistWeaponId[assistsFound] = g_DetectSiAssist[victim].weaponId[i];
		assistsFound++;
	}

	g_SkillEvents[eventIndex].assistsCount = assistsFound;
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	if (assistsFound > 0)
	{
		g_SkillEvents[eventIndex].assistScope = L4D2SkillAssistScope_SkillWindow;
		g_SkillEvents[eventIndex].assister = g_SkillEvents[eventIndex].assists[0];
		g_SkillEvents[eventIndex].assisterDamage = g_SkillEvents[eventIndex].assistDamage[0];
		g_SkillEvents[eventIndex].assisterShots = g_SkillEvents[eventIndex].assistShots[0];
		g_SkillEvents[eventIndex].assisterWeaponId = g_SkillEvents[eventIndex].assistWeaponId[0];
	}

	return assistsFound;
}

int Detect_WriteLifeKillAssistsToEvent(int eventIndex, DetectSiLifeContributorEntry entries[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES], int entryCount, int killerEntry)
{
	int assistsFound = 0;
	int maxAssists = L4D2_SKILLS_MAX_EVENT_ASSISTS;
	if (g_cvSurvivorLimit != null && g_cvSurvivorLimit.IntValue > 1 && g_cvSurvivorLimit.IntValue - 1 < maxAssists)
	{
		maxAssists = g_cvSurvivorLimit.IntValue - 1;
	}

	for (int i = 0; i < entryCount; i++)
	{
		if (i == killerEntry)
		{
			continue;
		}

		int assistDamage = entries[i].effectiveDamage;
		if (assistDamage <= 0)
		{
			continue;
		}

		if (assistsFound >= maxAssists || assistsFound >= L4D2_SKILLS_MAX_EVENT_ASSISTS)
		{
			break;
		}

		g_SkillEvents[eventIndex].assists[assistsFound] = entries[i].player;
		g_SkillEvents[eventIndex].assistDamage[assistsFound] = assistDamage;
		g_SkillEvents[eventIndex].assistShots[assistsFound] = entries[i].shots;
		g_SkillEvents[eventIndex].assistWeaponId[assistsFound] = entries[i].weaponId;
		assistsFound++;
	}

	g_SkillEvents[eventIndex].assistsCount = assistsFound;
	if (assistsFound > 0)
	{
		g_SkillEvents[eventIndex].assister = g_SkillEvents[eventIndex].assists[0];
		g_SkillEvents[eventIndex].assisterDamage = g_SkillEvents[eventIndex].assistDamage[0];
		g_SkillEvents[eventIndex].assisterShots = g_SkillEvents[eventIndex].assistShots[0];
		g_SkillEvents[eventIndex].assisterWeaponId = g_SkillEvents[eventIndex].assistWeaponId[0];
	}

	return assistsFound;
}

bool Detect_BuildLifeKillEventPayload(int eventId, L4D2ZombieClassType zombieClass, int victim, int killer, bool headshot, int &eventIndex, int &assistsFound)
{
	eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		assistsFound = 0;
		return false;
	}

	DetectSiLifeContributorEntry contributors[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int killerEntry = -1;
	int contributorCount = Detect_BuildSiLifeContributorSnapshot(victim, zombieClass, killer, contributors, killerEntry);
	if (killerEntry == -1 || contributorCount <= 0)
	{
		assistsFound = 0;
		return false;
	}

	g_SkillEvents[eventIndex].actor = contributors[killerEntry].player;
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = zombieClass;
	g_SkillEvents[eventIndex].assistScope = L4D2SkillAssistScope_LifeKill;
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_LifeKill;
	g_SkillEvents[eventIndex].actorWeaponId = contributors[killerEntry].weaponId;
	g_SkillEvents[eventIndex].actorDamage = contributors[killerEntry].effectiveDamage;
	g_SkillEvents[eventIndex].damage = g_SkillEvents[eventIndex].actorDamage;
	g_SkillEvents[eventIndex].shots = contributors[killerEntry].shots;
	g_SkillEvents[eventIndex].headshot = Detect_ResolveHeadshot(victim, killer, headshot);

	assistsFound = Detect_WriteLifeKillAssistsToEvent(eventIndex, contributors, contributorCount, killerEntry);
	return true;
}

void Detect_DebugLifeKillPayload(const char[] label, int eventId, L4D2SkillType type, int victim, int killer, int actorDamage, int shots, bool headshot, int assistsFound, int healthBeforeDamage = 0)
{
	if (!Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		return;
	}

	char assistsSummary[256];
	assistsSummary[0] = '\0';
	int eventIndex = Skills_GetEventIndex(eventId);
	for (int i = 0; i < assistsFound; i++)
	{
		char segment[72];
		FormatEx(segment, sizeof(segment), "%s%d:%d/%d",
			assistsSummary[0] == '\0' ? "" : " ",
			g_SkillEvents[eventIndex].assists[i].client,
			g_SkillEvents[eventIndex].assistDamage[i],
			g_SkillEvents[eventIndex].assistShots[i]);
		StrCat(assistsSummary, sizeof(assistsSummary), segment);
	}

	if (healthBeforeDamage > 0)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"%s. event=%d type=%d victim=%d killer=%d health_before=%d killer_dmg=%d killer_shots=%d headshot=%d assists=%d [%s]",
			label,
			eventId,
			type,
			victim,
			killer,
			healthBeforeDamage,
			actorDamage,
			shots,
			headshot ? 1 : 0,
			assistsFound,
			assistsSummary);
		return;
	}

	Skills_Debug(PlayerSkillsDebug_Detect,
		"%s. event=%d type=%d victim=%d killer=%d dmg=%d shots=%d headshot=%d assists=%d [%s]",
		label,
		eventId,
		type,
		victim,
		killer,
		actorDamage,
		shots,
		headshot ? 1 : 0,
		assistsFound,
		assistsSummary);
}

void Detect_EmitSiLifeKill(int victim, int killer, bool headshot = false)
{
	if (!Detect_IsTrackableSiLifeKillClass(victim) || !IsValidSurvivor(killer))
	{
		return;
	}

	L4D2ZombieClassType zombieClass = GetClientZombieClass(victim);
	L4D2SkillType type = Detect_GetSiLifeKillSkillType(zombieClass);
	if (type == L4D2Skill_None)
	{
		return;
	}

	if (type == L4D2Skill_BoomerKill
		&& (g_DetectBoomer[victim].deathCommitted || g_iDetectPendingBoomerKillEvent[victim] > 0))
	{
		return;
	}

	int eventId = Skills_CreateEvent(type);
	int eventIndex;
	int assistsFound;
	if (!Detect_BuildLifeKillEventPayload(eventId, zombieClass, victim, killer, headshot, eventIndex, assistsFound))
	{
		return;
	}

	Detect_DebugLifeKillPayload("SI life kill payload", eventId, type, victim, killer, g_SkillEvents[eventIndex].actorDamage, g_SkillEvents[eventIndex].shots, g_SkillEvents[eventIndex].headshot, assistsFound);

	if (type == L4D2Skill_BoomerKill)
	{
		Detect_CancelPendingBoomerKill(victim, "replaced_pending");
		Skills_SetEventPendingPublication(eventId, true);
		g_iDetectPendingBoomerKillEvent[victim] = eventId;
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Boomer kill publication queued. boomer=%d event=%d delay=0.10", victim, eventId);
		Detect_QueueClientTimer(0.10, Detect_TimerAnnounceBoomerKill, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE, eventId);
		return;
	}

	Action result = API_FireSkillDetected(eventId, type);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_EmitHunterLifeKill(int victim, int killer, int hunterHealthBeforeDamage, bool headshot = false)
{
	if (!IsValidSurvivor(killer))
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_HunterKill);
	int eventIndex;
	int assistsFound;
	if (!Detect_BuildLifeKillEventPayload(eventId, L4D2ZombieClass_Hunter, victim, killer, headshot, eventIndex, assistsFound))
	{
		return;
	}

	if (g_SkillEvents[eventIndex].actorDamage <= 0)
	{
		g_SkillEvents[eventIndex].actorDamage = hunterHealthBeforeDamage;
		g_SkillEvents[eventIndex].damage = hunterHealthBeforeDamage;
		if (g_SkillEvents[eventIndex].shots <= 0)
		{
			g_SkillEvents[eventIndex].shots = 1;
		}
	}

	Detect_DebugLifeKillPayload("Hunter life kill payload", eventId, L4D2Skill_HunterKill, victim, killer, g_SkillEvents[eventIndex].actorDamage, g_SkillEvents[eventIndex].shots, g_SkillEvents[eventIndex].headshot, assistsFound, hunterHealthBeforeDamage);

	Action result = API_FireSkillDetected(eventId, L4D2Skill_HunterKill);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}
