#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <l4d2_player_skills>
#define REQUIRE_PLUGIN

#define SKILLS_LOGDIR "logs/l4d2_player_skills"
#define SKILLS_LOG_PREFIX "[Player Skills API]"
#define SKILLS_SUBDIR_SKILL_EVENT "skills/event_detected"
#define SKILLS_SUBDIR_KILL_EVENT "kills/event_detected"
#define SKILLS_SUBDIR_BOSS_EVENT "boss/event_detected"
#define SKILLS_SUBDIR_BOSS_SESSION "boss/session_finalized"
#define SKILLS_SUBDIR_TANK_SESSION "boss/tank_session_closed"
#define SKILLS_SUBDIR_SKILL_SUMMARY "summary/skills"
#define SKILLS_SUBDIR_KILL_SUMMARY "summary/kills"
#define SKILLS_ROOT_TANK_SESSION "tank_session_closed"
#define SKILLS_ROOT_DATA "data"
#define SKILLS_FAMILY_TANK_SESSION "tank_session_closed"
#define SKILLS_FAMILY_SKILL_SUMMARY "skill_summary"
#define SKILLS_FAMILY_KILL_SUMMARY "kill_summary"
#define SKILLS_FAMILY_SKILL_EVENT "skill_event"
#define SKILLS_FAMILY_KILL_EVENT "kill_event"
#define SKILLS_FAMILY_BOSS_EVENT "boss_event"
#define SKILLS_FAMILY_BOSS_SESSION "boss_session"
#define SKILLS_LABEL_TANK "Tank"
#define SKILLS_LABEL_UNKNOWN_SKILL "UnknownSkill"
#define SKILLS_LABEL_UNKNOWN_KILL "UnknownKill"
#define SKILLS_LABEL_UNKNOWN_BOSS_EVENT "UnknownBossEvent"
#define SKILLS_LABEL_UNKNOWN_BOSS "UnknownBoss"
#define SKILLS_REASON_TANK_DEAD "TankDead"
#define SKILLS_REASON_SURVIVORS_ESCAPED "SurvivorsEscaped"
#define SKILLS_REASON_SURVIVORS_WIPED "SurvivorsWiped"
#define SKILLS_REASON_NONE "None"

ConVar g_cvDebug;

enum struct PlayerSkillsRuntimeState
{
	bool hasL4D2PlayerSkills;
	bool isLate;

	void Reset()
	{
		this.hasL4D2PlayerSkills = false;
		this.isLate = false;
	}
}

PlayerSkillsRuntimeState g_Runtime;

void Runtime_SetHasL4D2PlayerSkills(bool value, const char[] reason)
{
	if (g_Runtime.hasL4D2PlayerSkills == value)
	{
		return;
	}

	g_Runtime.hasL4D2PlayerSkills = value;
	LogMessage("%s hasL4D2PlayerSkills=%d reason=%s", SKILLS_LOG_PREFIX, value ? 1 : 0, reason);
}

public Plugin myinfo =
{
	name = "L4D2 Player Skills API",
	author = "lechuga",
	description = "Consumes the current l4d2_player_skills public API and dumps KeyValues payloads to logs.",
	version = "1.0.0",
	url = "https://github.com/AoC-Gamers/L4D2-Player-Skills"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_Runtime.isLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvDebug = CreateConVar("sm_skills_api_debug", "0", "Enable debug logging for the l4d2_player_skills API probe.", FCVAR_NONE, true, 0.0, true, 1.0);


	if (g_Runtime.isLate)
	{
		Runtime_SetHasL4D2PlayerSkills(LibraryExists(LIBRARY_L4D2_PLAYER_SKILLS), "late_start");
	}

	EnsureLogDirectory();
}

public void OnAllPluginsLoaded()
{
	Runtime_SetHasL4D2PlayerSkills(LibraryExists(LIBRARY_L4D2_PLAYER_SKILLS), "all_plugins_loaded");
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, LIBRARY_L4D2_PLAYER_SKILLS) != 0)
	{
		return;
	}

	Runtime_SetHasL4D2PlayerSkills(true, "library_added");
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, LIBRARY_L4D2_PLAYER_SKILLS) != 0)
	{
		return;
	}

	Runtime_SetHasL4D2PlayerSkills(false, "library_removed");
}

public Action PlayerSkills_OnSkillDetected(int eventId, L4D2ApiSkillType type)
{
	DumpSkillEvent(SKILLS_SUBDIR_SKILL_EVENT, eventId, type);
	return Plugin_Continue;
}

public Action PlayerSkills_OnKillDetected(int eventId, L4D2ApiKillType type)
{
	DumpKillEvent(SKILLS_SUBDIR_KILL_EVENT, eventId, type);
	return Plugin_Continue;
}

public Action PlayerSkills_OnBossEventDetected(int eventId, L4D2ApiBossEventType type)
{
	DumpBossEvent(SKILLS_SUBDIR_BOSS_EVENT, eventId, type);
	return Plugin_Continue;
}

public Action PlayerSkills_OnBossSessionFinalized(int sessionId, L4D2BossType type)
{
	DumpBossSession(SKILLS_SUBDIR_BOSS_SESSION, sessionId, type);
	return Plugin_Continue;
}

public void PlayerSkills_OnTankSessionClosed(int sessionId, L4D2TankSessionEndReason reason)
{
	char reasonName[32];
	GetTankReasonName(reason, reasonName, sizeof(reasonName));

	KeyValues kv = new KeyValues(SKILLS_ROOT_TANK_SESSION);
	WriteCommonMetadata(kv, SKILLS_FAMILY_TANK_SESSION);
	kv.SetNum("session_id", sessionId);
	kv.SetNum("reason", reason);
	kv.SetString("reason_name", reasonName);
	PlayerSkills_FillBossSessionKeyValues(sessionId, kv);

	char filePath[PLATFORM_MAX_PATH];
	BuildLogPath(SKILLS_SUBDIR_TANK_SESSION, SKILLS_LABEL_TANK, filePath, sizeof(filePath));
	ExportKvToFile(kv, filePath, SKILLS_FAMILY_TANK_SESSION);
	delete kv;
}

public void PlayerSkills_OnSkillSummaryFinalized(int summaryId)
{
	if (!PlayerSkills_IsSkillSummaryValid(summaryId))
	{
		return;
	}

	KeyValues kv = new KeyValues(SKILLS_ROOT_DATA);
	if (!PlayerSkills_FillSkillSummaryKeyValues(summaryId, kv))
	{
		delete kv;
		return;
	}
	WriteCommonMetadata(kv, SKILLS_FAMILY_SKILL_SUMMARY);

	char filePath[PLATFORM_MAX_PATH];
	BuildLogPath(SKILLS_SUBDIR_SKILL_SUMMARY, SKILLS_FAMILY_SKILL_SUMMARY, filePath, sizeof(filePath));
	ExportKvToFile(kv, filePath, SKILLS_FAMILY_SKILL_SUMMARY);
	delete kv;
}

public void PlayerSkills_OnKillSummaryFinalized(int summaryId)
{
	if (!PlayerSkills_IsKillSummaryValid(summaryId))
	{
		return;
	}

	KeyValues kv = new KeyValues(SKILLS_ROOT_DATA);
	if (!PlayerSkills_FillKillSummaryKeyValues(summaryId, kv))
	{
		delete kv;
		return;
	}
	WriteCommonMetadata(kv, SKILLS_FAMILY_KILL_SUMMARY);

	char filePath[PLATFORM_MAX_PATH];
	BuildLogPath(SKILLS_SUBDIR_KILL_SUMMARY, SKILLS_FAMILY_KILL_SUMMARY, filePath, sizeof(filePath));
	ExportKvToFile(kv, filePath, SKILLS_FAMILY_KILL_SUMMARY);
	delete kv;
}

void DumpSkillEvent(const char[] subdir, int eventId, L4D2ApiSkillType type)
{
	if (!PlayerSkills_IsSkillEventValid(eventId))
	{
		return;
	}

	KeyValues kv = new KeyValues(SKILLS_ROOT_DATA);
	if (!PlayerSkills_FillSkillEventKeyValues(eventId, kv))
	{
		delete kv;
		return;
	}
	WriteCommonMetadata(kv, SKILLS_FAMILY_SKILL_EVENT);

	char typeName[32];
	if (!PlayerSkills_GetApiSkillTypeName(type, typeName, sizeof(typeName)))
	{
		strcopy(typeName, sizeof(typeName), SKILLS_LABEL_UNKNOWN_SKILL);
	}

	char filePath[PLATFORM_MAX_PATH];
	BuildLogPath(subdir, typeName, filePath, sizeof(filePath));
	ExportKvToFile(kv, filePath, typeName);
	delete kv;
}

void DumpKillEvent(const char[] subdir, int eventId, L4D2ApiKillType type)
{
	if (!PlayerSkills_IsKillEventValid(eventId))
	{
		return;
	}

	KeyValues kv = new KeyValues(SKILLS_ROOT_DATA);
	if (!PlayerSkills_FillKillEventKeyValues(eventId, kv))
	{
		delete kv;
		return;
	}
	WriteCommonMetadata(kv, SKILLS_FAMILY_KILL_EVENT);

	char typeName[32];
	if (!PlayerSkills_GetApiKillTypeName(type, typeName, sizeof(typeName)))
	{
		strcopy(typeName, sizeof(typeName), SKILLS_LABEL_UNKNOWN_KILL);
	}

	char filePath[PLATFORM_MAX_PATH];
	BuildLogPath(subdir, typeName, filePath, sizeof(filePath));
	ExportKvToFile(kv, filePath, typeName);
	delete kv;
}

void DumpBossEvent(const char[] subdir, int eventId, L4D2ApiBossEventType type)
{
	if (!PlayerSkills_IsBossEventValid(eventId))
	{
		return;
	}

	KeyValues kv = new KeyValues(SKILLS_ROOT_DATA);
	if (!PlayerSkills_FillBossEventKeyValues(eventId, kv))
	{
		delete kv;
		return;
	}
	WriteCommonMetadata(kv, SKILLS_FAMILY_BOSS_EVENT);

	char typeName[32];
	if (!PlayerSkills_GetApiBossEventTypeName(type, typeName, sizeof(typeName)))
	{
		strcopy(typeName, sizeof(typeName), SKILLS_LABEL_UNKNOWN_BOSS_EVENT);
	}

	char filePath[PLATFORM_MAX_PATH];
	BuildLogPath(subdir, typeName, filePath, sizeof(filePath));
	ExportKvToFile(kv, filePath, typeName);
	delete kv;
}

void DumpBossSession(const char[] subdir, int sessionId, L4D2BossType type)
{
	if (!PlayerSkills_IsBossSessionValid(sessionId))
	{
		return;
	}

	KeyValues kv = new KeyValues(SKILLS_ROOT_DATA);
	if (!PlayerSkills_FillBossSessionKeyValues(sessionId, kv))
	{
		delete kv;
		return;
	}
	WriteCommonMetadata(kv, SKILLS_FAMILY_BOSS_SESSION);

	char typeName[16];
	if (!PlayerSkills_GetBossTypeName(type, typeName, sizeof(typeName)))
	{
		strcopy(typeName, sizeof(typeName), SKILLS_LABEL_UNKNOWN_BOSS);
	}

	char filePath[PLATFORM_MAX_PATH];
	BuildLogPath(subdir, typeName, filePath, sizeof(filePath));
	ExportKvToFile(kv, filePath, typeName);
	delete kv;
}

void Debug(const char[] fmt, any ...)
{
	if (g_cvDebug == null || !g_cvDebug.BoolValue)
	{
		return;
	}

	char buffer[512];
	VFormat(buffer, sizeof(buffer), fmt, 2);
	LogMessage("%s %s", SKILLS_LOG_PREFIX, buffer);
}

void EnsureLogDirectory()
{
	char basePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, basePath, sizeof(basePath), SKILLS_LOGDIR);
	if (!DirExists(basePath))
	{
		bool created = CreateDirectory(basePath, 511);
		Debug("EnsureLogDirectory path=%s created=%d exists_after=%d", basePath, created, DirExists(basePath));
	}
	else
	{
		Debug("EnsureLogDirectory path=%s already_exists=1", basePath);
	}
}

void EnsureDirectoryRecursive(const char[] fullPath)
{
	char normalized[PLATFORM_MAX_PATH];
	strcopy(normalized, sizeof(normalized), fullPath);
	ReplaceString(normalized, sizeof(normalized), "/", "\\");

	int length = strlen(normalized);
	for (int i = 0; i < length; i++)
	{
		if (normalized[i] != '\\')
		{
			continue;
		}

		if (i < 3)
		{
			continue;
		}

		char partial[PLATFORM_MAX_PATH];
		strcopy(partial, i + 1, normalized);
		if (!DirExists(partial))
		{
			bool created = CreateDirectory(partial, 511);
			Debug("EnsureDirectoryRecursive path=%s created=%d exists_after=%d", partial, created, DirExists(partial));
		}
	}

	if (!DirExists(normalized))
	{
		bool created = CreateDirectory(normalized, 511);
		Debug("EnsureDirectoryRecursive final_path=%s created=%d exists_after=%d", normalized, created, DirExists(normalized));
	}
}

void EnsureSubDirectory(const char[] subdir, char[] fullPath, int maxlen)
{
	BuildPath(Path_SM, fullPath, maxlen, "%s/%s", SKILLS_LOGDIR, subdir);
	if (!DirExists(fullPath))
	{
		EnsureDirectoryRecursive(fullPath);
	}
	Debug("EnsureSubDirectory subdir=%s path=%s exists=%d", subdir, fullPath, DirExists(fullPath));
}

void BuildLogPath(const char[] subdir, const char[] typeName, char[] path, int maxlen)
{
	char dirPath[PLATFORM_MAX_PATH];
	char mapName[64];
	char timestamp[32];
	int tick = GetGameTickCount();

	EnsureSubDirectory(subdir, dirPath, sizeof(dirPath));
	FormatTime(timestamp, sizeof(timestamp), "%Y%m%d_%H%M%S", GetTime());
	GetCurrentMap(mapName, sizeof(mapName));

	BuildPath(Path_SM, path, maxlen, "%s/%s/%s_%s_%s_%d.cfg",
		SKILLS_LOGDIR,
		subdir,
		typeName,
		timestamp,
		mapName,
		tick);
	Debug("BuildLogPath subdir=%s type=%s path=%s", subdir, typeName, path);
}

void WriteCommonMetadata(KeyValues kv, const char[] family)
{
	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));

	kv.SetString("family", family);
	kv.SetString("map", mapName);
	kv.SetNum("tick_id", GetGameTickCount());
}

void ExportKvToFile(KeyValues kv, const char[] filePath, const char[] label)
{
	char directoryPath[PLATFORM_MAX_PATH];
	strcopy(directoryPath, sizeof(directoryPath), filePath);
	int separator = FindCharInString(directoryPath, '\\', true);
	if (separator == -1)
	{
		separator = FindCharInString(directoryPath, '/', true);
	}
	if (separator != -1)
	{
		directoryPath[separator] = '\0';
		if (!DirExists(directoryPath))
		{
			EnsureDirectoryRecursive(directoryPath);
		}
	}

	bool ok = kv.ExportToFile(filePath);
	Debug("ExportKvToFile label=%s path=%s ok=%d", label, filePath, ok);
	if (!ok)
	{
		LogMessage("%s Export failed label=%s path=%s", SKILLS_LOG_PREFIX, label, filePath);
	}
}

void GetTankReasonName(L4D2TankSessionEndReason reason, char[] buffer, int maxlen)
{
	switch (reason)
	{
		case L4D2TankSessionEnd_TankDead: strcopy(buffer, maxlen, SKILLS_REASON_TANK_DEAD);
		case L4D2TankSessionEnd_SurvivorsEscaped: strcopy(buffer, maxlen, SKILLS_REASON_SURVIVORS_ESCAPED);
		case L4D2TankSessionEnd_SurvivorsWiped: strcopy(buffer, maxlen, SKILLS_REASON_SURVIVORS_WIPED);
		default: strcopy(buffer, maxlen, SKILLS_REASON_NONE);
	}
}
