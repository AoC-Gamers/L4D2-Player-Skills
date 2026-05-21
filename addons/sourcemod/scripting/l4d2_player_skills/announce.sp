#if defined _l4d2_player_skills_announce_included
	#endinput
#endif
#define _l4d2_player_skills_announce_included

int g_iAnnounceSortSession = -1;

void Announce_Init()
{
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

	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_HunterSkeet:
		{
			if (g_SkillEvents[eventIndex].grenadeLauncher)
			{
				CPrintToChatAll("%t %t", "Tag",
					g_SkillEvents[eventIndex].wouldQualifyAtBaseline ? "HunterSkeetGLFullHp" : "HunterSkeetGL",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].damage);
			}
			else if (g_SkillEvents[eventIndex].sniper)
			{
				CPrintToChatAll("%t %t", "Tag",
					g_SkillEvents[eventIndex].wouldQualifyAtBaseline ? "HunterSkeetSniperFullHp" : "HunterSkeetSniper",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].headshot ? "headshot" : "shot");
			}
			else if (g_SkillEvents[eventIndex].wouldQualifyAtBaseline)
			{
				CPrintToChatAll("%t %t", "Tag",
					g_SkillEvents[eventIndex].shots == 1 ? "SkeetSingleShotFullHp" : "SkeetMultiShotFullHp",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].damage,
					g_SkillEvents[eventIndex].shots);
			}
			else if (g_SkillEvents[eventIndex].assister.userid > 0)
			{
				CPrintToChatAll("%t %t", "Tag", "SkeetAssisted",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].assister.name);
			}
			else if (g_SkillEvents[eventIndex].shots == 1)
			{
				CPrintToChatAll("%t %t", "Tag", "SkeetSingleShot",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].shots);
			}
			else
			{
				CPrintToChatAll("%t %t", "Tag", "SkeetMultiShot",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					g_SkillEvents[eventIndex].shots);
			}
		}

		case L4D2Skill_HunterSkeetMelee:
		{
			CPrintToChatAll("%t %t", "Tag",
				g_SkillEvents[eventIndex].perfect ? "SkeetMeleePerfect" : "SkeetMelee",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name);
		}

		case L4D2Skill_HunterDeadstop:
		{
			CPrintToChatAll("%t %t", "Tag", "HunterDeadstop",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name);
		}

		case L4D2Skill_HunterHighPounce:
		{
			CPrintToChatAll("%t %t", "Tag", "HunterHighPounce",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name,
				g_SkillEvents[eventIndex].damage,
				g_SkillEvents[eventIndex].height);
		}

		case L4D2Skill_JockeyHighPounce:
		{
			CPrintToChatAll("%t %t", "Tag", "JockeyHighPounce",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name,
				g_SkillEvents[eventIndex].height);
		}

		case L4D2Skill_SpecialPinClear:
		{
			CPrintToChatAll("%t %t", "Tag",
				g_SkillEvents[eventIndex].withShove ? "SpecialPinClearShove" : "SpecialPinClear",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name,
				g_SkillEvents[eventIndex].pinVictim.name);
		}

		case L4D2Skill_SmokerTongueCut:
		{
			CPrintToChatAll("%t %t", "Tag", "SmokerTongueCut",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name);
		}

		case L4D2Skill_SmokerSelfClear:
		{
			CPrintToChatAll("%t %t", "Tag",
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
				CPrintToChatAll("%t %t", "Tag", "BoomerPopBot",
					g_SkillEvents[eventIndex].actor.name,
					timeText);
			}
			else
			{
				CPrintToChatAll("%t %t", "Tag", "BoomerPopPlayer",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].victim.name,
					timeText);
			}
		}

		case L4D2Skill_BoomerVomitLanded:
		{
			CPrintToChatAll("%t %t", "Tag",
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
						CPrintToChatAll("%t %t", "Tag", "CarAlarmHitForcedIndirect",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (forced)
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmHitAssist",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (indirect)
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmHitIndirect",
							g_SkillEvents[eventIndex].actor.name);
					}
					else
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmHit",
							g_SkillEvents[eventIndex].actor.name);
					}
				}

				case L4D2CarAlarm_Touched:
				{
					if (forced && indirect)
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmTouchedForcedIndirect",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (forced)
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmTouchedAssist",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (indirect)
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmTouchedIndirect",
							g_SkillEvents[eventIndex].actor.name);
					}
					else
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmTouched",
							g_SkillEvents[eventIndex].actor.name);
					}
				}

				case L4D2CarAlarm_Explosion:
				{
					if (forced && indirect)
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmExplosionForcedIndirect",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (forced)
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmExplosionAssist",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else if (indirect)
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmExplosionIndirect",
							g_SkillEvents[eventIndex].actor.name);
					}
					else
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmExplosion",
							g_SkillEvents[eventIndex].actor.name);
					}
				}

				case L4D2CarAlarm_Boomer:
				{
					if (g_SkillEvents[eventIndex].victim.userid > 0)
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmBoomerAssist",
							g_SkillEvents[eventIndex].actor.name,
							g_SkillEvents[eventIndex].victim.name);
					}
					else
					{
						CPrintToChatAll("%t %t", "Tag", "CarAlarmBoomer",
							g_SkillEvents[eventIndex].actor.name);
					}
				}

				default:
				{
					CPrintToChatAll("%t %t", "Tag", "CarAlarmTriggered",
						g_SkillEvents[eventIndex].actor.name);
				}
			}
		}

		case L4D2Skill_BunnyHopStreak:
		{
			char velocityText[16];
			FormatEx(velocityText, sizeof(velocityText), "%.1f", g_SkillEvents[eventIndex].maxVelocity);
			CPrintToChatAll("%t %t", "Tag",
				g_SkillEvents[eventIndex].streak == 1 ? "BunnyHopStreakSingle" : "BunnyHopStreakMulti",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].streak,
				velocityText);
		}

		case L4D2Skill_ChargerLevel:
		{
			CPrintToChatAll("%t %t", "Tag", "ChargerLevel",
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

			CPrintToChatAll("%t %t", "Tag",
				phrase,
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name,
				g_SkillEvents[eventIndex].height);
		}

		case L4D2Skill_ChargerDeathSetup:
		{
			CPrintToChatAll("%t %t", "Tag",
				g_SkillEvents[eventIndex].ledgeHang ? "ChargerDeathSetupLedge" : "ChargerDeathSetupIncap",
				g_SkillEvents[eventIndex].actor.name,
				g_SkillEvents[eventIndex].victim.name);
		}

		case L4D2Skill_WitchDead:
		{
			if (g_SkillEvents[eventIndex].crown)
			{
				CPrintToChatAll("%t %t", "Tag", "WitchCrown",
					g_SkillEvents[eventIndex].actor.name,
					g_SkillEvents[eventIndex].damage);
			}
		}

		case L4D2Skill_TankRockSkeet:
		{
			CPrintToChatAll("%t %t", "Tag", "TankRockSkeet",
				g_SkillEvents[eventIndex].actor.name);
		}

		case L4D2Skill_TankRockHit:
		{
			CPrintToChatAll("%t %t", "Tag", "TankRockHit",
				g_SkillEvents[eventIndex].victim.name);
		}
	}

	API_FireSkillAnnounced(eventId, g_SkillEvents[eventIndex].type);
}

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
