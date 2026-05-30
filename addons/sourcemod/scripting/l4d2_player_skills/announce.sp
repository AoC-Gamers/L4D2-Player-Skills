#if defined _l4d2_player_skills_announce_included
	#endinput
#endif
#define _l4d2_player_skills_announce_included

int g_iAnnounceSortSession = -1;

#define L4D2_SKILLS_SURVIVOR_TABLE_FAMILIES 17
#define L4D2_SKILLS_INFECTED_TABLE_FAMILIES 18

bool Announce_HasMask(ConVar cvar, int bit)
{
	return cvar != null && (cvar.IntValue & bit) != 0;
}

void Announce_FormatSimpleKillStat(int damage, int count, char[] buffer, int maxlen)
{
	FormatEx(buffer, maxlen, "%d/%d", damage, count);
}

void Announce_FormatAssistList(int eventIndex, char[] buffer, int maxlen)
{
	buffer[0] = '\0';

	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return;
	}

	for (int assistIndex = 0; assistIndex < g_SkillEvents[eventIndex].assistsCount && assistIndex < L4D2_SKILLS_MAX_EVENT_ASSISTS; assistIndex++)
	{
		char assistLabel[96];
		FormatEx(assistLabel, sizeof(assistLabel), "%s (%d/%d)",
			g_SkillEvents[eventIndex].assists[assistIndex].name,
			g_SkillEvents[eventIndex].assistDamage[assistIndex],
			g_SkillEvents[eventIndex].assistShots[assistIndex]);

		char segment[128];
		if (assistIndex == 0)
		{
			FormatEx(segment, sizeof(segment), "%s", assistLabel);
		}
		else
		{
			FormatEx(segment, sizeof(segment), ", %s", assistLabel);
		}

		StrCat(buffer, maxlen, segment);
	}
}

void Announce_FormatAssistNames(int eventIndex, char[] buffer, int maxlen)
{
	buffer[0] = '\0';

	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return;
	}

	for (int assistIndex = 0; assistIndex < g_SkillEvents[eventIndex].assistsCount && assistIndex < L4D2_SKILLS_MAX_EVENT_ASSISTS; assistIndex++)
	{
		char segment[128];
		if (assistIndex == 0)
		{
			FormatEx(segment, sizeof(segment), "%s", g_SkillEvents[eventIndex].assists[assistIndex].name);
		}
		else
		{
			FormatEx(segment, sizeof(segment), ", %s", g_SkillEvents[eventIndex].assists[assistIndex].name);
		}

		StrCat(buffer, maxlen, segment);
	}
}

void Announce_ChargerClawSummary(int charger)
{
	if (!Detect_ShouldAnnounceChargerClawSummary(charger))
	{
		return;
	}

	L4D2PlayerRef actor;
	actor.Capture(charger);

	char actorName[64];
	Skills_FormatInfectedPlayerRefName(actor, L4D2ZombieClass_Charger, actorName, sizeof(actorName));

	int victims[MAXPLAYERS + 1];
	int victimCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (Detect_GetChargerClawVictimHits(charger, client) <= 0)
		{
			continue;
		}

		victims[victimCount++] = client;
	}

	for (int pass = 0; pass < victimCount - 1; pass++)
	{
		for (int i = 0; i < victimCount - 1 - pass; i++)
		{
			if (Detect_GetChargerClawVictimDamage(charger, victims[i + 1]) <= Detect_GetChargerClawVictimDamage(charger, victims[i]))
			{
				continue;
			}

			int temp = victims[i];
			victims[i] = victims[i + 1];
			victims[i + 1] = temp;
		}
	}

	char victimList[256];
	victimList[0] = '\0';
	for (int i = 0; i < victimCount; i++)
	{
		char victimName[64];
		GetClientName(victims[i], victimName, sizeof(victimName));

		char segment[96];
		FormatEx(segment, sizeof(segment), "%s%s (%d/%d)",
			i == 0 ? "" : ", ",
			victimName,
			Detect_GetChargerClawVictimDamage(charger, victims[i]),
			Detect_GetChargerClawVictimHits(charger, victims[i]));
		StrCat(victimList, sizeof(victimList), segment);
	}

	char tag[32];
	FormatEx(tag, sizeof(tag), "%T", "Tag1", LANG_SERVER);
	CPrintToChatAll("%s %t", tag,
		"ChargerClawSummary",
		actorName,
		Detect_GetChargerClawTotalHits(charger),
		victimList);
}

void Announce_FormatChargerBowlTargets(int eventIndex, char[] firstName, int firstMaxlen, char[] secondName, int secondMaxlen)
{
	firstName[0] = '\0';
	secondName[0] = '\0';

	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return;
	}

	int charger = g_SkillEvents[eventIndex].actor.ResolveClient();
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		return;
	}

	if (Detect_GetChargerBowlImpactCount(charger) < 2)
	{
		return;
	}

	int firstVictim = Detect_GetChargerBowlImpactVictim(charger, 0);
	int secondVictim = Detect_GetChargerBowlImpactVictim(charger, 1);

	if (IsValidSurvivor(firstVictim))
	{
		GetClientName(firstVictim, firstName, firstMaxlen);
	}

	if (IsValidSurvivor(secondVictim))
	{
		GetClientName(secondVictim, secondName, secondMaxlen);
	}
}

bool Announce_ShouldAnnounceSkill(int eventIndex)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS || g_SkillEvents[eventIndex].id <= 0)
	{
		Skills_Debug(PlayerSkillsDebug_Announce, "Announce rejected. reason=invalid_event eventIndex=%d", eventIndex);
		return false;
	}

	bool shouldAnnounce = false;
	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_HunterSkeet:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_Skeet));
		}
		case L4D2Skill_HunterSkeetMelee:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_SkeetMelee));
		}
		case L4D2Skill_HunterDeadstop:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_Deadstop));
		}
		case L4D2Skill_HunterHighPounce:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_HighPounce));
		}
		case L4D2Skill_BoomerPop:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceBoomer, view_as<int>(PlayerSkillsAnnounceBoomer_Pop));
		}
		case L4D2Skill_BoomerKill:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceBoomer, view_as<int>(PlayerSkillsAnnounceBoomer_Kill));
		}
		case L4D2Skill_BoomerVomitLanded:
		{
			if (!Announce_HasMask(g_cvAnnounceBoomer, view_as<int>(PlayerSkillsAnnounceBoomer_Vomit)))
			{
				shouldAnnounce = false;
			}
			else
			{
				int minTargets = g_cvBoomerVomitMinTargets != null ? g_cvBoomerVomitMinTargets.IntValue : 4;
				shouldAnnounce = minTargets > 0 && g_SkillEvents[eventIndex].amount >= minTargets;
			}
		}
		case L4D2Skill_SmokerTongueCut:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceSmoker, view_as<int>(PlayerSkillsAnnounceSmoker_TongueCut));
		}
		case L4D2Skill_SmokerSelfClear:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceSmoker, view_as<int>(PlayerSkillsAnnounceSmoker_SelfClear));
		}
		case L4D2Skill_SmokerKill:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceSmoker, view_as<int>(PlayerSkillsAnnounceSmoker_Kill));
		}
		case L4D2Skill_HunterKill:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_Kill));
		}
		case L4D2Skill_JockeyHighPounce:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceJockey, view_as<int>(PlayerSkillsAnnounceJockey_HighPounce));
		}
		case L4D2Skill_SmokerLedgeHang:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceSmoker, view_as<int>(PlayerSkillsAnnounceSmoker_LedgeHang));
		}
		case L4D2Skill_JockeyLedgeHang:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceJockey, view_as<int>(PlayerSkillsAnnounceJockey_LedgeHang));
		}
		case L4D2Skill_JockeyJumpStop:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceJockey, view_as<int>(PlayerSkillsAnnounceJockey_JumpStop));
		}
		case L4D2Skill_JockeySkeetMelee:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceJockey, view_as<int>(PlayerSkillsAnnounceJockey_SkeetMelee));
		}
		case L4D2Skill_JockeySkeet:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceJockey, view_as<int>(PlayerSkillsAnnounceJockey_SkeetMelee));
		}
		case L4D2Skill_JockeyKill:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceJockey, view_as<int>(PlayerSkillsAnnounceJockey_Kill));
		}
		case L4D2Skill_SpitterKill:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceSpitter, view_as<int>(PlayerSkillsAnnounceSpitter_Kill));
		}
		case L4D2Skill_ChargerLevel:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_Level));
		}
		case L4D2Skill_ChargerInstaKill:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_InstaKill));
		}
		case L4D2Skill_ChargerDeathSetup:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_DeathSetup));
		}
		case L4D2Skill_ChargerLedgeHang:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_DeathSetup));
		}
		case L4D2Skill_ChargerKill:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_Kill));
		}
		case L4D2Skill_ChargerBowl:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_Bowl));
		}
		case L4D2Skill_SpecialPinClear:
		{
			switch (view_as<L4D2ZombieClassType>(g_SkillEvents[eventIndex].zombieClass))
			{
				case L4D2ZombieClass_Hunter:
				{
					shouldAnnounce = Announce_HasMask(g_cvAnnounceHunter, view_as<int>(PlayerSkillsAnnounceHunter_SpecialClear));
				}
				case L4D2ZombieClass_Smoker:
				{
					shouldAnnounce = Announce_HasMask(g_cvAnnounceSmoker, view_as<int>(PlayerSkillsAnnounceSmoker_SpecialClear));
				}
				case L4D2ZombieClass_Jockey:
				{
					shouldAnnounce = Announce_HasMask(g_cvAnnounceJockey, view_as<int>(PlayerSkillsAnnounceJockey_SpecialClear));
				}
				case L4D2ZombieClass_Charger:
				{
					shouldAnnounce = Announce_HasMask(g_cvAnnounceCharger, view_as<int>(PlayerSkillsAnnounceCharger_SpecialClear));
				}
			}
		}
		case L4D2Skill_WitchDead:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceWitch, view_as<int>(PlayerSkillsAnnounceBoss_Damage));
		}
		case L4D2Skill_WitchCrown:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceWitch, view_as<int>(PlayerSkillsAnnounceBoss_Crown));
		}
		case L4D2Skill_TankRockSkeet:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceTank, 2);
		}
		case L4D2Skill_TankRockHit:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceTank, 4);
		}
		case L4D2Skill_TankLedgeHang:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceTank, 8);
		}
		case L4D2Skill_BunnyHopStreak:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceOther, view_as<int>(PlayerSkillsAnnounceOther_BunnyHop));
		}
		case L4D2Skill_CarAlarmTriggered:
		{
			shouldAnnounce = Announce_HasMask(g_cvAnnounceOther, view_as<int>(PlayerSkillsAnnounceOther_CarAlarm));
		}
	}

	if (!shouldAnnounce)
	{
		char typeName[48];
		Skills_GetSkillTypeName(g_SkillEvents[eventIndex].type, typeName, sizeof(typeName));
		Skills_Debug(PlayerSkillsDebug_Announce,
			"Announce rejected. event=%d type=%s zombieClass=%d hunterMask=%d smokerMask=%d boomerMask=%d spitterMask=%d jockeyMask=%d chargerMask=%d otherMask=%d tankMask=%d witchMask=%d amount=%d",
			g_SkillEvents[eventIndex].id,
			typeName,
			g_SkillEvents[eventIndex].zombieClass,
			g_cvAnnounceHunter != null ? g_cvAnnounceHunter.IntValue : -1,
			g_cvAnnounceSmoker != null ? g_cvAnnounceSmoker.IntValue : -1,
			g_cvAnnounceBoomer != null ? g_cvAnnounceBoomer.IntValue : -1,
			g_cvAnnounceSpitter != null ? g_cvAnnounceSpitter.IntValue : -1,
			g_cvAnnounceJockey != null ? g_cvAnnounceJockey.IntValue : -1,
			g_cvAnnounceCharger != null ? g_cvAnnounceCharger.IntValue : -1,
			g_cvAnnounceOther != null ? g_cvAnnounceOther.IntValue : -1,
			g_cvAnnounceTank != null ? g_cvAnnounceTank.IntValue : -1,
			g_cvAnnounceWitch != null ? g_cvAnnounceWitch.IntValue : -1,
			g_SkillEvents[eventIndex].amount);
	}

	return shouldAnnounce;
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

bool Announce_WasCommandInvokedFromChat(int client)
{
	return client > 0 && IsValidClient(client) && GetCmdReplySource() == SM_REPLY_TO_CHAT;
}

void Announce_NotifyConsoleDelivery(int client)
{
	if (!Announce_WasCommandInvokedFromChat(client))
	{
		return;
	}

	Announce_ReplyCommand(client, "%t %t", "Tag", "ConsoleDeliveryNotice");
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
		case L4D2Skill_SpecialPinClear: return 4;
		case L4D2Skill_SmokerTongueCut: return 5;
		case L4D2Skill_SmokerSelfClear: return 6;
		case L4D2Skill_BoomerPop: return 7;
		case L4D2Skill_ChargerLevel: return 8;
		case L4D2Skill_CarAlarmTriggered: return 10;
		case L4D2Skill_BunnyHopStreak: return 11;
		case L4D2Skill_WitchCrown: return 12;
		case L4D2Skill_TankRockSkeet: return 13;
		case L4D2Skill_SmokerKill, L4D2Skill_BoomerKill, L4D2Skill_HunterKill, L4D2Skill_SpitterKill, L4D2Skill_JockeyKill, L4D2Skill_ChargerKill: return 14;
		case L4D2Skill_JockeyJumpStop: return 15;
		case L4D2Skill_JockeySkeetMelee: return 16;
		case L4D2Skill_JockeySkeet: return 17;
	}

	return -1;
}

int Announce_MapInfectedTableFamily(L4D2SkillType type)
{
	switch (type)
	{
		case L4D2Skill_HunterHighPounce: return 0;
		case L4D2Skill_JockeyHighPounce: return 2;
		case L4D2Skill_BoomerVomitLanded: return 4;
		case L4D2Skill_SmokerLedgeHang: return 8;
		case L4D2Skill_JockeyLedgeHang: return 9;
		case L4D2Skill_ChargerInstaKill: return 10;
		case L4D2Skill_ChargerDeathSetup: return 11;
		case L4D2Skill_ChargerLedgeHang: return 12;
		case L4D2Skill_TankRockHit: return 13;
		case L4D2Skill_TankLedgeHang: return 14;
		case L4D2Skill_ChargerBowl: return 15;
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
		case 4: strcopy(buffer, maxlen, "SpecialClears");
		case 5: strcopy(buffer, maxlen, "TongueCuts");
		case 6: strcopy(buffer, maxlen, "SmokerClears");
		case 7: strcopy(buffer, maxlen, "BoomerPops");
		case 8: strcopy(buffer, maxlen, "ChargerLevels");
		case 9: strcopy(buffer, maxlen, "LevelPerfect");
		case 10: strcopy(buffer, maxlen, "CarAlarms");
		case 11: strcopy(buffer, maxlen, "BunnyHopStreaks");
		case 12: strcopy(buffer, maxlen, "WitchCrowns");
		case 13: strcopy(buffer, maxlen, "TankRockSkeets");
		case 14: strcopy(buffer, maxlen, "SpecialInfectedKills");
		case 15: strcopy(buffer, maxlen, "JockeyJumpStops");
		case 16: strcopy(buffer, maxlen, "JockeySkeetMelees");
		case 17: strcopy(buffer, maxlen, "JockeySkeets");
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
		case 4: strcopy(buffer, maxlen, "BoomerVomit");
		case 5: strcopy(buffer, maxlen, "BoomerVomitTargets");
		case 6: strcopy(buffer, maxlen, "BoomerVomitPerfect");
		case 7: strcopy(buffer, maxlen, "BoomerVomitBest");
		case 8: strcopy(buffer, maxlen, "SmokerLedgeHangs");
		case 9: strcopy(buffer, maxlen, "JockeyLedgeHangs");
		case 10: strcopy(buffer, maxlen, "ChargerInstaKills");
		case 11: strcopy(buffer, maxlen, "ChargerDeathSetups");
		case 12: strcopy(buffer, maxlen, "ChargerLedgeHangs");
		case 13: strcopy(buffer, maxlen, "TankRockHits");
		case 14: strcopy(buffer, maxlen, "TankLedgeHangs");
		case 15: strcopy(buffer, maxlen, "ChargerBowls");
		case 16: strcopy(buffer, maxlen, "ChargerBowlTargets");
		case 17: strcopy(buffer, maxlen, "ChargerBowlBest");
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
		case 4: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SpecialPinClear);
		case 5: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SmokerTongueCut);
		case 6: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SmokerSelfClear);
		case 7: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_BoomerPop);
		case 8: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerLevel);
		case 9: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerLevel);
		case 10: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_CarAlarmTriggered);
		case 11: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_BunnyHopStreak);
		case 12: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_WitchCrown);
		case 13: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_TankRockSkeet);
		case 14:
		{
			return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SmokerKill)
				|| Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_BoomerKill)
				|| Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterKill)
				|| Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SpitterKill)
				|| Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyKill)
				|| Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerKill);
		}
		case 15: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyJumpStop);
		case 16: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeySkeetMelee);
		case 17: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeySkeet);
	}

	return false;
}

bool Announce_IsInfectedTableFamilyVisible(int family)
{
	switch (family)
	{
		case 0: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterHighPounce);
		case 1: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_HunterHighPounce);
		case 2: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyHighPounce);
		case 3: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyHighPounce);
		case 4, 5, 6, 7: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_BoomerVomitLanded);
		case 8: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_SmokerLedgeHang);
		case 9: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_JockeyLedgeHang);
		case 10: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerInstaKill);
		case 11: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerDeathSetup);
		case 12: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerLedgeHang);
		case 13: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_TankRockHit);
		case 14: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_TankLedgeHang);
		case 15, 16, 17: return Skills_IsSkillTypeEnabledInCurrentMode(L4D2Skill_ChargerBowl);
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
		case 4: return Announce_CountSkillTypeForClient(client, L4D2Skill_SpecialPinClear);
		case 5: return Announce_CountSkillTypeForClient(client, L4D2Skill_SmokerTongueCut);
		case 6: return Announce_CountSkillTypeForClient(client, L4D2Skill_SmokerSelfClear);
		case 7: return Announce_CountSkillTypeForClient(client, L4D2Skill_BoomerPop);
		case 8: return Announce_CountNonPerfectSkillTypeForClient(client, L4D2Skill_ChargerLevel);
		case 9: return Announce_CountPerfectSkillTypeForClient(client, L4D2Skill_ChargerLevel);
		case 10: return Announce_CountSkillTypeForClient(client, L4D2Skill_CarAlarmTriggered);
		case 11: return Announce_CountSkillTypeForClient(client, L4D2Skill_BunnyHopStreak);
		case 12: return Announce_CountSkillTypeForClient(client, L4D2Skill_WitchCrown);
		case 13: return Announce_CountSkillTypeForClient(client, L4D2Skill_TankRockSkeet);
		case 14:
		{
			return Announce_CountSkillTypeForClient(client, L4D2Skill_SmokerKill)
				+ Announce_CountSkillTypeForClient(client, L4D2Skill_BoomerKill)
				+ Announce_CountSkillTypeForClient(client, L4D2Skill_HunterKill)
				+ Announce_CountSkillTypeForClient(client, L4D2Skill_SpitterKill)
				+ Announce_CountSkillTypeForClient(client, L4D2Skill_JockeyKill)
				+ Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerKill);
		}
		case 15: return Announce_CountSkillTypeForClient(client, L4D2Skill_JockeyJumpStop);
		case 16: return Announce_CountSkillTypeForClient(client, L4D2Skill_JockeySkeetMelee);
		case 17: return Announce_CountSkillTypeForClient(client, L4D2Skill_JockeySkeet);
	}

	return 0;
}

int Announce_CountInfectedTableFamilyForClient(int client, int family)
{
	switch (family)
	{
		case 0: return Announce_CountSkillTypeForClient(client, L4D2Skill_HunterHighPounce);
		case 1: return Announce_MaxSkillHeightForClient(client, L4D2Skill_HunterHighPounce);
		case 2: return Announce_CountSkillTypeForClient(client, L4D2Skill_JockeyHighPounce);
		case 3: return Announce_MaxSkillHeightForClient(client, L4D2Skill_JockeyHighPounce);
		case 4: return Announce_CountSkillTypeForClient(client, L4D2Skill_BoomerVomitLanded);
		case 5: return Announce_SumSkillAmountForClient(client, L4D2Skill_BoomerVomitLanded);
		case 6: return Announce_CountPerfectSkillTypeForClient(client, L4D2Skill_BoomerVomitLanded);
		case 7: return Announce_MaxSkillAmountForClient(client, L4D2Skill_BoomerVomitLanded);
		case 8: return Announce_CountSkillTypeForClient(client, L4D2Skill_SmokerLedgeHang);
		case 9: return Announce_CountSkillTypeForClient(client, L4D2Skill_JockeyLedgeHang);
		case 10: return Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerInstaKill);
		case 11: return Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerDeathSetup);
		case 12: return Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerLedgeHang);
		case 13: return Announce_CountSkillTypeForClient(client, L4D2Skill_TankRockHit);
		case 14: return Announce_CountSkillTypeForClient(client, L4D2Skill_TankLedgeHang);
		case 15: return Announce_CountSkillTypeForClient(client, L4D2Skill_ChargerBowl);
		case 16: return Announce_SumSkillAmountForClient(client, L4D2Skill_ChargerBowl);
		case 17: return Announce_MaxSkillAmountForClient(client, L4D2Skill_ChargerBowl);
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

		if (team == L4DTeam_Infected && g_SkillEvents[index].type == L4D2Skill_JockeyHighPounce)
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

void Announce_RenderSkillsTeamTable(int client, L4DTeam team, int focusClient)
{
	if (team != L4DTeam_Survivor && team != L4DTeam_Infected)
	{
		return;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 110);
	ConsolePanel_EnableSafeAscii(panel, true);

	char line[192];
	Format(line, sizeof(line), "Skills -- %s", team == L4DTeam_Survivor ? "Survivors" : "Infected");
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

	ConsoleTable_AddColumn(panel.table, "Metrica", 20, ConsoleTableAlignment_Left, ConsoleTableCellType_String);

	int players[MAXPLAYERS + 1];
	int playerCount = Announce_CollectSortedHumanSkillClients(team, players, sizeof(players));
	for (int i = 0; i < playerCount; i++)
	{
		char playerName[32];
		Format(playerName, sizeof(playerName), "%s%N", players[i] == focusClient ? ">" : "", players[i]);
		ConsoleTable_AddColumn(panel.table, playerName, 12, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}

	bool hasAiColumn = false;
	int familyCount = (team == L4DTeam_Survivor) ? L4D2_SKILLS_SURVIVOR_TABLE_FAMILIES : L4D2_SKILLS_INFECTED_TABLE_FAMILIES;
	for (int family = 0; family < familyCount; family++)
	{
		int aiValue = Announce_CountTableFamilyForBots(team, family);
		if (aiValue > 0)
		{
			hasAiColumn = true;
			break;
		}
	}

	if (hasAiColumn)
	{
		ConsoleTable_AddColumn(panel.table, "IA", 12, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}

	for (int family = 0; family < familyCount; family++)
	{
		bool visible = (team == L4DTeam_Survivor)
			? Announce_IsSurvivorTableFamilyVisible(family)
			: Announce_IsInfectedTableFamilyVisible(family);
		if (!visible || !ConsoleTable_BeginRow(panel.table))
		{
			continue;
		}

		char metricName[32];
		if (team == L4DTeam_Survivor)
		{
			Announce_GetSurvivorTableFamilyName(family, metricName, sizeof(metricName));
		}
		else
		{
			Announce_GetInfectedTableFamilyName(family, metricName, sizeof(metricName));
		}

		ConsoleTable_AddStringCell(panel.table, metricName);
		for (int i = 0; i < playerCount; i++)
		{
			int value = (team == L4DTeam_Survivor)
				? Announce_CountSurvivorTableFamilyForClient(players[i], family)
				: Announce_CountInfectedTableFamilyForClient(players[i], family);
			ConsoleTable_AddIntCell(panel.table, value);
		}

		if (hasAiColumn)
		{
			ConsoleTable_AddIntCell(panel.table, Announce_CountTableFamilyForBots(team, family));
		}

		ConsoleTable_EndRow(panel.table);
	}

	ConsolePanel_RenderToClient(panel, client);
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

void Announce_PrintSimpleKillLine(const char[] tag, char[] line, bool finalize = true, bool withTag = true)
{
	if (finalize)
	{
		StrCat(line, 1024, ".");
	}
	if (withTag)
	{
		CPrintToChatAll("%s %s", tag, line);
		return;
	}

	CPrintToChatAll("%s", line);
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
			char assistList[256];
			char weaponName[64];
			Announce_FormatAssistList(eventIndex, assistList, sizeof(assistList));
			Skills_GetWeaponDisplayName(g_SkillEvents[eventIndex].actorWeaponId, weaponName, sizeof(weaponName));

			if (g_SkillEvents[eventIndex].grenadeLauncher || g_SkillEvents[eventIndex].sniper)
			{
				if (g_SkillEvents[eventIndex].headshot)
				{
					if (g_SkillEvents[eventIndex].assistsCount > 0)
					{
						CPrintToChatAll("%s %t", tag, "HunterSkeetWeaponHeadshotAssist", actorName, victimName, weaponName, assistList);
					}
					else
					{
						CPrintToChatAll("%s %t", tag, "HunterSkeetWeaponHeadshot", actorName, victimName, weaponName);
					}
				}
				else if (g_SkillEvents[eventIndex].perfect)
				{
					CPrintToChatAll("%s %t", tag, "HunterSkeetWeaponPerfect", actorName, victimName, weaponName);
				}
				else if (g_SkillEvents[eventIndex].assistsCount > 0)
				{
					CPrintToChatAll("%s %t", tag, "HunterSkeetWeaponAssist", actorName, victimName, weaponName, assistList);
				}
				else
				{
					CPrintToChatAll("%s %t", tag, "HunterSkeetWeapon", actorName, victimName, weaponName);
				}
			}
			else if (g_SkillEvents[eventIndex].perfect)
			{
				CPrintToChatAll("%s %t", tag,
					g_SkillEvents[eventIndex].shots == 1 ? "PerfectSkeetSingleShot" : "PerfectSkeetMultiShot",
					actorName,
					victimName,
					g_SkillEvents[eventIndex].damage,
					g_SkillEvents[eventIndex].shots);
			}
			else if (g_SkillEvents[eventIndex].assistsCount > 0)
			{
				CPrintToChatAll("%s %t", tag,
					g_SkillEvents[eventIndex].shots == 1 ? "SkeetSingleShotAssisted" : "SkeetMultiShotAssisted",
					actorName,
					victimName,
					g_SkillEvents[eventIndex].damage,
					g_SkillEvents[eventIndex].shots,
					assistList);
			}
			else if (g_SkillEvents[eventIndex].shots == 1)
			{
				CPrintToChatAll("%s %t", tag, "SkeetSingleShot",
					actorName,
					victimName,
					g_SkillEvents[eventIndex].damage,
					g_SkillEvents[eventIndex].shots);
			}
			else
			{
				CPrintToChatAll("%s %t", tag, "SkeetMultiShot",
					actorName,
					victimName,
					g_SkillEvents[eventIndex].damage,
					g_SkillEvents[eventIndex].shots);
			}
		}

		case L4D2Skill_HunterSkeetMelee:
		{
			char assistList[256];
			Announce_FormatAssistList(eventIndex, assistList, sizeof(assistList));
			int assistDamageTotal = 0;
			for (int i = 0; i < g_SkillEvents[eventIndex].assistsCount && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
			{
				assistDamageTotal += g_SkillEvents[eventIndex].assistDamage[i];
			}

			int actorMeleeDamage = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Hunter) - assistDamageTotal;
			if (actorMeleeDamage < 0)
			{
				actorMeleeDamage = 0;
			}

			int actorMeleeShots = g_SkillEvents[eventIndex].actorChipShots + 1;
			char meleeStat[64];
			Announce_FormatSimpleKillStat(actorMeleeDamage, actorMeleeShots, meleeStat, sizeof(meleeStat));

			if (g_SkillEvents[eventIndex].perfect)
			{
				CPrintToChatAll("%s %t", tag,
					"SkeetMeleePerfect",
					actorName,
					victimName);
			}
			else if (g_SkillEvents[eventIndex].actorChipDamage > 0 && g_SkillEvents[eventIndex].assistsCount > 0)
			{
				CPrintToChatAll("%s %t", tag,
					"SkeetMeleeStatAssist",
					actorName,
					victimName,
					meleeStat,
					assistList);
			}
			else if (g_SkillEvents[eventIndex].actorChipDamage > 0)
			{
				CPrintToChatAll("%s %t", tag,
					"SkeetMeleeStat",
					actorName,
					victimName,
					meleeStat);
			}
			else if (g_SkillEvents[eventIndex].assistsCount > 0)
			{
				CPrintToChatAll("%s %t", tag,
					"SkeetMeleeStatAssist",
					actorName,
					victimName,
					meleeStat,
					assistList);
			}
			else
			{
				CPrintToChatAll("%s %t", tag,
					"SkeetMelee",
					actorName,
					victimName);
			}
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

		case L4D2Skill_SmokerLedgeHang:
		{
			CPrintToChatAll("%s %t", tag, "SmokerLedgeHang",
				actorName,
				victimName);
		}

		case L4D2Skill_JockeyLedgeHang:
		{
			CPrintToChatAll("%s %t", tag, "JockeyLedgeHang",
				actorName,
				victimName);
		}

		case L4D2Skill_JockeyJumpStop:
		{
			CPrintToChatAll("%s %t", tag, "JockeyJumpStop",
				actorName,
				victimName);
		}

		case L4D2Skill_JockeySkeetMelee:
		{
			CPrintToChatAll("%s %t", tag, "JockeySkeetMelee",
				actorName,
				victimName);
		}

		case L4D2Skill_JockeySkeet:
		{
			char assistList[256];
			char weaponName[64];
			char actorStat[64];
			Announce_FormatAssistList(eventIndex, assistList, sizeof(assistList));
			Announce_FormatSimpleKillStat(g_SkillEvents[eventIndex].actorDamage, g_SkillEvents[eventIndex].shots, actorStat, sizeof(actorStat));
			Skills_GetWeaponDisplayName(g_SkillEvents[eventIndex].actorWeaponId, weaponName, sizeof(weaponName));
			bool specialWeapon = g_SkillEvents[eventIndex].sniper
				|| g_SkillEvents[eventIndex].grenadeLauncher
				|| g_SkillEvents[eventIndex].actorWeaponId == view_as<int>(L4D2WeaponId_PistolMagnum);

			if (g_SkillEvents[eventIndex].headshot)
			{
				if (specialWeapon && g_SkillEvents[eventIndex].assistsCount > 0)
				{
					CPrintToChatAll("%s %t", tag, "JockeySkeetWeaponHeadshotAssist", actorName, victimName, weaponName, actorStat, assistList);
				}
				else if (specialWeapon)
				{
					CPrintToChatAll("%s %t", tag, "JockeySkeetWeaponHeadshot", actorName, victimName, weaponName, actorStat);
				}
				else if (g_SkillEvents[eventIndex].assistsCount > 0)
				{
					CPrintToChatAll("%s %t", tag, "JockeySkeetHeadshotAssist", actorName, victimName, actorStat, assistList);
				}
				else
				{
					CPrintToChatAll("%s %t", tag, "JockeySkeetHeadshot", actorName, victimName, actorStat);
				}
			}
			else if (specialWeapon && g_SkillEvents[eventIndex].assistsCount > 0)
			{
				CPrintToChatAll("%s %t", tag, "JockeySkeetWeaponAssist", actorName, victimName, weaponName, actorStat, assistList);
			}
			else if (specialWeapon)
			{
				CPrintToChatAll("%s %t", tag, "JockeySkeetWeapon", actorName, victimName, weaponName, actorStat);
			}
			else if (g_SkillEvents[eventIndex].assistsCount > 0)
			{
				CPrintToChatAll("%s %t", tag, "JockeySkeetAssist", actorName, victimName, actorStat, assistList);
			}
			else
			{
				CPrintToChatAll("%s %t", tag, "JockeySkeet", actorName, victimName, actorStat);
			}
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
			char assistList[256];
			Announce_FormatAssistList(eventIndex, assistList, sizeof(assistList));

			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].withShove
					? (g_SkillEvents[eventIndex].assistsCount > 0 ? "SmokerSelfClearShoveAssist" : "SmokerSelfClearShove")
					: (g_SkillEvents[eventIndex].headshot
						? (g_SkillEvents[eventIndex].assistsCount > 0 ? "SmokerSelfClearHeadshotAssist" : "SmokerSelfClearHeadshot")
						: (g_SkillEvents[eventIndex].assistsCount > 0 ? "SmokerSelfClearKillAssist" : "SmokerSelfClearKill")),
				actorName,
				victimName,
				assistList);
		}

		case L4D2Skill_BoomerPop:
		{
			char timeText[16];
			char assistList[256];
			FormatEx(timeText, sizeof(timeText), "%.1f", g_SkillEvents[eventIndex].timeA);
			Announce_FormatAssistList(eventIndex, assistList, sizeof(assistList));

			if (g_SkillEvents[eventIndex].victim.bot)
			{
				CPrintToChatAll("%s %t", tag,
					g_SkillEvents[eventIndex].headshot
						? (g_SkillEvents[eventIndex].assistsCount > 0 ? "BoomerPopBotHeadshotAssist" : "BoomerPopBotHeadshot")
						: (g_SkillEvents[eventIndex].assistsCount > 0 ? "BoomerPopBotAssist" : "BoomerPopBot"),
					actorName,
					timeText,
					assistList);
			}
			else
			{
				CPrintToChatAll("%s %t", tag,
					g_SkillEvents[eventIndex].headshot
						? (g_SkillEvents[eventIndex].assistsCount > 0 ? "BoomerPopPlayerHeadshotAssist" : "BoomerPopPlayerHeadshot")
						: (g_SkillEvents[eventIndex].assistsCount > 0 ? "BoomerPopPlayerAssist" : "BoomerPopPlayer"),
					actorName,
					victimName,
					timeText,
					assistList);
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
			char assistList[256];
			Announce_FormatAssistList(eventIndex, assistList, sizeof(assistList));
			int assistDamageTotal = 0;
			for (int i = 0; i < g_SkillEvents[eventIndex].assistsCount && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
			{
				assistDamageTotal += g_SkillEvents[eventIndex].assistDamage[i];
			}

			int actorLevelDamage = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Charger) - assistDamageTotal;
			if (actorLevelDamage < 0)
			{
				actorLevelDamage = 0;
			}

			int actorLevelShots = g_SkillEvents[eventIndex].actorChipDamage > 0
				? g_SkillEvents[eventIndex].actorChipShots + 1
				: 0;
			char chipStat[64];
			Announce_FormatSimpleKillStat(
				actorLevelDamage,
				actorLevelShots,
				chipStat,
				sizeof(chipStat));

			if (g_SkillEvents[eventIndex].perfect)
			{
				CPrintToChatAll("%s %t", tag, "ChargerLevelPerfect", actorName, victimName);
			}
			else if (g_SkillEvents[eventIndex].actorChipDamage > 0 && g_SkillEvents[eventIndex].assistsCount > 0)
			{
				CPrintToChatAll("%s %t", tag, "ChargerLevelStatAssist", actorName, victimName, chipStat, assistList);
			}
			else if (g_SkillEvents[eventIndex].actorChipDamage > 0)
			{
				CPrintToChatAll("%s %t", tag, "ChargerLevelStat", actorName, victimName, chipStat);
			}
			else if (g_SkillEvents[eventIndex].assistsCount > 0)
			{
				CPrintToChatAll("%s %t", tag, "ChargerLevelAssist", actorName, victimName, assistList);
			}
			else
			{
				CPrintToChatAll("%s %t", tag, "ChargerLevel", actorName, victimName);
			}
		}

		case L4D2Skill_ChargerBowl:
		{
			if (g_SkillEvents[eventIndex].amount >= 3)
			{
				CPrintToChatAll("%s %t", tag,
					"ChargerBowlTeam",
					actorName);
			}
			else
			{
				char firstTarget[64];
				char secondTarget[64];
				Announce_FormatChargerBowlTargets(eventIndex, firstTarget, sizeof(firstTarget), secondTarget, sizeof(secondTarget));

				CPrintToChatAll("%s %t", tag,
					"ChargerBowlPair",
					actorName,
					firstTarget,
					secondTarget);
			}
		}

		case L4D2Skill_ChargerInstaKill:
		{
			char phrase[48];
			char assistNames[256];
			Announce_FormatAssistNames(eventIndex, assistNames, sizeof(assistNames));
			if (g_SkillEvents[eventIndex].incapped)
			{
				strcopy(phrase, sizeof(phrase), "ChargerInstaKillIncapSimple");
			}
			else if (g_SkillEvents[eventIndex].wasCarried)
			{
				if (g_SkillEvents[eventIndex].deadlySlam)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillCarryDeadly");
				}
				else if (g_SkillEvents[eventIndex].fatalFall)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillCarryFatalFall");
				}
				else
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillCarry");
				}
			}
			else
			{
				if (g_SkillEvents[eventIndex].deadlySlam)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillImpactDeadly");
				}
				else if (g_SkillEvents[eventIndex].fatalFall)
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillImpactFatalFall");
				}
				else
				{
					strcopy(phrase, sizeof(phrase), "ChargerInstaKillImpact");
				}
			}

			if (g_SkillEvents[eventIndex].assistsCount > 0)
			{
				if (g_SkillEvents[eventIndex].incapped)
				{
					CPrintToChatAll("%s %t %t", tag,
						phrase,
						actorName,
						victimName,
						"SkillAssistSuffix",
						assistNames);
				}
				else
				{
					CPrintToChatAll("%s %t %t", tag,
						phrase,
						actorName,
						victimName,
						g_SkillEvents[eventIndex].height,
						"SkillAssistSuffix",
						assistNames);
				}
			}
			else
			{
				if (g_SkillEvents[eventIndex].incapped)
				{
					CPrintToChatAll("%s %t", tag, phrase, actorName, victimName);
				}
				else
				{
					CPrintToChatAll("%s %t", tag,
						phrase,
						actorName,
						victimName,
						g_SkillEvents[eventIndex].height);
				}
			}
		}

		case L4D2Skill_ChargerDeathSetup:
		{
			CPrintToChatAll("%s %t", tag,
				"ChargerDeathSetupIncap",
				actorName,
				victimName);
		}

		case L4D2Skill_ChargerLedgeHang:
		{
			CPrintToChatAll("%s %t", tag,
				"ChargerLedgeHang",
				actorName,
				victimName);
		}

		case L4D2Skill_WitchDead:
		{
			if (g_SkillEvents[eventIndex].actor2 > 0)
			{
				int sessionIndex = API_GetBossSessionIndexById(g_SkillEvents[eventIndex].actor2);
				if (sessionIndex != -1)
				{
					Announce_WitchDamage(sessionIndex, false, "Tag1");
				}
			}
		}

		case L4D2Skill_WitchCrown:
		{
			char crownStat[64];
			char assistList[256];
			Announce_FormatSimpleKillStat(
				g_SkillEvents[eventIndex].actorDamage,
				g_SkillEvents[eventIndex].shots,
				crownStat,
				sizeof(crownStat));
			Announce_FormatAssistList(eventIndex, assistList, sizeof(assistList));

			if (g_SkillEvents[eventIndex].perfect)
			{
				CPrintToChatAll("%s %t", tag, "WitchCrownPerfect",
					actorName,
					crownStat);
			}
			else if (g_SkillEvents[eventIndex].assistsCount > 0)
			{
				CPrintToChatAll("%s %t", tag, "WitchCrownAssist",
					actorName,
					crownStat,
					assistList);
			}
			else
			{
				CPrintToChatAll("%s %t", tag, "WitchCrown",
					actorName,
					crownStat);
			}
		}

		case L4D2Skill_TankRockSkeet:
		{
			CPrintToChatAll("%s %t", tag, "TankRockSkeet",
				actorName);
		}

		case L4D2Skill_TankRockHit:
		{
			char line[192];
			FormatEx(line, sizeof(line), "%T", "TankRockHit",
				LANG_SERVER,
				victimName);
			CPrintToChatAll("%s %s", tag, line);
		}

		case L4D2Skill_TankLedgeHang:
		{
			CPrintToChatAll("%s %t", tag, "TankLedgeHang",
				actorName,
				victimName);
		}

		case L4D2Skill_SmokerKill, L4D2Skill_BoomerKill, L4D2Skill_HunterKill, L4D2Skill_SpitterKill, L4D2Skill_JockeyKill, L4D2Skill_ChargerKill:
		{
			FormatEx(tag, sizeof(tag), "%T", "Tag1", LANG_SERVER);
			char line[1024];
			char actorStat[64];
			Announce_FormatSimpleKillStat(
				g_SkillEvents[eventIndex].actorDamage,
				g_SkillEvents[eventIndex].shots,
				actorStat,
				sizeof(actorStat));

			FormatEx(line, sizeof(line), "%T",
				g_SkillEvents[eventIndex].headshot ? "SpecialInfectedKillLeadHeadshot" : "SpecialInfectedKillLead",
				LANG_SERVER,
				victimName,
				actorName,
				actorStat);

			for (int assistIndex = 0; assistIndex < g_SkillEvents[eventIndex].assistsCount && assistIndex < L4D2_SKILLS_MAX_EVENT_ASSISTS; assistIndex++)
			{
				char assistSegment[256];
				char assistStat[64];
				Announce_FormatSimpleKillStat(
					g_SkillEvents[eventIndex].assistDamage[assistIndex],
					g_SkillEvents[eventIndex].assistShots[assistIndex],
					assistStat,
					sizeof(assistStat));

				FormatEx(assistSegment, sizeof(assistSegment), "%T",
					assistIndex == 0 ? "SpecialInfectedKillAssistHead" : "SpecialInfectedKillAssistTail",
					LANG_SERVER,
					g_SkillEvents[eventIndex].assists[assistIndex].name,
					assistStat);

				StrCat(line, sizeof(line), assistSegment);
			}

			Announce_PrintSimpleKillLine(tag, line, true, true);
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

void Announce_WitchDamage(int sessionIndex, bool witchAlive, const char[] tagPhrase = "Tag")
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return;
	}

	if (witchAlive)
	{
		if (Announce_HasMask(g_cvAnnounceWitch, view_as<int>(PlayerSkillsAnnounceBoss_Damage)))
		{
			if (g_BossSessions[sessionIndex].incapVictim.userid > 0)
			{
				CPrintToChatAll("%t %t", tagPhrase, "BossWitchHealthRemainingIncap",
					g_BossSessions[sessionIndex].incapVictim.name,
					g_BossSessions[sessionIndex].lastHealth);
			}
			else
			{
				CPrintToChatAll("%t %t", tagPhrase, "BossWitchHealthRemaining",
					g_BossSessions[sessionIndex].lastHealth);
			}
		}

		g_BossSessions[sessionIndex].printed = true;
		g_BossSessions[sessionIndex].state = L4D2BossState_Printed;
		API_FireBossDamageAnnounced(g_BossSessions[sessionIndex].id, g_BossSessions[sessionIndex].type);
		return;
	}
	else
	{
		if (Announce_HasMask(g_cvAnnounceWitch, view_as<int>(PlayerSkillsAnnounceBoss_Damage)))
		{
			CPrintToChatAll("%t %t", tagPhrase, "BossWitchDamageTitle");
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
