#if defined _l4d2_player_skills_helpers_included
	#endinput
#endif
#define _l4d2_player_skills_helpers_included

#define L4D2_SKILLS_FAST_POP_TIME 1.0
#define L4D2_SKILLS_COMPETITIVE_POP_MAX_TIME 3.0

/**
 * @brief Checks whether the plugin is currently enabled.
 *
 * @return               True if the enable ConVar exists and is on.
 */
stock bool Skills_IsEnabled()
{
	return g_cvEnable != null && g_cvEnable.BoolValue;
}

stock bool Skills_IsRoundLive()
{
	return Skills_IsEnabled() && g_Runtime.roundLive;
}

stock bool Skills_IsCompetitiveMode()
{
	return g_Runtime.baseMode == PlayerSkillsGameMode_Versus
		|| g_Runtime.baseMode == PlayerSkillsGameMode_Scavenge;
}

stock void Skills_RefreshRoundLiveState()
{
	if (!Skills_IsEnabled())
	{
		g_Runtime.roundLive = false;
		return;
	}

	if (g_Runtime.roundLiveSignal == PlayerSkillsRoundLiveSignal_SafeArea
		&& g_Runtime.hasLeft4DHooks
		&& GetFeatureStatus(FeatureType_Native, "L4D_HasAnySurvivorLeftSafeArea") != FeatureStatus_Unknown
		&& L4D_HasAnySurvivorLeftSafeArea())
	{
		g_Runtime.roundLive = true;
		return;
	}
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

stock bool Skills_IsShotgunWeaponId(int wepid)
{
	switch (wepid)
	{
		case WEPID_PUMPSHOTGUN, WEPID_AUTOSHOTGUN, WEPID_SHOTGUN_CHROME, WEPID_SHOTGUN_SPAS:
		{
			return true;
		}
	}

	return false;
}

stock bool Skills_IsRangedShotWeaponId(int wepid)
{
	switch (wepid)
	{
		case WEPID_PISTOL, WEPID_PISTOL_MAGNUM,
			WEPID_SMG, WEPID_SMG_SILENCED, WEPID_SMG_MP5,
			WEPID_PUMPSHOTGUN, WEPID_AUTOSHOTGUN, WEPID_SHOTGUN_CHROME, WEPID_SHOTGUN_SPAS,
			WEPID_RIFLE, WEPID_RIFLE_AK47, WEPID_RIFLE_DESERT, WEPID_RIFLE_SG552, WEPID_RIFLE_M60,
			WEPID_HUNTING_RIFLE, WEPID_SNIPER_MILITARY, WEPID_SNIPER_AWP, WEPID_SNIPER_SCOUT,
			WEPID_GRENADE_LAUNCHER, WEPID_MACHINEGUN:
		{
			return true;
		}
	}

	return false;
}

stock int Skills_GetWeaponIdFromEventName(const char[] weaponName)
{
	return weaponName[0] != '\0' ? WeaponNameToId(weaponName) : WEPID_NONE;
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
	if (!g_Runtime.hasLeft4DHooks
		|| GetFeatureStatus(FeatureType_Native, "L4D_GetGameModeType") != FeatureStatus_Available)
	{
		return PlayerSkillsGameMode_Unknown;
	}

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

stock int Skills_GetConfiguredSurvivorLimit()
{
	return g_cvSurvivorLimit != null ? g_cvSurvivorLimit.IntValue : 0;
}

stock int Skills_GetConfiguredPlayerZombieLimit()
{
	return g_cvMaxPlayerZombies != null ? g_cvMaxPlayerZombies.IntValue : 0;
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

stock int Skills_GetEnabledSiPoolMask()
{
	int mask = view_as<int>(PlayerSkillsSiPool_None);

	if (Skills_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Smoker))
	{
		mask |= view_as<int>(PlayerSkillsSiPool_Smoker);
	}
	if (Skills_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Boomer))
	{
		mask |= view_as<int>(PlayerSkillsSiPool_Boomer);
	}
	if (Skills_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Hunter))
	{
		mask |= view_as<int>(PlayerSkillsSiPool_Hunter);
	}
	if (Skills_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Spitter))
	{
		mask |= view_as<int>(PlayerSkillsSiPool_Spitter);
	}
	if (Skills_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Jockey))
	{
		mask |= view_as<int>(PlayerSkillsSiPool_Jockey);
	}
	if (Skills_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Charger))
	{
		mask |= view_as<int>(PlayerSkillsSiPool_Charger);
	}

	return mask;
}

stock int Skills_CountEnabledSiClassesFromMask(int mask)
{
	int count = 0;

	if ((mask & view_as<int>(PlayerSkillsSiPool_Smoker)) != 0)
	{
		count++;
	}
	if ((mask & view_as<int>(PlayerSkillsSiPool_Boomer)) != 0)
	{
		count++;
	}
	if ((mask & view_as<int>(PlayerSkillsSiPool_Hunter)) != 0)
	{
		count++;
	}
	if ((mask & view_as<int>(PlayerSkillsSiPool_Spitter)) != 0)
	{
		count++;
	}
	if ((mask & view_as<int>(PlayerSkillsSiPool_Jockey)) != 0)
	{
		count++;
	}
	if ((mask & view_as<int>(PlayerSkillsSiPool_Charger)) != 0)
	{
		count++;
	}

	return count;
}

stock PlayerSkillsVersusContextType Skills_ClassifyVersusContext(int survivorLimit, int playerZombieLimit, int enabledSiClassCount)
{
	if (!Skills_IsVersusMode() || survivorLimit <= 0 || playerZombieLimit <= 0 || survivorLimit != playerZombieLimit || enabledSiClassCount <= 0)
	{
		return PlayerSkillsVersusContext_None;
	}

	switch (survivorLimit)
	{
		case 1: return PlayerSkillsVersusContext_Versus1v1;
		case 2: return PlayerSkillsVersusContext_Versus2v2;
		case 3: return PlayerSkillsVersusContext_Versus3v3;
		case 4: return PlayerSkillsVersusContext_Versus4v4;
	}

	return PlayerSkillsVersusContext_CustomTeamVersus;
}

stock void Skills_BuildCurrentModeContext(PlayerSkillsModeContextData context)
{
	context.Reset();
	context.baseMode = Skills_GetCurrentGameMode();
	context.isVersusMode = context.baseMode == PlayerSkillsGameMode_Versus;
	context.configuredSurvivorLimit = Skills_GetConfiguredSurvivorLimit();
	context.configuredPlayerZombieLimit = Skills_GetConfiguredPlayerZombieLimit();

	if (!context.isVersusMode)
	{
		return;
	}

	context.siPoolMask = Skills_GetEnabledSiPoolMask();
	context.enabledSiClassCount = Skills_CountEnabledSiClassesFromMask(context.siPoolMask);
	context.versusTeamSize = context.configuredSurvivorLimit == context.configuredPlayerZombieLimit
		? context.configuredSurvivorLimit
		: 0;
	context.versusContext = Skills_ClassifyVersusContext(
		context.configuredSurvivorLimit,
		context.configuredPlayerZombieLimit,
		context.enabledSiClassCount);
}

stock void Skills_GetLifecyclePolicyForContext(PlayerSkillsModeContextData context, PlayerSkillsLifecyclePolicyData policy)
{
	policy.Reset();

	switch (context.baseMode)
	{
		case PlayerSkillsGameMode_Scavenge:
		{
			policy.roundStartSignal = PlayerSkillsRoundStartSignal_ScavengeRoundStart;
			policy.roundEndSignal = PlayerSkillsRoundEndSignal_ScavengeRoundFinished;
			policy.roundLiveSignal = PlayerSkillsRoundLiveSignal_Immediate;
		}
		case PlayerSkillsGameMode_Versus, PlayerSkillsGameMode_Coop:
		{
			policy.roundStartSignal = PlayerSkillsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerSkillsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerSkillsRoundLiveSignal_SafeArea;
		}
		case PlayerSkillsGameMode_Survival:
		{
			policy.roundStartSignal = PlayerSkillsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerSkillsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerSkillsRoundLiveSignal_Immediate;
		}
		default:
		{
			policy.roundStartSignal = PlayerSkillsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerSkillsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerSkillsRoundLiveSignal_Immediate;
		}
	}
}

stock void Skills_RefreshModeContext()
{
	PlayerSkillsModeContextData context;
	PlayerSkillsLifecyclePolicyData policy;
	Skills_BuildCurrentModeContext(context);
	Skills_GetLifecyclePolicyForContext(context, policy);

	g_Runtime.baseMode = context.baseMode;
	g_Runtime.configuredSurvivorLimit = context.configuredSurvivorLimit;
	g_Runtime.configuredPlayerZombieLimit = context.configuredPlayerZombieLimit;
	g_Runtime.siPoolMask = context.siPoolMask;
	g_Runtime.enabledSiClassCount = context.enabledSiClassCount;
	g_Runtime.versusTeamSize = context.versusTeamSize;
	g_Runtime.versusContext = context.versusContext;
	g_Runtime.roundStartSignal = policy.roundStartSignal;
	g_Runtime.roundEndSignal = policy.roundEndSignal;
	g_Runtime.roundLiveSignal = policy.roundLiveSignal;
}

stock bool Skills_ShouldHandleRoundStartEvent(const char[] eventName)
{
	switch (g_Runtime.roundStartSignal)
	{
		case PlayerSkillsRoundStartSignal_ScavengeRoundStart:
		{
			return StrEqual(eventName, "scavenge_round_start", false);
		}
		case PlayerSkillsRoundStartSignal_GenericRoundStart:
		{
			return StrEqual(eventName, "round_start", false);
		}
	}

	return false;
}

stock bool Skills_ShouldHandleRoundEndEvent(const char[] eventName)
{
	switch (g_Runtime.roundEndSignal)
	{
		case PlayerSkillsRoundEndSignal_ScavengeRoundFinished:
		{
			return StrEqual(eventName, "scavenge_round_finished", false);
		}
		case PlayerSkillsRoundEndSignal_GenericRoundEnd:
		{
			return StrEqual(eventName, "round_end", false);
		}
	}

	return false;
}

stock void Skills_GetModeBaseName(PlayerSkillsGameMode baseMode, char[] buffer, int maxlen)
{
	switch (baseMode)
	{
		case PlayerSkillsGameMode_Coop:
		{
			strcopy(buffer, maxlen, "Coop");
		}
		case PlayerSkillsGameMode_Versus:
		{
			strcopy(buffer, maxlen, "Versus");
		}
		case PlayerSkillsGameMode_Survival:
		{
			strcopy(buffer, maxlen, "Survival");
		}
		case PlayerSkillsGameMode_Scavenge:
		{
			strcopy(buffer, maxlen, "Scavenge");
		}
		default:
		{
			strcopy(buffer, maxlen, "Unknown");
		}
	}
}

stock void Skills_GetVersusContextName(PlayerSkillsVersusContextType context, char[] buffer, int maxlen)
{
	switch (context)
	{
		case PlayerSkillsVersusContext_Versus1v1:
		{
			strcopy(buffer, maxlen, "Versus1v1");
		}
		case PlayerSkillsVersusContext_Versus2v2:
		{
			strcopy(buffer, maxlen, "Versus2v2");
		}
		case PlayerSkillsVersusContext_Versus3v3:
		{
			strcopy(buffer, maxlen, "Versus3v3");
		}
		case PlayerSkillsVersusContext_Versus4v4:
		{
			strcopy(buffer, maxlen, "Versus4v4");
		}
		case PlayerSkillsVersusContext_CustomTeamVersus:
		{
			strcopy(buffer, maxlen, "CustomTeamVersus");
		}
		default:
		{
			strcopy(buffer, maxlen, "None");
		}
	}
}

stock void Skills_GetZombieClassName(L4D2ZombieClassType zombieClass, char[] buffer, int maxlen)
{
	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker: strcopy(buffer, maxlen, "Smoker");
		case L4D2ZombieClass_Boomer: strcopy(buffer, maxlen, "Boomer");
		case L4D2ZombieClass_Hunter: strcopy(buffer, maxlen, "Hunter");
		case L4D2ZombieClass_Spitter: strcopy(buffer, maxlen, "Spitter");
		case L4D2ZombieClass_Jockey: strcopy(buffer, maxlen, "Jockey");
		case L4D2ZombieClass_Charger: strcopy(buffer, maxlen, "Charger");
		case L4D2ZombieClass_Witch: strcopy(buffer, maxlen, "Witch");
		case L4D2ZombieClass_Tank: strcopy(buffer, maxlen, "Tank");
		default: strcopy(buffer, maxlen, "Infected");
	}
}

stock void Skills_FormatInfectedPlayerRefName(L4D2PlayerRef player, L4D2ZombieClassType zombieClass, char[] buffer, int maxlen)
{
	char className[32];
	Skills_GetZombieClassName(zombieClass, className, sizeof(className));

	if (player.bot)
	{
		FormatEx(buffer, maxlen, "%s (IA)", className);
		return;
	}

	if (player.name[0] != '\0')
	{
		FormatEx(buffer, maxlen, "%s (%s)", className, player.name);
		return;
	}

	strcopy(buffer, maxlen, className);
}

stock void Skills_GetSkillTypeName(L4D2SkillType type, char[] buffer, int maxlen)
{
	switch (type)
	{
		case L4D2Skill_HunterSkeet: strcopy(buffer, maxlen, "HunterSkeet");
		case L4D2Skill_HunterSkeetMelee: strcopy(buffer, maxlen, "HunterSkeetMelee");
		case L4D2Skill_HunterDeadstop: strcopy(buffer, maxlen, "HunterDeadstop");
		case L4D2Skill_BoomerPop: strcopy(buffer, maxlen, "BoomerPop");
		case L4D2Skill_ChargerLevel: strcopy(buffer, maxlen, "ChargerLevel");
		case L4D2Skill_TankDead: strcopy(buffer, maxlen, "TankDead");
		case L4D2Skill_WitchDead: strcopy(buffer, maxlen, "WitchDead");
		case L4D2Skill_WitchIncap: strcopy(buffer, maxlen, "WitchIncap");
		case L4D2Skill_SmokerTongueCut: strcopy(buffer, maxlen, "SmokerTongueCut");
		case L4D2Skill_SmokerSelfClear: strcopy(buffer, maxlen, "SmokerSelfClear");
		case L4D2Skill_TankRockSkeet: strcopy(buffer, maxlen, "TankRockSkeet");
		case L4D2Skill_TankRockHit: strcopy(buffer, maxlen, "TankRockHit");
		case L4D2Skill_HunterHighPounce: strcopy(buffer, maxlen, "HunterHighPounce");
		case L4D2Skill_JockeyHighPounce: strcopy(buffer, maxlen, "JockeyHighPounce");
		case L4D2Skill_ChargerInstaKill: strcopy(buffer, maxlen, "ChargerInstaKill");
		case L4D2Skill_ChargerDeathSetup: strcopy(buffer, maxlen, "ChargerDeathSetup");
		case L4D2Skill_ChargerBowl: strcopy(buffer, maxlen, "ChargerBowl");
		case L4D2Skill_SpecialPinClear: strcopy(buffer, maxlen, "SpecialPinClear");
		case L4D2Skill_BoomerVomitLanded: strcopy(buffer, maxlen, "BoomerVomitLanded");
		case L4D2Skill_BunnyHopStreak: strcopy(buffer, maxlen, "BunnyHopStreak");
		case L4D2Skill_CarAlarmTriggered: strcopy(buffer, maxlen, "CarAlarmTriggered");
		case L4D2Skill_SmokerKill: strcopy(buffer, maxlen, "SmokerKill");
		case L4D2Skill_BoomerKill: strcopy(buffer, maxlen, "BoomerKill");
		case L4D2Skill_HunterKill: strcopy(buffer, maxlen, "HunterKill");
		case L4D2Skill_SpitterKill: strcopy(buffer, maxlen, "SpitterKill");
		case L4D2Skill_JockeyKill: strcopy(buffer, maxlen, "JockeyKill");
		case L4D2Skill_ChargerKill: strcopy(buffer, maxlen, "ChargerKill");
		case L4D2Skill_JockeyJumpStop: strcopy(buffer, maxlen, "JockeyJumpStop");
		case L4D2Skill_JockeySkeetMelee: strcopy(buffer, maxlen, "JockeySkeetMelee");
		default: strcopy(buffer, maxlen, "None");
	}
}

stock void Skills_FormatEventPlayerRoleName(int eventIndex, int slot, char[] buffer, int maxlen)
{
	buffer[0] = '\0';

	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS || g_SkillEvents[eventIndex].id <= 0)
	{
		return;
	}

	L4D2PlayerRef player;
	Skills_GetEventPlayerRefBySlot(eventIndex, view_as<int>(slot), player);
	if (player.userid <= 0 && player.name[0] == '\0')
	{
		return;
	}

	if (slot == 1)
	{
		L4D2ZombieClassType zombieClass = L4D2ZombieClass_NotInfected;

		switch (g_SkillEvents[eventIndex].type)
		{
			case L4D2Skill_HunterSkeet, L4D2Skill_HunterSkeetMelee, L4D2Skill_HunterDeadstop, L4D2Skill_HunterHighPounce:
			{
				zombieClass = L4D2ZombieClass_Hunter;
			}
			case L4D2Skill_BoomerPop, L4D2Skill_BoomerVomitLanded:
			{
				zombieClass = L4D2ZombieClass_Boomer;
			}
			case L4D2Skill_SmokerTongueCut, L4D2Skill_SmokerSelfClear:
			{
				zombieClass = L4D2ZombieClass_Smoker;
			}
			case L4D2Skill_JockeyHighPounce, L4D2Skill_JockeyJumpStop, L4D2Skill_JockeySkeetMelee:
			{
				zombieClass = L4D2ZombieClass_Jockey;
			}
			case L4D2Skill_ChargerLevel, L4D2Skill_ChargerInstaKill, L4D2Skill_ChargerDeathSetup, L4D2Skill_ChargerBowl:
			{
				zombieClass = L4D2ZombieClass_Charger;
			}
			case L4D2Skill_SmokerKill:
			{
				zombieClass = L4D2ZombieClass_Smoker;
			}
			case L4D2Skill_BoomerKill:
			{
				zombieClass = L4D2ZombieClass_Boomer;
			}
			case L4D2Skill_HunterKill:
			{
				zombieClass = L4D2ZombieClass_Hunter;
			}
			case L4D2Skill_SpitterKill:
			{
				zombieClass = L4D2ZombieClass_Spitter;
			}
			case L4D2Skill_JockeyKill:
			{
				zombieClass = L4D2ZombieClass_Jockey;
			}
			case L4D2Skill_ChargerKill:
			{
				zombieClass = L4D2ZombieClass_Charger;
			}
			case L4D2Skill_TankRockSkeet, L4D2Skill_TankRockHit, L4D2Skill_TankDead:
			{
				zombieClass = L4D2ZombieClass_Tank;
			}
		}

		if (zombieClass != L4D2ZombieClass_NotInfected)
		{
			Skills_FormatInfectedPlayerRefName(player, zombieClass, buffer, maxlen);
			return;
		}
	}
	else if (slot == 0)
	{
		L4D2ZombieClassType zombieClass = L4D2ZombieClass_NotInfected;

		switch (g_SkillEvents[eventIndex].type)
		{
			case L4D2Skill_HunterHighPounce:
			{
				zombieClass = L4D2ZombieClass_Hunter;
			}
			case L4D2Skill_JockeyHighPounce:
			{
				zombieClass = L4D2ZombieClass_Jockey;
			}
			case L4D2Skill_BoomerVomitLanded:
			{
				zombieClass = L4D2ZombieClass_Boomer;
			}
		case L4D2Skill_ChargerInstaKill, L4D2Skill_ChargerDeathSetup, L4D2Skill_ChargerBowl:
			{
				zombieClass = L4D2ZombieClass_Charger;
			}
			case L4D2Skill_TankDead:
			{
				zombieClass = L4D2ZombieClass_Tank;
			}
		}

		if (zombieClass != L4D2ZombieClass_NotInfected)
		{
			Skills_FormatInfectedPlayerRefName(player, zombieClass, buffer, maxlen);
			return;
		}
	}

	strcopy(buffer, maxlen, player.name);
}

stock bool Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClassType zombieClass)
{
	if (g_Runtime.baseMode != PlayerSkillsGameMode_Versus)
	{
		return true;
	}

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			return (g_Runtime.siPoolMask & view_as<int>(PlayerSkillsSiPool_Smoker)) != 0;
		}
		case L4D2ZombieClass_Boomer:
		{
			return (g_Runtime.siPoolMask & view_as<int>(PlayerSkillsSiPool_Boomer)) != 0;
		}
		case L4D2ZombieClass_Hunter:
		{
			return (g_Runtime.siPoolMask & view_as<int>(PlayerSkillsSiPool_Hunter)) != 0;
		}
		case L4D2ZombieClass_Spitter:
		{
			return (g_Runtime.siPoolMask & view_as<int>(PlayerSkillsSiPool_Spitter)) != 0;
		}
		case L4D2ZombieClass_Jockey:
		{
			return (g_Runtime.siPoolMask & view_as<int>(PlayerSkillsSiPool_Jockey)) != 0;
		}
		case L4D2ZombieClass_Charger:
		{
			return (g_Runtime.siPoolMask & view_as<int>(PlayerSkillsSiPool_Charger)) != 0;
		}
	}

	return true;
}

/**
 * @brief Returns whether a skill type is enabled in the current mode after applying Versus SI limits.
 *
 * @param type           Target skill type.
 *
 * @return               True when the skill type should be considered visible/rated in the current mode.
 */
stock bool Skills_IsSkillTypeEnabledInCurrentMode(L4D2SkillType type)
{
	switch (type)
	{
		case L4D2Skill_HunterSkeet, L4D2Skill_HunterSkeetMelee, L4D2Skill_HunterDeadstop, L4D2Skill_HunterHighPounce:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Hunter);
		}
		case L4D2Skill_BoomerPop, L4D2Skill_BoomerVomitLanded:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Boomer);
		}
		case L4D2Skill_ChargerLevel, L4D2Skill_ChargerInstaKill, L4D2Skill_ChargerDeathSetup, L4D2Skill_ChargerBowl:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Charger);
		}
		case L4D2Skill_SmokerTongueCut, L4D2Skill_SmokerSelfClear:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Smoker);
		}
		case L4D2Skill_SmokerKill:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Smoker);
		}
		case L4D2Skill_JockeyHighPounce, L4D2Skill_JockeyJumpStop, L4D2Skill_JockeySkeetMelee:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Jockey);
		}
		case L4D2Skill_JockeyKill:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Jockey);
		}
		case L4D2Skill_SpitterKill:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Spitter);
		}
		case L4D2Skill_BoomerKill:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Boomer);
		}
		case L4D2Skill_HunterKill:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Hunter);
		}
		case L4D2Skill_ChargerKill:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Charger);
		}
	}

	return true;
}

/**
 * @brief Returns whether a stored skill event is enabled in the current mode after applying Versus SI limits.
 *
 * @param eventIndex     Zero-based slot index inside g_SkillEvents.
 *
 * @return               True when the event should be considered visible/rated in the current mode.
 */
stock bool Skills_IsSkillEventEnabledInCurrentMode(int eventIndex)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS || g_SkillEvents[eventIndex].id <= 0)
	{
		return false;
	}

	if (!Skills_IsVersusMode())
	{
		return true;
	}

	switch (g_SkillEvents[eventIndex].type)
	{
		case L4D2Skill_SpecialPinClear:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(view_as<L4D2ZombieClassType>(g_SkillEvents[eventIndex].zombieClass));
		}
		case L4D2Skill_CarAlarmTriggered:
		{
			if (g_SkillEvents[eventIndex].reason == view_as<int>(L4D2CarAlarm_Boomer))
			{
				return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Boomer);
			}

			return true;
		}
	}

	return Skills_IsSkillTypeEnabledInCurrentMode(g_SkillEvents[eventIndex].type);
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

	if (!Skills_IsSkillEventEnabledInCurrentMode(eventIndex))
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
		case L4D2Skill_JockeyJumpStop:
		{
			return 1;
		}
		case L4D2Skill_JockeySkeetMelee:
		{
			return 3;
		}
		case L4D2Skill_BoomerVomitLanded:
		{
			int survivorLimit = Skills_GetConfiguredSurvivorLimit();
			if (survivorLimit <= 0)
			{
				survivorLimit = 4;
			}

			if (g_SkillEvents[eventIndex].amount >= survivorLimit)
			{
				return 2;
			}

			if (survivorLimit <= 1)
			{
				return g_SkillEvents[eventIndex].amount >= 1 ? 1 : 0;
			}

			return g_SkillEvents[eventIndex].amount >= (survivorLimit - 1) ? 1 : 0;
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
		case L4D2Skill_ChargerBowl:
		{
			return g_SkillEvents[eventIndex].amount >= 3 ? 3 : 2;
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
	LogToFileEx(g_sDebugLogPath, "tick=%d %s", GetGameTickCount(), buffer);
}

void LoadPluginTranslations()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "translations/"...TRANSLATION_FILE... ".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file \""...TRANSLATION_FILE...".txt\"");
	}
	LoadTranslations(TRANSLATION_FILE);
}
