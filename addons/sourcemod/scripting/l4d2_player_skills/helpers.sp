#if defined _l4d2_player_skills_helpers_included
	#endinput
#endif
#define _l4d2_player_skills_helpers_included

#define L4D2_SKILLS_FAST_POP_TIME 1.0

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
 * @brief Returns the current base game mode as a typed value.
 *
 * @return               Parsed game mode, or Unknown if unavailable.
 */
stock PlayerSkillsGameMode Skills_GetCurrentGameMode()
{
	switch (L4D_GetGameModeType())
	{
		case GAMEMODE_COOP:
		{
			return PlayerSkillsGameMode_Coop;
		}
		case GAMEMODE_VERSUS:
		{
			return PlayerSkillsGameMode_Versus;
		}
		case GAMEMODE_SURVIVAL:
		{
			return PlayerSkillsGameMode_Survival;
		}
		case GAMEMODE_SCAVENGE:
		{
			return PlayerSkillsGameMode_Scavenge;
		}
	}

	return PlayerSkillsGameMode_Unknown;
}

/**
 * @brief Checks whether the current map is running in Coop-style mode.
 *
 * @return               True in Coop or Realism style modes.
 */
stock bool Skills_IsCoopMode()
{
	return Skills_GetCurrentGameMode() == PlayerSkillsGameMode_Coop;
}

/**
 * @brief Checks whether the current map is running in Versus mode.
 *
 * @return               True when left4dhooks reports a Versus-style mode.
 */
stock bool Skills_IsVersusMode()
{
	return Skills_GetCurrentGameMode() == PlayerSkillsGameMode_Versus;
}

/**
 * @brief Checks whether the current map is running in Survival mode.
 *
 * @return               True when left4dhooks reports Survival.
 */
stock bool Skills_IsSurvivalMode()
{
	return Skills_GetCurrentGameMode() == PlayerSkillsGameMode_Survival;
}

/**
 * @brief Checks whether the current map is running in Scavenge mode.
 *
 * @return               True when left4dhooks reports a Scavenge-style mode.
 */
stock bool Skills_IsScavengeMode()
{
	return Skills_GetCurrentGameMode() == PlayerSkillsGameMode_Scavenge;
}

/**
 * @brief Checks whether a cvar scope is relevant in the current base mode.
 *
 * @param scope          Contextual scope associated with a cvar or rule.
 *
 * @return               True if the scope applies to the current mode.
 */
stock bool Skills_IsScopeRelevant(PlayerSkillsCvarScope scope)
{
	switch (scope)
	{
		case PlayerSkillsCvarScope_Global:
		{
			return true;
		}
		case PlayerSkillsCvarScope_Coop:
		{
			return Skills_IsCoopMode();
		}
		case PlayerSkillsCvarScope_Versus:
		{
			return Skills_IsVersusMode();
		}
		case PlayerSkillsCvarScope_Survival:
		{
			return Skills_IsSurvivalMode();
		}
		case PlayerSkillsCvarScope_Scavenge:
		{
			return Skills_IsScavengeMode();
		}
	}

	return false;
}

/**
 * @brief Checks whether closet rescue logic is relevant in the current mode.
 *
 * @return               True in Coop-style modes.
 */
stock bool Skills_IsClosetRescueRelevant()
{
	return Skills_IsScopeRelevant(PlayerSkillsCvarScope_Coop);
}

/**
 * @brief Returns the configured maximum health for a special infected class.
 *
 * @param zombieClass    Target infected class.
 *
 * @return               Configured max health, or 0 if the class is not supported.
 */
stock int Skills_GetSpecialMaxHealth(L4D2ZombieClassType zombieClass)
{
	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			return g_cvSmokerHealth != null ? g_cvSmokerHealth.IntValue : L4D2_SKILLS_DEFAULT_SMOKER_HEALTH;
		}
		case L4D2ZombieClass_Boomer:
		{
			return g_cvBoomerHealth != null ? g_cvBoomerHealth.IntValue : L4D2_SKILLS_DEFAULT_BOOMER_HEALTH;
		}
		case L4D2ZombieClass_Hunter:
		{
			return g_cvHunterHealth != null ? g_cvHunterHealth.IntValue : L4D2_SKILLS_DEFAULT_HUNTER_HEALTH;
		}
		case L4D2ZombieClass_Spitter:
		{
			return g_cvSpitterHealth != null ? g_cvSpitterHealth.IntValue : L4D2_SKILLS_DEFAULT_SPITTER_HEALTH;
		}
		case L4D2ZombieClass_Jockey:
		{
			return g_cvJockeyHealth != null ? g_cvJockeyHealth.IntValue : L4D2_SKILLS_DEFAULT_JOCKEY_HEALTH;
		}
		case L4D2ZombieClass_Charger:
		{
			return g_cvChargerHealth != null ? g_cvChargerHealth.IntValue : L4D2_SKILLS_DEFAULT_CHARGER_HEALTH;
		}
		case L4D2ZombieClass_Tank:
		{
			return g_cvTankHealth != null ? g_cvTankHealth.IntValue : L4D2_SKILLS_DEFAULT_TANK_HEALTH;
		}
	}

	return 0;
}

/**
 * @brief Returns the configured maximum health for a Witch.
 *
 * @return               Configured Witch max health.
 */
stock int Skills_GetWitchMaxHealth()
{
	return g_cvWitchHealth != null ? g_cvWitchHealth.IntValue : L4D2_SKILLS_DEFAULT_WITCH_HEALTH;
}

/**
 * @brief Returns the configured maximum Hunter pounce bonus damage.
 *
 * @return               Configured Hunter pounce bonus damage baseline.
 */
stock float Skills_GetHunterMaxPounceBonusDamage()
{
	return g_cvHunterMaxPounceBonusDamage != null ? g_cvHunterMaxPounceBonusDamage.FloatValue : L4D2_SKILLS_DEFAULT_HUNTER_MAX_POUNCE_BONUS_DAMAGE;
}

/**
 * @brief Returns the configured maximum total Hunter pounce damage.
 * @remarks The game adds a base point on top of the configurable bonus.
 *
 * @return               Maximum total Hunter pounce damage.
 */
stock int Skills_GetHunterMaxPounceTotalDamage()
{
	return RoundToFloor(Skills_GetHunterMaxPounceBonusDamage()) + 1;
}

/**
 * @brief Returns the configured minimum vertical height for HunterHighPounce.
 *
 * @return               Configured Hunter high-pounce threshold.
 */
stock float Skills_GetHunterHighPounceHeightThreshold()
{
	return g_cvHunterHighPounceHeight != null ? g_cvHunterHighPounceHeight.FloatValue : L4D2_SKILLS_DEFAULT_HUNTER_HIGH_POUNCE_HEIGHT;
}

/**
 * @brief Returns the configured minimum vertical height for JockeyHighPounce.
 *
 * @return               Configured Jockey high-pounce threshold.
 */
stock float Skills_GetJockeyHighPounceHeightThreshold()
{
	return g_cvJockeyHighPounceHeight != null ? g_cvJockeyHighPounceHeight.FloatValue : L4D2_SKILLS_DEFAULT_JOCKEY_HIGH_POUNCE_HEIGHT;
}

/**
 * @brief Returns whether a special infected class is enabled by Versus limit cvars.
 * @remarks This helper is only meaningful in player-controlled infected modes.
 *          Outside Versus it returns false instead of implying global availability.
 *
 * @param zombieClass    Target infected class.
 *
 * @return               True if the current mode is Versus and the class has a positive limit.
 */
stock bool Skills_IsVersusSpecialLimitEnabled(L4D2ZombieClassType zombieClass)
{
	if (!Skills_IsVersusMode())
	{
		return false;
	}

	ConVar limit = null;

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			limit = g_cvVersusSmokerLimit;
		}
		case L4D2ZombieClass_Boomer:
		{
			limit = g_cvVersusBoomerLimit;
		}
		case L4D2ZombieClass_Hunter:
		{
			limit = g_cvVersusHunterLimit;
		}
		case L4D2ZombieClass_Spitter:
		{
			limit = g_cvVersusSpitterLimit;
		}
		case L4D2ZombieClass_Jockey:
		{
			limit = g_cvVersusJockeyLimit;
		}
		case L4D2ZombieClass_Charger:
		{
			limit = g_cvVersusChargerLimit;
		}
		default:
		{
			return true;
		}
	}

	return limit == null || limit.IntValue > 0;
}

/**
 * @brief Returns the public 0-3 star rating for a stored skill event.
 *
 * @param eventIndex     Zero-based slot index inside g_SkillEvents.
 *
 * @return               0 for unrated events, otherwise a rating from 1 to 3.
 */
stock int Skills_GetEventRating(int eventIndex)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS || g_SkillEvents[eventIndex].id <= 0)
	{
		return 0;
	}

	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_SmokerTongueCut:
		{
			return 2;
		}
		case L4D2Skill_SmokerSelfClear, L4D2Skill_SpecialPinClear, L4D2Skill_HunterDeadstop:
		{
			return 1;
		}
		case L4D2Skill_HunterSkeet:
		{
			return (g_SkillEvents[eventIndex].headshot || g_SkillEvents[eventIndex].perfect) ? 3 : 2;
		}
		case L4D2Skill_HunterSkeetMelee:
		{
			return g_SkillEvents[eventIndex].perfect ? 3 : 2;
		}
		case L4D2Skill_HunterHighPounce:
		{
			int damage = g_SkillEvents[eventIndex].damage;
			int maxTotalDamage = Skills_GetHunterMaxPounceTotalDamage();

			if (damage >= 22 && damage <= maxTotalDamage)
			{
				return 3;
			}

			if (damage >= 15)
			{
				return 2;
			}

			return 1;
		}
		case L4D2Skill_JockeyHighPounce:
		{
			float threshold = Skills_GetJockeyHighPounceHeightThreshold();
			float height = g_SkillEvents[eventIndex].height;

			if (height >= (threshold + 350.0))
			{
				return 3;
			}

			if (height >= (threshold + 150.0))
			{
				return 2;
			}

			return 1;
		}
		case L4D2Skill_BoomerVomitLanded:
		{
			if (g_SkillEvents[eventIndex].amount >= 4)
			{
				return 2;
			}

			return g_SkillEvents[eventIndex].amount >= 3 ? 1 : 0;
		}
		case L4D2Skill_BoomerPop:
		{
			if (g_SkillEvents[eventIndex].timeA > 0.0 && g_SkillEvents[eventIndex].timeA <= 0.5)
			{
				return 3;
			}

			if (g_SkillEvents[eventIndex].timeA > 0.5 && g_SkillEvents[eventIndex].timeA <= 1.4)
			{
				return 2;
			}

			return 1;
		}
		case L4D2Skill_BunnyHopStreak:
		{
			return 1;
		}
		case L4D2Skill_ChargerLevel:
		{
			return g_SkillEvents[eventIndex].perfect ? 3 : 2;
		}
		case L4D2Skill_ChargerInstaKill:
		{
			return 3;
		}
		case L4D2Skill_ChargerDeathSetup:
		{
			return 2;
		}
		case L4D2Skill_WitchDead:
		{
			return g_SkillEvents[eventIndex].crown ? 2 : 0;
		}
		case L4D2Skill_TankRockSkeet:
		{
			return 2;
		}
		case L4D2Skill_CarAlarmTriggered:
		{
			if (g_SkillEvents[eventIndex].reason == view_as<int>(L4D2CarAlarm_Boomer))
			{
				return g_SkillEvents[eventIndex].victim.userid > 0 ? 1 : 0;
			}

			return (g_SkillEvents[eventIndex].forced && g_SkillEvents[eventIndex].victim.userid > 0) ? 1 : 0;
		}
	}

	return 0;
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
