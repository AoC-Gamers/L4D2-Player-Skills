#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <console_table>
#include <left4dhooks>
#include <l4d2_player_skills>

#define L4D2_PLAYER_SKILLS_SERIES_MAX_SERIES 8
#define L4D2_PLAYER_SKILLS_SERIES_MAX_ENTRIES 64
#define L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS 8

enum PlayerSkillsSeriesScope
{
	PlayerSkillsSeriesScope_None = 0,
	PlayerSkillsSeriesScope_Mission,
	PlayerSkillsSeriesScope_Map
}

enum PlayerSkillsSeriesFilter
{
	PlayerSkillsSeriesFilter_All = 0,
	PlayerSkillsSeriesFilter_Survivor,
	PlayerSkillsSeriesFilter_Infected
}

enum struct PlayerSkillsSeriesPlayerData
{
	bool active;
	int team;
	int accountId;
	bool bot;
	char name[MAX_NAME_LENGTH];
	int skillCounts[L4D2ApiSkill_Size];
	int killCounts[L4D2ApiKill_Size];

	void Reset()
	{
		this.active = false;
		this.team = 0;
		this.accountId = 0;
		this.bot = false;
		this.name[0] = '\0';

		for (int i = 0; i < view_as<int>(L4D2ApiSkill_Size); i++)
		{
			this.skillCounts[i] = 0;
		}

		for (int i = 0; i < view_as<int>(L4D2ApiKill_Size); i++)
		{
			this.killCounts[i] = 0;
		}
	}
}

enum struct PlayerSkillsSeriesEntryData
{
	bool active;
	int sequence;
	int baseMode;
	int createdAt;
	char map[64];
	char missionKey[32];
	int skillSummaryId;
	int killSummaryId;
	int skillTotalEvents;
	int killTotalEvents;
	PlayerSkillsSeriesPlayerData players[L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS];

	void Reset()
	{
		this.active = false;
		this.sequence = 0;
		this.baseMode = GAMEMODE_UNKNOWN;
		this.createdAt = 0;
		this.map[0] = '\0';
		this.missionKey[0] = '\0';
		this.skillSummaryId = 0;
		this.killSummaryId = 0;
		this.skillTotalEvents = 0;
		this.killTotalEvents = 0;

		for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; i++)
		{
			this.players[i].Reset();
		}
	}
}

enum struct PlayerSkillsSeriesAggregatePlayerData
{
	bool active;
	int team;
	int accountId;
	bool bot;
	char name[MAX_NAME_LENGTH];
	int entries;
	int skillCounts[L4D2ApiSkill_Size];
	int killCounts[L4D2ApiKill_Size];

	void Reset()
	{
		this.active = false;
		this.team = 0;
		this.accountId = 0;
		this.bot = false;
		this.name[0] = '\0';
		this.entries = 0;

		for (int i = 0; i < view_as<int>(L4D2ApiSkill_Size); i++)
		{
			this.skillCounts[i] = 0;
		}

		for (int i = 0; i < view_as<int>(L4D2ApiKill_Size); i++)
		{
			this.killCounts[i] = 0;
		}
	}
}

enum struct PlayerSkillsSeriesData
{
	bool active;
	bool closed;
	int id;
	int baseMode;
	PlayerSkillsSeriesScope scope;
	int entryCount;
	int totalSkillEvents;
	int totalKillEvents;
	char map[64];
	char missionKey[32];
	PlayerSkillsSeriesEntryData entries[L4D2_PLAYER_SKILLS_SERIES_MAX_ENTRIES];

	void Reset()
	{
		this.active = false;
		this.closed = false;
		this.id = 0;
		this.baseMode = GAMEMODE_UNKNOWN;
		this.scope = PlayerSkillsSeriesScope_None;
		this.entryCount = 0;
		this.totalSkillEvents = 0;
		this.totalKillEvents = 0;
		this.map[0] = '\0';
		this.missionKey[0] = '\0';

		for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_ENTRIES; i++)
		{
			this.entries[i].Reset();
		}
	}
}

PlayerSkillsSeriesData g_Series[L4D2_PLAYER_SKILLS_SERIES_MAX_SERIES];
int g_iActiveSeriesIndex = -1;
int g_iSeriesSerial = 0;

public Plugin myinfo =
{
	name = "L4D2 Player Skills Series",
	author = "lechuga",
	description = "Stores finalized PlayerSkills summaries into short-lived mode-aware series.",
	version = "1.0.0",
	url = "https://github.com/AoC-Gamers/L4D2-Player-Skills"
};

public void OnPluginStart()
{
	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_SERIES; i++)
	{
		g_Series[i].Reset();
	}

	RegConsoleCmd("sm_skills_series", Command_SkillsSeries, "Print the current PlayerSkills series buffer or a requested series detail.");
	RegConsoleCmd("sm_skills_series_stats", Command_SkillsSeriesStats, "Print aggregated PlayerSkills series stats. Usage: sm_skills_series_stats <surv|infect|all> [id].");
}

public void PlayerSkills_OnSkillSummaryFinalized(int summaryId)
{
	Series_ConsumeSummary(summaryId, true);
}

public void PlayerSkills_OnKillSummaryFinalized(int summaryId)
{
	Series_ConsumeSummary(summaryId, false);
}

Action Command_SkillsSeries(int client, int args)
{
	if (client <= 0 || !IsClientInGame(client))
	{
		ReplyToCommand(client, "sm_skills_series is in-game only.");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		Series_PrintBuffer(client);
		return Plugin_Handled;
	}

	char arg[16];
	GetCmdArg(1, arg, sizeof(arg));

	int index = Series_FindSeriesIndexById(StringToInt(arg));
	if (index == -1)
	{
		ReplyToCommand(client, "Unknown skills series id.");
		return Plugin_Handled;
	}

	Series_PrintEntries(client, index);
	return Plugin_Handled;
}

Action Command_SkillsSeriesStats(int client, int args)
{
	if (client <= 0 || !IsClientInGame(client))
	{
		ReplyToCommand(client, "sm_skills_series_stats is in-game only.");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_skills_series_stats <surv|infect|all> [id]");
		return Plugin_Handled;
	}

	char filterArg[16];
	GetCmdArg(1, filterArg, sizeof(filterArg));

	PlayerSkillsSeriesFilter filter = Series_ParseFilter(filterArg);
	if (filter == view_as<PlayerSkillsSeriesFilter>(-1))
	{
		ReplyToCommand(client, "Usage: sm_skills_series_stats <surv|infect|all> [id]");
		return Plugin_Handled;
	}

	int index = Series_GetDefaultSeriesIndex();
	if (args >= 2)
	{
		char idArg[16];
		GetCmdArg(2, idArg, sizeof(idArg));
		index = Series_FindSeriesIndexById(StringToInt(idArg));
	}

	if (index == -1)
	{
		ReplyToCommand(client, "No skills series is available.");
		return Plugin_Handled;
	}

	Series_PrintAggregatedStats(client, index, filter);
	return Plugin_Handled;
}

void Series_ConsumeSummary(int summaryId, bool skillSummary)
{
	if (summaryId <= 0)
	{
		return;
	}

	Handle kv = CreateKeyValues("player_skills_series_summary");
	bool valid = skillSummary
		? PlayerSkills_IsSkillSummaryValid(summaryId) && PlayerSkills_FillSkillSummaryKeyValues(summaryId, kv)
		: PlayerSkills_IsKillSummaryValid(summaryId) && PlayerSkills_FillKillSummaryKeyValues(summaryId, kv);
	if (!valid)
	{
		delete kv;
		return;
	}

	char root[32];
	strcopy(root, sizeof(root), skillSummary ? "skill_summary" : "kill_summary");

	KvRewind(kv);
	if (!KvJumpToKey(kv, root, false))
	{
		delete kv;
		return;
	}

	int baseMode = KvGetNum(kv, "base_mode", GAMEMODE_UNKNOWN);
	int totalEvents = KvGetNum(kv, "total_events", 0);
	int createdAt = RoundToFloor(KvGetFloat(kv, "created_at", 0.0));

	char currentMap[64];
	char missionKey[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	Series_BuildMissionKeyFromMap(currentMap, missionKey, sizeof(missionKey));

	PlayerSkillsSeriesScope scope = Series_DetermineScope(baseMode);
	if (scope == PlayerSkillsSeriesScope_None)
	{
		delete kv;
		return;
	}

	if (g_iActiveSeriesIndex == -1 || Series_ShouldStartNewSeries(g_iActiveSeriesIndex, baseMode, scope, currentMap, missionKey))
	{
		Series_CloseActiveSeries();
		g_iActiveSeriesIndex = Series_AllocateSeriesSlot();
		if (g_iActiveSeriesIndex == -1)
		{
			delete kv;
			return;
		}

		Series_Open(g_iActiveSeriesIndex, baseMode, scope, currentMap, missionKey);
	}

	int entryIndex = Series_FindOrCreateEntry(g_iActiveSeriesIndex, baseMode, createdAt, currentMap, missionKey, skillSummary);
	if (entryIndex == -1)
	{
		delete kv;
		return;
	}

	if (skillSummary)
	{
		g_Series[g_iActiveSeriesIndex].entries[entryIndex].skillSummaryId = summaryId;
		g_Series[g_iActiveSeriesIndex].entries[entryIndex].skillTotalEvents = totalEvents;
		g_Series[g_iActiveSeriesIndex].totalSkillEvents += totalEvents;
	}
	else
	{
		g_Series[g_iActiveSeriesIndex].entries[entryIndex].killSummaryId = summaryId;
		g_Series[g_iActiveSeriesIndex].entries[entryIndex].killTotalEvents = totalEvents;
		g_Series[g_iActiveSeriesIndex].totalKillEvents += totalEvents;
	}

	Series_ConsumeSummaryEntries(kv, root, g_iActiveSeriesIndex, entryIndex, skillSummary);
	delete kv;
}

void Series_ConsumeSummaryEntries(Handle kv, const char[] root, int seriesIndex, int entryIndex, bool skillSummary)
{
	KvRewind(kv);
	if (!KvJumpToKey(kv, root, false)
		|| !KvJumpToKey(kv, "entries", false)
		|| !KvGotoFirstSubKey(kv, false))
	{
		return;
	}

	do
	{
		PlayerSkillsSeriesPlayerData playerData;
		playerData.Reset();
		playerData.active = true;
		playerData.team = KvGetNum(kv, "team", 0);
		playerData.accountId = KvGetNum(kv, "accountid", 0);
		playerData.bot = KvGetNum(kv, "bot", 0) > 0;
		KvGetString(kv, "name", playerData.name, sizeof(playerData.name));

		int playerIndex = Series_FindOrCreateEntryPlayerIndex(seriesIndex, entryIndex, playerData);
		if (playerIndex == -1)
		{
			continue;
		}

		if (!KvJumpToKey(kv, "counts", false))
		{
			continue;
		}

		if (KvGotoFirstSubKey(kv, false))
		{
			KvGoBack(kv);
			continue;
		}

		do
		{
			char countKey[48];
			KvGetSectionName(kv, countKey, sizeof(countKey));
			int countValue = KvGetNum(kv, NULL_STRING, 0);

			if (skillSummary)
			{
				int skillType = Series_FindSkillTypeByName(countKey);
				if (skillType > 0)
				{
					g_Series[seriesIndex].entries[entryIndex].players[playerIndex].skillCounts[skillType] += countValue;
				}
			}
			else
			{
				int killType = Series_FindKillTypeByName(countKey);
				if (killType > 0)
				{
					g_Series[seriesIndex].entries[entryIndex].players[playerIndex].killCounts[killType] += countValue;
				}
			}
		}
		while (KvGotoNextKey(kv, false));

		KvGoBack(kv);
	}
	while (KvGotoNextKey(kv, false));
}

int Series_FindOrCreateEntryPlayerIndex(int seriesIndex, int entryIndex, PlayerSkillsSeriesPlayerData playerData)
{
	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; i++)
	{
		if (!g_Series[seriesIndex].entries[entryIndex].players[i].active)
		{
			continue;
		}

		if (Series_PlayersMatch(g_Series[seriesIndex].entries[entryIndex].players[i], playerData))
		{
			return i;
		}
	}

	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; i++)
	{
		if (g_Series[seriesIndex].entries[entryIndex].players[i].active)
		{
			continue;
		}

		g_Series[seriesIndex].entries[entryIndex].players[i] = playerData;
		return i;
	}

	return -1;
}

bool Series_PlayersMatch(PlayerSkillsSeriesPlayerData left, PlayerSkillsSeriesPlayerData right)
{
	if (!left.active || !right.active || left.team != right.team)
	{
		return false;
	}

	if (left.bot || right.bot)
	{
		return left.bot == right.bot && StrEqual(left.name, right.name, false);
	}

	return left.accountId > 0 && right.accountId > 0 && left.accountId == right.accountId;
}

int Series_FindSkillTypeByName(const char[] name)
{
	char typeName[32];
	for (int type = 1; type < view_as<int>(L4D2ApiSkill_Size); type++)
	{
		PlayerSkills_GetApiSkillTypeName(view_as<L4D2ApiSkillType>(type), typeName, sizeof(typeName));
		if (StrEqual(name, typeName, false))
		{
			return type;
		}
	}

	return 0;
}

int Series_FindKillTypeByName(const char[] name)
{
	char typeName[32];
	for (int type = 1; type < view_as<int>(L4D2ApiKill_Size); type++)
	{
		PlayerSkills_GetApiKillTypeName(view_as<L4D2ApiKillType>(type), typeName, sizeof(typeName));
		if (StrEqual(name, typeName, false))
		{
			return type;
		}
	}

	return 0;
}

PlayerSkillsSeriesScope Series_DetermineScope(int baseMode)
{
	switch (baseMode)
	{
		case GAMEMODE_COOP, GAMEMODE_VERSUS:
		{
			return PlayerSkillsSeriesScope_Mission;
		}

		case GAMEMODE_SCAVENGE, GAMEMODE_SURVIVAL:
		{
			return PlayerSkillsSeriesScope_Map;
		}
	}

	return PlayerSkillsSeriesScope_None;
}

bool Series_ShouldStartNewSeries(int index, int baseMode, PlayerSkillsSeriesScope scope, const char[] map, const char[] missionKey)
{
	if (index < 0 || index >= L4D2_PLAYER_SKILLS_SERIES_MAX_SERIES || !g_Series[index].active)
	{
		return true;
	}

	if (g_Series[index].baseMode != baseMode || g_Series[index].scope != scope)
	{
		return true;
	}

	if (scope == PlayerSkillsSeriesScope_Mission)
	{
		return !StrEqual(g_Series[index].missionKey, missionKey, false);
	}

	return !StrEqual(g_Series[index].map, map, false);
}

void Series_CloseActiveSeries()
{
	if (g_iActiveSeriesIndex == -1)
	{
		return;
	}

	g_Series[g_iActiveSeriesIndex].closed = true;
	g_iActiveSeriesIndex = -1;
}

int Series_AllocateSeriesSlot()
{
	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_SERIES; i++)
	{
		if (g_Series[i].active)
		{
			continue;
		}

		return i;
	}

	int replaceIndex = 0;
	for (int i = 1; i < L4D2_PLAYER_SKILLS_SERIES_MAX_SERIES; i++)
	{
		if (g_Series[i].id < g_Series[replaceIndex].id)
		{
			replaceIndex = i;
		}
	}

	g_Series[replaceIndex].Reset();
	return replaceIndex;
}

void Series_Open(int index, int baseMode, PlayerSkillsSeriesScope scope, const char[] map, const char[] missionKey)
{
	g_Series[index].Reset();
	g_Series[index].active = true;
	g_Series[index].closed = false;
	g_Series[index].id = ++g_iSeriesSerial;
	g_Series[index].baseMode = baseMode;
	g_Series[index].scope = scope;
	strcopy(g_Series[index].map, sizeof(g_Series[index].map), map);
	strcopy(g_Series[index].missionKey, sizeof(g_Series[index].missionKey), missionKey);
}

int Series_FindOrCreateEntry(int seriesIndex, int baseMode, int createdAt, const char[] map, const char[] missionKey, bool skillSummary)
{
	if (seriesIndex < 0 || seriesIndex >= L4D2_PLAYER_SKILLS_SERIES_MAX_SERIES || !g_Series[seriesIndex].active)
	{
		return -1;
	}

	if (g_Series[seriesIndex].entryCount > 0)
	{
		int lastIndex = g_Series[seriesIndex].entryCount - 1;
		if (g_Series[seriesIndex].entries[lastIndex].active
			&& g_Series[seriesIndex].entries[lastIndex].baseMode == baseMode
			&& StrEqual(g_Series[seriesIndex].entries[lastIndex].map, map, false)
			&& StrEqual(g_Series[seriesIndex].entries[lastIndex].missionKey, missionKey, false)
			&& ((skillSummary && g_Series[seriesIndex].entries[lastIndex].skillSummaryId == 0)
				|| (!skillSummary && g_Series[seriesIndex].entries[lastIndex].killSummaryId == 0)))
		{
			return lastIndex;
		}
	}

	if (g_Series[seriesIndex].entryCount >= L4D2_PLAYER_SKILLS_SERIES_MAX_ENTRIES)
	{
		return -1;
	}

	int entryIndex = g_Series[seriesIndex].entryCount++;
	g_Series[seriesIndex].entries[entryIndex].Reset();
	g_Series[seriesIndex].entries[entryIndex].active = true;
	g_Series[seriesIndex].entries[entryIndex].sequence = entryIndex + 1;
	g_Series[seriesIndex].entries[entryIndex].baseMode = baseMode;
	g_Series[seriesIndex].entries[entryIndex].createdAt = createdAt;
	strcopy(g_Series[seriesIndex].entries[entryIndex].map, sizeof(g_Series[seriesIndex].entries[entryIndex].map), map);
	strcopy(g_Series[seriesIndex].entries[entryIndex].missionKey, sizeof(g_Series[seriesIndex].entries[entryIndex].missionKey), missionKey);
	return entryIndex;
}

void Series_BuildMissionKeyFromMap(const char[] map, char[] buffer, int maxlen)
{
	int marker = FindCharInString(map, 'm');
	if (marker <= 0)
	{
		strcopy(buffer, maxlen, map);
		return;
	}

	strcopy(buffer, maxlen, map);
	buffer[marker] = '\0';
}

int Series_FindSeriesIndexById(int seriesId)
{
	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_SERIES; i++)
	{
		if (g_Series[i].active && g_Series[i].id == seriesId)
		{
			return i;
		}
	}

	return -1;
}

int Series_GetDefaultSeriesIndex()
{
	if (g_iActiveSeriesIndex != -1 && g_Series[g_iActiveSeriesIndex].active)
	{
		return g_iActiveSeriesIndex;
	}

	int latestIndex = -1;
	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_SERIES; i++)
	{
		if (!g_Series[i].active)
		{
			continue;
		}

		if (latestIndex == -1 || g_Series[i].id > g_Series[latestIndex].id)
		{
			latestIndex = i;
		}
	}

	return latestIndex;
}

PlayerSkillsSeriesFilter Series_ParseFilter(const char[] value)
{
	if (StrEqual(value, "surv", false) || StrEqual(value, "survivor", false))
	{
		return PlayerSkillsSeriesFilter_Survivor;
	}

	if (StrEqual(value, "infect", false) || StrEqual(value, "infected", false))
	{
		return PlayerSkillsSeriesFilter_Infected;
	}

	if (StrEqual(value, "all", false))
	{
		return PlayerSkillsSeriesFilter_All;
	}

	return view_as<PlayerSkillsSeriesFilter>(-1);
}

void Series_PrintBuffer(int client)
{
	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 110);
	ConsolePanel_EnableSafeAscii(panel, false);

	ConsolePanel_AddHeaderLine(panel, "PlayerSkills Series Buffer");
	ConsolePanel_AddHeaderLine(panel, "Short-lived mission/map grouping for finalized skill and kill summaries");

	ConsoleTable_AddColumn(panel.table, "Id", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "State", 8, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Mode", 9, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Scope", 8, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Entries", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Skills", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Kills", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Map", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Mission", 10, ConsoleTableAlignment_Left, ConsoleTableCellType_String);

	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_SERIES; i++)
	{
		if (!g_Series[i].active || !ConsoleTable_BeginRow(panel.table))
		{
			continue;
		}

		char state[8];
		char mode[16];
		char scope[16];
		strcopy(state, sizeof(state), g_Series[i].closed ? "Closed" : "Active");
		Series_GetModeLabel(g_Series[i].baseMode, mode, sizeof(mode));
		Series_GetScopeLabel(g_Series[i].scope, scope, sizeof(scope));

		ConsoleTable_AddIntCell(panel.table, g_Series[i].id);
		ConsoleTable_AddStringCell(panel.table, state);
		ConsoleTable_AddStringCell(panel.table, mode);
		ConsoleTable_AddStringCell(panel.table, scope);
		ConsoleTable_AddIntCell(panel.table, g_Series[i].entryCount);
		ConsoleTable_AddIntCell(panel.table, g_Series[i].totalSkillEvents);
		ConsoleTable_AddIntCell(panel.table, g_Series[i].totalKillEvents);
		ConsoleTable_AddStringCell(panel.table, g_Series[i].map);
		ConsoleTable_AddStringCell(panel.table, g_Series[i].missionKey);
		ConsoleTable_EndRow(panel.table);
	}

	ConsolePanel_RenderToClient(panel, client);
}

void Series_PrintEntries(int client, int index)
{
	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 110);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[160];
	char mode[16];
	char scope[16];
	Series_GetModeLabel(g_Series[index].baseMode, mode, sizeof(mode));
	Series_GetScopeLabel(g_Series[index].scope, scope, sizeof(scope));

	Format(line, sizeof(line), "PlayerSkills Series %d", g_Series[index].id);
	ConsolePanel_AddHeaderLine(panel, line);
	Format(line, sizeof(line), "State=%s  Mode=%s  Scope=%s  Entries=%d", g_Series[index].closed ? "Closed" : "Active", mode, scope, g_Series[index].entryCount);
	ConsolePanel_AddHeaderLine(panel, line);

	ConsoleTable_AddColumn(panel.table, "Idx", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Time", 10, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Skills", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Kills", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Map", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Mission", 10, ConsoleTableAlignment_Left, ConsoleTableCellType_String);

	for (int i = 0; i < g_Series[index].entryCount; i++)
	{
		if (!g_Series[index].entries[i].active || !ConsoleTable_BeginRow(panel.table))
		{
			continue;
		}

		ConsoleTable_AddIntCell(panel.table, g_Series[index].entries[i].sequence);
		ConsoleTable_AddIntCell(panel.table, g_Series[index].entries[i].createdAt);
		ConsoleTable_AddIntCell(panel.table, g_Series[index].entries[i].skillTotalEvents);
		ConsoleTable_AddIntCell(panel.table, g_Series[index].entries[i].killTotalEvents);
		ConsoleTable_AddStringCell(panel.table, g_Series[index].entries[i].map);
		ConsoleTable_AddStringCell(panel.table, g_Series[index].entries[i].missionKey);
		ConsoleTable_EndRow(panel.table);
	}

	ConsolePanel_RenderToClient(panel, client);
}

void Series_PrintAggregatedStats(int client, int index, PlayerSkillsSeriesFilter filter)
{
	if (filter == PlayerSkillsSeriesFilter_All || filter == PlayerSkillsSeriesFilter_Survivor)
	{
		Series_PrintAggregatedTeamStats(client, index, view_as<int>(L4DTeam_Survivor));
	}

	if (filter == PlayerSkillsSeriesFilter_All || filter == PlayerSkillsSeriesFilter_Infected)
	{
		Series_PrintAggregatedTeamStats(client, index, view_as<int>(L4DTeam_Infected));
	}
}

void Series_PrintAggregatedTeamStats(int client, int index, int team)
{
	PlayerSkillsSeriesAggregatePlayerData players[L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS];
	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; i++)
	{
		players[i].Reset();
	}

	Series_BuildAggregatePlayers(index, team, players);
	Series_SortAggregatePlayers(players);
	Series_PrintAggregateTable(client, index, team, players, true);
	Series_PrintAggregateTable(client, index, team, players, false);
}

void Series_BuildAggregatePlayers(int index, int team, PlayerSkillsSeriesAggregatePlayerData[] players)
{
	for (int entryIndex = 0; entryIndex < g_Series[index].entryCount; entryIndex++)
	{
		if (!g_Series[index].entries[entryIndex].active)
		{
			continue;
		}

		for (int playerIndex = 0; playerIndex < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; playerIndex++)
		{
			if (!g_Series[index].entries[entryIndex].players[playerIndex].active
				|| g_Series[index].entries[entryIndex].players[playerIndex].team != team)
			{
				continue;
			}

			int aggregateIndex = Series_FindAggregatePlayerIndex(players, g_Series[index].entries[entryIndex].players[playerIndex]);
			if (aggregateIndex == -1)
			{
				aggregateIndex = Series_AllocateAggregatePlayerIndex(players);
				if (aggregateIndex == -1)
				{
					continue;
				}

				players[aggregateIndex].active = true;
				players[aggregateIndex].team = g_Series[index].entries[entryIndex].players[playerIndex].team;
				players[aggregateIndex].accountId = g_Series[index].entries[entryIndex].players[playerIndex].accountId;
				players[aggregateIndex].bot = g_Series[index].entries[entryIndex].players[playerIndex].bot;
				strcopy(players[aggregateIndex].name, sizeof(players[aggregateIndex].name), g_Series[index].entries[entryIndex].players[playerIndex].name);
			}

			players[aggregateIndex].entries++;

			for (int skillType = 1; skillType < view_as<int>(L4D2ApiSkill_Size); skillType++)
			{
				players[aggregateIndex].skillCounts[skillType] += g_Series[index].entries[entryIndex].players[playerIndex].skillCounts[skillType];
			}

			for (int killType = 1; killType < view_as<int>(L4D2ApiKill_Size); killType++)
			{
				players[aggregateIndex].killCounts[killType] += g_Series[index].entries[entryIndex].players[playerIndex].killCounts[killType];
			}
		}
	}
}

int Series_FindAggregatePlayerIndex(PlayerSkillsSeriesAggregatePlayerData[] players, PlayerSkillsSeriesPlayerData playerData)
{
	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; i++)
	{
		if (!players[i].active || players[i].team != playerData.team)
		{
			continue;
		}

		if (playerData.bot)
		{
			if (players[i].bot && StrEqual(players[i].name, playerData.name, false))
			{
				return i;
			}
			continue;
		}

		if (!players[i].bot && players[i].accountId > 0 && players[i].accountId == playerData.accountId)
		{
			return i;
		}
	}

	return -1;
}

int Series_AllocateAggregatePlayerIndex(PlayerSkillsSeriesAggregatePlayerData[] players)
{
	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; i++)
	{
		if (!players[i].active)
		{
			return i;
		}
	}

	return -1;
}

void Series_SortAggregatePlayers(PlayerSkillsSeriesAggregatePlayerData[] players)
{
	for (int i = 0; i < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS - 1; i++)
	{
		int bestIndex = i;

		for (int j = i + 1; j < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; j++)
		{
			if (Series_ShouldAggregatePlayerSortBefore(players[j], players[bestIndex]))
			{
				bestIndex = j;
			}
		}

		if (bestIndex == i)
		{
			continue;
		}

		Series_SwapAggregatePlayers(players, i, bestIndex);
	}
}

bool Series_ShouldAggregatePlayerSortBefore(PlayerSkillsSeriesAggregatePlayerData left, PlayerSkillsSeriesAggregatePlayerData right)
{
	if (left.active != right.active)
	{
		return left.active && !right.active;
	}

	if (!left.active)
	{
		return false;
	}

	if (left.bot != right.bot)
	{
		return !left.bot && right.bot;
	}

	int leftTotal = Series_CountAggregatePlayerTotal(left, true) + Series_CountAggregatePlayerTotal(left, false);
	int rightTotal = Series_CountAggregatePlayerTotal(right, true) + Series_CountAggregatePlayerTotal(right, false);
	if (leftTotal != rightTotal)
	{
		return leftTotal > rightTotal;
	}

	if (left.entries != right.entries)
	{
		return left.entries > right.entries;
	}

	return strcmp(left.name, right.name, false) < 0;
}

int Series_CountAggregatePlayerTotal(PlayerSkillsSeriesAggregatePlayerData player, bool skillCounts)
{
	int total = 0;

	if (skillCounts)
	{
		for (int i = 1; i < view_as<int>(L4D2ApiSkill_Size); i++)
		{
			total += player.skillCounts[i];
		}
		return total;
	}

	for (int i = 1; i < view_as<int>(L4D2ApiKill_Size); i++)
	{
		total += player.killCounts[i];
	}
	return total;
}

void Series_SwapAggregatePlayers(PlayerSkillsSeriesAggregatePlayerData[] players, int leftIndex, int rightIndex)
{
	bool tempActive = players[leftIndex].active;
	int tempTeam = players[leftIndex].team;
	int tempAccountId = players[leftIndex].accountId;
	bool tempBot = players[leftIndex].bot;
	char tempName[MAX_NAME_LENGTH];
	strcopy(tempName, sizeof(tempName), players[leftIndex].name);
	int tempEntries = players[leftIndex].entries;
	int tempSkillCounts[L4D2ApiSkill_Size];
	int tempKillCounts[L4D2ApiKill_Size];

	for (int i = 0; i < view_as<int>(L4D2ApiSkill_Size); i++)
	{
		tempSkillCounts[i] = players[leftIndex].skillCounts[i];
	}

	for (int i = 0; i < view_as<int>(L4D2ApiKill_Size); i++)
	{
		tempKillCounts[i] = players[leftIndex].killCounts[i];
	}

	players[leftIndex].active = players[rightIndex].active;
	players[leftIndex].team = players[rightIndex].team;
	players[leftIndex].accountId = players[rightIndex].accountId;
	players[leftIndex].bot = players[rightIndex].bot;
	strcopy(players[leftIndex].name, sizeof(players[leftIndex].name), players[rightIndex].name);
	players[leftIndex].entries = players[rightIndex].entries;

	for (int i = 0; i < view_as<int>(L4D2ApiSkill_Size); i++)
	{
		players[leftIndex].skillCounts[i] = players[rightIndex].skillCounts[i];
	}

	for (int i = 0; i < view_as<int>(L4D2ApiKill_Size); i++)
	{
		players[leftIndex].killCounts[i] = players[rightIndex].killCounts[i];
	}

	players[rightIndex].active = tempActive;
	players[rightIndex].team = tempTeam;
	players[rightIndex].accountId = tempAccountId;
	players[rightIndex].bot = tempBot;
	strcopy(players[rightIndex].name, sizeof(players[rightIndex].name), tempName);
	players[rightIndex].entries = tempEntries;

	for (int i = 0; i < view_as<int>(L4D2ApiSkill_Size); i++)
	{
		players[rightIndex].skillCounts[i] = tempSkillCounts[i];
	}

	for (int i = 0; i < view_as<int>(L4D2ApiKill_Size); i++)
	{
		players[rightIndex].killCounts[i] = tempKillCounts[i];
	}
}

void Series_PrintAggregateTable(int client, int index, int team, PlayerSkillsSeriesAggregatePlayerData[] players, bool skillCounts)
{
	bool anyRows = false;
	for (int type = 1; type < (skillCounts ? view_as<int>(L4D2ApiSkill_Size) : view_as<int>(L4D2ApiKill_Size)); type++)
	{
		for (int playerIndex = 0; playerIndex < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; playerIndex++)
		{
			if (!players[playerIndex].active)
			{
				continue;
			}

			int value = skillCounts ? players[playerIndex].skillCounts[type] : players[playerIndex].killCounts[type];
			if (value > 0)
			{
				anyRows = true;
				break;
			}
		}

		if (anyRows)
		{
			break;
		}
	}

	if (!anyRows)
	{
		return;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 120);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[160];
	char teamLabel[16];
	Series_GetTeamLabel(team, teamLabel, sizeof(teamLabel));
	Format(line, sizeof(line), "%s -- %s -- Series %d", skillCounts ? "Skills" : "Kills", teamLabel, g_Series[index].id);
	ConsolePanel_AddHeaderLine(panel, line);
	Format(line, sizeof(line), "Mode-aware aggregate across %d entries", g_Series[index].entryCount);
	ConsolePanel_AddHeaderLine(panel, line);

	ConsoleTable_AddColumn(panel.table, "Metrica", 22, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	for (int playerIndex = 0; playerIndex < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; playerIndex++)
	{
		if (!players[playerIndex].active || players[playerIndex].bot)
		{
			continue;
		}

		ConsoleTable_AddColumn(panel.table, players[playerIndex].name, 12, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}

	bool hasAiColumn = false;
	for (int playerIndex = 0; playerIndex < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; playerIndex++)
	{
		if (players[playerIndex].active && players[playerIndex].bot)
		{
			hasAiColumn = true;
			break;
		}
	}

	if (hasAiColumn)
	{
		ConsoleTable_AddColumn(panel.table, "IA", 12, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}

	for (int type = 1; type < (skillCounts ? view_as<int>(L4D2ApiSkill_Size) : view_as<int>(L4D2ApiKill_Size)); type++)
	{
		bool visible = false;
		for (int playerIndex = 0; playerIndex < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; playerIndex++)
		{
			if (!players[playerIndex].active)
			{
				continue;
			}

			int value = skillCounts ? players[playerIndex].skillCounts[type] : players[playerIndex].killCounts[type];
			if (value > 0)
			{
				visible = true;
				break;
			}
		}

		if (!visible || !ConsoleTable_BeginRow(panel.table))
		{
			continue;
		}

		char metricName[48];
		if (skillCounts)
		{
			PlayerSkills_GetApiSkillTypeName(view_as<L4D2ApiSkillType>(type), metricName, sizeof(metricName));
		}
		else
		{
			PlayerSkills_GetApiKillTypeName(view_as<L4D2ApiKillType>(type), metricName, sizeof(metricName));
		}

		ConsoleTable_AddStringCell(panel.table, metricName);
		for (int playerIndex = 0; playerIndex < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; playerIndex++)
		{
			if (!players[playerIndex].active || players[playerIndex].bot)
			{
				continue;
			}

			ConsoleTable_AddIntCell(panel.table, skillCounts ? players[playerIndex].skillCounts[type] : players[playerIndex].killCounts[type]);
		}

		if (hasAiColumn)
		{
			int aiValue = 0;
			for (int playerIndex = 0; playerIndex < L4D2_PLAYER_SKILLS_SERIES_MAX_PLAYERS; playerIndex++)
			{
				if (!players[playerIndex].active || !players[playerIndex].bot)
				{
					continue;
				}

				aiValue += skillCounts ? players[playerIndex].skillCounts[type] : players[playerIndex].killCounts[type];
			}

			ConsoleTable_AddIntCell(panel.table, aiValue);
		}

		ConsoleTable_EndRow(panel.table);
	}

	ConsolePanel_RenderToClient(panel, client);
}

void Series_GetModeLabel(int baseMode, char[] buffer, int maxlen)
{
	switch (baseMode)
	{
		case GAMEMODE_COOP: strcopy(buffer, maxlen, "Coop");
		case GAMEMODE_VERSUS: strcopy(buffer, maxlen, "Versus");
		case GAMEMODE_SCAVENGE: strcopy(buffer, maxlen, "Scavenge");
		case GAMEMODE_SURVIVAL: strcopy(buffer, maxlen, "Survival");
		default: strcopy(buffer, maxlen, "Unknown");
	}
}

void Series_GetScopeLabel(PlayerSkillsSeriesScope scope, char[] buffer, int maxlen)
{
	switch (scope)
	{
		case PlayerSkillsSeriesScope_Mission: strcopy(buffer, maxlen, "Mission");
		case PlayerSkillsSeriesScope_Map: strcopy(buffer, maxlen, "Map");
		default: strcopy(buffer, maxlen, "None");
	}
}

void Series_GetTeamLabel(int team, char[] buffer, int maxlen)
{
	switch (team)
	{
		case view_as<int>(L4DTeam_Survivor): strcopy(buffer, maxlen, "Survivors");
		case view_as<int>(L4DTeam_Infected): strcopy(buffer, maxlen, "Infected");
		default: strcopy(buffer, maxlen, "Unknown");
	}
}
