#if defined _l4d2_player_skills_announce_included
	#endinput
#endif
#define _l4d2_player_skills_announce_included

// Announce and chat-command coordinator. This file formats visible output for
// skill events, boss summaries, and lightweight player-facing commands.

int g_iAnnounceSortSession = -1;

// Initialization and commands.
void Announce_Init()
{
	RegConsoleCmd("sm_skills", Command_Skills, "Print a summary of your detected skills.");
}

Action Command_Skills(int client, int args)
{
	if (client <= 0 || !IsValidClient(client))
	{
		char tag[32];
		FormatEx(tag, sizeof(tag), "%T", "Tag", LANG_SERVER);
		ReplyToCommand(client, "%s sm_skills is in-game only.", tag);
		return Plugin_Handled;
	}

	if (!Skills_IsEnabled())
	{
		CPrintToChat(client, "%t {red}Plugin disabled.{default}", "Tag");
		return Plugin_Handled;
	}

	int target = client;
	if (args >= 1)
	{
		char pattern[MAX_TARGET_LENGTH];
		GetCmdArg(1, pattern, sizeof(pattern));

		int targets[1];
		char targetName[MAX_TARGET_LENGTH];
		bool targetNameMl = false;
		int found = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), targetNameMl);
		if (found != 1)
		{
			ReplyToTargetError(client, found);
			return Plugin_Handled;
		}

		target = targets[0];
	}

	char targetName[MAX_NAME_LENGTH];
	GetClientName(target, targetName, sizeof(targetName));

	int counts[L4D2Skill_Size];
	int total = 0;

	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id <= 0 || !g_SkillEvents[index].actor.IsSamePersistentPlayer(target))
		{
			continue;
		}

		switch (g_SkillEvents[index].type)
		{
			case L4D2Skill_WitchDead:
			{
				if (!g_SkillEvents[index].crown)
				{
					continue;
				}
			}

			case L4D2Skill_TankDead, L4D2Skill_WitchIncap, L4D2Skill_TankRockHit:
			{
				continue;
			}
		}

		counts[g_SkillEvents[index].type]++;
		total++;
	}

	if (total <= 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "SkillsSummaryEmpty", targetName);
		return Plugin_Handled;
	}

	CPrintToChat(client, "%t %t", "Tag", "SkillsSummaryHeader", targetName);

	Announce_PrintSkillsSummaryLine(client, counts,
		L4D2Skill_HunterSkeet, "SkillsLabelSkeet",
		L4D2Skill_HunterSkeetMelee, "SkillsLabelSkeetMelee",
		L4D2Skill_HunterDeadstop, "SkillsLabelDeadstop",
		L4D2Skill_BoomerPop, "SkillsLabelPop",
		L4D2Skill_ChargerLevel, "SkillsLabelLevel",
		L4D2Skill_WitchDead, "SkillsLabelCrown");

	Announce_PrintSkillsSummaryLine(client, counts,
		L4D2Skill_SmokerTongueCut, "SkillsLabelTongueCut",
		L4D2Skill_SmokerSelfClear, "SkillsLabelSelfClear",
		L4D2Skill_ChargerInstaKill, "SkillsLabelInstaKill",
		L4D2Skill_ChargerDeathSetup, "SkillsLabelDeathSetup",
		L4D2Skill_SpecialPinClear, "SkillsLabelPinClear",
		L4D2Skill_BunnyHopStreak, "SkillsLabelBHop");

	Announce_PrintSkillsSummaryLine(client, counts,
		L4D2Skill_HunterHighPounce, "SkillsLabelHunterHighPounce",
		L4D2Skill_JockeyHighPounce, "SkillsLabelJockeyHighPounce",
		L4D2Skill_BoomerVomitLanded, "SkillsLabelVomit",
		L4D2Skill_CarAlarmTriggered, "SkillsLabelCarAlarm",
		L4D2Skill_TankRockSkeet, "SkillsLabelRockSkeet",
		L4D2Skill_None, "");

	return Plugin_Handled;
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
		CPrintToChat(client, "%t %s", "Tag", line);
	}
}

void Announce_AppendSkillStat(int client, char[] line, int maxlen, const int counts[L4D2Skill_Size], L4D2SkillType type, const char[] phrase, bool &hasAny)
{
	if (type <= L4D2Skill_None || type >= L4D2Skill_Size || counts[type] <= 0 || phrase[0] == '\0')
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
	if (g_cvAnnounceSkills == null || !g_cvAnnounceSkills.BoolValue)
	{
		return;
	}

	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	char tag[32];
	Announce_GetSkillTag(eventIndex, tag, sizeof(tag));

	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_HunterSkeet:
		{
			if (g_SkillEvents[eventIndex].grenadeLauncher)
			{
				CPrintToChatAll("%s %t", tag,
					g_SkillEvents[eventIndex].wouldQualifyAtBaseline ? "HunterSkeetGLFullHp" : "HunterSkeetGL",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].damage);
			}
			else if (g_SkillEvents[eventIndex].sniper)
			{
				CPrintToChatAll("%s %t", tag,
					g_SkillEvents[eventIndex].wouldQualifyAtBaseline ? "HunterSkeetSniperFullHp" : "HunterSkeetSniper",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].headshot ? "headshot" : "shot");
			}
			else if (g_SkillEvents[eventIndex].wouldQualifyAtBaseline)
			{
				CPrintToChatAll("%s %t", tag,
					g_SkillEvents[eventIndex].shots == 1 ? "SkeetSingleShotFullHp" : "SkeetMultiShotFullHp",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].damage,
					g_SkillEvents[eventIndex].shots);
			}
			else if (g_SkillEvents[eventIndex].assister.userid > 0)
			{
				CPrintToChatAll("%s %t", tag, "SkeetAssisted",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].assister.name);
			}
			else if (g_SkillEvents[eventIndex].shots == 1)
			{
				CPrintToChatAll("%s %t", tag, "SkeetSingleShot",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].shots);
			}
			else
			{
				CPrintToChatAll("%s %t", tag, "SkeetMultiShot",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].shots);
			}
		}

		case L4D2Skill_HunterSkeetMelee:
		{
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].perfect ? "SkeetMeleePerfect" : "SkeetMelee",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name);
		}

		case L4D2Skill_HunterDeadstop:
		{
			CPrintToChatAll("%s %t", tag, "HunterDeadstop",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name);
		}

		case L4D2Skill_HunterHighPounce:
		{
			CPrintToChatAll("%s %t", tag, "HunterHighPounce",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name,
				g_SkillEvents[eventIndex].damage,
				g_SkillEvents[eventIndex].height);
		}

		case L4D2Skill_JockeyHighPounce:
		{
			CPrintToChatAll("%s %t", tag, "JockeyHighPounce",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name,
				g_SkillEvents[eventIndex].height);
		}

		case L4D2Skill_SpecialPinClear:
		{
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].withShove ? "SpecialPinClearShove" : "SpecialPinClear",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name,
				g_SkillEvents[eventIndex].pinVictim.name);
		}

		case L4D2Skill_SmokerTongueCut:
		{
			CPrintToChatAll("%s %t", tag, "SmokerTongueCut",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name);
		}

		case L4D2Skill_SmokerSelfClear:
		{
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].withShove ? "SmokerSelfClearShove" : "SmokerSelfClearKill",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name);
		}

		case L4D2Skill_BoomerPop:
		{
			char timeText[16];
			FormatEx(timeText, sizeof(timeText), "%.1f", g_SkillEvents[eventIndex].timeA);

			if (g_SkillEvents[eventIndex].victim.bot)
			{
				CPrintToChatAll("%s %t", tag, "BoomerPopBot",
					g_SkillEvents[eventIndex].actor.name,
					timeText);
			}
			else
			{
				CPrintToChatAll("%s %t", tag, "BoomerPopPlayer",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					timeText);
			}
		}

		case L4D2Skill_BoomerVomitLanded:
		{
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].amount == 1 ? "BoomerVomitLandedSingle" : "BoomerVomitLandedMulti",
				g_SkillEvents[eventIndex].actor.name,
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
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (forced)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmHitAssist",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmHitIndirect",
							g_SkillEvents[eventIndex].actor.name);
					}
					else
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmHit",
							g_SkillEvents[eventIndex].actor.name);
					}
				}

				case L4D2CarAlarm_Touched:
				{
					if (forced && indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmTouchedForcedIndirect",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (forced)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmTouchedAssist",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmTouchedIndirect",
							g_SkillEvents[eventIndex].actor.name);
					}
					else
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmTouched",
							g_SkillEvents[eventIndex].actor.name);
					}
				}

				case L4D2CarAlarm_Explosion:
				{
					if (forced && indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmExplosionForcedIndirect",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (forced)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmExplosionAssist",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (indirect)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmExplosionIndirect",
							g_SkillEvents[eventIndex].actor.name);
					}
					else
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmExplosion",
							g_SkillEvents[eventIndex].actor.name);
					}
				}

				case L4D2CarAlarm_Boomer:
				{
					if (g_SkillEvents[eventIndex].victim.userid > 0)
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmBoomerAssist",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else
					{
						CPrintToChatAll("%s %t", tag, "CarAlarmBoomer",
							g_SkillEvents[eventIndex].actor.name);
					}
				}

				default:
				{
					CPrintToChatAll("%s %t", tag, "CarAlarmTriggered",
						g_SkillEvents[eventIndex].actor.name);
				}
			}
		}

		case L4D2Skill_BunnyHopStreak:
		{
			char velocityText[16];
			FormatEx(velocityText, sizeof(velocityText), "%.1f", g_SkillEvents[eventIndex].maxVelocity);
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].streak == 1 ? "BunnyHopStreakSingle" : "BunnyHopStreakMulti",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].streak,
				velocityText);
		}

		case L4D2Skill_ChargerLevel:
		{
			CPrintToChatAll("%s %t", tag, g_SkillEvents[eventIndex].perfect ? "ChargerLevelPerfect" : "ChargerLevel",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name);
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
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name,
				g_SkillEvents[eventIndex].height);
		}

		case L4D2Skill_ChargerDeathSetup:
		{
			CPrintToChatAll("%s %t", tag,
				g_SkillEvents[eventIndex].ledgeHang ? "ChargerDeathSetupLedge" : "ChargerDeathSetupIncap",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name);
		}

		case L4D2Skill_WitchDead:
		{
			if (g_SkillEvents[eventIndex].crown)
			{
				CPrintToChatAll("%s %t", tag, "WitchCrown",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].damage);
			}
		}

		case L4D2Skill_TankRockSkeet:
		{
			CPrintToChatAll("%s %t", tag, "TankRockSkeet",
				g_SkillEvents[eventIndex].actor.name);
		}

		case L4D2Skill_TankRockHit:
		{
			CPrintToChatAll("%s %t", tag, "TankRockHit",
				g_SkillEvents[eventIndex].victim.name);
		}
	}

	API_FireSkillAnnounced(eventId, g_SkillEvents[eventIndex].type);
}

// Boss announce flow.
void Announce_BossDamage(int sessionIndex)
{
	if (g_cvAnnounceBossDamage == null || !g_cvAnnounceBossDamage.BoolValue)
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
		CPrintToChatAll("%t %t", "Tag", "BossTankHealthRemaining",
			bossName,
			g_BossSessions[sessionIndex].lastHealth);
	}
	else
	{
		CPrintToChatAll("%t %t", "Tag", "BossTankDamageTitle",
			bossName);
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

		CPrintToChatAll("%t", "BossDamageEntry",
			damage,
			percent,
			g_BossDamage[sessionIndex][entry].player.name);
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
		CPrintToChatAll("%t %t", "Tag", "BossWitchHealthRemaining",
			g_BossSessions[sessionIndex].lastHealth);
	}
	else
	{
		CPrintToChatAll("%t %t", "Tag", "BossWitchDamageTitle");
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
	char combinedName[64];

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

		if ((g_iWitchPrintMinimum > 0 && percent < g_iWitchPrintMinimum)
			|| (g_iWitchPrintMaxLines > 0 && survivorCount > g_iWitchPrintMaxLines && i + 1 >= g_iWitchPrintMaxLines))
		{
			restDamage += damage;
			restPercent += percent;
			continue;
		}

		CPrintToChatAll("%t",
			Announce_IsWitchCrownerEntry(sessionIndex, entry) ? "BossDamageEntryCrown" : "BossDamageEntry",
			damage,
			percent,
			g_BossDamage[sessionIndex][entry].player.name);
	}

	if (restDamage > 0)
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
	CPrintToChatAll("%t %t", "Tag", "WitchKilledByTank", tankName);
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
