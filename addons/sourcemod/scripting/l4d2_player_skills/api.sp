#if defined _l4d2_player_skills_api_included
	#endinput
#endif
#define _l4d2_player_skills_api_included

Handle g_hForwardSkillDetected = INVALID_HANDLE;
Handle g_hForwardSkillAnnounced = INVALID_HANDLE;
Handle g_hForwardBossDamageFinalized = INVALID_HANDLE;
Handle g_hForwardBossDamageAnnounced = INVALID_HANDLE;
Handle g_hForwardSummaryFinalized = INVALID_HANDLE;

void API_CreateForwards()
{
	g_hForwardSkillDetected = CreateGlobalForward("PlayerSkills_OnSkillDetected", ET_Event, Param_Cell, Param_Cell);
	g_hForwardSkillAnnounced = CreateGlobalForward("PlayerSkills_OnSkillAnnounced", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardBossDamageFinalized = CreateGlobalForward("PlayerSkills_OnBossDamageFinalized", ET_Event, Param_Cell, Param_Cell);
	g_hForwardBossDamageAnnounced = CreateGlobalForward("PlayerSkills_OnBossDamageAnnounced", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardSummaryFinalized = CreateGlobalForward("PlayerSkills_OnSummaryFinalized", ET_Ignore, Param_Cell);
}

void API_CreateNatives()
{
	CreateNative("PlayerSkills_IsEventValid", Native_PlayerSkills_IsEventValid);
	CreateNative("PlayerSkills_FillEventKeyValues", Native_PlayerSkills_FillEventKeyValues);
	CreateNative("PlayerSkills_GetEventType", Native_PlayerSkills_GetEventType);
	CreateNative("PlayerSkills_GetEventInt", Native_PlayerSkills_GetEventInt);
	CreateNative("PlayerSkills_GetEventFloat", Native_PlayerSkills_GetEventFloat);
	CreateNative("PlayerSkills_GetEventBool", Native_PlayerSkills_GetEventBool);
	CreateNative("PlayerSkills_GetEventClient", Native_PlayerSkills_GetEventClient);
	CreateNative("PlayerSkills_GetEventUserId", Native_PlayerSkills_GetEventUserId);
	CreateNative("PlayerSkills_GetEventAccountId", Native_PlayerSkills_GetEventAccountId);
	CreateNative("PlayerSkills_IsEventPlayerBot", Native_PlayerSkills_IsEventPlayerBot);
	CreateNative("PlayerSkills_GetEventPlayerName", Native_PlayerSkills_GetEventPlayerName);
	CreateNative("PlayerSkills_GetEventPlayerAuth", Native_PlayerSkills_GetEventPlayerAuth);
	CreateNative("PlayerSkills_GetEventAssistsCount", Native_PlayerSkills_GetEventAssistsCount);
	CreateNative("PlayerSkills_GetEventAssistScope", Native_PlayerSkills_GetEventAssistScope);
	CreateNative("PlayerSkills_GetEventDamageScope", Native_PlayerSkills_GetEventDamageScope);
	CreateNative("PlayerSkills_GetEventAssistUserId", Native_PlayerSkills_GetEventAssistUserId);
	CreateNative("PlayerSkills_GetEventAssistAccountId", Native_PlayerSkills_GetEventAssistAccountId);
	CreateNative("PlayerSkills_IsEventAssistBot", Native_PlayerSkills_IsEventAssistBot);
	CreateNative("PlayerSkills_GetEventAssistName", Native_PlayerSkills_GetEventAssistName);
	CreateNative("PlayerSkills_GetEventAssistDamage", Native_PlayerSkills_GetEventAssistDamage);
	CreateNative("PlayerSkills_GetEventAssistShots", Native_PlayerSkills_GetEventAssistShots);
	CreateNative("PlayerSkills_GetEventAssistWeaponId", Native_PlayerSkills_GetEventAssistWeaponId);
	CreateNative("PlayerSkills_GetBossType", Native_PlayerSkills_GetBossType);
	CreateNative("PlayerSkills_GetBossClient", Native_PlayerSkills_GetBossClient);
	CreateNative("PlayerSkills_GetBossUserId", Native_PlayerSkills_GetBossUserId);
	CreateNative("PlayerSkills_GetBossAccountId", Native_PlayerSkills_GetBossAccountId);
	CreateNative("PlayerSkills_IsBossPlayerBot", Native_PlayerSkills_IsBossPlayerBot);
	CreateNative("PlayerSkills_GetBossPlayerName", Native_PlayerSkills_GetBossPlayerName);
	CreateNative("PlayerSkills_GetBossPlayerAuth", Native_PlayerSkills_GetBossPlayerAuth);
	CreateNative("PlayerSkills_GetBossMaxHealth", Native_PlayerSkills_GetBossMaxHealth);
	CreateNative("PlayerSkills_GetBossLastHealth", Native_PlayerSkills_GetBossLastHealth);
	CreateNative("PlayerSkills_GetBossTotalDamage", Native_PlayerSkills_GetBossTotalDamage);
	CreateNative("PlayerSkills_IsBossInStasis", Native_PlayerSkills_IsBossInStasis);
	CreateNative("PlayerSkills_GetBossDamageEntryCount", Native_PlayerSkills_GetBossDamageEntryCount);
	CreateNative("PlayerSkills_GetBossDamageEntryClient", Native_PlayerSkills_GetBossDamageEntryClient);
	CreateNative("PlayerSkills_GetBossDamageEntryUserId", Native_PlayerSkills_GetBossDamageEntryUserId);
	CreateNative("PlayerSkills_GetBossDamageEntryAccountId", Native_PlayerSkills_GetBossDamageEntryAccountId);
	CreateNative("PlayerSkills_GetBossDamageEntryDamage", Native_PlayerSkills_GetBossDamageEntryDamage);
	CreateNative("PlayerSkills_GetBossDamageEntryShots", Native_PlayerSkills_GetBossDamageEntryShots);
	CreateNative("PlayerSkills_IsBossDamageEntryBot", Native_PlayerSkills_IsBossDamageEntryBot);
	CreateNative("PlayerSkills_GetBossDamageEntryName", Native_PlayerSkills_GetBossDamageEntryName);
	CreateNative("PlayerSkills_GetBossDamageEntryAuth", Native_PlayerSkills_GetBossDamageEntryAuth);
	CreateNative("PlayerSkills_IsSummaryValid", Native_PlayerSkills_IsSummaryValid);
	CreateNative("PlayerSkills_FillSummaryKeyValues", Native_PlayerSkills_FillSummaryKeyValues);
}

Action API_FireSkillDetected(int eventId, L4D2SkillType type)
{
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		char typeName[48];
		char actorName[64];
		char victimName[64];
		char assisterName[64];
		char pinVictimName[64];
		Skills_GetSkillTypeName(type, typeName, sizeof(typeName));
		Skills_FormatEventPlayerRoleName(eventIndex, 0, actorName, sizeof(actorName));
		Skills_FormatEventPlayerRoleName(eventIndex, 1, victimName, sizeof(victimName));
		Skills_FormatEventPlayerRoleName(eventIndex, 2, assisterName, sizeof(assisterName));
		Skills_FormatEventPlayerRoleName(eventIndex, 3, pinVictimName, sizeof(pinVictimName));

		Skills_Debug(PlayerSkillsDebug_Core,
			"Skill detected. id=%d type=%s actor=%s victim=%s assister=%s pin=%s damage=%d shots=%d amount=%d reason=%d",
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

	if (g_hForwardSkillDetected == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}

	Action result = Plugin_Continue;

	Call_StartForward(g_hForwardSkillDetected);
	Call_PushCell(eventId);
	Call_PushCell(type);
	Call_Finish(result);

	if (eventIndex != -1)
	{
		char typeName[48];
		Skills_GetSkillTypeName(type, typeName, sizeof(typeName));
		Skills_Debug(PlayerSkillsDebug_Api, "Skill forward finished. id=%d type=%s result=%d", eventId, typeName, result);
	}

	return result;
}

void API_FireSkillAnnounced(int eventId, L4D2SkillType type)
{
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		char typeName[48];
		char actorName[64];
		char victimName[64];
		Skills_GetSkillTypeName(type, typeName, sizeof(typeName));
		Skills_FormatEventPlayerRoleName(eventIndex, 0, actorName, sizeof(actorName));
		Skills_FormatEventPlayerRoleName(eventIndex, 1, victimName, sizeof(victimName));
		Skills_Debug(PlayerSkillsDebug_Announce, "Skill announced. id=%d type=%s actor=%s victim=%s", eventId, typeName, actorName, victimName);
	}

	if (g_hForwardSkillAnnounced == INVALID_HANDLE)
	{
		return;
	}

	Call_StartForward(g_hForwardSkillAnnounced);
	Call_PushCell(eventId);
	Call_PushCell(type);
	Call_Finish();
}

Action API_FireBossDamageFinalized(int sessionId, L4D2BossType type)
{
	if (g_hForwardBossDamageFinalized == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}

	Action result = Plugin_Continue;

	Call_StartForward(g_hForwardBossDamageFinalized);
	Call_PushCell(sessionId);
	Call_PushCell(type);
	Call_Finish(result);

	return result;
}

void API_FireBossDamageAnnounced(int sessionId, L4D2BossType type)
{
	if (g_hForwardBossDamageAnnounced == INVALID_HANDLE)
	{
		return;
	}

	Call_StartForward(g_hForwardBossDamageAnnounced);
	Call_PushCell(sessionId);
	Call_PushCell(type);
	Call_Finish();
}

void API_FireSummaryFinalized(int summaryId)
{
	if (g_hForwardSummaryFinalized == INVALID_HANDLE)
	{
		return;
	}

	Call_StartForward(g_hForwardSummaryFinalized);
	Call_PushCell(summaryId);
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

	return count;
}

bool API_IsBossEntryValid(int sessionIndex, int entry)
{
	return sessionIndex >= 0
		&& sessionIndex < L4D2_SKILLS_MAX_BOSSES
		&& entry >= 0
		&& entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES
		&& g_BossDamage[sessionIndex][entry].active;
}

bool API_IsEventAssistIndexValid(int eventIndex, int assistIndex)
{
	return eventIndex >= 0
		&& eventIndex < L4D2_SKILLS_MAX_EVENTS
		&& assistIndex >= 0
		&& assistIndex < g_SkillEvents[eventIndex].assistsCount
		&& assistIndex < L4D2_SKILLS_MAX_EVENT_ASSISTS
		&& g_SkillEvents[eventIndex].assists[assistIndex].userid > 0;
}

int API_GetSummaryIndexById(int summaryId)
{
	if (summaryId <= 0)
	{
		return -1;
	}

	for (int index = 0; index < L4D2_SKILLS_MAX_SUMMARIES; index++)
	{
		if (g_SkillSummaries[index].id == summaryId)
		{
			return index;
		}
	}

	return -1;
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

bool API_ShouldIncludeEventInSummary(int eventIndex)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS || g_SkillEvents[eventIndex].id <= 0)
	{
		return false;
	}

	if (!Skills_IsSkillEventEnabledInCurrentMode(eventIndex))
	{
		return false;
	}

	if (g_SkillEvents[eventIndex].type == L4D2Skill_WitchDead
		|| g_SkillEvents[eventIndex].type == L4D2Skill_WitchIncap)
	{
		return false;
	}

	return g_SkillEvents[eventIndex].actor.userid > 0
		|| g_SkillEvents[eventIndex].actor.accountId > 0
		|| g_SkillEvents[eventIndex].actor.bot;
}

bool API_SummaryEntryMatchesPlayer(int summaryIndex, int entryIndex, L4DTeam team, L4D2PlayerRef player)
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

int API_FindOrCreateSummaryEntry(int summaryIndex, L4DTeam team, L4D2PlayerRef player)
{
	for (int entry = 0; entry < L4D2_SKILLS_MAX_SUMMARY_ENTRIES; entry++)
	{
		if (API_SummaryEntryMatchesPlayer(summaryIndex, entry, team, player))
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

int API_CreateSummaryFromCurrentState()
{
	int totalEvents = 0;
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (API_ShouldIncludeEventInSummary(index))
		{
			totalEvents++;
		}
	}

	if (totalEvents <= 0)
	{
		return 0;
	}

	int slot = g_iNextSummarySlot;
	g_iNextSummarySlot = (g_iNextSummarySlot + 1) % L4D2_SKILLS_MAX_SUMMARIES;

	g_SkillSummaries[slot].Reset();
	g_SkillSummaries[slot].id = ++g_iSummarySerial;
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

	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (!API_ShouldIncludeEventInSummary(index))
		{
			continue;
		}

		L4DTeam team = API_GetSummaryActorTeam(index);
		int entry = API_FindOrCreateSummaryEntry(slot, team, g_SkillEvents[index].actor);
		if (entry == -1)
		{
			continue;
		}

		g_SkillSummaries[slot].entries[entry].counts[g_SkillEvents[index].type]++;
	}

	Skills_Debug(PlayerSkillsDebug_Api, "Summary finalized. id=%d map=%s total_events=%d",
		g_SkillSummaries[slot].id,
		g_SkillSummaries[slot].map,
		g_SkillSummaries[slot].totalEvents);

	return g_SkillSummaries[slot].id;
}

void API_FinalizeSummaryFromCurrentState()
{
	int summaryId = API_CreateSummaryFromCurrentState();
	if (summaryId > 0)
	{
		API_FireSummaryFinalized(summaryId);
	}
}

void API_GetBossPlayerRefBySlot(int sessionIndex, int slot, L4D2PlayerRef player)
{
	player.Reset();

	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES)
	{
		return;
	}

	switch (slot)
	{
		case 0: player = g_BossSessions[sessionIndex].owner;
		case 1: player = g_BossSessions[sessionIndex].pendingOwner;
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

void API_WriteEventSpecialRoles(Handle kv, int eventIndex)
{
	if (g_SkillEvents[eventIndex].victim.userid > 0
		|| g_SkillEvents[eventIndex].victim.accountId > 0
		|| g_SkillEvents[eventIndex].victim.bot
		|| g_SkillEvents[eventIndex].victim.name[0] != '\0')
	{
		API_SetEventPlayerKeys(kv, "victim", g_SkillEvents[eventIndex].victim);
	}

	if (g_SkillEvents[eventIndex].pinVictim.userid <= 0)
	{
		return;
	}

	API_SetEventPlayerKeys(kv, "pinvictim", g_SkillEvents[eventIndex].pinVictim);
}

void API_WriteEventSkillProperties(Handle kv, int eventIndex)
{
	if (!KvJumpToKey(kv, "skill_properties", true))
	{
		return;
	}

	if (g_SkillEvents[eventIndex].damage > 0)
	{
		KvSetNum(kv, "damage", g_SkillEvents[eventIndex].damage);
	}

	if (g_SkillEvents[eventIndex].actorDamage > 0)
	{
		KvSetNum(kv, "actor_damage", g_SkillEvents[eventIndex].actorDamage);
	}

	if (g_SkillEvents[eventIndex].assisterDamage > 0)
	{
		KvSetNum(kv, "assister_damage", g_SkillEvents[eventIndex].assisterDamage);
	}

	if (g_SkillEvents[eventIndex].assisterShots > 0)
	{
		KvSetNum(kv, "assister_shots", g_SkillEvents[eventIndex].assisterShots);
	}

	if (g_SkillEvents[eventIndex].assistScope != L4D2SkillAssistScope_None)
	{
		KvSetNum(kv, "assist_scope", g_SkillEvents[eventIndex].assistScope);
	}

	if (g_SkillEvents[eventIndex].damageScope != L4D2SkillDamageScope_None)
	{
		KvSetNum(kv, "damage_scope", g_SkillEvents[eventIndex].damageScope);
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

	if (g_SkillEvents[eventIndex].reportedHigh)
	{
		KvSetNum(kv, "reported_high", 1);
	}

	if (g_SkillEvents[eventIndex].indirect)
	{
		KvSetNum(kv, "indirect", 1);
	}

	if (g_SkillEvents[eventIndex].forced)
	{
		KvSetNum(kv, "forced", 1);
	}

	if (g_SkillEvents[eventIndex].incapped)
	{
		KvSetNum(kv, "incapped", 1);
	}

	if (g_SkillEvents[eventIndex].ledgeHang)
	{
		KvSetNum(kv, "ledge_hang", 1);
	}

	if (g_SkillEvents[eventIndex].fatalFall)
	{
		KvSetNum(kv, "fatal_fall", 1);
	}

	if (g_SkillEvents[eventIndex].deadlySlam)
	{
		KvSetNum(kv, "deadly_slam", 1);
	}

	if (g_SkillEvents[eventIndex].streak > 0)
	{
		KvSetNum(kv, "streak", g_SkillEvents[eventIndex].streak);
	}

	if (g_SkillEvents[eventIndex].perfect)
	{
		KvSetNum(kv, "perfect", 1);
	}

	if (g_SkillEvents[eventIndex].headshot)
	{
		KvSetNum(kv, "headshot", 1);
	}

	if (g_SkillEvents[eventIndex].sniper)
	{
		KvSetNum(kv, "sniper", 1);
	}

	if (g_SkillEvents[eventIndex].grenadeLauncher)
	{
		KvSetNum(kv, "grenade_launcher", 1);
	}

	if (g_SkillEvents[eventIndex].crown)
	{
		KvSetNum(kv, "crown", 1);
	}

	if (g_SkillEvents[eventIndex].startled)
	{
		KvSetNum(kv, "startled", 1);
	}

	if (g_SkillEvents[eventIndex].timeA > 0.0)
	{
		KvSetFloat(kv, "time_a", g_SkillEvents[eventIndex].timeA);
	}

	if (g_SkillEvents[eventIndex].timeB > 0.0)
	{
		KvSetFloat(kv, "time_b", g_SkillEvents[eventIndex].timeB);
	}

	if (g_SkillEvents[eventIndex].calculatedDamage > 0.0)
	{
		KvSetFloat(kv, "calculated_damage", g_SkillEvents[eventIndex].calculatedDamage);
	}

	if (g_SkillEvents[eventIndex].height > 0.0)
	{
		KvSetFloat(kv, "height", g_SkillEvents[eventIndex].height);
	}

	if (g_SkillEvents[eventIndex].distance > 0.0)
	{
		KvSetFloat(kv, "distance", g_SkillEvents[eventIndex].distance);
	}

	if (g_SkillEvents[eventIndex].maxVelocity > 0.0)
	{
		KvSetFloat(kv, "max_velocity", g_SkillEvents[eventIndex].maxVelocity);
	}

	KvGoBack(kv);
}

void API_WriteTankSessionProperties(Handle kv, int eventIndex, int sessionIndex)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return;
	}

	if (!KvJumpToKey(kv, "tank_session", true))
	{
		return;
	}

	KvSetNum(kv, "rocks_thrown", g_BossSessions[sessionIndex].rocksThrown);
	KvSetNum(kv, "rocks_hit", g_BossSessions[sessionIndex].rocksHit);
	KvSetNum(kv, "incaps", g_BossSessions[sessionIndex].incaps);
	KvSetNum(kv, "kills", g_BossSessions[sessionIndex].kills);
	KvSetNum(kv, "wipe", Boss_DidTankWipe(sessionIndex) ? 1 : 0);

	float aliveTime = 0.0;
	if (g_BossSessions[sessionIndex].startedAt > 0.0)
	{
		aliveTime = g_SkillEvents[eventIndex].createdAt - g_BossSessions[sessionIndex].startedAt;
	}
	KvSetFloat(kv, "alive_time", aliveTime);

	KvGoBack(kv);
}

void API_WriteWitchSessionProperties(Handle kv, int eventIndex, int sessionIndex)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return;
	}

	if (!KvJumpToKey(kv, "witch_session", true))
	{
		return;
	}

	float aliveTime = 0.0;
	if (g_BossSessions[sessionIndex].startedAt > 0.0)
	{
		aliveTime = g_SkillEvents[eventIndex].createdAt - g_BossSessions[sessionIndex].startedAt;
	}

	KvSetFloat(kv, "alive_time", aliveTime);
	KvSetNum(kv, "startled", g_BossSessions[sessionIndex].startled ? 1 : 0);
	KvSetNum(kv, "total_damage", g_BossSessions[sessionIndex].totalDamage);

	KvGoBack(kv);
}

void API_WriteEventContextBlock(Handle kv)
{
	if (!KvJumpToKey(kv, "context", true))
	{
		return;
	}

	char baseModeName[24];
	char versusContextName[32];
	Skills_GetModeBaseName(g_Runtime.baseMode, baseModeName, sizeof(baseModeName));
	Skills_GetVersusContextName(g_Runtime.versusContext, versusContextName, sizeof(versusContextName));

	KvSetNum(kv, "base_mode", g_Runtime.baseMode);
	KvSetString(kv, "base_mode_name", baseModeName);
	KvSetNum(kv, "survivor_limit", g_Runtime.configuredSurvivorLimit);
	KvSetNum(kv, "infected_limit", g_Runtime.configuredPlayerZombieLimit);
	KvSetNum(kv, "si_pool_mask", g_Runtime.siPoolMask);
	KvSetNum(kv, "enabled_si_classes", g_Runtime.enabledSiClassCount);
	KvSetNum(kv, "team_size", g_Runtime.versusTeamSize);
	KvSetNum(kv, "versus_context", g_Runtime.versusContext);
	KvSetString(kv, "versus_context_name", versusContextName);
	KvSetNum(kv, "round_start_signal", g_Runtime.roundStartSignal);
	KvSetNum(kv, "round_end_signal", g_Runtime.roundEndSignal);
	KvSetNum(kv, "round_live_signal", g_Runtime.roundLiveSignal);

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

void API_WriteSummaryContextBlock(Handle kv, int summaryIndex)
{
	if (!KvJumpToKey(kv, "context", true))
	{
		return;
	}

	char baseModeName[24];
	char versusContextName[32];
	Skills_GetModeBaseName(g_SkillSummaries[summaryIndex].baseMode, baseModeName, sizeof(baseModeName));
	Skills_GetVersusContextName(g_SkillSummaries[summaryIndex].versusContext, versusContextName, sizeof(versusContextName));

	KvSetNum(kv, "base_mode", g_SkillSummaries[summaryIndex].baseMode);
	KvSetString(kv, "base_mode_name", baseModeName);
	KvSetNum(kv, "survivor_limit", g_SkillSummaries[summaryIndex].configuredSurvivorLimit);
	KvSetNum(kv, "infected_limit", g_SkillSummaries[summaryIndex].configuredPlayerZombieLimit);
	KvSetNum(kv, "si_pool_mask", g_SkillSummaries[summaryIndex].siPoolMask);
	KvSetNum(kv, "enabled_si_classes", g_SkillSummaries[summaryIndex].enabledSiClassCount);
	KvSetNum(kv, "team_size", g_SkillSummaries[summaryIndex].versusTeamSize);
	KvSetNum(kv, "versus_context", g_SkillSummaries[summaryIndex].versusContext);
	KvSetString(kv, "versus_context_name", versusContextName);
	KvSetNum(kv, "round_start_signal", g_SkillSummaries[summaryIndex].roundStartSignal);
	KvSetNum(kv, "round_end_signal", g_SkillSummaries[summaryIndex].roundEndSignal);
	KvSetNum(kv, "round_live_signal", g_SkillSummaries[summaryIndex].roundLiveSignal);

	KvGoBack(kv);
}

void API_WriteSummaryEntries(Handle kv, int summaryIndex)
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
			for (int type = 1; type < view_as<int>(L4D2Skill_Size); type++)
			{
				if (g_SkillSummaries[summaryIndex].entries[entry].counts[type] > 0)
				{
					char typeName[48];
					Skills_GetSkillTypeName(view_as<L4D2SkillType>(type), typeName, sizeof(typeName));
					KvSetNum(kv, typeName, g_SkillSummaries[summaryIndex].entries[entry].counts[type]);
				}
			}
			KvGoBack(kv);
		}

		KvGoBack(kv);
	}

	KvGoBack(kv);
}

public int Native_PlayerSkills_IsEventValid(Handle plugin, int numParams)
{
	return Skills_IsEventValid(GetNativeCell(1));
}

public int Native_PlayerSkills_IsSummaryValid(Handle plugin, int numParams)
{
	return API_GetSummaryIndexById(GetNativeCell(1)) != -1;
}

public int Native_PlayerSkills_FillSummaryKeyValues(Handle plugin, int numParams)
{
	int summaryIndex = API_GetSummaryIndexById(GetNativeCell(1));
	Handle kv = GetNativeCell(2);
	if (summaryIndex == -1 || kv == INVALID_HANDLE)
	{
		return false;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "summary", true))
	{
		return false;
	}

	KvSetNum(kv, "id", g_SkillSummaries[summaryIndex].id);
	KvSetString(kv, "map", g_SkillSummaries[summaryIndex].map);
	KvSetNum(kv, "total_events", g_SkillSummaries[summaryIndex].totalEvents);
	KvSetFloat(kv, "created_at", g_SkillSummaries[summaryIndex].createdAt);
	API_WriteSummaryContextBlock(kv, summaryIndex);
	API_WriteSummaryEntries(kv, summaryIndex);

	KvGoBack(kv);
	KvRewind(kv);
	return true;
}

public int Native_PlayerSkills_FillEventKeyValues(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	Handle kv = GetNativeCell(2);

	if (eventIndex == -1 || kv == INVALID_HANDLE)
	{
		return false;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "event", true))
	{
		return false;
	}

	KvSetNum(kv, "id", g_SkillEvents[eventIndex].id);
	KvSetNum(kv, "type_id", g_SkillEvents[eventIndex].type);

	API_WriteEventContextBlock(kv);
	API_SetEventPlayerKeys(kv, "actor", g_SkillEvents[eventIndex].actor);
	API_WriteEventAssists(kv, eventIndex);
	API_WriteEventSpecialRoles(kv, eventIndex);
	API_WriteEventSkillProperties(kv, eventIndex);

	if (g_SkillEvents[eventIndex].type == L4D2Skill_TankDead && g_SkillEvents[eventIndex].actor2 > 0)
	{
		API_WriteTankSessionProperties(kv, eventIndex, API_GetBossSessionIndexById(g_SkillEvents[eventIndex].actor2));
	}

	if ((g_SkillEvents[eventIndex].type == L4D2Skill_WitchDead || g_SkillEvents[eventIndex].type == L4D2Skill_WitchCrown || g_SkillEvents[eventIndex].type == L4D2Skill_WitchIncap)
		&& g_SkillEvents[eventIndex].actor2 > 0)
	{
		API_WriteWitchSessionProperties(kv, eventIndex, API_GetBossSessionIndexById(g_SkillEvents[eventIndex].actor2));
	}

	KvGoBack(kv);
	KvRewind(kv);
	return true;
}

public int Native_PlayerSkills_GetEventType(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	return eventIndex != -1 ? g_SkillEvents[eventIndex].type : L4D2Skill_None;
}

public int Native_PlayerSkills_GetEventInt(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	if (eventIndex == -1)
	{
		return 0;
	}

	switch (GetNativeCell(2))
	{
		case 0: return g_SkillEvents[eventIndex].damage;
		case 1: return g_SkillEvents[eventIndex].chipDamage;
		case 2: return g_SkillEvents[eventIndex].shots;
		case 3: return g_SkillEvents[eventIndex].shoveCount;
		case 4: return g_SkillEvents[eventIndex].amount;
		case 5: return g_SkillEvents[eventIndex].streak;
		case 6: return g_SkillEvents[eventIndex].zombieClass;
		case 7: return g_SkillEvents[eventIndex].reason;
		case 8: return g_SkillEvents[eventIndex].actor2;
		case 9: return g_SkillEvents[eventIndex].victim2;
		case 10: return Skills_GetEventRating(eventIndex);
	}

	return 0;
}

public any Native_PlayerSkills_GetEventFloat(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	if (eventIndex == -1)
	{
		return 0.0;
	}

	switch (GetNativeCell(2))
	{
		case 0: return g_SkillEvents[eventIndex].timeA;
		case 1: return g_SkillEvents[eventIndex].timeB;
		case 2: return g_SkillEvents[eventIndex].calculatedDamage;
		case 3: return g_SkillEvents[eventIndex].height;
		case 4: return g_SkillEvents[eventIndex].distance;
		case 5: return g_SkillEvents[eventIndex].maxVelocity;
		case 6: return g_SkillEvents[eventIndex].createdAt;
	}

	return 0.0;
}

public int Native_PlayerSkills_GetEventBool(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	if (eventIndex == -1)
	{
		return false;
	}

	switch (GetNativeCell(2))
	{
		case 0: return g_SkillEvents[eventIndex].withShove;
		case 1: return g_SkillEvents[eventIndex].indirect;
		case 2: return g_SkillEvents[eventIndex].forced;
		case 3: return g_SkillEvents[eventIndex].wasCarried;
		case 4: return g_SkillEvents[eventIndex].reportedHigh;
		case 5: return g_SkillEvents[eventIndex].incapped;
		case 6: return g_SkillEvents[eventIndex].ledgeHang;
		case 7: return g_SkillEvents[eventIndex].fatalFall;
		case 8: return g_SkillEvents[eventIndex].deadlySlam;
		case 9: return false;
		case 10: return g_SkillEvents[eventIndex].crown;
		case 11: return g_SkillEvents[eventIndex].startled;
		case 12: return g_SkillEvents[eventIndex].perfect;
		case 13: return g_SkillEvents[eventIndex].headshot;
		case 14: return g_SkillEvents[eventIndex].sniper;
		case 15: return g_SkillEvents[eventIndex].grenadeLauncher;
	}

	return false;
}

public int Native_PlayerSkills_GetEventClient(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	if (eventIndex == -1)
	{
		return 0;
	}

	L4D2PlayerRef player;
	Skills_GetEventPlayerRefBySlot(eventIndex, GetNativeCell(2), player);
	return player.ResolveClient();
}

public int Native_PlayerSkills_GetEventUserId(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	if (eventIndex == -1)
	{
		return 0;
	}

	L4D2PlayerRef player;
	Skills_GetEventPlayerRefBySlot(eventIndex, GetNativeCell(2), player);
	return player.userid;
}

public int Native_PlayerSkills_GetEventAccountId(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	if (eventIndex == -1)
	{
		return 0;
	}

	L4D2PlayerRef player;
	Skills_GetEventPlayerRefBySlot(eventIndex, GetNativeCell(2), player);
	return player.accountId;
}

public int Native_PlayerSkills_IsEventPlayerBot(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	if (eventIndex == -1)
	{
		return false;
	}

	L4D2PlayerRef player;
	Skills_GetEventPlayerRefBySlot(eventIndex, GetNativeCell(2), player);
	return player.bot;
}

public int Native_PlayerSkills_GetEventPlayerName(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	char buffer[MAX_NAME_LENGTH];
	buffer[0] = '\0';

	if (eventIndex != -1)
	{
		L4D2PlayerRef player;
		Skills_GetEventPlayerRefBySlot(eventIndex, GetNativeCell(2), player);
		strcopy(buffer, sizeof(buffer), player.name);
	}

	SetNativeString(3, buffer, GetNativeCell(4), true);
	return 0;
}

public int Native_PlayerSkills_GetEventPlayerAuth(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	char buffer[32];
	buffer[0] = '\0';

	if (eventIndex != -1)
	{
		L4D2PlayerRef player;
		Skills_GetEventPlayerRefBySlot(eventIndex, GetNativeCell(2), player);
		strcopy(buffer, sizeof(buffer), player.auth);
	}

	SetNativeString(3, buffer, GetNativeCell(4), true);
	return 0;
}

public int Native_PlayerSkills_GetEventAssistsCount(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	return eventIndex != -1 ? g_SkillEvents[eventIndex].assistsCount : 0;
}

public int Native_PlayerSkills_GetEventAssistScope(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	return eventIndex != -1 ? g_SkillEvents[eventIndex].assistScope : L4D2SkillAssistScope_None;
}

public int Native_PlayerSkills_GetEventDamageScope(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	return eventIndex != -1 ? g_SkillEvents[eventIndex].damageScope : L4D2SkillDamageScope_None;
}

public int Native_PlayerSkills_GetEventAssistUserId(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	int assistIndex = GetNativeCell(2);
	return API_IsEventAssistIndexValid(eventIndex, assistIndex) ? g_SkillEvents[eventIndex].assists[assistIndex].userid : 0;
}

public int Native_PlayerSkills_GetEventAssistAccountId(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	int assistIndex = GetNativeCell(2);
	return API_IsEventAssistIndexValid(eventIndex, assistIndex) ? g_SkillEvents[eventIndex].assists[assistIndex].accountId : 0;
}

public int Native_PlayerSkills_IsEventAssistBot(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	int assistIndex = GetNativeCell(2);
	return API_IsEventAssistIndexValid(eventIndex, assistIndex) ? g_SkillEvents[eventIndex].assists[assistIndex].bot : false;
}

public int Native_PlayerSkills_GetEventAssistName(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	int assistIndex = GetNativeCell(2);
	char buffer[MAX_NAME_LENGTH];
	buffer[0] = '\0';

	if (API_IsEventAssistIndexValid(eventIndex, assistIndex))
	{
		strcopy(buffer, sizeof(buffer), g_SkillEvents[eventIndex].assists[assistIndex].name);
	}

	SetNativeString(3, buffer, GetNativeCell(4), true);
	return 0;
}

public int Native_PlayerSkills_GetEventAssistDamage(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	int assistIndex = GetNativeCell(2);
	return API_IsEventAssistIndexValid(eventIndex, assistIndex) ? g_SkillEvents[eventIndex].assistDamage[assistIndex] : 0;
}

public int Native_PlayerSkills_GetEventAssistShots(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	int assistIndex = GetNativeCell(2);
	return API_IsEventAssistIndexValid(eventIndex, assistIndex) ? g_SkillEvents[eventIndex].assistShots[assistIndex] : 0;
}

public int Native_PlayerSkills_GetEventAssistWeaponId(Handle plugin, int numParams)
{
	int eventIndex = API_GetEventIndexOrFail(GetNativeCell(1));
	int assistIndex = GetNativeCell(2);
	return API_IsEventAssistIndexValid(eventIndex, assistIndex) ? g_SkillEvents[eventIndex].assistWeaponId[assistIndex] : WEPID_NONE;
}

public int Native_PlayerSkills_GetBossType(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	return sessionIndex != -1 ? g_BossSessions[sessionIndex].type : L4D2Boss_None;
}

public int Native_PlayerSkills_GetBossClient(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	if (sessionIndex == -1)
	{
		return 0;
	}

	L4D2PlayerRef player;
	API_GetBossPlayerRefBySlot(sessionIndex, GetNativeCell(2), player);
	return player.ResolveClient();
}

public int Native_PlayerSkills_GetBossUserId(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	if (sessionIndex == -1)
	{
		return 0;
	}

	L4D2PlayerRef player;
	API_GetBossPlayerRefBySlot(sessionIndex, GetNativeCell(2), player);
	return player.userid;
}

public int Native_PlayerSkills_GetBossAccountId(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	if (sessionIndex == -1)
	{
		return 0;
	}

	L4D2PlayerRef player;
	API_GetBossPlayerRefBySlot(sessionIndex, GetNativeCell(2), player);
	return player.accountId;
}

public int Native_PlayerSkills_IsBossPlayerBot(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	if (sessionIndex == -1)
	{
		return false;
	}

	L4D2PlayerRef player;
	API_GetBossPlayerRefBySlot(sessionIndex, GetNativeCell(2), player);
	return player.bot;
}

public int Native_PlayerSkills_GetBossPlayerName(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	char buffer[MAX_NAME_LENGTH];
	buffer[0] = '\0';

	if (sessionIndex != -1)
	{
		L4D2PlayerRef player;
		API_GetBossPlayerRefBySlot(sessionIndex, GetNativeCell(2), player);
		strcopy(buffer, sizeof(buffer), player.name);
	}

	SetNativeString(3, buffer, GetNativeCell(4), true);
	return 0;
}

public int Native_PlayerSkills_GetBossPlayerAuth(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	char buffer[32];
	buffer[0] = '\0';

	if (sessionIndex != -1)
	{
		L4D2PlayerRef player;
		API_GetBossPlayerRefBySlot(sessionIndex, GetNativeCell(2), player);
		strcopy(buffer, sizeof(buffer), player.auth);
	}

	SetNativeString(3, buffer, GetNativeCell(4), true);
	return 0;
}

public int Native_PlayerSkills_GetBossMaxHealth(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	return sessionIndex != -1 ? g_BossSessions[sessionIndex].maxHealth : 0;
}

public int Native_PlayerSkills_GetBossLastHealth(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	return sessionIndex != -1 ? g_BossSessions[sessionIndex].lastHealth : 0;
}

public int Native_PlayerSkills_GetBossTotalDamage(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	return sessionIndex != -1 ? g_BossSessions[sessionIndex].totalDamage : 0;
}

public int Native_PlayerSkills_IsBossInStasis(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	return sessionIndex != -1 ? g_BossSessions[sessionIndex].inStasis : false;
}

public int Native_PlayerSkills_GetBossDamageEntryCount(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	return sessionIndex != -1 ? API_GetBossDamageEntryCountByIndex(sessionIndex) : 0;
}

public int Native_PlayerSkills_GetBossDamageEntryClient(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	int entry = GetNativeCell(2);
	return API_IsBossEntryValid(sessionIndex, entry) ? g_BossDamage[sessionIndex][entry].player.ResolveClient() : 0;
}

public int Native_PlayerSkills_GetBossDamageEntryUserId(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	int entry = GetNativeCell(2);
	return API_IsBossEntryValid(sessionIndex, entry) ? g_BossDamage[sessionIndex][entry].player.userid : 0;
}

public int Native_PlayerSkills_GetBossDamageEntryAccountId(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	int entry = GetNativeCell(2);
	return API_IsBossEntryValid(sessionIndex, entry) ? g_BossDamage[sessionIndex][entry].player.accountId : 0;
}

public int Native_PlayerSkills_GetBossDamageEntryDamage(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	int entry = GetNativeCell(2);
	return API_IsBossEntryValid(sessionIndex, entry) ? g_BossDamage[sessionIndex][entry].damage : 0;
}

public int Native_PlayerSkills_GetBossDamageEntryShots(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	int entry = GetNativeCell(2);
	return API_IsBossEntryValid(sessionIndex, entry) ? g_BossDamage[sessionIndex][entry].shots : 0;
}

public int Native_PlayerSkills_IsBossDamageEntryBot(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	int entry = GetNativeCell(2);
	return API_IsBossEntryValid(sessionIndex, entry) ? g_BossDamage[sessionIndex][entry].player.bot : false;
}

public int Native_PlayerSkills_GetBossDamageEntryName(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	int entry = GetNativeCell(2);
	char buffer[MAX_NAME_LENGTH];
	buffer[0] = '\0';

	if (API_IsBossEntryValid(sessionIndex, entry))
	{
		strcopy(buffer, sizeof(buffer), g_BossDamage[sessionIndex][entry].player.name);
	}

	SetNativeString(3, buffer, GetNativeCell(4), true);
	return 0;
}

public int Native_PlayerSkills_GetBossDamageEntryAuth(Handle plugin, int numParams)
{
	int sessionIndex = API_GetBossSessionIndexById(GetNativeCell(1));
	int entry = GetNativeCell(2);
	char buffer[32];
	buffer[0] = '\0';

	if (API_IsBossEntryValid(sessionIndex, entry))
	{
		strcopy(buffer, sizeof(buffer), g_BossDamage[sessionIndex][entry].player.auth);
	}

	SetNativeString(3, buffer, GetNativeCell(4), true);
	return 0;
}
