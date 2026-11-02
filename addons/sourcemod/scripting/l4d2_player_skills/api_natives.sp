#if defined _l4d2_player_skills_api_natives_included
	#endinput
#endif
#define _l4d2_player_skills_api_natives_included

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
