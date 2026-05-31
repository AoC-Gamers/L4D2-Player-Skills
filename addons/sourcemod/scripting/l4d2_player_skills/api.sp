#if defined _l4d2_player_skills_api_included
	#endinput
#endif
#define _l4d2_player_skills_api_included

Handle g_hForwardSkillDetected = INVALID_HANDLE;
Handle g_hForwardKillDetected = INVALID_HANDLE;
Handle g_hForwardBossEventDetected = INVALID_HANDLE;
Handle g_hForwardBossSessionFinalized = INVALID_HANDLE;
Handle g_hForwardTankSessionClosed = INVALID_HANDLE;
Handle g_hForwardSkillSummaryFinalized = INVALID_HANDLE;
Handle g_hForwardKillSummaryFinalized = INVALID_HANDLE;

void API_CreateForwards()
{
	g_hForwardSkillDetected = CreateGlobalForward("PlayerSkills_OnSkillDetected", ET_Event, Param_Cell, Param_Cell);
	g_hForwardKillDetected = CreateGlobalForward("PlayerSkills_OnKillDetected", ET_Event, Param_Cell, Param_Cell);
	g_hForwardBossEventDetected = CreateGlobalForward("PlayerSkills_OnBossEventDetected", ET_Event, Param_Cell, Param_Cell);
	g_hForwardBossSessionFinalized = CreateGlobalForward("PlayerSkills_OnBossSessionFinalized", ET_Event, Param_Cell, Param_Cell);
	g_hForwardTankSessionClosed = CreateGlobalForward("PlayerSkills_OnTankSessionClosed", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardSkillSummaryFinalized = CreateGlobalForward("PlayerSkills_OnSkillSummaryFinalized", ET_Ignore, Param_Cell);
	g_hForwardKillSummaryFinalized = CreateGlobalForward("PlayerSkills_OnKillSummaryFinalized", ET_Ignore, Param_Cell);
}

void API_CreateNatives()
{
	CreateNative("PlayerSkills_IsSkillEventValid", Native_PlayerSkills_IsSkillEventValid);
	CreateNative("PlayerSkills_FillSkillEventKeyValues", Native_PlayerSkills_FillSkillEventKeyValues);
	CreateNative("PlayerSkills_IsKillEventValid", Native_PlayerSkills_IsKillEventValid);
	CreateNative("PlayerSkills_FillKillEventKeyValues", Native_PlayerSkills_FillKillEventKeyValues);
	CreateNative("PlayerSkills_IsBossEventValid", Native_PlayerSkills_IsBossEventValid);
	CreateNative("PlayerSkills_FillBossEventKeyValues", Native_PlayerSkills_FillBossEventKeyValues);
	CreateNative("PlayerSkills_IsBossSessionValid", Native_PlayerSkills_IsBossSessionValid);
	CreateNative("PlayerSkills_FillBossSessionKeyValues", Native_PlayerSkills_FillBossSessionKeyValues);
	CreateNative("PlayerSkills_IsSkillSummaryValid", Native_PlayerSkills_IsSkillSummaryValid);
	CreateNative("PlayerSkills_FillSkillSummaryKeyValues", Native_PlayerSkills_FillSkillSummaryKeyValues);
	CreateNative("PlayerSkills_IsKillSummaryValid", Native_PlayerSkills_IsKillSummaryValid);
	CreateNative("PlayerSkills_FillKillSummaryKeyValues", Native_PlayerSkills_FillKillSummaryKeyValues);
}

L4D2ApiEventFamily API_GetEventFamily(L4D2SkillType type)
{
	switch (type)
	{
		case L4D2Skill_HunterSkeet,
			L4D2Skill_HunterSkeetMelee,
			L4D2Skill_HunterDeadstop,
			L4D2Skill_BoomerPop,
			L4D2Skill_ChargerLevel,
			L4D2Skill_SmokerTongueCut,
			L4D2Skill_SmokerSelfClear,
			L4D2Skill_HunterHighPounce,
			L4D2Skill_JockeyHighPounce,
			L4D2Skill_SmokerLedgeHang,
			L4D2Skill_JockeyLedgeHang,
			L4D2Skill_ChargerInstaKill,
			L4D2Skill_ChargerDeathSetup,
			L4D2Skill_ChargerLedgeHang,
			L4D2Skill_ChargerBowl,
			L4D2Skill_SpecialPinClear,
			L4D2Skill_BoomerVomitLanded,
			L4D2Skill_BunnyHopStreak,
			L4D2Skill_CarAlarmTriggered,
			L4D2Skill_JockeyJumpStop,
			L4D2Skill_JockeySkeetMelee,
			L4D2Skill_JockeySkeet:
		{
			return L4D2ApiEventFamily_Skill;
		}

		case L4D2Skill_SmokerKill,
			L4D2Skill_BoomerKill,
			L4D2Skill_HunterKill,
			L4D2Skill_SpitterKill,
			L4D2Skill_JockeyKill,
			L4D2Skill_ChargerKill:
		{
			return L4D2ApiEventFamily_Kill;
		}

		case L4D2Skill_TankDead,
			L4D2Skill_WitchDead,
			L4D2Skill_WitchIncap,
			L4D2Skill_TankRockSkeet,
			L4D2Skill_TankRockHit,
			L4D2Skill_TankLedgeHang,
			L4D2Skill_WitchCrown:
		{
			return L4D2ApiEventFamily_BossEvent;
		}
	}

	return L4D2ApiEventFamily_None;
}

L4D2ApiSkillType API_MapSkillType(L4D2SkillType type)
{
	switch (type)
	{
		case L4D2Skill_HunterSkeet: return L4D2ApiSkill_HunterSkeet;
		case L4D2Skill_HunterSkeetMelee: return L4D2ApiSkill_HunterSkeetMelee;
		case L4D2Skill_HunterDeadstop: return L4D2ApiSkill_HunterDeadstop;
		case L4D2Skill_BoomerPop: return L4D2ApiSkill_BoomerPop;
		case L4D2Skill_ChargerLevel: return L4D2ApiSkill_ChargerLevel;
		case L4D2Skill_SmokerTongueCut: return L4D2ApiSkill_SmokerTongueCut;
		case L4D2Skill_SmokerSelfClear: return L4D2ApiSkill_SmokerSelfClear;
		case L4D2Skill_HunterHighPounce: return L4D2ApiSkill_HunterHighPounce;
		case L4D2Skill_JockeyHighPounce: return L4D2ApiSkill_JockeyHighPounce;
		case L4D2Skill_SmokerLedgeHang: return L4D2ApiSkill_SmokerLedgeHang;
		case L4D2Skill_JockeyLedgeHang: return L4D2ApiSkill_JockeyLedgeHang;
		case L4D2Skill_ChargerInstaKill: return L4D2ApiSkill_ChargerInstaKill;
		case L4D2Skill_ChargerDeathSetup: return L4D2ApiSkill_ChargerDeathSetup;
		case L4D2Skill_ChargerLedgeHang: return L4D2ApiSkill_ChargerLedgeHang;
		case L4D2Skill_ChargerBowl: return L4D2ApiSkill_ChargerBowl;
		case L4D2Skill_SpecialPinClear: return L4D2ApiSkill_SpecialPinClear;
		case L4D2Skill_BoomerVomitLanded: return L4D2ApiSkill_BoomerVomitLanded;
		case L4D2Skill_BunnyHopStreak: return L4D2ApiSkill_BunnyHopStreak;
		case L4D2Skill_CarAlarmTriggered: return L4D2ApiSkill_CarAlarmTriggered;
		case L4D2Skill_JockeyJumpStop: return L4D2ApiSkill_JockeyJumpStop;
		case L4D2Skill_JockeySkeetMelee: return L4D2ApiSkill_JockeySkeetMelee;
		case L4D2Skill_JockeySkeet: return L4D2ApiSkill_JockeySkeet;
	}

	return L4D2ApiSkill_None;
}

L4D2ApiKillType API_MapKillType(L4D2SkillType type)
{
	switch (type)
	{
		case L4D2Skill_SmokerKill: return L4D2ApiKill_SmokerKill;
		case L4D2Skill_BoomerKill: return L4D2ApiKill_BoomerKill;
		case L4D2Skill_HunterKill: return L4D2ApiKill_HunterKill;
		case L4D2Skill_SpitterKill: return L4D2ApiKill_SpitterKill;
		case L4D2Skill_JockeyKill: return L4D2ApiKill_JockeyKill;
		case L4D2Skill_ChargerKill: return L4D2ApiKill_ChargerKill;
	}

	return L4D2ApiKill_None;
}

L4D2ApiBossEventType API_MapBossEventType(L4D2SkillType type)
{
	switch (type)
	{
		case L4D2Skill_TankDead: return L4D2ApiBossEvent_TankDead;
		case L4D2Skill_WitchDead: return L4D2ApiBossEvent_WitchDead;
		case L4D2Skill_WitchIncap: return L4D2ApiBossEvent_WitchIncap;
		case L4D2Skill_TankRockSkeet: return L4D2ApiBossEvent_TankRockSkeet;
		case L4D2Skill_TankRockHit: return L4D2ApiBossEvent_TankRockHit;
		case L4D2Skill_TankLedgeHang: return L4D2ApiBossEvent_TankLedgeHang;
		case L4D2Skill_WitchCrown: return L4D2ApiBossEvent_WitchCrown;
	}

	return L4D2ApiBossEvent_None;
}

void API_GetSkillTypeName(L4D2ApiSkillType type, char[] buffer, int maxlen)
{
	switch (type)
	{
		case L4D2ApiSkill_HunterSkeet: strcopy(buffer, maxlen, "HunterSkeet");
		case L4D2ApiSkill_HunterSkeetMelee: strcopy(buffer, maxlen, "HunterSkeetMelee");
		case L4D2ApiSkill_HunterDeadstop: strcopy(buffer, maxlen, "HunterDeadstop");
		case L4D2ApiSkill_BoomerPop: strcopy(buffer, maxlen, "BoomerPop");
		case L4D2ApiSkill_ChargerLevel: strcopy(buffer, maxlen, "ChargerLevel");
		case L4D2ApiSkill_SmokerTongueCut: strcopy(buffer, maxlen, "SmokerTongueCut");
		case L4D2ApiSkill_SmokerSelfClear: strcopy(buffer, maxlen, "SmokerSelfClear");
		case L4D2ApiSkill_HunterHighPounce: strcopy(buffer, maxlen, "HunterHighPounce");
		case L4D2ApiSkill_JockeyHighPounce: strcopy(buffer, maxlen, "JockeyHighPounce");
		case L4D2ApiSkill_SmokerLedgeHang: strcopy(buffer, maxlen, "SmokerLedgeHang");
		case L4D2ApiSkill_JockeyLedgeHang: strcopy(buffer, maxlen, "JockeyLedgeHang");
		case L4D2ApiSkill_ChargerInstaKill: strcopy(buffer, maxlen, "ChargerInstaKill");
		case L4D2ApiSkill_ChargerDeathSetup: strcopy(buffer, maxlen, "ChargerDeathSetup");
		case L4D2ApiSkill_ChargerLedgeHang: strcopy(buffer, maxlen, "ChargerLedgeHang");
		case L4D2ApiSkill_ChargerBowl: strcopy(buffer, maxlen, "ChargerBowl");
		case L4D2ApiSkill_SpecialPinClear: strcopy(buffer, maxlen, "SpecialPinClear");
		case L4D2ApiSkill_BoomerVomitLanded: strcopy(buffer, maxlen, "BoomerVomitLanded");
		case L4D2ApiSkill_BunnyHopStreak: strcopy(buffer, maxlen, "BunnyHopStreak");
		case L4D2ApiSkill_CarAlarmTriggered: strcopy(buffer, maxlen, "CarAlarmTriggered");
		case L4D2ApiSkill_JockeyJumpStop: strcopy(buffer, maxlen, "JockeyJumpStop");
		case L4D2ApiSkill_JockeySkeetMelee: strcopy(buffer, maxlen, "JockeySkeetMelee");
		case L4D2ApiSkill_JockeySkeet: strcopy(buffer, maxlen, "JockeySkeet");
		default: strcopy(buffer, maxlen, "None");
	}
}

void API_GetKillTypeName(L4D2ApiKillType type, char[] buffer, int maxlen)
{
	switch (type)
	{
		case L4D2ApiKill_SmokerKill: strcopy(buffer, maxlen, "SmokerKill");
		case L4D2ApiKill_BoomerKill: strcopy(buffer, maxlen, "BoomerKill");
		case L4D2ApiKill_HunterKill: strcopy(buffer, maxlen, "HunterKill");
		case L4D2ApiKill_SpitterKill: strcopy(buffer, maxlen, "SpitterKill");
		case L4D2ApiKill_JockeyKill: strcopy(buffer, maxlen, "JockeyKill");
		case L4D2ApiKill_ChargerKill: strcopy(buffer, maxlen, "ChargerKill");
		default: strcopy(buffer, maxlen, "None");
	}
}

void API_GetBossEventTypeName(L4D2ApiBossEventType type, char[] buffer, int maxlen)
{
	switch (type)
	{
		case L4D2ApiBossEvent_TankDead: strcopy(buffer, maxlen, "TankDead");
		case L4D2ApiBossEvent_WitchDead: strcopy(buffer, maxlen, "WitchDead");
		case L4D2ApiBossEvent_WitchIncap: strcopy(buffer, maxlen, "WitchIncap");
		case L4D2ApiBossEvent_TankRockSkeet: strcopy(buffer, maxlen, "TankRockSkeet");
		case L4D2ApiBossEvent_TankRockHit: strcopy(buffer, maxlen, "TankRockHit");
		case L4D2ApiBossEvent_TankLedgeHang: strcopy(buffer, maxlen, "TankLedgeHang");
		case L4D2ApiBossEvent_WitchCrown: strcopy(buffer, maxlen, "WitchCrown");
		default: strcopy(buffer, maxlen, "None");
	}
}

Action API_FireFamilyDetected(Handle forwardHandle, int eventId, int publicTypeId, const char[] typeName, const char[] debugLabel)
{
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		char actorName[64];
		char victimName[64];
		char assisterName[64];
		char pinVictimName[64];
		Skills_FormatEventPlayerRoleName(eventIndex, 0, actorName, sizeof(actorName));
		Skills_FormatEventPlayerRoleName(eventIndex, 1, victimName, sizeof(victimName));
		Skills_FormatEventPlayerRoleName(eventIndex, 2, assisterName, sizeof(assisterName));
		Skills_FormatEventPlayerRoleName(eventIndex, 3, pinVictimName, sizeof(pinVictimName));

		Skills_Debug(PlayerSkillsDebug_Core,
			"%s detected. id=%d type=%s actor=%s victim=%s assister=%s pin=%s damage=%d shots=%d amount=%d reason=%d",
			debugLabel,
			eventId,
			typeName,
			actorName,
			victimName,
			assisterName,
			pinVictimName,
			g_SkillEvents[eventIndex].damage,
			g_SkillEvents[eventIndex].shots,
			g_SkillEvents[eventIndex].amount,
			g_SkillEvents[eventIndex].reason);
	}

	if (forwardHandle == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}

	Action result = Plugin_Continue;
	Call_StartForward(forwardHandle);
	Call_PushCell(eventId);
	Call_PushCell(publicTypeId);
	Call_Finish(result);

	Skills_Debug(PlayerSkillsDebug_Api, "%s forward finished. id=%d type=%s result=%d", debugLabel, eventId, typeName, result);
	return result;
}

Action API_FireSkillDetected(int eventId, L4D2SkillType type)
{
	switch (API_GetEventFamily(type))
	{
		case L4D2ApiEventFamily_Skill:
		{
			L4D2ApiSkillType publicType = API_MapSkillType(type);
			char typeName[48];
			API_GetSkillTypeName(publicType, typeName, sizeof(typeName));
			return API_FireFamilyDetected(g_hForwardSkillDetected, eventId, view_as<int>(publicType), typeName, "Skill");
		}

		case L4D2ApiEventFamily_Kill:
		{
			L4D2ApiKillType publicType = API_MapKillType(type);
			char typeName[48];
			API_GetKillTypeName(publicType, typeName, sizeof(typeName));
			return API_FireFamilyDetected(g_hForwardKillDetected, eventId, view_as<int>(publicType), typeName, "Kill");
		}

		case L4D2ApiEventFamily_BossEvent:
		{
			L4D2ApiBossEventType publicType = API_MapBossEventType(type);
			char typeName[48];
			API_GetBossEventTypeName(publicType, typeName, sizeof(typeName));
			return API_FireFamilyDetected(g_hForwardBossEventDetected, eventId, view_as<int>(publicType), typeName, "Boss event");
		}
	}

	return Plugin_Continue;
}

Action API_FireBossDamageFinalized(int sessionId, L4D2BossType type)
{
	if (g_hForwardBossSessionFinalized == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}

	Action result = Plugin_Continue;
	Call_StartForward(g_hForwardBossSessionFinalized);
	Call_PushCell(sessionId);
	Call_PushCell(type);
	Call_Finish(result);
	return result;
}

void API_FireTankSessionClosed(int sessionId, L4D2TankSessionEndReason reason)
{
	if (g_hForwardTankSessionClosed == INVALID_HANDLE)
	{
		return;
	}

	Call_StartForward(g_hForwardTankSessionClosed);
	Call_PushCell(sessionId);
	Call_PushCell(reason);
	Call_Finish();
}

int API_GetEventIndexOrFail(int eventId)
{
	return Skills_GetEventIndex(eventId);
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

L4DTeam API_GetSummaryActorTeam(int eventIndex)
{
	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_HunterHighPounce,
			L4D2Skill_JockeyHighPounce,
			L4D2Skill_SmokerLedgeHang,
			L4D2Skill_JockeyLedgeHang,
			L4D2Skill_ChargerInstaKill,
			L4D2Skill_ChargerDeathSetup,
			L4D2Skill_ChargerLedgeHang,
			L4D2Skill_BoomerVomitLanded,
			L4D2Skill_TankRockHit,
			L4D2Skill_TankLedgeHang:
		{
			return L4DTeam_Infected;
		}
	}

	return L4DTeam_Survivor;
}

bool API_ShouldIncludeEventInSummary(int eventIndex, L4D2ApiEventFamily family)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS || g_SkillEvents[eventIndex].id <= 0)
	{
		return false;
	}

	if (!Skills_IsSkillEventEnabledInCurrentMode(eventIndex))
	{
		return false;
	}

	if (API_GetEventFamily(g_SkillEvents[eventIndex].type) != family)
	{
		return false;
	}

	return g_SkillEvents[eventIndex].actor.userid > 0
		|| g_SkillEvents[eventIndex].actor.accountId > 0
		|| g_SkillEvents[eventIndex].actor.bot;
}

bool API_SkillSummaryEntryMatchesPlayer(int summaryIndex, int entryIndex, L4DTeam team, L4D2PlayerRef player)
{
	if (!g_SkillSummaries[summaryIndex].entries[entryIndex].active
		|| g_SkillSummaries[summaryIndex].entries[entryIndex].team != team)
	{
		return false;
	}

	if (player.bot)
	{
		return g_SkillSummaries[summaryIndex].entries[entryIndex].player.bot;
	}

	if (g_SkillSummaries[summaryIndex].entries[entryIndex].player.bot)
	{
		return false;
	}

	if (g_SkillSummaries[summaryIndex].entries[entryIndex].player.accountId > 0 && player.accountId > 0)
	{
		return g_SkillSummaries[summaryIndex].entries[entryIndex].player.accountId == player.accountId;
	}

	return g_SkillSummaries[summaryIndex].entries[entryIndex].player.auth[0] != '\0'
		&& player.auth[0] != '\0'
		&& strcmp(g_SkillSummaries[summaryIndex].entries[entryIndex].player.auth, player.auth) == 0;
}

int API_FindOrCreateSkillSummaryEntry(int summaryIndex, L4DTeam team, L4D2PlayerRef player)
{
	for (int entry = 0; entry < L4D2_SKILLS_MAX_SUMMARY_ENTRIES; entry++)
	{
		if (API_SkillSummaryEntryMatchesPlayer(summaryIndex, entry, team, player))
		{
			return entry;
		}
	}

	for (int entry = 0; entry < L4D2_SKILLS_MAX_SUMMARY_ENTRIES; entry++)
	{
		if (g_SkillSummaries[summaryIndex].entries[entry].active)
		{
			continue;
		}

		g_SkillSummaries[summaryIndex].entries[entry].Reset();
		g_SkillSummaries[summaryIndex].entries[entry].active = true;
		g_SkillSummaries[summaryIndex].entries[entry].team = team;

		if (player.bot)
		{
			g_SkillSummaries[summaryIndex].entries[entry].player.bot = true;
			g_SkillSummaries[summaryIndex].entries[entry].player.userid = 0;
			g_SkillSummaries[summaryIndex].entries[entry].player.accountId = 0;
			strcopy(g_SkillSummaries[summaryIndex].entries[entry].player.name, MAX_NAME_LENGTH, "IA");
			strcopy(g_SkillSummaries[summaryIndex].entries[entry].player.auth, 32, "BOT");
		}
		else
		{
			g_SkillSummaries[summaryIndex].entries[entry].player = player;
		}

		return entry;
	}

	return -1;
}

bool API_KillSummaryEntryMatchesPlayer(int summaryIndex, int entryIndex, L4DTeam team, L4D2PlayerRef player)
{
	if (!g_KillSummaries[summaryIndex].entries[entryIndex].active
		|| g_KillSummaries[summaryIndex].entries[entryIndex].team != team)
	{
		return false;
	}

	if (player.bot)
	{
		return g_KillSummaries[summaryIndex].entries[entryIndex].player.bot;
	}

	if (g_KillSummaries[summaryIndex].entries[entryIndex].player.bot)
	{
		return false;
	}

	if (g_KillSummaries[summaryIndex].entries[entryIndex].player.accountId > 0 && player.accountId > 0)
	{
		return g_KillSummaries[summaryIndex].entries[entryIndex].player.accountId == player.accountId;
	}

	return g_KillSummaries[summaryIndex].entries[entryIndex].player.auth[0] != '\0'
		&& player.auth[0] != '\0'
		&& strcmp(g_KillSummaries[summaryIndex].entries[entryIndex].player.auth, player.auth) == 0;
}

int API_FindOrCreateKillSummaryEntry(int summaryIndex, L4DTeam team, L4D2PlayerRef player)
{
	for (int entry = 0; entry < L4D2_SKILLS_MAX_SUMMARY_ENTRIES; entry++)
	{
		if (API_KillSummaryEntryMatchesPlayer(summaryIndex, entry, team, player))
		{
			return entry;
		}
	}

	for (int entry = 0; entry < L4D2_SKILLS_MAX_SUMMARY_ENTRIES; entry++)
	{
		if (g_KillSummaries[summaryIndex].entries[entry].active)
		{
			continue;
		}

		g_KillSummaries[summaryIndex].entries[entry].Reset();
		g_KillSummaries[summaryIndex].entries[entry].active = true;
		g_KillSummaries[summaryIndex].entries[entry].team = team;

		if (player.bot)
		{
			g_KillSummaries[summaryIndex].entries[entry].player.bot = true;
			g_KillSummaries[summaryIndex].entries[entry].player.userid = 0;
			g_KillSummaries[summaryIndex].entries[entry].player.accountId = 0;
			strcopy(g_KillSummaries[summaryIndex].entries[entry].player.name, MAX_NAME_LENGTH, "IA");
			strcopy(g_KillSummaries[summaryIndex].entries[entry].player.auth, 32, "BOT");
		}
		else
		{
			g_KillSummaries[summaryIndex].entries[entry].player = player;
		}

		return entry;
	}

	return -1;
}

void API_InitSkillSummaryMetadata(int slot, int totalEvents)
{
	g_SkillSummaries[slot].Reset();
	g_SkillSummaries[slot].id = ++g_iSkillSummarySerial;
	g_SkillSummaries[slot].createdAt = GetGameTime();
	g_SkillSummaries[slot].baseMode = g_Runtime.baseMode;
	g_SkillSummaries[slot].configuredSurvivorLimit = g_Runtime.configuredSurvivorLimit;
	g_SkillSummaries[slot].configuredPlayerZombieLimit = g_Runtime.configuredPlayerZombieLimit;
	g_SkillSummaries[slot].siPoolMask = g_Runtime.siPoolMask;
	g_SkillSummaries[slot].enabledSiClassCount = g_Runtime.enabledSiClassCount;
	g_SkillSummaries[slot].versusTeamSize = g_Runtime.versusTeamSize;
	g_SkillSummaries[slot].versusContext = g_Runtime.versusContext;
	g_SkillSummaries[slot].roundStartSignal = g_Runtime.roundStartSignal;
	g_SkillSummaries[slot].roundEndSignal = g_Runtime.roundEndSignal;
	g_SkillSummaries[slot].roundLiveSignal = g_Runtime.roundLiveSignal;
	g_SkillSummaries[slot].totalEvents = totalEvents;
	GetCurrentMap(g_SkillSummaries[slot].map, sizeof(g_SkillSummaries[slot].map));
}

void API_InitKillSummaryMetadata(int slot, int totalEvents)
{
	g_KillSummaries[slot].Reset();
	g_KillSummaries[slot].id = ++g_iKillSummarySerial;
	g_KillSummaries[slot].createdAt = GetGameTime();
	g_KillSummaries[slot].baseMode = g_Runtime.baseMode;
	g_KillSummaries[slot].configuredSurvivorLimit = g_Runtime.configuredSurvivorLimit;
	g_KillSummaries[slot].configuredPlayerZombieLimit = g_Runtime.configuredPlayerZombieLimit;
	g_KillSummaries[slot].siPoolMask = g_Runtime.siPoolMask;
	g_KillSummaries[slot].enabledSiClassCount = g_Runtime.enabledSiClassCount;
	g_KillSummaries[slot].versusTeamSize = g_Runtime.versusTeamSize;
	g_KillSummaries[slot].versusContext = g_Runtime.versusContext;
	g_KillSummaries[slot].roundStartSignal = g_Runtime.roundStartSignal;
	g_KillSummaries[slot].roundEndSignal = g_Runtime.roundEndSignal;
	g_KillSummaries[slot].roundLiveSignal = g_Runtime.roundLiveSignal;
	g_KillSummaries[slot].totalEvents = totalEvents;
	GetCurrentMap(g_KillSummaries[slot].map, sizeof(g_KillSummaries[slot].map));
}

int API_CreateSkillSummaryFromCurrentState()
{
	int totalEvents = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (API_ShouldIncludeEventInSummary(index, L4D2ApiEventFamily_Skill))
		{
			totalEvents++;
		}
	}

	if (totalEvents <= 0)
	{
		return 0;
	}

	int slot = g_iNextSkillSummarySlot;
	g_iNextSkillSummarySlot = (g_iNextSkillSummarySlot + 1) % L4D2_SKILLS_MAX_SUMMARIES;
	API_InitSkillSummaryMetadata(slot, totalEvents);

	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (!API_ShouldIncludeEventInSummary(index, L4D2ApiEventFamily_Skill))
		{
			continue;
		}

		L4DTeam team = API_GetSummaryActorTeam(index);
		int entry = API_FindOrCreateSkillSummaryEntry(slot, team, g_SkillEvents[index].actor);
		if (entry == -1)
		{
			continue;
		}

		L4D2ApiSkillType publicType = API_MapSkillType(g_SkillEvents[index].type);
		if (publicType != L4D2ApiSkill_None)
		{
			g_SkillSummaries[slot].entries[entry].counts[publicType]++;
		}
	}

	Skills_Debug(PlayerSkillsDebug_Api, "Skill summary finalized. id=%d map=%s total_events=%d",
		g_SkillSummaries[slot].id,
		g_SkillSummaries[slot].map,
		g_SkillSummaries[slot].totalEvents);

	return g_SkillSummaries[slot].id;
}

int API_CreateKillSummaryFromCurrentState()
{
	int totalEvents = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (API_ShouldIncludeEventInSummary(index, L4D2ApiEventFamily_Kill))
		{
			totalEvents++;
		}
	}

	if (totalEvents <= 0)
	{
		return 0;
	}

	int slot = g_iNextKillSummarySlot;
	g_iNextKillSummarySlot = (g_iNextKillSummarySlot + 1) % L4D2_SKILLS_MAX_SUMMARIES;
	API_InitKillSummaryMetadata(slot, totalEvents);

	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (!API_ShouldIncludeEventInSummary(index, L4D2ApiEventFamily_Kill))
		{
			continue;
		}

		L4DTeam team = API_GetSummaryActorTeam(index);
		int entry = API_FindOrCreateKillSummaryEntry(slot, team, g_SkillEvents[index].actor);
		if (entry == -1)
		{
			continue;
		}

		L4D2ApiKillType publicType = API_MapKillType(g_SkillEvents[index].type);
		if (publicType != L4D2ApiKill_None)
		{
			g_KillSummaries[slot].entries[entry].counts[publicType]++;
		}
	}

	Skills_Debug(PlayerSkillsDebug_Api, "Kill summary finalized. id=%d map=%s total_events=%d",
		g_KillSummaries[slot].id,
		g_KillSummaries[slot].map,
		g_KillSummaries[slot].totalEvents);

	return g_KillSummaries[slot].id;
}

void API_FinalizeSummaryFromCurrentState()
{
	int skillSummaryId = API_CreateSkillSummaryFromCurrentState();
	if (skillSummaryId > 0 && g_hForwardSkillSummaryFinalized != INVALID_HANDLE)
	{
		Call_StartForward(g_hForwardSkillSummaryFinalized);
		Call_PushCell(skillSummaryId);
		Call_Finish();
	}

	int killSummaryId = API_CreateKillSummaryFromCurrentState();
	if (killSummaryId > 0 && g_hForwardKillSummaryFinalized != INVALID_HANDLE)
	{
		Call_StartForward(g_hForwardKillSummaryFinalized);
		Call_PushCell(killSummaryId);
		Call_Finish();
	}
}

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
		API_GetSummaryTeamName(g_SkillSummaries[summaryIndex].entries[entry].team, teamName, sizeof(teamName));
		KvSetNum(kv, "team", g_SkillSummaries[summaryIndex].entries[entry].team);
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
		API_GetSummaryTeamName(g_KillSummaries[summaryIndex].entries[entry].team, teamName, sizeof(teamName));
		KvSetNum(kv, "team", g_KillSummaries[summaryIndex].entries[entry].team);
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

public int Native_PlayerSkills_IsSkillEventValid(Handle plugin, int numParams)
{
	return API_IsFamilyEventValid(GetNativeCell(1), L4D2ApiEventFamily_Skill);
}

public int Native_PlayerSkills_FillSkillEventKeyValues(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	Handle kv = GetNativeCell(2);
	if (eventIndex == -1 || kv == INVALID_HANDLE || API_GetEventFamily(g_SkillEvents[eventIndex].type) != L4D2ApiEventFamily_Skill)
	{
		return false;
	}

	return API_WriteEventKeyValuesForFamily(kv, eventIndex, L4D2ApiEventFamily_Skill);
}

public int Native_PlayerSkills_IsKillEventValid(Handle plugin, int numParams)
{
	return API_IsFamilyEventValid(GetNativeCell(1), L4D2ApiEventFamily_Kill);
}

public int Native_PlayerSkills_FillKillEventKeyValues(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	Handle kv = GetNativeCell(2);
	if (eventIndex == -1 || kv == INVALID_HANDLE || API_GetEventFamily(g_SkillEvents[eventIndex].type) != L4D2ApiEventFamily_Kill)
	{
		return false;
	}

	return API_WriteEventKeyValuesForFamily(kv, eventIndex, L4D2ApiEventFamily_Kill);
}

public int Native_PlayerSkills_IsBossEventValid(Handle plugin, int numParams)
{
	return API_IsFamilyEventValid(GetNativeCell(1), L4D2ApiEventFamily_BossEvent);
}

public int Native_PlayerSkills_FillBossEventKeyValues(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	Handle kv = GetNativeCell(2);
	if (eventIndex == -1 || kv == INVALID_HANDLE || API_GetEventFamily(g_SkillEvents[eventIndex].type) != L4D2ApiEventFamily_BossEvent)
	{
		return false;
	}

	return API_WriteEventKeyValuesForFamily(kv, eventIndex, L4D2ApiEventFamily_BossEvent);
}

public int Native_PlayerSkills_IsBossSessionValid(Handle plugin, int numParams)
{
	return API_GetBossSessionIndexById(GetNativeCell(1)) != -1;
}

public int Native_PlayerSkills_FillBossSessionKeyValues(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	Handle kv = GetNativeCell(2);

	if (sessionIndex == -1 || kv == INVALID_HANDLE)
	{
		return false;
	}

	KvRewind(kv);
	API_WriteBossSessionKeyValues(kv, sessionIndex);
	KvRewind(kv);
	return true;
}

public int Native_PlayerSkills_IsSkillSummaryValid(Handle plugin, int numParams)
{
	return API_IsSkillSummaryValid(GetNativeCell(1));
}

public int Native_PlayerSkills_FillSkillSummaryKeyValues(Handle plugin, int numParams)
{
	int summaryIndex = API_GetSkillSummaryIndexById(GetNativeCell(1));
	Handle kv = GetNativeCell(2);
	if (summaryIndex == -1 || kv == INVALID_HANDLE)
	{
		return false;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "skill_summary", true))
	{
		return false;
	}

	KvSetNum(kv, "id", g_SkillSummaries[summaryIndex].id);
	KvSetNum(kv, "total_events", g_SkillSummaries[summaryIndex].totalEvents);
	KvSetFloat(kv, "created_at", g_SkillSummaries[summaryIndex].createdAt);
	KvSetNum(kv, "base_mode", g_SkillSummaries[summaryIndex].baseMode);
	API_WriteSkillSummaryEntries(kv, summaryIndex);

	KvGoBack(kv);
	KvRewind(kv);
	return true;
}

public int Native_PlayerSkills_IsKillSummaryValid(Handle plugin, int numParams)
{
	return API_IsKillSummaryValid(GetNativeCell(1));
}

public int Native_PlayerSkills_FillKillSummaryKeyValues(Handle plugin, int numParams)
{
	int summaryIndex = API_GetKillSummaryIndexById(GetNativeCell(1));
	Handle kv = GetNativeCell(2);
	if (summaryIndex == -1 || kv == INVALID_HANDLE)
	{
		return false;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "kill_summary", true))
	{
		return false;
	}

	KvSetNum(kv, "id", g_KillSummaries[summaryIndex].id);
	KvSetNum(kv, "total_events", g_KillSummaries[summaryIndex].totalEvents);
	KvSetFloat(kv, "created_at", g_KillSummaries[summaryIndex].createdAt);
	KvSetNum(kv, "base_mode", g_KillSummaries[summaryIndex].baseMode);
	API_WriteKillSummaryEntries(kv, summaryIndex);

	KvGoBack(kv);
	KvRewind(kv);
	return true;
}
