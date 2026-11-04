#if defined _l4d2_player_skills_api_included
	#endinput
#endif
#define _l4d2_player_skills_api_included

#include "l4d2_player_skills/publication.sp"

static const L4D2ApiEventFamily g_ApiEventFamilyBySkill[L4D2Skill_Size] =
{
	L4D2ApiEventFamily_None,      // L4D2Skill_None
	L4D2ApiEventFamily_Skill,     // L4D2Skill_HunterSkeet
	L4D2ApiEventFamily_Skill,     // L4D2Skill_HunterSkeetMelee
	L4D2ApiEventFamily_Skill,     // L4D2Skill_HunterDeadstop
	L4D2ApiEventFamily_Skill,     // L4D2Skill_BoomerPop
	L4D2ApiEventFamily_Skill,     // L4D2Skill_ChargerLevel
	L4D2ApiEventFamily_BossEvent, // L4D2Skill_TankDead
	L4D2ApiEventFamily_BossEvent, // L4D2Skill_WitchDead
	L4D2ApiEventFamily_BossEvent, // L4D2Skill_WitchIncap
	L4D2ApiEventFamily_Skill,     // L4D2Skill_SmokerTongueCut
	L4D2ApiEventFamily_Skill,     // L4D2Skill_SmokerSelfClear
	L4D2ApiEventFamily_BossEvent, // L4D2Skill_TankRockSkeet
	L4D2ApiEventFamily_BossEvent, // L4D2Skill_TankRockHit
	L4D2ApiEventFamily_Skill,     // L4D2Skill_HunterHighPounce
	L4D2ApiEventFamily_Skill,     // L4D2Skill_JockeyHighLeap
	L4D2ApiEventFamily_Skill,     // L4D2Skill_SmokerLedgeHang
	L4D2ApiEventFamily_Skill,     // L4D2Skill_JockeyLedgeHang
	L4D2ApiEventFamily_Skill,     // L4D2Skill_ChargerInstaKill
	L4D2ApiEventFamily_Skill,     // L4D2Skill_ChargerDeathSetup
	L4D2ApiEventFamily_Skill,     // L4D2Skill_ChargerLedgeHang
	L4D2ApiEventFamily_Skill,     // L4D2Skill_ChargerBowl
	L4D2ApiEventFamily_BossEvent, // L4D2Skill_TankLedgeHang
	L4D2ApiEventFamily_Skill,     // L4D2Skill_SpecialPinClear
	L4D2ApiEventFamily_Skill,     // L4D2Skill_BoomerVomitLanded
	L4D2ApiEventFamily_Skill,     // L4D2Skill_BunnyHopStreak
	L4D2ApiEventFamily_Skill,     // L4D2Skill_CarAlarmTriggered
	L4D2ApiEventFamily_Kill,      // L4D2Skill_SmokerKill
	L4D2ApiEventFamily_Kill,      // L4D2Skill_BoomerKill
	L4D2ApiEventFamily_Kill,      // L4D2Skill_HunterKill
	L4D2ApiEventFamily_Kill,      // L4D2Skill_SpitterKill
	L4D2ApiEventFamily_Kill,      // L4D2Skill_JockeyKill
	L4D2ApiEventFamily_Kill,      // L4D2Skill_ChargerKill
	L4D2ApiEventFamily_Skill,     // L4D2Skill_JockeyJumpStop
	L4D2ApiEventFamily_Skill,     // L4D2Skill_JockeySkeetMelee
	L4D2ApiEventFamily_Skill,     // L4D2Skill_JockeySkeet
	L4D2ApiEventFamily_BossEvent  // L4D2Skill_WitchCrown
};

static const int g_ApiPublicTypeIdBySkill[L4D2Skill_Size] =
{
	0,                                  // L4D2Skill_None
	view_as<int>(L4D2ApiSkill_HunterSkeet),
	view_as<int>(L4D2ApiSkill_HunterSkeetMelee),
	view_as<int>(L4D2ApiSkill_HunterDeadstop),
	view_as<int>(L4D2ApiSkill_BoomerPop),
	view_as<int>(L4D2ApiSkill_ChargerLevel),
	view_as<int>(L4D2ApiBossEvent_TankDead),
	view_as<int>(L4D2ApiBossEvent_WitchDead),
	view_as<int>(L4D2ApiBossEvent_WitchIncap),
	view_as<int>(L4D2ApiSkill_SmokerTongueCut),
	view_as<int>(L4D2ApiSkill_SmokerSelfClear),
	view_as<int>(L4D2ApiBossEvent_TankRockSkeet),
	view_as<int>(L4D2ApiBossEvent_TankRockHit),
	view_as<int>(L4D2ApiSkill_HunterHighPounce),
	view_as<int>(L4D2ApiSkill_JockeyHighLeap),
	view_as<int>(L4D2ApiSkill_SmokerLedgeHang),
	view_as<int>(L4D2ApiSkill_JockeyLedgeHang),
	view_as<int>(L4D2ApiSkill_ChargerInstaKill),
	view_as<int>(L4D2ApiSkill_ChargerDeathSetup),
	view_as<int>(L4D2ApiSkill_ChargerLedgeHang),
	view_as<int>(L4D2ApiSkill_ChargerBowl),
	view_as<int>(L4D2ApiBossEvent_TankLedgeHang),
	view_as<int>(L4D2ApiSkill_SpecialPinClear),
	view_as<int>(L4D2ApiSkill_BoomerVomitLanded),
	view_as<int>(L4D2ApiSkill_BunnyHopStreak),
	view_as<int>(L4D2ApiSkill_CarAlarmTriggered),
	view_as<int>(L4D2ApiKill_SmokerKill),
	view_as<int>(L4D2ApiKill_BoomerKill),
	view_as<int>(L4D2ApiKill_HunterKill),
	view_as<int>(L4D2ApiKill_SpitterKill),
	view_as<int>(L4D2ApiKill_JockeyKill),
	view_as<int>(L4D2ApiKill_ChargerKill),
	view_as<int>(L4D2ApiSkill_JockeyJumpStop),
	view_as<int>(L4D2ApiSkill_JockeySkeetMelee),
	view_as<int>(L4D2ApiSkill_JockeySkeet),
	view_as<int>(L4D2ApiBossEvent_WitchCrown)
};

#include "l4d2_player_skills/api_natives.sp"

L4D2ApiEventFamily API_GetEventFamily(L4D2SkillType type)
{
	return (type >= L4D2Skill_None && type < L4D2Skill_Size)
		? g_ApiEventFamilyBySkill[type]
		: L4D2ApiEventFamily_None;
}

L4D2ApiSkillType API_MapSkillType(L4D2SkillType type)
{
	return API_GetEventFamily(type) == L4D2ApiEventFamily_Skill
		? view_as<L4D2ApiSkillType>(g_ApiPublicTypeIdBySkill[type])
		: L4D2ApiSkill_None;
}

L4D2ApiKillType API_MapKillType(L4D2SkillType type)
{
	return API_GetEventFamily(type) == L4D2ApiEventFamily_Kill
		? view_as<L4D2ApiKillType>(g_ApiPublicTypeIdBySkill[type])
		: L4D2ApiKill_None;
}

L4D2ApiBossEventType API_MapBossEventType(L4D2SkillType type)
{
	return API_GetEventFamily(type) == L4D2ApiEventFamily_BossEvent
		? view_as<L4D2ApiBossEventType>(g_ApiPublicTypeIdBySkill[type])
		: L4D2ApiBossEvent_None;
}

void API_GetSkillTypeName(L4D2ApiSkillType type, char[] buffer, int maxlen)
{
	PlayerSkills_GetApiSkillTypeName(type, buffer, maxlen);
}

void API_GetKillTypeName(L4D2ApiKillType type, char[] buffer, int maxlen)
{
	PlayerSkills_GetApiKillTypeName(type, buffer, maxlen);
}

void API_GetBossEventTypeName(L4D2ApiBossEventType type, char[] buffer, int maxlen)
{
	PlayerSkills_GetApiBossEventTypeName(type, buffer, maxlen);
}

int API_GetEventIndexOrFail(int eventId)
{
	int index = Skills_GetEventIndex(eventId);
	return index != -1 && !g_SkillEvents[index].pendingPublication ? index : -1;
}

int API_GetBossSessionIndexById(int sessionId)
{
	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == sessionId)
		{
			return index;
		}
	}

	return -1;
}

bool API_IsFamilyEventValid(int eventId, L4D2ApiEventFamily family)
{
	int eventIndex = API_GetEventIndexOrFail(eventId);
	return eventIndex != -1 && API_GetEventFamily(g_SkillEvents[eventIndex].type) == family;
}

bool API_IsSkillSummaryValid(int summaryId)
{
	if (summaryId <= 0)
	{
		return false;
	}

	for (int index = 0; index < L4D2_SKILLS_MAX_SUMMARIES; index++)
	{
		if (g_SkillSummaries[index].id == summaryId)
		{
			return true;
		}
	}

	return false;
}

bool API_IsKillSummaryValid(int summaryId)
{
	if (summaryId <= 0)
	{
		return false;
	}

	for (int index = 0; index < L4D2_SKILLS_MAX_SUMMARIES; index++)
	{
		if (g_KillSummaries[index].id == summaryId)
		{
			return true;
		}
	}

	return false;
}

int API_GetSkillSummaryIndexById(int summaryId)
{
	for (int index = 0; index < L4D2_SKILLS_MAX_SUMMARIES; index++)
	{
		if (g_SkillSummaries[index].id == summaryId)
		{
			return index;
		}
	}

	return -1;
}

int API_GetKillSummaryIndexById(int summaryId)
{
	for (int index = 0; index < L4D2_SKILLS_MAX_SUMMARIES; index++)
	{
		if (g_KillSummaries[index].id == summaryId)
		{
			return index;
		}
	}

	return -1;
}

int API_GetBossDamageEntryCountByIndex(int sessionIndex)
{
	int count = 0;

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (g_BossDamage[sessionIndex][entry].active)
		{
			count++;
		}
	}

	if (Boss_GetOtherDamage(sessionIndex) > 0)
	{
		count++;
	}

	return count;
}

#include "l4d2_player_skills/summaries.sp"

void API_SetEventPlayerKeys(Handle kv, const char[] prefix, L4D2PlayerRef player)
{
	char key[64];

	FormatEx(key, sizeof(key), "%s_userid", prefix);
	KvSetNum(kv, key, player.userid);

	FormatEx(key, sizeof(key), "%s_accountid", prefix);
	KvSetNum(kv, key, player.accountId);

	FormatEx(key, sizeof(key), "%s_name", prefix);
	KvSetString(kv, key, player.name);

	FormatEx(key, sizeof(key), "%s_bot", prefix);
	KvSetNum(kv, key, player.bot ? 1 : 0);

	FormatEx(key, sizeof(key), "%s_team", prefix);
	KvSetNum(kv, key, player.team);

	FormatEx(key, sizeof(key), "%s_character", prefix);
	KvSetNum(kv, key, player.character);

	FormatEx(key, sizeof(key), "%s_zombie_class", prefix);
	KvSetNum(kv, key, player.zombieClass);
}

void API_WriteEventAssists(Handle kv, int eventIndex)
{
	int assistsCount = g_SkillEvents[eventIndex].assistsCount;
	KvSetNum(kv, "assists_count", assistsCount);

	if (!KvJumpToKey(kv, "assists", true))
	{
		return;
	}

	for (int i = 0; i < assistsCount && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		char indexKey[8];
		IntToString(i, indexKey, sizeof(indexKey));

		if (KvJumpToKey(kv, indexKey, true))
		{
			KvSetNum(kv, "userid", g_SkillEvents[eventIndex].assists[i].userid);
			KvSetNum(kv, "accountid", g_SkillEvents[eventIndex].assists[i].accountId);
			KvSetString(kv, "name", g_SkillEvents[eventIndex].assists[i].name);
			KvSetNum(kv, "bot", g_SkillEvents[eventIndex].assists[i].bot ? 1 : 0);
			KvSetNum(kv, "team", g_SkillEvents[eventIndex].assists[i].team);
			KvSetNum(kv, "character", g_SkillEvents[eventIndex].assists[i].character);
			KvSetNum(kv, "zombie_class", g_SkillEvents[eventIndex].assists[i].zombieClass);
			KvSetNum(kv, "damage", g_SkillEvents[eventIndex].assistDamage[i]);
			KvSetNum(kv, "shots", g_SkillEvents[eventIndex].assistShots[i]);
			KvSetNum(kv, "weaponid", g_SkillEvents[eventIndex].assistWeaponId[i]);
			KvGoBack(kv);
		}
	}

	KvGoBack(kv);
}

bool API_ShouldWriteEventVictimKeys(int eventIndex, L4D2ApiEventFamily family)
{
	if (family != L4D2ApiEventFamily_BossEvent)
	{
		return true;
	}

	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_TankDead, L4D2Skill_WitchDead, L4D2Skill_WitchCrown:
		{
			return false;
		}
	}

	return true;
}

bool API_ShouldEmbedBossSessionInEvent(int eventIndex)
{
	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_TankDead:
		{
			// TankDead is emitted before the boss session reaches its terminal finalized state.
			// Embedding the session snapshot here is misleading because end_reason/state still
			// reflect a pre-finalization view.
			return false;
		}
	}

	return true;
}

void API_WriteEventSpecialRoles(Handle kv, int eventIndex, L4D2ApiEventFamily family)
{
	if (API_ShouldWriteEventVictimKeys(eventIndex, family)
		&& (g_SkillEvents[eventIndex].victim.userid > 0
			|| g_SkillEvents[eventIndex].victim.accountId > 0
			|| g_SkillEvents[eventIndex].victim.bot
			|| g_SkillEvents[eventIndex].victim.name[0] != '\0'))
	{
		API_SetEventPlayerKeys(kv, "victim", g_SkillEvents[eventIndex].victim);
	}

	if (g_SkillEvents[eventIndex].pinVictim.userid <= 0)
	{
		return;
	}

	API_SetEventPlayerKeys(kv, "pinvictim", g_SkillEvents[eventIndex].pinVictim);
}

bool API_ShouldWriteActorWeaponId(int eventIndex)
{
	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_WitchDead:
		{
			return false;
		}
	}

	return true;
}

int API_GetSuppressedKillTypeForSkillEvent(int eventIndex)
{
	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_HunterSkeet, L4D2Skill_HunterSkeetMelee:
		{
			return view_as<int>(L4D2ApiKill_HunterKill);
		}

		case L4D2Skill_BoomerPop:
		{
			return view_as<int>(L4D2ApiKill_BoomerKill);
		}

		case L4D2Skill_ChargerLevel:
		{
			return view_as<int>(L4D2ApiKill_ChargerKill);
		}

		case L4D2Skill_JockeySkeetMelee, L4D2Skill_JockeySkeet:
		{
			return view_as<int>(L4D2ApiKill_JockeyKill);
		}

		case L4D2Skill_SmokerSelfClear:
		{
			if (!g_SkillEvents[eventIndex].withShove)
			{
				return view_as<int>(L4D2ApiKill_SmokerKill);
			}
		}
	}

	return view_as<int>(L4D2ApiKill_None);
}

void API_WriteEventSkillConsequences(Handle kv, int eventIndex)
{
	int suppressedKillType = API_GetSuppressedKillTypeForSkillEvent(eventIndex);
	if (suppressedKillType > view_as<int>(L4D2ApiKill_None))
	{
		char killTypeName[32];
		API_GetKillTypeName(view_as<L4D2ApiKillType>(suppressedKillType), killTypeName, sizeof(killTypeName));
		KvSetNum(kv, "implies_si_death", 1);
		KvSetNum(kv, "suppressed_kill_type_id", suppressedKillType);
		KvSetString(kv, "suppressed_kill_type", killTypeName);
	}

	if (g_SkillEvents[eventIndex].type == L4D2Skill_SmokerSelfClear)
	{
		KvSetString(kv, "clear_mode", g_SkillEvents[eventIndex].withShove ? "shove" : "kill");
	}
}

void API_WriteEventSkillProperties(Handle kv, int eventIndex)
{
	if (!KvJumpToKey(kv, "properties", true))
	{
		return;
	}

	if (g_SkillEvents[eventIndex].actorDamage > 0)
	{
		KvSetNum(kv, "actor_damage", g_SkillEvents[eventIndex].actorDamage);
	}

	if (API_ShouldWriteActorWeaponId(eventIndex)
		&& g_SkillEvents[eventIndex].actorWeaponId > WEPID_NONE)
	{
		KvSetNum(kv, "actor_weaponid", g_SkillEvents[eventIndex].actorWeaponId);
	}

	if (g_SkillEvents[eventIndex].chipDamage > 0)
	{
		KvSetNum(kv, "chip_damage", g_SkillEvents[eventIndex].chipDamage);
	}

	if (g_SkillEvents[eventIndex].reason > 0)
	{
		KvSetNum(kv, "reason", g_SkillEvents[eventIndex].reason);
	}

	int rating = Skills_GetEventRating(eventIndex);
	if (rating > 0)
	{
		KvSetNum(kv, "rating", rating);
	}

	if (g_SkillEvents[eventIndex].shots > 0)
	{
		KvSetNum(kv, "shots", g_SkillEvents[eventIndex].shots);
	}

	if (g_SkillEvents[eventIndex].shoveCount > 0)
	{
		KvSetNum(kv, "shove_count", g_SkillEvents[eventIndex].shoveCount);
	}

	if (g_SkillEvents[eventIndex].amount > 0)
	{
		KvSetNum(kv, "amount", g_SkillEvents[eventIndex].amount);
	}

	if (g_SkillEvents[eventIndex].reportedHigh) KvSetNum(kv, "reported_high", 1);
	if (g_SkillEvents[eventIndex].indirect) KvSetNum(kv, "indirect", 1);
	if (g_SkillEvents[eventIndex].forced) KvSetNum(kv, "forced", 1);
	if (g_SkillEvents[eventIndex].incapped) KvSetNum(kv, "incapped", 1);
	if (g_SkillEvents[eventIndex].ledgeHang) KvSetNum(kv, "ledge_hang", 1);
	if (g_SkillEvents[eventIndex].fatalFall) KvSetNum(kv, "fatal_fall", 1);
	if (g_SkillEvents[eventIndex].deadlySlam) KvSetNum(kv, "deadly_slam", 1);
	if (g_SkillEvents[eventIndex].perfect) KvSetNum(kv, "perfect", 1);
	if (g_SkillEvents[eventIndex].headshot) KvSetNum(kv, "headshot", 1);
	if (g_SkillEvents[eventIndex].sniper) KvSetNum(kv, "sniper", 1);
	if (g_SkillEvents[eventIndex].grenadeLauncher) KvSetNum(kv, "grenade_launcher", 1);
	if (g_SkillEvents[eventIndex].crown) KvSetNum(kv, "crown", 1);
	if (g_SkillEvents[eventIndex].startled) KvSetNum(kv, "startled", 1);

	if (g_SkillEvents[eventIndex].streak > 0)
	{
		KvSetNum(kv, "streak", g_SkillEvents[eventIndex].streak);
	}

	if (g_SkillEvents[eventIndex].timeA > 0.0) KvSetFloat(kv, "time_a", g_SkillEvents[eventIndex].timeA);
	if (g_SkillEvents[eventIndex].timeB > 0.0) KvSetFloat(kv, "time_b", g_SkillEvents[eventIndex].timeB);
	if (g_SkillEvents[eventIndex].calculatedDamage > 0.0) KvSetFloat(kv, "calculated_damage", g_SkillEvents[eventIndex].calculatedDamage);
	if (g_SkillEvents[eventIndex].height > 0.0) KvSetFloat(kv, "height", g_SkillEvents[eventIndex].height);
	if (g_SkillEvents[eventIndex].distance > 0.0) KvSetFloat(kv, "distance", g_SkillEvents[eventIndex].distance);
	if (g_SkillEvents[eventIndex].maxVelocity > 0.0) KvSetFloat(kv, "max_velocity", g_SkillEvents[eventIndex].maxVelocity);

	if (API_GetEventFamily(g_SkillEvents[eventIndex].type) == L4D2ApiEventFamily_Skill)
	{
		API_WriteEventSkillConsequences(kv, eventIndex);
	}

	KvGoBack(kv);
}

void API_WriteBossDamageEntries(Handle kv, int sessionIndex)
{
	int count = API_GetBossDamageEntryCountByIndex(sessionIndex);
	KvSetNum(kv, "damage_entries_count", count);

	if (!KvJumpToKey(kv, "damage_entries", true))
	{
		return;
	}

	int writeIndex = 0;
	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active)
		{
			continue;
		}

		char entryKey[8];
		IntToString(writeIndex++, entryKey, sizeof(entryKey));
		if (!KvJumpToKey(kv, entryKey, true))
		{
			continue;
		}

		KvSetNum(kv, "userid", g_BossDamage[sessionIndex][entry].player.userid);
		KvSetNum(kv, "accountid", g_BossDamage[sessionIndex][entry].player.accountId);
		KvSetString(kv, "name", g_BossDamage[sessionIndex][entry].player.name);
		KvSetNum(kv, "bot", g_BossDamage[sessionIndex][entry].player.bot ? 1 : 0);
		KvSetNum(kv, "damage", g_BossDamage[sessionIndex][entry].damage);
		KvSetNum(kv, "shots", g_BossDamage[sessionIndex][entry].shots);
		KvGoBack(kv);
	}

	int otherDamage = Boss_GetOtherDamage(sessionIndex);
	if (otherDamage > 0)
	{
		char entryKey[8];
		IntToString(writeIndex++, entryKey, sizeof(entryKey));
		if (KvJumpToKey(kv, entryKey, true))
		{
			KvSetNum(kv, "userid", 0);
			KvSetNum(kv, "accountid", 0);
			KvSetString(kv, "name", "Other");
			KvSetNum(kv, "bot", 1);
			KvSetNum(kv, "damage", otherDamage);
			KvSetNum(kv, "shots", 0);
			KvGoBack(kv);
		}
	}

	KvGoBack(kv);
}

int API_GetTankControlEntryCountByIndex(int sessionIndex)
{
	int count = 0;
	for (int entry = 0; entry < g_BossSessions[sessionIndex].tank.controlCount && entry < L4D2_SKILLS_MAX_TANK_CONTROLS; entry++)
	{
		if (g_BossSessions[sessionIndex].tank.controls[entry].active)
		{
			count++;
		}
	}

	return count;
}

void API_WriteBossTankControls(Handle kv, int sessionIndex)
{
	int count = API_GetTankControlEntryCountByIndex(sessionIndex);
	KvSetNum(kv, "tank_control_count", count);
	if (!KvJumpToKey(kv, "tank_control", true))
	{
		return;
	}

	int writeIndex = 0;
	for (int entry = 0; entry < g_BossSessions[sessionIndex].tank.controlCount && entry < L4D2_SKILLS_MAX_TANK_CONTROLS; entry++)
	{
		if (!g_BossSessions[sessionIndex].tank.controls[entry].active)
		{
			continue;
		}

		char entryKey[8];
		IntToString(writeIndex++, entryKey, sizeof(entryKey));
		if (!KvJumpToKey(kv, entryKey, true))
		{
			continue;
		}

		KvSetNum(kv, "userid", g_BossSessions[sessionIndex].tank.controls[entry].player.userid);
		KvSetNum(kv, "accountid", g_BossSessions[sessionIndex].tank.controls[entry].player.accountId);
		KvSetString(kv, "name", g_BossSessions[sessionIndex].tank.controls[entry].player.name);
		KvSetNum(kv, "bot", g_BossSessions[sessionIndex].tank.controls[entry].player.bot ? 1 : 0);
		if (g_BossSessions[sessionIndex].tank.controls[entry].synthetic)
		{
			KvSetNum(kv, "synthetic", 1);
		}

		float controlTime = g_BossSessions[sessionIndex].tank.controls[entry].controlTime;
		if (g_BossSessions[sessionIndex].tank.controls[entry].startedAt > 0.0)
		{
			controlTime += GetGameTime() - g_BossSessions[sessionIndex].tank.controls[entry].startedAt;
		}
			KvSetFloat(kv, "control_time", controlTime);
			if (g_BossSessions[sessionIndex].tank.controls[entry].overflow)
			{
				KvSetNum(kv, "overflow", 1);
				KvSetNum(kv, "merged_controls", g_BossSessions[sessionIndex].tank.controls[entry].mergedControls);
			}
			KvSetNum(kv, "rocks_thrown", g_BossSessions[sessionIndex].tank.controls[entry].rocksThrown);
			KvSetNum(kv, "rocks_hit", g_BossSessions[sessionIndex].tank.controls[entry].rocksHit);
			KvGoBack(kv);
	}

	KvGoBack(kv);
}

void API_WriteBossSessionKeyValues(Handle kv, int sessionIndex)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return;
	}

	if (!KvJumpToKey(kv, "boss_session", true))
	{
		return;
	}

	KvSetNum(kv, "id", g_BossSessions[sessionIndex].id);
	KvSetNum(kv, "type", g_BossSessions[sessionIndex].type);
	KvSetNum(kv, "state", g_BossSessions[sessionIndex].state);
	KvSetNum(kv, "total_damage", g_BossSessions[sessionIndex].totalDamage);

	float aliveTime = 0.0;
	if (g_BossSessions[sessionIndex].startedAt > 0.0)
	{
		float endTime = g_BossSessions[sessionIndex].closedAt > 0.0 ? g_BossSessions[sessionIndex].closedAt : GetGameTime();
		aliveTime = endTime - g_BossSessions[sessionIndex].startedAt;
	}
	KvSetFloat(kv, "alive_time", aliveTime);

	API_WriteBossDamageEntries(kv, sessionIndex);

	switch (g_BossSessions[sessionIndex].type)
	{
		case L4D2Boss_Tank:
		{
			if (KvJumpToKey(kv, "tank_session", true))
			{
				KvSetNum(kv, "in_stasis", g_BossSessions[sessionIndex].tank.inStasis ? 1 : 0);
				KvSetNum(kv, "end_reason", g_BossSessions[sessionIndex].tank.endReason);
				KvSetNum(kv, "punches_hit", g_BossSessions[sessionIndex].tank.punchesHit);
				KvSetNum(kv, "punch_damage", g_BossSessions[sessionIndex].tank.punchDamage);
				KvSetNum(kv, "hittables_hit", g_BossSessions[sessionIndex].tank.hittablesHit);
				KvSetNum(kv, "hittable_damage", g_BossSessions[sessionIndex].tank.hittableDamage);
				KvSetNum(kv, "incaps", g_BossSessions[sessionIndex].tank.incaps);
				KvSetNum(kv, "ledge_hangs", g_BossSessions[sessionIndex].tank.ledgeHangs);
				KvGoBack(kv);
			}

			API_WriteBossTankControls(kv, sessionIndex);
		}

			case L4D2Boss_Witch:
			{
				if (KvJumpToKey(kv, "witch_session", true))
				{
					KvSetNum(kv, "startled", g_BossSessions[sessionIndex].witch.startled ? 1 : 0);
					KvSetNum(kv, "crown_detected", g_BossSessions[sessionIndex].witch.crownDetected ? 1 : 0);

					if (g_BossSessions[sessionIndex].witch.harasser.userid > 0 || g_BossSessions[sessionIndex].witch.harasser.name[0] != '\0')
					{
						API_SetEventPlayerKeys(kv, "harasser", g_BossSessions[sessionIndex].witch.harasser);
					}

					if (g_BossSessions[sessionIndex].witch.incapVictim.userid > 0 || g_BossSessions[sessionIndex].witch.incapVictim.name[0] != '\0')
					{
						API_SetEventPlayerKeys(kv, "incap_victim", g_BossSessions[sessionIndex].witch.incapVictim);
					}

					if (g_BossSessions[sessionIndex].witch.crowner.userid > 0 || g_BossSessions[sessionIndex].witch.crowner.name[0] != '\0')
					{
						API_SetEventPlayerKeys(kv, "crowner", g_BossSessions[sessionIndex].witch.crowner);
					}

					KvGoBack(kv);
				}
			}
		}

	KvGoBack(kv);
}

void API_GetSummaryTeamName(L4DTeam team, char[] buffer, int maxlen)
{
	switch (team)
	{
		case L4DTeam_Survivor:
		{
			strcopy(buffer, maxlen, "survivor");
			return;
		}
		case L4DTeam_Infected:
		{
			strcopy(buffer, maxlen, "infected");
			return;
		}
	}

	strcopy(buffer, maxlen, "unknown");
}

void API_WriteSkillSummaryEntries(Handle kv, int summaryIndex)
{
	int count = 0;
	for (int entry = 0; entry < L4D2_SKILLS_MAX_SUMMARY_ENTRIES; entry++)
	{
		if (g_SkillSummaries[summaryIndex].entries[entry].active)
		{
			count++;
		}
	}

	KvSetNum(kv, "entries_count", count);
	if (!KvJumpToKey(kv, "entries", true))
	{
		return;
	}

	int summaryEntryIndex = 0;
	for (int entry = 0; entry < L4D2_SKILLS_MAX_SUMMARY_ENTRIES; entry++)
	{
		if (!g_SkillSummaries[summaryIndex].entries[entry].active)
		{
			continue;
		}

		char entryKey[8];
		IntToString(summaryEntryIndex++, entryKey, sizeof(entryKey));
		if (!KvJumpToKey(kv, entryKey, true))
		{
			continue;
		}

		char teamName[16];
		API_GetSummaryTeamName(g_SkillSummaries[summaryIndex].entries[entry].player.team, teamName, sizeof(teamName));
		KvSetNum(kv, "team", g_SkillSummaries[summaryIndex].entries[entry].player.team);
		KvSetString(kv, "team_name", teamName);
		KvSetNum(kv, "userid", g_SkillSummaries[summaryIndex].entries[entry].player.userid);
		KvSetNum(kv, "accountid", g_SkillSummaries[summaryIndex].entries[entry].player.accountId);
		KvSetString(kv, "name", g_SkillSummaries[summaryIndex].entries[entry].player.name);
		KvSetNum(kv, "bot", g_SkillSummaries[summaryIndex].entries[entry].player.bot ? 1 : 0);

		if (KvJumpToKey(kv, "counts", true))
		{
			for (int type = 1; type < view_as<int>(L4D2ApiSkill_Size); type++)
			{
				if (g_SkillSummaries[summaryIndex].entries[entry].counts[type] > 0)
				{
					char typeName[48];
					API_GetSkillTypeName(view_as<L4D2ApiSkillType>(type), typeName, sizeof(typeName));
					KvSetNum(kv, typeName, g_SkillSummaries[summaryIndex].entries[entry].counts[type]);
				}
			}
			KvGoBack(kv);
		}

		KvGoBack(kv);
	}

	KvGoBack(kv);
}

void API_WriteKillSummaryEntries(Handle kv, int summaryIndex)
{
	int count = 0;
	for (int entry = 0; entry < L4D2_SKILLS_MAX_SUMMARY_ENTRIES; entry++)
	{
		if (g_KillSummaries[summaryIndex].entries[entry].active)
		{
			count++;
		}
	}

	KvSetNum(kv, "entries_count", count);
	if (!KvJumpToKey(kv, "entries", true))
	{
		return;
	}

	int summaryEntryIndex = 0;
	for (int entry = 0; entry < L4D2_SKILLS_MAX_SUMMARY_ENTRIES; entry++)
	{
		if (!g_KillSummaries[summaryIndex].entries[entry].active)
		{
			continue;
		}

		char entryKey[8];
		IntToString(summaryEntryIndex++, entryKey, sizeof(entryKey));
		if (!KvJumpToKey(kv, entryKey, true))
		{
			continue;
		}

		char teamName[16];
		API_GetSummaryTeamName(g_KillSummaries[summaryIndex].entries[entry].player.team, teamName, sizeof(teamName));
		KvSetNum(kv, "team", g_KillSummaries[summaryIndex].entries[entry].player.team);
		KvSetString(kv, "team_name", teamName);
		KvSetNum(kv, "userid", g_KillSummaries[summaryIndex].entries[entry].player.userid);
		KvSetNum(kv, "accountid", g_KillSummaries[summaryIndex].entries[entry].player.accountId);
		KvSetString(kv, "name", g_KillSummaries[summaryIndex].entries[entry].player.name);
		KvSetNum(kv, "bot", g_KillSummaries[summaryIndex].entries[entry].player.bot ? 1 : 0);

		if (KvJumpToKey(kv, "counts", true))
		{
			for (int type = 1; type < view_as<int>(L4D2ApiKill_Size); type++)
			{
				if (g_KillSummaries[summaryIndex].entries[entry].counts[type] > 0)
				{
					char typeName[48];
					API_GetKillTypeName(view_as<L4D2ApiKillType>(type), typeName, sizeof(typeName));
					KvSetNum(kv, typeName, g_KillSummaries[summaryIndex].entries[entry].counts[type]);
				}
			}
			KvGoBack(kv);
		}

		KvGoBack(kv);
	}

	KvGoBack(kv);
}

bool API_WriteEventKeyValuesForFamily(Handle kv, int eventIndex, L4D2ApiEventFamily family)
{
	char rootKey[32];
	rootKey[0] = '\0';
	int publicTypeId = 0;

	switch (family)
	{
		case L4D2ApiEventFamily_Skill:
		{
			strcopy(rootKey, sizeof(rootKey), "skill_event");
			L4D2ApiSkillType publicType = API_MapSkillType(g_SkillEvents[eventIndex].type);
			publicTypeId = view_as<int>(publicType);
		}

		case L4D2ApiEventFamily_Kill:
		{
			strcopy(rootKey, sizeof(rootKey), "kill_event");
			L4D2ApiKillType publicType = API_MapKillType(g_SkillEvents[eventIndex].type);
			publicTypeId = view_as<int>(publicType);
		}

		case L4D2ApiEventFamily_BossEvent:
		{
			strcopy(rootKey, sizeof(rootKey), "boss_event");
			L4D2ApiBossEventType publicType = API_MapBossEventType(g_SkillEvents[eventIndex].type);
			publicTypeId = view_as<int>(publicType);
		}

		default:
		{
			return false;
		}
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, rootKey, true))
	{
		return false;
	}

	KvSetNum(kv, "id", g_SkillEvents[eventIndex].id);
	KvSetNum(kv, "type_id", publicTypeId);
	KvSetNum(kv, "base_mode", g_Runtime.baseMode);
	API_SetEventPlayerKeys(kv, "actor", g_SkillEvents[eventIndex].actor);
	API_WriteEventAssists(kv, eventIndex);
	API_WriteEventSpecialRoles(kv, eventIndex, family);
	API_WriteEventSkillProperties(kv, eventIndex);

	if (family == L4D2ApiEventFamily_BossEvent)
	{
		if (API_ShouldEmbedBossSessionInEvent(eventIndex)
			&& g_SkillEvents[eventIndex].actor2 > 0)
		{
			int sessionIndex = API_GetBossSessionIndexById(g_SkillEvents[eventIndex].actor2);
			if (sessionIndex != -1)
			{
				switch (g_SkillEvents[eventIndex].type)
				{
					case L4D2Skill_TankDead, L4D2Skill_TankRockSkeet, L4D2Skill_TankRockHit, L4D2Skill_TankLedgeHang,
						L4D2Skill_WitchDead, L4D2Skill_WitchIncap, L4D2Skill_WitchCrown:
					{
						API_WriteBossSessionKeyValues(kv, sessionIndex);
					}
				}
			}
		}
	}

	KvGoBack(kv);
	KvRewind(kv);
	return true;
}
