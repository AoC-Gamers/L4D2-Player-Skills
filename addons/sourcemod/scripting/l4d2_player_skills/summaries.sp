#if defined _l4d2_player_skills_summaries_included
	#endinput
#endif
#define _l4d2_player_skills_summaries_included

// This module owns summary finalization state; storage and serial counters remain declared once in the core.
bool g_bSummaryFinalizedForRound;

L4DTeam API_GetSummaryActorTeam(int eventIndex)
{
	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_HunterHighPounce,
			L4D2Skill_JockeyHighLeap,
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
		|| g_SkillSummaries[summaryIndex].entries[entryIndex].player.team != team)
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

		if (player.bot)
		{
			g_SkillSummaries[summaryIndex].entries[entry].player.bot = true;
			g_SkillSummaries[summaryIndex].entries[entry].player.team = team;
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
		|| g_KillSummaries[summaryIndex].entries[entryIndex].player.team != team)
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

		if (player.bot)
		{
			g_KillSummaries[summaryIndex].entries[entry].player.bot = true;
			g_KillSummaries[summaryIndex].entries[entry].player.team = team;
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

void API_ResetRoundSummaryState()
{
	g_bSummaryFinalizedForRound = false;
	Skills_ResetEvents();
}

void API_FinalizeSummaryFromCurrentState()
{
	if (g_bSummaryFinalizedForRound)
	{
		return;
	}

	g_bSummaryFinalizedForRound = true;

	// Freeze both families before any consumer can start/reset another round.
	int skillSummaryId = API_CreateSkillSummaryFromCurrentState();
	int killSummaryId = API_CreateKillSummaryFromCurrentState();
	if (skillSummaryId > 0 && g_hForwardSkillSummaryFinalized != INVALID_HANDLE)
	{
		Call_StartForward(g_hForwardSkillSummaryFinalized);
		Call_PushCell(skillSummaryId);
		Call_Finish();
	}

	if (killSummaryId > 0 && g_hForwardKillSummaryFinalized != INVALID_HANDLE)
	{
		Call_StartForward(g_hForwardKillSummaryFinalized);
		Call_PushCell(killSummaryId);
		Call_Finish();
	}
}
