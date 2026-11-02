#if defined _l4d2_player_skills_queries_included
	#endinput
#endif
#define _l4d2_player_skills_queries_included

int Announce_CountSkillTypeForClient(int client, L4D2SkillType type)
{
	if (!IsValidClient(client))
	{
		return 0;
	}

	if (!Skills_IsSkillTypeEnabledInCurrentMode(type))
	{
		return 0;
	}

	int count = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id <= 0
			|| g_SkillEvents[index].type != type
			|| !g_SkillEvents[index].actor.IsSamePersistentPlayer(client)
			|| !Skills_IsSkillEventEnabledInCurrentMode(index))
		{
			continue;
		}

		count++;
	}

	return count;
}

int Announce_CountSkillTypeForPlayerRef(L4D2PlayerRef player, L4D2SkillType type)
{
	if (!Skills_IsSkillTypeEnabledInCurrentMode(type))
	{
		return 0;
	}

	int count = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id <= 0
			|| g_SkillEvents[index].type != type
			|| !g_SkillEvents[index].actor.IsSamePersistentRef(player)
			|| !Skills_IsSkillEventEnabledInCurrentMode(index))
		{
			continue;
		}

		count++;
	}

	return count;
}

int Announce_CountSkillTypeForVictimClient(int client, L4D2SkillType type)
{
	if (!IsValidClient(client))
	{
		return 0;
	}

	if (!Skills_IsSkillTypeEnabledInCurrentMode(type))
	{
		return 0;
	}

	int count = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id <= 0
			|| g_SkillEvents[index].type != type
			|| !g_SkillEvents[index].victim.IsSamePersistentPlayer(client)
			|| !Skills_IsSkillEventEnabledInCurrentMode(index))
		{
			continue;
		}

		count++;
	}

	return count;
}

int Announce_SumSkillAmountForClient(int client, L4D2SkillType type)
{
	if (!IsValidClient(client))
	{
		return 0;
	}

	if (!Skills_IsSkillTypeEnabledInCurrentMode(type))
	{
		return 0;
	}

	int total = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id <= 0
			|| g_SkillEvents[index].type != type
			|| !g_SkillEvents[index].actor.IsSamePersistentPlayer(client)
			|| !Skills_IsSkillEventEnabledInCurrentMode(index))
		{
			continue;
		}

		total += g_SkillEvents[index].amount;
	}

	return total;
}

int Announce_CountPerfectSkillTypeForClient(int client, L4D2SkillType type)
{
	if (!IsValidClient(client))
	{
		return 0;
	}

	if (!Skills_IsSkillTypeEnabledInCurrentMode(type))
	{
		return 0;
	}

	int count = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id <= 0
			|| g_SkillEvents[index].type != type
			|| !g_SkillEvents[index].actor.IsSamePersistentPlayer(client)
			|| !g_SkillEvents[index].perfect
			|| !Skills_IsSkillEventEnabledInCurrentMode(index))
		{
			continue;
		}

		count++;
	}

	return count;
}

int Announce_CountNonPerfectSkillTypeForClient(int client, L4D2SkillType type)
{
	if (!IsValidClient(client))
	{
		return 0;
	}

	if (!Skills_IsSkillTypeEnabledInCurrentMode(type))
	{
		return 0;
	}

	int count = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id <= 0
			|| g_SkillEvents[index].type != type
			|| !g_SkillEvents[index].actor.IsSamePersistentPlayer(client)
			|| g_SkillEvents[index].perfect
			|| !Skills_IsSkillEventEnabledInCurrentMode(index))
		{
			continue;
		}

		count++;
	}

	return count;
}

int Announce_MaxSkillAmountForClient(int client, L4D2SkillType type)
{
	if (!IsValidClient(client))
	{
		return 0;
	}

	if (!Skills_IsSkillTypeEnabledInCurrentMode(type))
	{
		return 0;
	}

	int best = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id <= 0
			|| g_SkillEvents[index].type != type
			|| !g_SkillEvents[index].actor.IsSamePersistentPlayer(client)
			|| !Skills_IsSkillEventEnabledInCurrentMode(index))
		{
			continue;
		}

		if (g_SkillEvents[index].amount > best)
		{
			best = g_SkillEvents[index].amount;
		}
	}

	return best;
}

int Announce_MaxSkillHeightForClient(int client, L4D2SkillType type)
{
	if (!IsValidClient(client))
	{
		return 0;
	}

	if (!Skills_IsSkillTypeEnabledInCurrentMode(type))
	{
		return 0;
	}

	float best = 0.0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id <= 0
			|| g_SkillEvents[index].type != type
			|| !g_SkillEvents[index].actor.IsSamePersistentPlayer(client)
			|| !Skills_IsSkillEventEnabledInCurrentMode(index))
		{
			continue;
		}

		if (g_SkillEvents[index].height > best)
		{
			best = g_SkillEvents[index].height;
		}
	}

	return RoundToFloor(best);
}

int Announce_MapSurvivorTableFamily(L4D2SkillType type)
{
	switch (type)
	{
		case L4D2Skill_HunterSkeet: return 0;
		case L4D2Skill_HunterSkeetMelee: return 2;
		case L4D2Skill_HunterDeadstop: return 3;
		case L4D2Skill_JockeyJumpStop: return 4;
		case L4D2Skill_JockeySkeetMelee: return 5;
		case L4D2Skill_JockeySkeet: return 6;
		case L4D2Skill_SmokerTongueCut: return 7;
		case L4D2Skill_SmokerSelfClear: return 8;
		case L4D2Skill_SpecialPinClear: return 9;
		case L4D2Skill_BoomerPop: return 10;
		case L4D2Skill_ChargerLevel: return 11;
		case L4D2Skill_WitchCrown: return 13;
		case L4D2Skill_TankRockSkeet: return 14;
		case L4D2Skill_BunnyHopStreak: return 15;
		case L4D2Skill_CarAlarmTriggered: return 16;
		case L4D2Skill_SmokerKill, L4D2Skill_BoomerKill, L4D2Skill_HunterKill, L4D2Skill_SpitterKill, L4D2Skill_JockeyKill, L4D2Skill_ChargerKill: return 17;
	}

	return -1;
}

int Announce_MapInfectedTableFamily(L4D2SkillType type)
{
	switch (type)
	{
		case L4D2Skill_HunterHighPounce: return 0;
		case L4D2Skill_JockeyHighLeap: return 2;
		case L4D2Skill_JockeyLedgeHang: return 4;
		case L4D2Skill_SmokerLedgeHang: return 5;
		case L4D2Skill_BoomerVomitLanded: return 6;
		case L4D2Skill_ChargerInstaKill: return 10;
		case L4D2Skill_ChargerDeathSetup: return 11;
		case L4D2Skill_ChargerLedgeHang: return 12;
		case L4D2Skill_ChargerBowl: return 13;
		case L4D2Skill_TankRockHit: return 16;
		case L4D2Skill_TankLedgeHang: return 17;
	}

	return -1;
}

void Announce_GetSurvivorTableFamilyName(int family, char[] buffer, int maxlen)
{
	switch (family)
	{
		case 0: strcopy(buffer, maxlen, "Skeets");
		case 1: strcopy(buffer, maxlen, "SkeetPerfect");
		case 2: strcopy(buffer, maxlen, "SkeetMelees");
		case 3: strcopy(buffer, maxlen, "Deadstops");
		case 4: strcopy(buffer, maxlen, "JockeyJumpStops");
		case 5: strcopy(buffer, maxlen, "JockeySkeetMelees");
		case 6: strcopy(buffer, maxlen, "JockeySkeets");
		case 7: strcopy(buffer, maxlen, "TongueCuts");
		case 8: strcopy(buffer, maxlen, "SmokerClears");
		case 9: strcopy(buffer, maxlen, "SpecialClears");
		case 10: strcopy(buffer, maxlen, "BoomerPops");
		case 11: strcopy(buffer, maxlen, "ChargerLevels");
		case 12: strcopy(buffer, maxlen, "LevelPerfect");
		case 13: strcopy(buffer, maxlen, "WitchCrowns");
		case 14: strcopy(buffer, maxlen, "TankRockSkeets");
		case 15: strcopy(buffer, maxlen, "BunnyHopStreaks");
		case 16: strcopy(buffer, maxlen, "CarAlarms");
		case 17: strcopy(buffer, maxlen, "SpecialInfectedKills");
		default: buffer[0] = '\0';
	}
}

void Announce_GetInfectedTableFamilyName(int family, char[] buffer, int maxlen)
{
	switch (family)
	{
		case 0: strcopy(buffer, maxlen, "HunterPounces");
		case 1: strcopy(buffer, maxlen, "HunterPounceBest");
		case 2: strcopy(buffer, maxlen, "JockeyPounces");
		case 3: strcopy(buffer, maxlen, "JockeyPounceBest");
		case 4: strcopy(buffer, maxlen, "JockeyLedgeHangs");
		case 5: strcopy(buffer, maxlen, "SmokerLedgeHangs");
		case 6: strcopy(buffer, maxlen, "BoomerVomit");
		case 7: strcopy(buffer, maxlen, "BoomerVomitTargets");
		case 8: strcopy(buffer, maxlen, "BoomerVomitPerfect");
		case 9: strcopy(buffer, maxlen, "BoomerVomitBest");
		case 10: strcopy(buffer, maxlen, "ChargerInstaKills");
		case 11: strcopy(buffer, maxlen, "ChargerDeathSetups");
		case 12: strcopy(buffer, maxlen, "ChargerLedgeHangs");
		case 13: strcopy(buffer, maxlen, "ChargerBowls");
		case 14: strcopy(buffer, maxlen, "ChargerBowlTargets");
		case 15: strcopy(buffer, maxlen, "ChargerBowlBest");
		case 16: strcopy(buffer, maxlen, "TankRockHits");
		case 17: strcopy(buffer, maxlen, "TankLedgeHangs");
		default: buffer[0] = '\0';
	}
}

bool Announce_IsSurvivorTableFamilyVisible(int family)
{
	switch (family)
	{
		case 0: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterSkeet);
		case 1: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterSkeet);
		case 2: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterSkeetMelee);
		case 3: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterDeadstop);
		case 4: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyJumpStop);
		case 5: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeySkeetMelee);
		case 6: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeySkeet);
		case 7: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SmokerTongueCut);
		case 8: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SmokerSelfClear);
		case 9: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SpecialPinClear);
		case 10: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_BoomerPop);
		case 11: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerLevel);
		case 12: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerLevel);
		case 13: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_WitchCrown);
		case 14: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_TankRockSkeet);
		case 15: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_BunnyHopStreak);
		case 16: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_CarAlarmTriggered);
		case 17:
		{
			return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SmokerKill)
				|| Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_BoomerKill)
				|| Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterKill)
				|| Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SpitterKill)
				|| Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyKill)
				|| Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerKill);
		}
	}

	return false;
}

bool Announce_IsInfectedTableFamilyVisible(int family)
{
	switch (family)
	{
		case 0: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterHighPounce);
		case 1: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterHighPounce);
		case 2: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyHighLeap);
		case 3: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyHighLeap);
		case 4: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyLedgeHang);
		case 5: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SmokerLedgeHang);
		case 6, 7, 8, 9: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_BoomerVomitLanded);
		case 10: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerInstaKill);
		case 11: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerDeathSetup);
		case 12: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerLedgeHang);
		case 13, 14, 15: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerBowl);
		case 16: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_TankRockHit);
		case 17: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_TankLedgeHang);
	}

	return false;
}

int Announce_CountSurvivorTableFamilyForClient(int client, int family)
{
	switch (family)
	{
		case 0: return Announce_CountSkillTypeForClient(client, L4D2Skill_HunterSkeet);
		case 1: return Announce_CountPerfectSkillTypeForClient(client, L4D2Skill_HunterSkeet);
		case 2: return Announce_CountSkillTypeForClient(client, L4D2Skill_HunterSkeetMelee);
		case 3: return Announce_CountSkillTypeForClient(client, L4D2Skill_HunterDeadstop);
		case 4: return Announce_CountSkillTypeForClient(client, L4D2Skill_JockeyJumpStop);
		case 5: return Announce_CountSkillTypeForClient(client, L4D2Skill_JockeySkeetMelee);
		case 6: return Announce_CountSkillTypeForClient(client, L4D2Skill_JockeySkeet);
		case 7: return Announce_CountSkillTypeForClient(client, L4D2Skill_SmokerTongueCut);
		case 8: return Announce_CountSkillTypeForClient(client, L4D2Skill_SmokerSelfClear);
		case 9: return Announce_CountSkillTypeForClient(client, L4D2Skill_SpecialPinClear);
		case 10: return Announce_CountSkillTypeForClient(client, L4D2Skill_BoomerPop);
		case 11: return Announce_CountNonPerfectSkillTypeForClient(client, L4D2Skill_ChargerLevel);
		case 12: return Announce_CountPerfectSkillTypeForClient(client, L4D2Skill_ChargerLevel);
		case 13: return Announce_CountSkillTypeForClient(client, L4D2Skill_WitchCrown);
		case 14: return Announce_CountSkillTypeForClient(client, L4D2Skill_TankRockSkeet);
		case 15: return Announce_CountSkillTypeForClient(client, L4D2Skill_BunnyHopStreak);
		case 16: return Announce_CountSkillTypeForClient(client, L4D2Skill_CarAlarmTriggered);
		case 17:
		{
			return Announce_CountSkillTypeForClient(client, L4D2Skill_SmokerKill)
				+ Announce_CountSkillTypeForClient(client, L4D2Skill_BoomerKill)
				+ Announce_CountSkillTypeForClient(client, L4D2Skill_HunterKill)
				+ Announce_CountSkillTypeForClient(client, L4D2Skill_SpitterKill)
				+ Announce_CountSkillTypeForClient(client, L4D2Skill_JockeyKill)
				+ Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerKill);
		}
	}

	return 0;
}

int Announce_CountInfectedTableFamilyForClient(int client, int family)
{
	switch (family)
	{
		case 0: return Announce_CountSkillTypeForClient(client, L4D2Skill_HunterHighPounce);
		case 1: return Announce_MaxSkillHeightForClient(client, L4D2Skill_HunterHighPounce);
		case 2: return Announce_CountSkillTypeForClient(client, L4D2Skill_JockeyHighLeap);
		case 3: return Announce_MaxSkillHeightForClient(client, L4D2Skill_JockeyHighLeap);
		case 4: return Announce_CountSkillTypeForClient(client, L4D2Skill_JockeyLedgeHang);
		case 5: return Announce_CountSkillTypeForClient(client, L4D2Skill_SmokerLedgeHang);
		case 6: return Announce_CountSkillTypeForClient(client, L4D2Skill_BoomerVomitLanded);
		case 7: return Announce_SumSkillAmountForClient(client, L4D2Skill_BoomerVomitLanded);
		case 8: return Announce_CountPerfectSkillTypeForClient(client, L4D2Skill_BoomerVomitLanded);
		case 9: return Announce_MaxSkillAmountForClient(client, L4D2Skill_BoomerVomitLanded);
		case 10: return Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerInstaKill);
		case 11: return Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerDeathSetup);
		case 12: return Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerLedgeHang);
		case 13: return Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerBowl);
		case 14: return Announce_SumSkillAmountForClient(client, L4D2Skill_ChargerBowl);
		case 15: return Announce_MaxSkillAmountForClient(client, L4D2Skill_ChargerBowl);
		case 16: return Announce_CountSkillTypeForClient(client, L4D2Skill_TankRockHit);
		case 17: return Announce_CountSkillTypeForClient(client, L4D2Skill_TankLedgeHang);
	}

	return 0;
}

int Announce_CountTableFamilyForBots(L4DTeam team, int family)
{
	int count = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id <= 0
			|| !g_SkillEvents[index].actor.bot
			|| !Skills_IsSkillEventEnabledInCurrentMode(index))
		{
			continue;
		}

		if (team == L4DTeam_Infected && g_SkillEvents[index].type == L4D2Skill_BoomerVomitLanded)
		{
			if (family == 4)
			{
				count++;
			}
			else if (family == 5)
			{
				count += g_SkillEvents[index].amount;
			}
			else if (family == 6)
			{
				count += g_SkillEvents[index].perfect ? 1 : 0;
			}
			else if (family == 7 && g_SkillEvents[index].amount > count)
			{
				count = g_SkillEvents[index].amount;
			}

			continue;
		}

		if (team == L4DTeam_Infected && g_SkillEvents[index].type == L4D2Skill_HunterHighPounce)
		{
			if (family == 0)
			{
				count++;
			}
			else if (family == 1)
			{
				int height = RoundToFloor(g_SkillEvents[index].height);
				if (height > count)
				{
					count = height;
				}
			}

			continue;
		}

		if (team == L4DTeam_Infected && g_SkillEvents[index].type == L4D2Skill_JockeyHighLeap)
		{
			if (family == 2)
			{
				count++;
			}
			else if (family == 3)
			{
				int height = RoundToFloor(g_SkillEvents[index].height);
				if (height > count)
				{
					count = height;
				}
			}

			continue;
		}

		if (team == L4DTeam_Infected && g_SkillEvents[index].type == L4D2Skill_ChargerBowl)
		{
			if (family == 15)
			{
				count++;
			}
			else if (family == 16)
			{
				count += g_SkillEvents[index].amount;
			}
			else if (family == 17 && g_SkillEvents[index].amount > count)
			{
				count = g_SkillEvents[index].amount;
			}

			continue;
		}

		if (team == L4DTeam_Infected && g_SkillEvents[index].type == L4D2Skill_SmokerLedgeHang)
		{
			if (family == 8)
			{
				count++;
			}

			continue;
		}

		if (team == L4DTeam_Infected && g_SkillEvents[index].type == L4D2Skill_JockeyLedgeHang)
		{
			if (family == 9)
			{
				count++;
			}

			continue;
		}

		if (team == L4DTeam_Infected && g_SkillEvents[index].type == L4D2Skill_ChargerLedgeHang)
		{
			if (family == 12)
			{
				count++;
			}

			continue;
		}

		if (team == L4DTeam_Infected && g_SkillEvents[index].type == L4D2Skill_TankLedgeHang)
		{
			if (family == 14)
			{
				count++;
			}

			continue;
		}

		if (team == L4DTeam_Survivor && g_SkillEvents[index].type == L4D2Skill_HunterSkeet)
		{
			if (family == 0)
			{
				count++;
				continue;
			}
			else if (family == 1)
			{
				count += g_SkillEvents[index].perfect ? 1 : 0;
				continue;
			}
		}

		if (team == L4DTeam_Survivor && g_SkillEvents[index].type == L4D2Skill_ChargerLevel)
		{
			if (family == 8)
			{
				count += g_SkillEvents[index].perfect ? 0 : 1;
				continue;
			}
			else if (family == 9)
			{
				count += g_SkillEvents[index].perfect ? 1 : 0;
				continue;
			}
		}

		int mapped = (team == L4DTeam_Survivor)
			? Announce_MapSurvivorTableFamily(g_SkillEvents[index].type)
			: Announce_MapInfectedTableFamily(g_SkillEvents[index].type);
		if (mapped == family)
		{
			count++;
		}
	}

	return count;
}

int Announce_GetTableScoreForClient(int client, L4DTeam team)
{
	int total = 0;
	if (team == L4DTeam_Survivor)
	{
		for (int family = 0; family < L4D2_SKILLS_SURVIVOR_TABLE_FAMILIES; family++)
		{
			if (Announce_IsSurvivorTableFamilyVisible(family))
			{
				total += Announce_CountSurvivorTableFamilyForClient(client, family);
			}
		}

		return total;
	}

	for (int family = 0; family < L4D2_SKILLS_INFECTED_TABLE_FAMILIES; family++)
	{
		if (Announce_IsInfectedTableFamilyVisible(family))
		{
			total += Announce_CountInfectedTableFamilyForClient(client, family);
		}
	}

	return total;
}

int Announce_CollectSortedHumanSkillClients(L4DTeam team, int[] clients, int maxClients)
{
	int count = 0;
	for (int client = 1; client <= MaxClients && count < maxClients; client++)
	{
		if (!IsValidClient(client) || IsFakeClient(client) || GetClientL4DTeam(client) != team)
		{
			continue;
		}

		clients[count++] = client;
	}

	for (int i = 1; i < count; i++)
	{
		int key = clients[i];
		int keyScore = Announce_GetTableScoreForClient(key, team);
		int j = i - 1;

		while (j >= 0 && Announce_GetTableScoreForClient(clients[j], team) < keyScore)
		{
			clients[j + 1] = clients[j];
			j--;
		}

		clients[j + 1] = key;
	}

	return count;
}

void Announce_GetSurvivorTableGroupName(int group, char[] buffer, int maxlen)
{
	switch (group)
	{
		case 0: strcopy(buffer, maxlen, "[Hunter]");
		case 1: strcopy(buffer, maxlen, "[Jockey]");
		case 2: strcopy(buffer, maxlen, "[Smoker]");
		case 3: strcopy(buffer, maxlen, "[Boomer]");
		case 4: strcopy(buffer, maxlen, "[Charger]");
		case 5: strcopy(buffer, maxlen, "[Bosses]");
		case 6: strcopy(buffer, maxlen, "[Misc]");
		default: buffer[0] = '\0';
	}
}

void Announce_GetInfectedTableGroupName(int group, char[] buffer, int maxlen)
{
	switch (group)
	{
		case 0: strcopy(buffer, maxlen, "[Hunter]");
		case 1: strcopy(buffer, maxlen, "[Jockey]");
		case 2: strcopy(buffer, maxlen, "[Smoker]");
		case 3: strcopy(buffer, maxlen, "[Boomer]");
		case 4: strcopy(buffer, maxlen, "[Charger]");
		case 5: strcopy(buffer, maxlen, "[Tank]");
		default: buffer[0] = '\0';
	}
}

int Announce_GetSurvivorTableFamilyGroup(int family)
{
	switch (family)
	{
		case 0, 1, 2, 3: return 0;
		case 4, 5, 6: return 1;
		case 7, 8, 9: return 2;
		case 10: return 3;
		case 11, 12: return 4;
		case 13, 14: return 5;
		case 15, 16, 17: return 6;
	}

	return -1;
}

int Announce_GetInfectedTableFamilyGroup(int family)
{
	switch (family)
	{
		case 0, 1: return 0;
		case 2, 3, 4: return 1;
		case 5: return 2;
		case 6, 7, 8, 9: return 3;
		case 10, 11, 12, 13, 14, 15: return 4;
		case 16, 17: return 5;
	}

	return -1;
}

bool Announce_DoesTableFamilyHaveAnyData(L4DTeam team, int family, const int[] players, int playerCount, bool hasAiColumn)
{
	for (int i = 0; i < playerCount; i++)
	{
		int value = (team == L4DTeam_Survivor)
			? Announce_CountSurvivorTableFamilyForClient(players[i], family)
			: Announce_CountInfectedTableFamilyForClient(players[i], family);
		if (value > 0)
		{
			return true;
		}
	}

	if (hasAiColumn && Announce_CountTableFamilyForBots(team, family) > 0)
	{
		return true;
	}

	return false;
}

bool Announce_DoesTableGroupHaveAnyData(L4DTeam team, int group, const int[] players, int playerCount, bool hasAiColumn)
{
	int familyCount = (team == L4DTeam_Survivor) ? L4D2_SKILLS_SURVIVOR_TABLE_FAMILIES : L4D2_SKILLS_INFECTED_TABLE_FAMILIES;
	for (int family = 0; family < familyCount; family++)
	{
		bool visible = (team == L4DTeam_Survivor)
			? Announce_IsSurvivorTableFamilyVisible(family)
			: Announce_IsInfectedTableFamilyVisible(family);
		if (!visible)
		{
			continue;
		}

		int familyGroup = (team == L4DTeam_Survivor)
			? Announce_GetSurvivorTableFamilyGroup(family)
			: Announce_GetInfectedTableFamilyGroup(family);
		if (familyGroup != group)
		{
			continue;
		}

		if (Announce_DoesTableFamilyHaveAnyData(team, family, players, playerCount, hasAiColumn))
		{
			return true;
		}
	}

	return false;
}
