// Private detector ownership: skeet quality

void Detect_LogSkeetQuality(int victim, int attacker, const char[] skillName, const char[] stage, int eventIndex)
{
	if (!Skills_IsDebugEnabled(PlayerSkillsDebug_Detect)
		|| eventIndex < 0
		|| eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return;
	}

	char victimName[64];
	char attackerName[64];
	if (IsValidClient(victim))
	{
		FormatEx(victimName, sizeof(victimName), "%N", victim);
	}
	else
	{
		strcopy(victimName, sizeof(victimName), "<none>");
	}

	if (IsValidClient(attacker))
	{
		FormatEx(attackerName, sizeof(attackerName), "%N", attacker);
	}
	else
	{
		strcopy(attackerName, sizeof(attackerName), "<none>");
	}

	int assistDamageTotal = 0;
	for (int i = 0; i < g_SkillEvents[eventIndex].assistsCount && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		assistDamageTotal += g_SkillEvents[eventIndex].assistDamage[i];
	}

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Skeet quality. skill=%s stage=%s victim=%d victim_name=%s attacker=%d attacker_name=%s actor_damage=%d shots=%d actor_chip=%d actor_chip_shots=%d assist_damage=%d assists=%d chip=%d perfect=%d",
		skillName,
		stage,
		victim,
		victimName,
		attacker,
		attackerName,
		g_SkillEvents[eventIndex].actorDamage,
		g_SkillEvents[eventIndex].shots,
		g_SkillEvents[eventIndex].actorChipDamage,
		g_SkillEvents[eventIndex].actorChipShots,
		assistDamageTotal,
		g_SkillEvents[eventIndex].assistsCount,
		g_SkillEvents[eventIndex].chipDamage,
		g_SkillEvents[eventIndex].perfect ? 1 : 0);
}

void Detect_OpenSkeetQualityWindow(int victim)
{
	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	g_DetectSkeetQualityWindow[victim].Reset();
	g_DetectSkeetQualityWindow[victim].active = true;

	int slotCount = Detect_GetSiLifeSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		g_DetectSkeetQualityWindow[victim].attackerClients[i] = g_DetectSiLife[victim].attackerClients[i];
		g_DetectSkeetQualityWindow[victim].attackerUserids[i] = g_DetectSiLife[victim].attackerUserids[i];
		g_DetectSkeetQualityWindow[victim].attackerAccountIds[i] = g_DetectSiLife[victim].attackerAccountIds[i];
		g_DetectSkeetQualityWindow[victim].attackerBots[i] = g_DetectSiLife[victim].attackerBots[i];
		g_DetectSkeetQualityWindow[victim].attackerSurvivorCharacters[i] = g_DetectSiLife[victim].attackerSurvivorCharacters[i];
		g_DetectSkeetQualityWindow[victim].damage[i] = g_DetectSiLife[victim].entries[i].damage;
		g_DetectSkeetQualityWindow[victim].shots[i] = g_DetectSiLife[victim].entries[i].shots;
	}
}

void Detect_CloseSkeetQualityWindow(int victim)
{
	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	g_DetectSkeetQualityWindow[victim].Reset();
}

int Detect_GetSkeetQualitySnapshotDamageByAttacker(int victim, int attacker)
{
	if (victim < 1 || victim > MaxClients || !IsValidSurvivor(attacker) || !g_DetectSkeetQualityWindow[victim].active)
	{
		return 0;
	}

	int slotCount = Detect_GetSiLifeSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (Skills_IsClientMatchingIdentity(
			attacker,
			g_DetectSkeetQualityWindow[victim].attackerAccountIds[i],
			g_DetectSkeetQualityWindow[victim].attackerBots[i],
			g_DetectSkeetQualityWindow[victim].attackerSurvivorCharacters[i],
			g_DetectSkeetQualityWindow[victim].attackerUserids[i]))
		{
			return g_DetectSkeetQualityWindow[victim].damage[i];
		}
	}

	return 0;
}

int Detect_GetSkeetQualitySnapshotShotsByAttacker(int victim, int attacker)
{
	if (victim < 1 || victim > MaxClients || !IsValidSurvivor(attacker) || !g_DetectSkeetQualityWindow[victim].active)
	{
		return 0;
	}

	int slotCount = Detect_GetSiLifeSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (Skills_IsClientMatchingIdentity(
			attacker,
			g_DetectSkeetQualityWindow[victim].attackerAccountIds[i],
			g_DetectSkeetQualityWindow[victim].attackerBots[i],
			g_DetectSkeetQualityWindow[victim].attackerSurvivorCharacters[i],
			g_DetectSkeetQualityWindow[victim].attackerUserids[i]))
		{
			return g_DetectSkeetQualityWindow[victim].shots[i];
		}
	}

	return 0;
}

int Detect_GetSkeetQualityWindowDamageByAttacker(int victim, int attacker)
{
	int totalDamage = Detect_GetSiLifeDamageByAttacker(victim, attacker);
	int startDamage = Detect_GetSkeetQualitySnapshotDamageByAttacker(victim, attacker);
	int windowDamage = totalDamage - startDamage;
	return windowDamage > 0 ? windowDamage : 0;
}

int Detect_GetSkeetQualityWindowShotsByAttacker(int victim, int attacker)
{
	int totalShots = Detect_GetSiLifeShotsByAttacker(victim, attacker);
	int startShots = Detect_GetSkeetQualitySnapshotShotsByAttacker(victim, attacker);
	int windowShots = totalShots - startShots;
	return windowShots > 0 ? windowShots : 0;
}

int Detect_FillSkeetQualityFromLifeSnapshot(int eventIndex, int victim, int actor)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return 0;
	}

	int assistsFound = Detect_WriteSiTrackAssistsToEventAsSkillWindow(eventIndex, victim, actor);
	int assistDamageTotal = 0;
	for (int i = 0; i < g_SkillEvents[eventIndex].assistsCount && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		assistDamageTotal += g_SkillEvents[eventIndex].assistDamage[i];
	}

	g_SkillEvents[eventIndex].actorChipDamage = Detect_GetSkeetQualitySnapshotDamageByAttacker(victim, actor);
	g_SkillEvents[eventIndex].actorChipShots = Detect_GetSkeetQualitySnapshotShotsByAttacker(victim, actor);
	g_SkillEvents[eventIndex].chipDamage = g_SkillEvents[eventIndex].actorChipDamage + assistDamageTotal;
	return assistsFound;
}
