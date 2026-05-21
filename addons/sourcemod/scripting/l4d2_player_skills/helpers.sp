#if defined _l4d2_player_skills_helpers_included
	#endinput
#endif
#define _l4d2_player_skills_helpers_included

/**
 * @brief Checks whether the plugin is currently enabled.
 *
 * @return               True if the enable ConVar exists and is on.
 */
stock bool Skills_IsEnabled()
{
	return g_cvEnable != null && g_cvEnable.BoolValue;
}

/**
 * @brief Checks whether a client index is valid and in-game.
 *
 * @param client         Client index to inspect.
 *
 * @return               True if the client is in the valid SourceMod range and connected in-game.
 */
stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

/**
 * @brief Clears the circular runtime buffer of detected skill events.
 *
 * @noreturn
 */
stock void Skills_ResetEvents()
{
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		g_SkillEvents[index].Reset();
	}

	g_iEventSerial	 = 0;
	g_iNextEventSlot = 0;
}

/**
 * @brief Allocates a new runtime skill event in the circular buffer.
 *
 * @param type           Skill type to assign to the new event.
 *
 * @return               Runtime event identifier for the new slot.
 */
stock int Skills_CreateEvent(L4D2SkillType type)
{
	int slot		 = g_iNextEventSlot;
	g_iNextEventSlot = (g_iNextEventSlot + 1) % L4D2_SKILLS_MAX_EVENTS;

	g_SkillEvents[slot].Reset();
	g_SkillEvents[slot].id		  = ++g_iEventSerial;
	g_SkillEvents[slot].type	  = type;
	g_SkillEvents[slot].createdAt = GetGameTime();

	return g_SkillEvents[slot].id;
}

/**
 * @brief Resolves a runtime event id to its current storage slot.
 *
 * @param eventId        Runtime skill event identifier.
 *
 * @return               Zero-based slot index, or -1 if not found.
 */
stock int Skills_GetEventIndex(int eventId)
{
	if (eventId <= 0)
	{
		return -1;
	}

	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id == eventId)
		{
			return index;
		}
	}

	return -1;
}

/**
 * @brief Checks whether a runtime skill event id is still valid.
 *
 * @param eventId        Runtime skill event identifier.
 *
 * @return               True if the event still exists in the circular buffer.
 */
stock bool Skills_IsEventValid(int eventId)
{
	return Skills_GetEventIndex(eventId) != -1;
}

/**
 * @brief Copies one captured player role from a stored skill event.
 *
 * @param eventIndex     Zero-based slot index inside g_SkillEvents.
 * @param slot           Player role slot from L4D2SkillPlayerSlot.
 * @param player         Output player snapshot buffer.
 *
 * @noreturn
 */
stock void Skills_GetEventPlayerRefBySlot(int eventIndex, int slot, L4D2PlayerRef player)
{
	player.Reset();

	switch (slot)
	{
		case 0:
		{
			player = g_SkillEvents[eventIndex].actor;
			return;
		}
		case 1:
		{
			player = g_SkillEvents[eventIndex].victim;
			return;
		}
		case 2:
		{
			player = g_SkillEvents[eventIndex].assister;
			return;
		}
		case 3:
		{
			player = g_SkillEvents[eventIndex].pinVictim;
			return;
		}
	}
}

/**
 * @brief Resolves a userid back to a live client index when possible.
 *
 * @param userid         Runtime Source client userid.
 *
 * @return               Client index, or 0 if the userid is no longer online.
 */
stock int ResolveClientFromUserId(int userid)
{
	int client = GetClientOfUserId(userid);
	return IsValidClient(client) ? client : 0;
}

/**
 * @brief Returns the typed L4D team for a client.
 *
 * @param client         Client index to inspect.
 *
 * @return               Team enum, or L4DTeam_Unassigned if invalid.
 */
stock L4DTeam GetClientL4DTeam(int client)
{
	return IsValidClient(client) ? L4D_GetClientTeam(client) : L4DTeam_Unassigned;
}

/**
 * @brief Checks whether a client belongs to the requested L4D team.
 *
 * @param client         Client index to inspect.
 * @param team           Target L4D team.
 *
 * @return               True if the client is valid and belongs to that team.
 */
stock bool IsClientOnTeam(int client, L4DTeam team)
{
	return GetClientL4DTeam(client) == team;
}

/**
 * @brief Returns the typed zombie class for an infected client.
 *
 * @param client         Client index to inspect.
 *
 * @return               Zombie class enum, or NotInfected when unavailable.
 */
stock L4D2ZombieClassType GetClientZombieClass(int client)
{
	return IsValidInfected(client) ? L4D2_GetPlayerZombieClass(client) : L4D2ZombieClass_NotInfected;
}

/**
 * @brief Checks whether an infected client matches a specific zombie class.
 *
 * @param client         Client index to inspect.
 * @param zombieClass    Target zombie class.
 *
 * @return               True if the client is infected and matches the class.
 */
stock bool IsValidZombieClass(int client, L4D2ZombieClassType zombieClass)
{
	return IsValidInfected(client) && GetClientZombieClass(client) == zombieClass;
}

/**
 * @brief Checks whether a client is a valid survivor.
 *
 * @param client         Client index to inspect.
 *
 * @return               True if the client belongs to the survivor team.
 */
stock bool IsValidSurvivor(int client)
{
	return IsClientOnTeam(client, L4DTeam_Survivor);
}

/**
 * @brief Checks whether a client is a valid special infected player.
 *
 * @param client         Client index to inspect.
 *
 * @return               True if the client belongs to the infected team.
 */
stock bool IsValidInfected(int client)
{
	return IsClientOnTeam(client, L4DTeam_Infected);
}

/**
 * @brief Checks whether a client is a valid Tank player.
 *
 * @param client         Client index to inspect.
 *
 * @return               True if the client is infected and of Tank class.
 */
stock bool IsValidTank(int client)
{
	return IsValidZombieClass(client, L4D2ZombieClass_Tank);
}

/**
 * @brief Checks whether an entity is a Witch.
 *
 * @param entity         Entity index to inspect.
 *
 * @return               True if the entity classname matches a Witch variant.
 */
stock bool IsWitchEntity(int entity)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
	{
		return false;
	}

	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrContains(classname, "witch", false) != -1;
}

/**
 * @brief Checks whether a specific debug category is enabled in the bitmask ConVar.
 *
 * @param category       Bitmask category from PlayerSkillsDebugCategory.
 *
 * @return               True if that category is enabled.
 */
stock bool Skills_IsDebugEnabled(PlayerSkillsDebugCategory category)
{
	if (g_cvDebug == null)
	{
		return false;
	}

	int mask = g_cvDebug.IntValue;
	return (mask & view_as<int>(category)) != 0;
}

/**
 * @brief Writes a formatted debug line when the selected category is enabled.
 *
 * @param category       Bitmask category from PlayerSkillsDebugCategory.
 * @param fmt            Format string.
 * @param ...            Format arguments.
 *
 * @noreturn
 */
stock void Skills_Debug(PlayerSkillsDebugCategory category, const char[] fmt, any...)
{
	if (!Skills_IsDebugEnabled(category))
	{
		return;
	}

	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 3);
	LogToFileEx(g_sDebugLogPath, "[l4d2_player_skills] %s", buffer);
}
