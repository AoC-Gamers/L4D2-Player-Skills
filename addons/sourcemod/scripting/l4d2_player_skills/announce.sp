#if defined _l4d2_player_skills_announce_included
	#endinput
#endif
#define _l4d2_player_skills_announce_included

int g_iAnnounceSortSession = -1;

bool Announce_HasMask(ConVar cvar, int bit)
{
	return cvar != null && (cvar.IntValue & bit) != 0;
}

bool Announce_ShouldAnnounceSkill(int eventIndex)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS || g_SkillEvents[eventIndex].id <= 0)
	{
		return false;
	}

	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_HunterSkeet:
		{
			return Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_Skeet));
		}
		case L4D2Skill_HunterSkeetMelee:
		{
			return Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_SkeetMelee));
		}
		case L4D2Skill_HunterDeadstop:
		{
			return Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_Deadstop));
		}
		case L4D2Skill_HunterHighPounce:
		{
			return Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_HighPounce));
		}
		case L4D2Skill_BoomerPop:
		{
			return Announce_HasMask(g_cvAnnounceBoomer, view_as<int>(PlayerSkillsAnnounceBoomer_Pop));
		}
		case L4D2Skill_BoomerKill:
		{
			return Announce_HasMask(g_cvAnnounceBoomer, view_as<int>(PlayerSkillsAnnounceBoomer_Kill));
		}
		case L4D2Skill_BoomerVomitLanded:
		{
			if (!Announce_HasMask(g_cvAnnounceBoomer, view_as<int>(PlayerSkillsAnnounceBoomer_Vomit)))
			{
				return false;
			}

			int survivorLimit = Skills_GetConfiguredSurvivorLimit();
			if (survivorLimit <= 0)
			{
				survivorLimit = 4;
			}

			return g_SkillEvents[eventIndex].amount >= survivorLimit;
		}
		case L4D2Skill_SmokerTongueCut:
		{
			return Announce_HasMask(g_cvAnnounceSmoker, view_as<int>(PlayerSkillsAnnounceSmoker_TongueCut));
		}
		case L4D2Skill_SmokerSelfClear:
		{
			return Announce_HasMask(g_cvAnnounceSmoker, view_as<int>(PlayerSkillsAnnounceSmoker_SelfClear));
		}
		case L4D2Skill_SmokerKill:
		{
			return Announce_HasMask(g_cvAnnounceSmoker, view_as<int>(PlayerSkillsAnnounceSmoker_Kill));
		}
		case L4D2Skill_HunterKill:
		{
			return Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_Kill));
		}
		case L4D2Skill_JockeyHighPounce:
		{
			return Announce_HasMask(g_cvAnnounceJockey, view_as<int>(PlayerSkillsAnnounceJockey_HighPounce));
		}
		case L4D2Skill_JockeyKill:
		{
			return Announce_HasMask(g_cvAnnounceJockey, view_as<int>(PlayerSkillsAnnounceJockey_Kill));
		}
		case L4D2Skill_SpitterKill:
		{
			return Announce_HasMask(g_cvAnnounceSpitter, view_as<int>(PlayerSkillsAnnounceSpitter_Kill));
		}
		case L4D2Skill_ChargerLevel:
		{
			return Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_Level));
		}
		case L4D2Skill_ChargerInstaKill:
		{
			return Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_InstaKill));
		}
		case L4D2Skill_ChargerDeathSetup:
		{
			return Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_DeathSetup));
		}
		case L4D2Skill_ChargerKill:
		{
			return Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_Kill));
		}
		case L4D2Skill_SpecialPinClear:
		{
			switch (view_as<L4D2ZombieClassType>(g_SkillEvents[eventIndex].zombieClass))
			{
				case L4D2ZombieClass_Hunter:
				{
					return Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_SpecialClear));
				}
				case L4D2ZombieClass_Smoker:
				{
					return Announce_HasMask(g_cvAnnounceSmoker, view_as<int>(PlayerSkillsAnnounceSmoker_SpecialClear));
				}
				case L4D2ZombieClass_Jockey:
				{
					return Announce_HasMask(g_cvAnnounceJockey, view_as<int>(PlayerSkillsAnnounceJockey_SpecialClear));
				}
				case L4D2ZombieClass_Charger:
				{
					return Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_SpecialClear));
				}
			}

			return false;
		}
		case L4D2Skill_WitchDead:
		{
			return g_SkillEvents[eventIndex].crown
				&& Announce_HasMask(g_cvAnnounceWitch, view_as<int>(PlayerSkillsAnnounceBoss_Crown));
		}
		case L4D2Skill_TankRockSkeet:
		{
			return Announce_HasMask(g_cvAnnounceTank, view_as<int>(PlayerSkillsAnnounceBoss_RockSkeet));
		}
		case L4D2Skill_TankRockHit:
		{
			return Announce_HasMask(g_cvAnnounceTank, view_as<int>(PlayerSkillsAnnounceBoss_RockHit));
		}
		case L4D2Skill_BunnyHopStreak:
		{
			return Announce_HasMask(g_cvAnnounceOther, view_as<int>(PlayerSkillsAnnounceOther_BunnyHop));
		}
		case L4D2Skill_CarAlarmTriggered:
		{
			return Announce_HasMask(g_cvAnnounceOther, view_as<int>(PlayerSkillsAnnounceOther_CarAlarm));
		}
	}

	return false;
}

bool Announce_ShouldAnnounceBoss(int sessionIndex)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return false;
	}

	switch (g_BossSessions[sessionIndex].type)
	{
		case L4D2Boss_Tank:
		{
			return g_cvAnnounceTank != null && g_cvAnnounceTank.IntValue != 0;
		}
		case L4D2Boss_Witch:
		{
			return g_cvAnnounceWitch != null && g_cvAnnounceWitch.IntValue != 0;
		}
	}

	return false;
}

void Announce_ReplyCommand(int client, const char[] message, any ...)
{
	char buffer[256];
	VFormat(buffer, sizeof(buffer), message, 3);
	CReplyToCommand(client, "%s", buffer);
}

void Announce_RenderSkillsTable(int client, int target)
{
	L4DTeam team = GetClientL4DTeam(target);
	if (team != L4DTeam_Survivor && team != L4DTeam_Infected)
	{
		Announce_ReplyCommand(client, "%t %t", "Tag", "SkillsComparableTableUnavailable");
		return;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 86);
	ConsolePanel_EnableSafeAscii(panel, true);

	char line[160];
	Format(line, sizeof(line), "L4D2 Player Skills");
	ConsolePanel_AddHeaderLine(panel, line);

	Format(line, sizeof(line), "Player: %N | Team: %s", target, team == L4DTeam_Survivor ? "Survivor" : "Infected");
	ConsolePanel_AddHeaderLine(panel, line);

	char baseModeName[24];
	char versusContextName[32];
	Skills_GetModeBaseName(g_Runtime.baseMode, baseModeName, sizeof(baseModeName));
	Skills_GetVersusContextName(g_Runtime.versusContext, versusContextName, sizeof(versusContextName));
	if (g_Runtime.baseMode == PlayerSkillsGameMode_Versus && g_Runtime.versusContext != PlayerSkillsVersusContext_None)
	{
		Format(line, sizeof(line), "Mode: %s | Context: %s | TeamSize: %d", baseModeName, versusContextName, g_Runtime.versusTeamSize);
	}
	else
	{
		Format(line, sizeof(line), "Mode: %s", baseModeName);
	}
	ConsolePanel_AddHeaderLine(panel, line);

	if (team == L4DTeam_Survivor)
	{
		bool showHunter = Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterSkeet);
		bool showBoomer = Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_BoomerPop);
		bool showCharger = Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerLevel);
		bool showSmoker = Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SmokerTongueCut);

		ConsoleTable_AddColumn(panel.table, "Player", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
		if (showHunter)
		{
			ConsoleTable_AddColumn(panel.table, "Sk", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
			ConsoleTable_AddColumn(panel.table, "SM", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
			ConsoleTable_AddColumn(panel.table, "DS", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
		}
		if (showBoomer)
		{
			ConsoleTable_AddColumn(panel.table, "BP", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
		}
		if (showCharger)
		{
			ConsoleTable_AddColumn(panel.table, "Lv", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
		}
		ConsoleTable_AddColumn(panel.table, "Cr", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
		if (showSmoker)
		{
			ConsoleTable_AddColumn(panel.table, "TC", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
			ConsoleTable_AddColumn(panel.table, "SC", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
		}
		ConsoleTable_AddColumn(panel.table, "RS", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);

		int players[MAXPLAYERS + 1];
		int count = Announce_CollectSortedSkillClients(team, players, sizeof(players));
		for (int i = 0; i < count; i++)
		{
			if (!ConsoleTable_BeginRow(panel.table))
			{
				break;
			}

			char playerName[32];
			Format(playerName, sizeof(playerName), "%s%N", players[i] == target ? ">" : "", players[i]);

			ConsoleTable_AddStringCell(panel.table, playerName);
			if (showHunter)
			{
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_HunterSkeet));
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_HunterSkeetMelee));
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_HunterDeadstop));
			}
			if (showBoomer)
			{
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_BoomerPop));
			}
			if (showCharger)
			{
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_ChargerLevel));
			}
			ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_WitchDead));
			if (showSmoker)
			{
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_SmokerTongueCut));
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_SmokerSelfClear));
			}
			ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_TankRockSkeet));
			ConsoleTable_EndRow(panel.table);
		}

		char legendA[160];
		char legendB[160];
		legendA[0] = '\0';
		legendB[0] = '\0';
		if (showHunter)
		{
			StrCat(legendA, sizeof(legendA), "Sk=Skeets SM=SkeetMelees DS=Deadstops ");
		}
		if (showBoomer)
		{
			StrCat(legendA, sizeof(legendA), "BP=BoomerPops ");
		}
		if (showCharger)
		{
			StrCat(legendA, sizeof(legendA), "Lv=Levels ");
		}
		StrCat(legendB, sizeof(legendB), "Cr=Crowns ");
		if (showSmoker)
		{
			StrCat(legendB, sizeof(legendB), "TC=TongueCuts SC=SmokerClears ");
		}
		StrCat(legendB, sizeof(legendB), "RS=RockSkeets");
		if (legendA[0] != '\0')
		{
			ConsolePanel_AddHeaderLine(panel, legendA);
		}
		ConsolePanel_AddHeaderLine(panel, legendB);
	}
	else
	{
		bool showHunter = Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterHighPounce);
		bool showJockey = Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyHighPounce);
		bool showBoomer = Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_BoomerVomitLanded);
		bool showCharger = Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerInstaKill);

		ConsoleTable_AddColumn(panel.table, "Player", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
		if (showHunter)
		{
			ConsoleTable_AddColumn(panel.table, "HP", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
		}
		if (showJockey)
		{
			ConsoleTable_AddColumn(panel.table, "JP", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
		}
		if (showBoomer)
		{
			ConsoleTable_AddColumn(panel.table, "BV", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
		}
		if (showCharger)
		{
			ConsoleTable_AddColumn(panel.table, "IK", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
			ConsoleTable_AddColumn(panel.table, "DS", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
		}
		ConsoleTable_AddColumn(panel.table, "CA", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
		ConsoleTable_AddColumn(panel.table, "RH", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);

		int players[MAXPLAYERS + 1];
		int count = Announce_CollectSortedSkillClients(team, players, sizeof(players));
		for (int i = 0; i < count; i++)
		{
			if (!ConsoleTable_BeginRow(panel.table))
			{
				break;
			}

			char playerName[32];
			Format(playerName, sizeof(playerName), "%s%N", players[i] == target ? ">" : "", players[i]);

			ConsoleTable_AddStringCell(panel.table, playerName);
			if (showHunter)
			{
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_HunterHighPounce));
			}
			if (showJockey)
			{
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_JockeyHighPounce));
			}
			if (showBoomer)
			{
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_BoomerVomitLanded));
			}
			if (showCharger)
			{
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_ChargerInstaKill));
				ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_ChargerDeathSetup));
			}
			ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_CarAlarmTriggered));
			ConsoleTable_AddIntCell(panel.table, Announce_CountSkillTypeForClient(players[i], L4D2Skill_TankRockHit));
			ConsoleTable_EndRow(panel.table);
		}

		char legendA[160];
		char legendB[160];
		legendA[0] = '\0';
		legendB[0] = '\0';
		if (showHunter)
		{
			StrCat(legendA, sizeof(legendA), "HP=HunterPounces ");
		}
		if (showJockey)
		{
			StrCat(legendA, sizeof(legendA), "JP=JockeyPounces ");
		}
		if (showBoomer)
		{
			StrCat(legendA, sizeof(legendA), "BV=BoomerVomit ");
		}
		if (showCharger)
		{
			StrCat(legendB, sizeof(legendB), "IK=InstaKills DS=DeathSetups ");
		}
		StrCat(legendB, sizeof(legendB), "CA=CarAlarms RH=RockHits");
		if (legendA[0] != '\0')
		{
			ConsolePanel_AddHeaderLine(panel, legendA);
		}
		ConsolePanel_AddHeaderLine(panel, legendB);
	}

	ConsolePanel_RenderToClient(panel, client);
}

// Skill summary helpers.
void Announce_PrintSkillsSummaryLine(int client, const int counts[L4D2Skill_Size],
	L4D2SkillType typeA, const char[] phraseA,
	L4D2SkillType typeB, const char[] phraseB,
	L4D2SkillType typeC, const char[] phraseC,
	L4D2SkillType typeD, const char[] phraseD,
	L4D2SkillType typeE, const char[] phraseE,
	L4D2SkillType typeF, const char[] phraseF)
{
	char line[256];
	bool hasAny = false;

	Announce_AppendSkillStat(client, line, sizeof(line), counts, typeA, phraseA, hasAny);
	Announce_AppendSkillStat(client, line, sizeof(line), counts, typeB, phraseB, hasAny);
	Announce_AppendSkillStat(client, line, sizeof(line), counts, typeC, phraseC, hasAny);
	Announce_AppendSkillStat(client, line, sizeof(line), counts, typeD, phraseD, hasAny);
	Announce_AppendSkillStat(client, line, sizeof(line), counts, typeE, phraseE, hasAny);
	Announce_AppendSkillStat(client, line, sizeof(line), counts, typeF, phraseF, hasAny);

	if (hasAny)
	{
		Announce_ReplyCommand(client, "%t %s", "Tag", line);
	}
}

void Announce_AppendSkillStat(int client, char[] line, int maxlen, const int counts[L4D2Skill_Size], L4D2SkillType type, const char[] phrase, bool &hasAny)
{
	if (type <= L4D2Skill_None || type >= L4D2Skill_Size || counts[type] <= 0 || phrase[0] == '\0')
	{
		return;
	}

	if (!Skills_IsSkillTypeEnabledInCurrentMode(type))
	{
		return;
	}

	char label[48];
	FormatEx(label, sizeof(label), "%T", phrase, client);

	if (hasAny)
	{
		StrCat(line, maxlen, " {default}| ");
	}

	char segment[80];
	FormatEx(segment, sizeof(segment), "{green}%s{default}: {olive}%d", label, counts[type]);
	StrCat(line, maxlen, segment);
	hasAny = true;
}

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

		if (type == L4D2Skill_WitchDead && !g_SkillEvents[index].crown)
		{
			continue;
		}

		count++;
	}

	return count;
}

int Announce_GetSkillScoreForClient(int client, L4DTeam team)
{
	if (team == L4DTeam_Survivor)
	{
		return Announce_CountSkillTypeForClient(client, L4D2Skill_HunterSkeet)
			+ Announce_CountSkillTypeForClient(client, L4D2Skill_HunterSkeetMelee)
			+ Announce_CountSkillTypeForClient(client, L4D2Skill_HunterDeadstop)
			+ Announce_CountSkillTypeForClient(client, L4D2Skill_BoomerPop)
			+ Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerLevel)
			+ Announce_CountSkillTypeForClient(client, L4D2Skill_WitchDead)
			+ Announce_CountSkillTypeForClient(client, L4D2Skill_SmokerTongueCut)
			+ Announce_CountSkillTypeForClient(client, L4D2Skill_SmokerSelfClear)
			+ Announce_CountSkillTypeForClient(client, L4D2Skill_TankRockSkeet);
	}

	return Announce_CountSkillTypeForClient(client, L4D2Skill_HunterHighPounce)
		+ Announce_CountSkillTypeForClient(client, L4D2Skill_JockeyHighPounce)
		+ Announce_CountSkillTypeForClient(client, L4D2Skill_BoomerVomitLanded)
		+ Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerInstaKill)
		+ Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerDeathSetup)
		+ Announce_CountSkillTypeForClient(client, L4D2Skill_CarAlarmTriggered)
		+ Announce_CountSkillTypeForClient(client, L4D2Skill_TankRockHit);
}

int Announce_CollectSortedSkillClients(L4DTeam team, int[] clients, int maxClients)
{
	int count = 0;
	for (int client = 1; client <= MaxClients && count < maxClients; client++)
	{
		if (!IsValidClient(client) || GetClientL4DTeam(client) != team)
		{
			continue;
		}

		clients[count++] = client;
	}

	for (int i = 1; i < count; i++)
	{
		int key = clients[i];
		int keyScore = Announce_GetSkillScoreForClient(key, team);
		int j = i - 1;

		while (j >= 0 && Announce_GetSkillScoreForClient(clients[j], team) < keyScore)
		{
			clients[j + 1] = clients[j];
			j--;
		}

		clients[j + 1] = key;
	}

	return count;
}

// Skill event announce flow.
void Announce_GetSkillTag(int eventIndex, char[] buffer, int maxlen)
{
	int rating = Skills_GetEventRating(eventIndex);
	switch (rating)
	{
		case 1:
		{
			strcopy(buffer, maxlen, "[{olive}★{default}]");
			return;
		}
		case 2:
		{
			strcopy(buffer, maxlen, "[{olive}★★{default}]");
			return;
		}
		case 3:
		{
			strcopy(buffer, maxlen, "[{olive}★★★{default}]");
			return;
		}
	}

	FormatEx(buffer, maxlen, "%T", "Tag", LANG_SERVER);
}

void Announce_Skill(int eventId)
{
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	if (!Announce_ShouldAnnounceSkill(eventIndex))
	{
		return;
	}

	char tag[32];
	char actorName[64];
	char victimName[64];
	char assisterName[64];
	char pinVictimName[64];
	Announce_GetSkillTag(eventIndex, tag, sizeof(tag));
	Skills_FormatEventPlayerRoleName(eventIndex, 0, actorName, sizeof(actorName));
	Skills_FormatEventPlayerRoleName(eventIndex, 1, victimName, sizeof(victimName));
	Skills_FormatEventPlayerRoleName(eventIndex, 2, assisterName, sizeof(assisterName));
	Skills_FormatEventPlayerRoleName(eventIndex, 3, pinVictimName, sizeof(pinVictimName));

	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_HunterSkeet:
		{
			if (g_SkillEvents[eventIndex].grenadeLauncher)
			{
				CPrintToChatAll("%s %t", tag,
					g_SkillEvents[eventIndex].wouldQualifyAtBaseline ? "HunterSkeetGLFullHp" : "HunterSkeetGL",
					actorName,
					victimName,
					g_SkillEvents[eventIndex].damage);
			}
			else if (g_SkillEvents[eventIndex].sniper)
			{
				CPrintToChatAll("%s %t", tag,
					g_SkillEvents[eventIndex].wouldQualifyAtBaseline ? "HunterSkeetSniperFullHp" : "HunterSkeetSniper",
					actorName,
					victimName,
					g_SkillEvents[eventIndex].headshot ? "headshot" : "shot");
			}
			else if (g_SkillEvents[eventIndex].wouldQualifyAtBaseline)
			{
				CPrintToChatAll("%s %t", tag,
					g_SkillEvents[eventIndex].shots == 1 ? "SkeetSingleShotFullHp" : "SkeetMultiShotFullHp",
					actorName,
					victimName,
					g_SkillEvents[eventIndex].damage,
					g_SkillEvents[eventIndex].shots);
			}
			else if (g_SkillEvents[eventIndex].assister.userid > 0)
			{
				CPrintToChatAll("%s %t", tag, "SkeetAssisted",
					actorName,
					victimName,
					assisterName);
			}
			else if (g_SkillEvents[eventIndex].shots == 1)
			{
				CPrintToChatAll("%s %t", tag, "SkeetSingleShot",
					actorName,
					victimName,
					g_SkillEvents[eventIndex].shots);
			}
			else
			{
				CPrintToChatAll("%s %t", tag, "SkeetMultiShot",
					actorName,
					victimName,
					g_SkillEvents[eventIndex].shots);
			}
		}

		case L4D2Skill_HunterSkeetMelee:
		{
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].perfect ? "SkeetMeleePerfect" : "SkeetMelee",
				actorName,
				victimName);
		}

		case L4D2Skill_HunterDeadstop:
		{
			CPrintToChatAll("%s %t", tag, "HunterDeadstop",
				actorName,
				victimName);
		}

		case L4D2Skill_HunterHighPounce:
		{
			CPrintToChatAll("%s %t", tag, "HunterHighPounce",
				actorName,
				victimName,
				g_SkillEvents[eventIndex].damage,
				g_SkillEvents[eventIndex].height);
		}

		case L4D2Skill_JockeyHighPounce:
		{
			CPrintToChatAll("%s %t", tag, "JockeyHighPounce",
				actorName,
				victimName,
				g_SkillEvents[eventIndex].height);
		}

		case L4D2Skill_SpecialPinClear:
		{
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].withShove ? "SpecialPinClearShove" : "SpecialPinClear",
				actorName,
				victimName,
				pinVictimName);
		}

		case L4D2Skill_SmokerTongueCut:
		{
			CPrintToChatAll("%s %t", tag, "SmokerTongueCut",
				actorName,
				victimName);
		}

		case L4D2Skill_SmokerSelfClear:
		{
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].withShove ? "SmokerSelfClearShove" : "SmokerSelfClearKill",
				actorName,
				victimName);
		}

		case L4D2Skill_BoomerPop:
		{
			char timeText[16];
			FormatEx(timeText, sizeof(timeText), "%.1f", g_SkillEvents[eventIndex].timeA);

			if (g_SkillEvents[eventIndex].victim.bot)
			{
				CPrintToChatAll("%s %t", tag, "BoomerPopBot",
					actorName,
					timeText);
			}
			else
			{
				CPrintToChatAll("%s %t", tag, "BoomerPopPlayer",
					actorName,
					victimName,
					timeText);
			}
		}

		case L4D2Skill_BoomerVomitLanded:
		{
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].amount == 1 ? "BoomerVomitLandedSingle" : "BoomerVomitLandedMulti",
				actorName,
				g_SkillEvents[eventIndex].amount);
		}

		case L4D2Skill_CarAlarmTriggered:
		{
			bool forced = g_SkillEvents[eventIndex].forced && g_SkillEvents[eventIndex].victim.userid > 0;
			bool indirect = g_SkillEvents[eventIndex].indirect;

			switch (g_SkillEvents[eventIndex].reason)
			{
				case L4D2CarAlarm_Hit:
				{
					if (forced && indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmHitForcedIndirect",
							actorName,
							victimName);
					}
					else if (forced)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmHitAssist",
							actorName,
							victimName);
					}
					else if (indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmHitIndirect",
							actorName);
					}
					else
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmHit",
							actorName);
					}
				}

				case L4D2CarAlarm_Touched:
				{
					if (forced && indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmTouchedForcedIndirect",
							actorName,
							victimName);
					}
					else if (forced)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmTouchedAssist",
							actorName,
							victimName);
					}
					else if (indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmTouchedIndirect",
							actorName);
					}
					else
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmTouched",
							actorName);
					}
				}

				case L4D2CarAlarm_Explosion:
				{
					if (forced && indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmExplosionForcedIndirect",
							actorName,
							victimName);
					}
					else if (forced)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmExplosionAssist",
							actorName,
							victimName);
					}
					else if (indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmExplosionIndirect",
							actorName);
					}
					else
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmExplosion",
							actorName);
					}
				}

				case L4D2CarAlarm_Boomer:
				{
					if (g_SkillEvents[eventIndex].victim.userid > 0)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmBoomerAssist",
							actorName,
							victimName);
					}
					else
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmBoomer",
							actorName);
					}
				}

				default:
				{
					CPrintToChatAll("%s %t", tag, "CarAlarmTriggered",
						actorName);
				}
			}
		}

		case L4D2Skill_BunnyHopStreak:
		{
			char velocityText[16];
			FormatEx(velocityText, sizeof(velocityText), "%.1f", g_SkillEvents[eventIndex].maxVelocity);
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].streak == 1 ? "BunnyHopStreakSingle" : "BunnyHopStreakMulti",
				actorName,
				g_SkillEvents[eventIndex].streak,
				velocityText);
		}

		case L4D2Skill_ChargerLevel:
		{
			CPrintToChatAll("%s %t", tag, g_SkillEvents[eventIndex].perfect ? "ChargerLevelPerfect" : "ChargerLevel",
				actorName,
				victimName);
		}

		case L4D2Skill_ChargerInstaKill:
		{
			char phrase[48];
			if (g_SkillEvents[eventIndex].wasCarried)
			{
				if (g_SkillEvents[eventIndex].ledgeHang)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillCarryLedge");
				}
				else if (g_SkillEvents[eventIndex].deadlySlam)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillCarryDeadly");
				}
				else if (g_SkillEvents[eventIndex].fatalFall)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillCarryFatalFall");
				}
				else if (g_SkillEvents[eventIndex].incapped)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillCarryIncap");
				}
				else
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillCarry");
				}
			}
			else
			{
				if (g_SkillEvents[eventIndex].ledgeHang)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillImpactLedge");
				}
				else if (g_SkillEvents[eventIndex].deadlySlam)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillImpactDeadly");
				}
				else if (g_SkillEvents[eventIndex].fatalFall)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillImpactFatalFall");
				}
				else if (g_SkillEvents[eventIndex].incapped)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillImpactIncap");
				}
				else
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillImpact");
				}
			}

			CPrintToChatAll("%s %t", tag,
				phrase,
				actorName,
				victimName,
				g_SkillEvents[eventIndex].height);
		}

		case L4D2Skill_ChargerDeathSetup:
		{
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].ledgeHang ? "ChargerDeathSetupLedge" : "ChargerDeathSetupIncap",
				actorName,
				victimName);
		}

		case L4D2Skill_WitchDead:
		{
			if (g_SkillEvents[eventIndex].crown)
			{
				CPrintToChatAll("%s %t", tag, "WitchCrown",
					actorName,
					g_SkillEvents[eventIndex].damage);
			}
		}

		case L4D2Skill_TankRockSkeet:
		{
			CPrintToChatAll("%s %t", tag, "TankRockSkeet",
				actorName);
		}

		case L4D2Skill_TankRockHit:
		{
			CPrintToChatAll("%s %t", tag, "TankRockHit",
				victimName);
		}

		case L4D2Skill_SmokerKill, L4D2Skill_BoomerKill, L4D2Skill_HunterKill, L4D2Skill_SpitterKill, L4D2Skill_JockeyKill, L4D2Skill_ChargerKill:
		{
			char line[256];
			FormatEx(line, sizeof(line), "%T", "SpecialInfectedKillLead",
				LANG_SERVER,
				victimName,
				actorName,
				g_SkillEvents[eventIndex].actorDamage);

			for (int assistIndex = 0; assistIndex < g_SkillEvents[eventIndex].assistsCount && assistIndex < L4D2_SKILLS_MAX_EVENT_ASSISTS; assistIndex++)
			{
				char assistSegment[96];
				FormatEx(assistSegment, sizeof(assistSegment), "%T",
					assistIndex == 0 ? "SpecialInfectedKillAssistHead" : "SpecialInfectedKillAssistTail",
					LANG_SERVER,
					g_SkillEvents[eventIndex].assists[assistIndex].name,
					g_SkillEvents[eventIndex].assistDamage[assistIndex]);
				StrCat(line, sizeof(line), assistSegment);
			}

			StrCat(line, sizeof(line), ".");
			CPrintToChatAll("%s %s", tag, line);
		}
	}

	API_FireSkillAnnounced(eventId, g_SkillEvents[eventIndex].type);
}

// Boss announce flow.
void Announce_BossDamage(int sessionIndex)
{
	if (!Announce_ShouldAnnounceBoss(sessionIndex))
	{
		return;
	}

	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return;
	}

	switch (g_BossSessions[sessionIndex].type)
	{
		case L4D2Boss_Tank:
		{
			Announce_TankDamage(sessionIndex, g_BossSessions[sessionIndex].state == L4D2BossState_Escaped && g_BossSessions[sessionIndex].lastHealth > 0);
			return;
		}

		case L4D2Boss_Witch:
		{
			Announce_WitchDamage(sessionIndex, g_BossSessions[sessionIndex].state == L4D2BossState_Escaped && g_BossSessions[sessionIndex].lastHealth > 0);
			return;
		}
	}

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active || g_BossDamage[sessionIndex][entry].damage <= 0)
		{
			continue;
		}

		int percent = 0;
		if (g_BossSessions[sessionIndex].maxHealth > 0)
		{
			percent = RoundToNearest(float(g_BossDamage[sessionIndex][entry].damage) / float(g_BossSessions[sessionIndex].maxHealth) * 100.0);
		}

		CPrintToChatAll("{blue}[{default}%d{blue}] ({default}%d%%{blue}) {olive}%s",
			g_BossDamage[sessionIndex][entry].damage,
			percent,
			g_BossDamage[sessionIndex][entry].player.name);
	}

	g_BossSessions[sessionIndex].printed = true;
	g_BossSessions[sessionIndex].state = L4D2BossState_Printed;

	API_FireBossDamageAnnounced(g_BossSessions[sessionIndex].id, g_BossSessions[sessionIndex].type);
}

// Tank and Witch summary helpers.
void Announce_TankDamage(int sessionIndex, bool tankAlive)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return;
	}

	char bossName[64];
	Announce_GetBossName(sessionIndex, bossName, sizeof(bossName));

	if (tankAlive)
	{
		if (Announce_HasMask(g_cvAnnounceTank, view_as<int>(PlayerSkillsAnnounceBoss_Damage)))
		{
			CPrintToChatAll("%t %t", "Tag", "BossTankHealthRemaining",
				bossName,
				g_BossSessions[sessionIndex].lastHealth);
		}
	}
	else
	{
		if (Announce_HasMask(g_cvAnnounceTank, view_as<int>(PlayerSkillsAnnounceBoss_Damage)))
		{
			CPrintToChatAll("%t %t", "Tag", "BossTankDamageTitle",
				bossName);
		}
	}

	int survivorEntries[L4D2_SKILLS_MAX_DAMAGE_ENTRIES];
	int survivorCount = 0;
	int totalPercent = 0;
	int totalDamage = 0;

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active || g_BossDamage[sessionIndex][entry].damage <= 0)
		{
			continue;
		}

		survivorEntries[survivorCount++] = entry;
		totalDamage += g_BossDamage[sessionIndex][entry].damage;
		totalPercent += Announce_GetDamagePercent(sessionIndex, g_BossDamage[sessionIndex][entry].damage);
	}

	g_iAnnounceSortSession = sessionIndex;
	SortCustom1D(survivorEntries, survivorCount, Announce_SortByDamageDesc);

	int percentAdjustment = 0;
	if (totalPercent < 100
		&& float(totalDamage) > (float(g_BossSessions[sessionIndex].maxHealth) - (float(g_BossSessions[sessionIndex].maxHealth) / 200.0)))
	{
		percentAdjustment = 100 - totalPercent;
	}

	int lastPercent = 100;
	for (int i = 0; i < survivorCount; i++)
	{
		int entry = survivorEntries[i];
		int damage = g_BossDamage[sessionIndex][entry].damage;
		int percent = Announce_GetDamagePercent(sessionIndex, damage);

		if (percentAdjustment != 0 && damage > 0 && !Announce_IsExactPercent(sessionIndex, damage))
		{
			int adjustedPercent = percent + percentAdjustment;
			if (adjustedPercent <= lastPercent)
			{
				percent = adjustedPercent;
				percentAdjustment = 0;
			}
		}

		lastPercent = percent;

		if (Announce_HasMask(g_cvAnnounceTank, view_as<int>(PlayerSkillsAnnounceBoss_Damage)))
		{
			CPrintToChatAll("%t", "BossDamageEntry",
				damage,
				percent,
				g_BossDamage[sessionIndex][entry].player.name);
		}
	}

	g_BossSessions[sessionIndex].printed = true;
	g_BossSessions[sessionIndex].state = L4D2BossState_Printed;

	API_FireBossDamageAnnounced(g_BossSessions[sessionIndex].id, g_BossSessions[sessionIndex].type);
}

void Announce_WitchDamage(int sessionIndex, bool witchAlive)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return;
	}

	if (witchAlive)
	{
		if (Announce_HasMask(g_cvAnnounceWitch, view_as<int>(PlayerSkillsAnnounceBoss_Damage)))
		{
			CPrintToChatAll("%t %t", "Tag", "BossWitchHealthRemaining",
				g_BossSessions[sessionIndex].lastHealth);
		}
	}
	else
	{
		if (Announce_HasMask(g_cvAnnounceWitch, view_as<int>(PlayerSkillsAnnounceBoss_Damage)))
		{
			CPrintToChatAll("%t %t", "Tag", "BossWitchDamageTitle");
		}
	}

	int survivorEntries[L4D2_SKILLS_MAX_DAMAGE_ENTRIES];
	int survivorCount = 0;
	int totalPercent = 0;

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active || g_BossDamage[sessionIndex][entry].damage <= 0)
		{
			continue;
		}

		survivorEntries[survivorCount++] = entry;
		totalPercent += Announce_GetDamagePercent(sessionIndex, g_BossDamage[sessionIndex][entry].damage);
	}

	g_iAnnounceSortSession = sessionIndex;
	SortCustom1D(survivorEntries, survivorCount, Announce_SortByDamageDesc);

	int percentAdjustment = 0;
	if (totalPercent < 100
		&& float(g_BossSessions[sessionIndex].totalDamage) > (float(g_BossSessions[sessionIndex].maxHealth) - (float(g_BossSessions[sessionIndex].maxHealth) / 200.0)))
	{
		percentAdjustment = 100 - totalPercent;
	}

	int lastPercent = 100;
	int restDamage = 0;
	int restPercent = 0;
	int maxEntries = 4;
	char combinedName[64];

	if (g_cvWitchPrintMaxEntries != null)
	{
		maxEntries = g_cvWitchPrintMaxEntries.IntValue;
		if (maxEntries < 1)
		{
			maxEntries = 1;
		}
	}

	Format(combinedName, sizeof(combinedName), "%T", "BossWitchDamageCombinedName", LANG_SERVER);

	for (int i = 0; i < survivorCount; i++)
	{
		int entry = survivorEntries[i];
		int damage = g_BossDamage[sessionIndex][entry].damage;
		int percent = Announce_GetDamagePercent(sessionIndex, damage);

		if (percentAdjustment != 0 && damage > 0 && !Announce_IsExactPercent(sessionIndex, damage))
		{
			int adjustedPercent = percent + percentAdjustment;
			if (adjustedPercent <= lastPercent)
			{
				percent = adjustedPercent;
				percentAdjustment = 0;
			}
		}

		lastPercent = percent;

		if (survivorCount > maxEntries && i >= maxEntries)
		{
			restDamage += damage;
			restPercent += percent;
			continue;
		}

		if (Announce_HasMask(g_cvAnnounceWitch, view_as<int>(PlayerSkillsAnnounceBoss_Damage)))
		{
			CPrintToChatAll("%t",
				Announce_IsWitchCrownerEntry(sessionIndex, entry) ? "BossDamageEntryCrown" : "BossDamageEntry",
				damage,
				percent,
				g_BossDamage[sessionIndex][entry].player.name);
		}
	}

	if (restDamage > 0 && Announce_HasMask(g_cvAnnounceWitch, view_as<int>(PlayerSkillsAnnounceBoss_Damage)))
	{
		CPrintToChatAll("%t", "BossWitchDamageCombined",
			restDamage,
			restPercent,
			combinedName);
	}

	g_BossSessions[sessionIndex].printed = true;
	g_BossSessions[sessionIndex].state = L4D2BossState_Printed;

	API_FireBossDamageAnnounced(g_BossSessions[sessionIndex].id, g_BossSessions[sessionIndex].type);
}

void Announce_WitchKilledByTank(int sessionIndex, int tank)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES)
	{
		return;
	}

	if (!IsValidTank(tank))
	{
		return;
	}

	char tankName[MAX_NAME_LENGTH];
	GetClientName(tank, tankName, sizeof(tankName));
	if (Announce_HasMask(g_cvAnnounceWitch, view_as<int>(PlayerSkillsAnnounceBoss_Misc)))
	{
		CPrintToChatAll("%t %t", "Tag", "WitchKilledByTank", tankName);
	}
}

int Announce_GetDamagePercent(int sessionIndex, int damage)
{
	if (g_BossSessions[sessionIndex].maxHealth <= 0)
	{
		return 0;
	}

	return RoundToNearest((damage / float(g_BossSessions[sessionIndex].maxHealth)) * 100.0);
}

bool Announce_IsExactPercent(int sessionIndex, int damage)
{
	if (g_BossSessions[sessionIndex].maxHealth <= 0)
	{
		return false;
	}

	float actualPercent = (damage / float(g_BossSessions[sessionIndex].maxHealth)) * 100.0;
	float difference = float(Announce_GetDamagePercent(sessionIndex, damage)) - actualPercent;
	return FloatAbs(difference) < 0.001;
}

int Announce_SortByDamageDesc(int elem1, int elem2, const int[] array, Handle hndl)
{
	int damage1 = g_BossDamage[g_iAnnounceSortSession][elem1].damage;
	int damage2 = g_BossDamage[g_iAnnounceSortSession][elem2].damage;

	if (damage1 > damage2)
	{
		return -1;
	}
	if (damage2 > damage1)
	{
		return 1;
	}
	if (elem1 > elem2)
	{
		return -1;
	}
	if (elem2 > elem1)
	{
		return 1;
	}
	return 0;
}

bool Announce_IsWitchCrownerEntry(int sessionIndex, int entry)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES)
	{
		return false;
	}

	if (entry < 0 || entry >= L4D2_SKILLS_MAX_DAMAGE_ENTRIES)
	{
		return false;
	}

	if (!g_BossSessions[sessionIndex].crownDetected)
	{
		return false;
	}

	return g_BossSessions[sessionIndex].crowner.userid > 0
		&& g_BossDamage[sessionIndex][entry].player.userid == g_BossSessions[sessionIndex].crowner.userid;
}

void Announce_GetBossName(int sessionIndex, char[] buffer, int maxlen)
{
	if (g_BossSessions[sessionIndex].owner.name[0] != '\0')
	{
		strcopy(buffer, maxlen, g_BossSessions[sessionIndex].owner.name);
		return;
	}

	switch (g_BossSessions[sessionIndex].type)
	{
		case L4D2Boss_Tank:
		{
			strcopy(buffer, maxlen, "AI");
		}

		case L4D2Boss_Witch:
		{
			strcopy(buffer, maxlen, "Witch");
		}

		default:
		{
			strcopy(buffer, maxlen, "Unknown");
		}
	}
}
