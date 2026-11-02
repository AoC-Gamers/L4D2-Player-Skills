#if defined _l4d2_player_skills_helpers_included
	#endinput
#endif
#define _l4d2_player_skills_helpers_included

#include "l4d2_player_skills/mode_context.sp"

#define L4D2_SKILLS_FAST_POP_TIME 1.0
#define L4D2_SKILLS_COMPETITIVE_POP_MAX_TIME 3.0

enum TankHealthContextError
{
	TankHealthContextError_None = 0,
	TankHealthContextError_BaseHealth,
	TankHealthContextError_ModeDependency,
	TankHealthContextError_UnknownMode,
	TankHealthContextError_DifficultyUnavailable,
	TankHealthContextError_DifficultyUnknown
}

static TankHealthContextError g_TankHealthContextLastError = TankHealthContextError_None;

static void Skills_TankHealthContextError(TankHealthContextError error, const char[] message)
{
	if (g_TankHealthContextLastError != error)
	{
		LogError("Tank expected-health resolution failed: %s", message);
		g_TankHealthContextLastError = error;
	}
}

/**
 * @brief Applies the standard L4D2 mode and difficulty factor to base Tank health.
 * @remarks RoundToNearest is the explicit integer policy for fractional results;
 *          exact parity with the engine's internal conversion is not verified.
 *          Survival and Scavenge retain the prior unadjusted base-health behavior.
 *
 * @param baseHealth    Base health configured by z_tank_health.
 * @param mode          Base mode resolved through Left4DHooks.
 * @param difficulty    Current z_difficulty value; used only in Coop.
 *
 * @return              Contextualized expected maximum, or 0 when unresolved.
 */
stock int Skills_CalculateContextualTankHealth(int baseHealth, PlayerSkillsGameMode mode, const char[] difficulty)
{
	if (baseHealth <= 0)
	{
		return 0;
	}

	float factor;
	switch (mode)
	{
		case PlayerSkillsGameMode_Versus:
		{
			factor = 1.5;
		}
		case PlayerSkillsGameMode_Coop:
		{
			if (StrEqual(difficulty, "Easy", false))
			{
				factor = 0.75;
			}
			else if (StrEqual(difficulty, "Normal", false))
			{
				factor = 1.0;
			}
			else if (StrEqual(difficulty, "Hard", false) || StrEqual(difficulty, "Impossible", false))
			{
				factor = 2.0;
			}
			else
			{
				return 0;
			}
		}
		case PlayerSkillsGameMode_Survival, PlayerSkillsGameMode_Scavenge:
		{
			return baseHealth;
		}
		default:
		{
			return 0;
		}
	}

	return RoundToNearest(float(baseHealth) * factor);
}

/**
 * @brief Resolves expected maximum Tank health for the current game context.
 * @remarks z_tank_health is the base setting. Survival and Scavenge retain the
 *          existing base-health behavior; unknown contexts return 0.
 *
 * @param baseHealth    Base health configured by z_tank_health.
 *
 * @return              Expected maximum health, or 0 when resolution fails.
 */
stock int Skills_ContextualizeTankHealth(int baseHealth)
{
	if (baseHealth <= 0)
	{
		Skills_TankHealthContextError(TankHealthContextError_BaseHealth, "z_tank_health base value is not positive");
		return 0;
	}

	PlayerSkillsGameMode mode = Skills_GetCurrentGameMode();
	if (mode == PlayerSkillsGameMode_Unknown)
	{
		if (!g_Runtime.hasLeft4DHooks || GetFeatureStatus(FeatureType_Native, "L4D_GetGameModeType") != FeatureStatus_Available)
		{
			Skills_TankHealthContextError(TankHealthContextError_ModeDependency, "Left4DHooks game-mode native is unavailable");
		}
		else
		{
			Skills_TankHealthContextError(TankHealthContextError_UnknownMode, "Left4DHooks could not resolve the current base mode");
		}
		return 0;
	}

	char difficulty[32];
	difficulty[0] = '\0';
	if (mode == PlayerSkillsGameMode_Coop)
	{
		if (g_cvDifficulty == null)
		{
			Skills_TankHealthContextError(TankHealthContextError_DifficultyUnavailable, "z_difficulty ConVar is unavailable");
			return 0;
		}
		g_cvDifficulty.GetString(difficulty, sizeof(difficulty));
	}

	int expectedHealth = Skills_CalculateContextualTankHealth(baseHealth, mode, difficulty);
	if (expectedHealth <= 0)
	{
		Skills_TankHealthContextError(TankHealthContextError_DifficultyUnknown, "z_difficulty is not Easy, Normal, Hard, or Impossible");
		return 0;
	}

	g_TankHealthContextLastError = TankHealthContextError_None;
	return expectedHealth;
}

static const char g_L4D2WeaponDisplayNames[WEPID_SIZE][] =
{
	"None", "Pistol", "Uzi",
	"Pump", "Auto Shotgun", "M-16",
	"Hunting Rifle", "Silenced SMG", "Chrome",
	"Desert Rifle", "Military Sniper", "SPAS Shotgun",
	"First Aid Kit", "Molotov", "Pipe Bomb",
	"Pills", "Gascan", "Propane Tank",
	"Oxygen Tank", "Melee", "Chainsaw",
	"Grenade Launcher", "Ammo Pack", "Adrenaline",
	"Defibrillator", "Bile Bomb", "AK-47",
	"Gnome", "Cola Bottles", "Fireworks",
	"Incendiary Ammo Pack", "Explosive Ammo Pack", "Magnum",
	"MP5", "SG552", "AWP",
	"Scout", "M60", "Tank Claw",
	"Hunter Claw", "Charger Claw", "Boomer Claw",
	"Smoker Claw", "Spitter Claw", "Jockey Claw",
	"Machinegun", "Vomit", "Splat",
	"Pounce", "Lounge", "Pull",
	"Choke", "Rock", "Physics",
	"Ammo", "Upgrade Item"
};

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

stock bool Skills_HasPlayerStats()
{
	return g_Runtime.hasPlayerStats;
}

stock bool Skills_UsesExternalLifecycle()
{
	return g_Runtime.usesExternalLifecycle;
}

stock bool Skills_CanUsePlayerStats()
{
	return Skills_HasPlayerStats()
		&& GetFeatureStatus(FeatureType_Native, "PlayerStats_GetCurrentModeProperty") == FeatureStatus_Available
		&& GetFeatureStatus(FeatureType_Native, "PlayerStats_IsRoundLive") == FeatureStatus_Available;
}

stock bool Skills_IsCompetitiveMode()
{
	return g_Runtime.baseMode == PlayerSkillsGameMode_Versus || g_Runtime.baseMode == PlayerSkillsGameMode_Scavenge;
}

/**
 * @brief Returns the compact survivor-side capacity for short-lived interaction trackers.
 * @remarks These trackers should size to the functional survivor space of the mode,
 *          not to MAXPLAYERS. Examples: skill-window assists, hunter skeet shot windows,
 *          charger claw summaries.
 *
 * @return               Survivor entry capacity clamped to the plugin maximum.
 */
stock int Skills_GetTrackedSurvivorEntryCapacity()
{
	int slotCount = Skills_GetConfiguredSurvivorLimit();
	if (slotCount < 1)
	{
		slotCount = L4D2_SKILLS_DEFAULT_SURVIVOR_LIMIT;
	}
	slotCount++;
	if (slotCount > L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES)
	{
		slotCount = L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES;
	}

	return slotCount;
}

/**
 * @brief Returns the compact infected-side capacity for short-lived interaction trackers.
 * @remarks Competitive infected windows should size to z_max_player_zombies when present,
 *          not to MAXPLAYERS.
 *
 * @return               Infected entry capacity clamped to the plugin maximum.
 */
stock int Skills_GetTrackedInfectedEntryCapacity()
{
	int slotCount = Skills_GetConfiguredPlayerZombieLimit();
	if (slotCount < 1)
	{
		slotCount = L4D2_SKILLS_DEFAULT_PLAYER_ZOMBIE_LIMIT;
	}
	if (slotCount > L4D2_SKILLS_MAX_TRACKED_INFECTED_ENTRIES)
	{
		slotCount = L4D2_SKILLS_MAX_TRACKED_INFECTED_ENTRIES;
	}

	return slotCount;
}

/**
 * @brief Returns the compact same-class infected capacity for short-lived trackers.
 * @remarks This is useful when a skill window can involve multiple infected of the
 *          same class at once and the class-specific versus limit is more precise
 *          than z_max_player_zombies.
 *
 * @param zombieClass    Target special infected class.
 *
 * @return               Class entry capacity clamped to the plugin maximum.
 */
stock int Skills_GetTrackedZombieClassEntryCapacity(L4D2ZombieClassType zombieClass)
{
	int slotCount = 0;

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			slotCount = g_cvVersusSmokerLimit != null ? g_cvVersusSmokerLimit.IntValue : 0;
		}
		case L4D2ZombieClass_Boomer:
		{
			slotCount = g_cvVersusBoomerLimit != null ? g_cvVersusBoomerLimit.IntValue : 0;
		}
		case L4D2ZombieClass_Hunter:
		{
			slotCount = g_cvVersusHunterLimit != null ? g_cvVersusHunterLimit.IntValue : 0;
		}
		case L4D2ZombieClass_Spitter:
		{
			slotCount = g_cvVersusSpitterLimit != null ? g_cvVersusSpitterLimit.IntValue : 0;
		}
		case L4D2ZombieClass_Jockey:
		{
			slotCount = g_cvVersusJockeyLimit != null ? g_cvVersusJockeyLimit.IntValue : 0;
		}
		case L4D2ZombieClass_Charger:
		{
			slotCount = g_cvVersusChargerLimit != null ? g_cvVersusChargerLimit.IntValue : 0;
		}
	}

	if (slotCount < 1)
	{
		return Skills_GetTrackedInfectedEntryCapacity();
	}
	if (slotCount > L4D2_SKILLS_MAX_TRACKED_INFECTED_ENTRIES)
	{
		slotCount = L4D2_SKILLS_MAX_TRACKED_INFECTED_ENTRIES;
	}

	return slotCount;
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
		case WEPID_PISTOL, WEPID_PISTOL_MAGNUM, WEPID_SMG, WEPID_SMG_SILENCED, WEPID_SMG_MP5, WEPID_PUMPSHOTGUN,
			WEPID_AUTOSHOTGUN, WEPID_SHOTGUN_CHROME, WEPID_SHOTGUN_SPAS,WEPID_RIFLE, WEPID_RIFLE_AK47,
			WEPID_RIFLE_DESERT, WEPID_RIFLE_SG552, WEPID_RIFLE_M60,WEPID_HUNTING_RIFLE, WEPID_SNIPER_MILITARY,
			WEPID_SNIPER_AWP, WEPID_SNIPER_SCOUT, WEPID_GRENADE_LAUNCHER, WEPID_MACHINEGUN:
		{
			return true;
		}
	}

	return false;
}

stock int Skills_GetWeaponIdFromEventName(const char[] weaponName)
{
	if (weaponName[0] == '\0')
	{
		return WEPID_NONE;
	}

	if (StrEqual(weaponName, "grenade_launcher_projectile"))
	{
		return WEPID_GRENADE_LAUNCHER;
	}

	int weaponId = L4D2_GetWeaponIdByWeaponName(weaponName);
	if (weaponId != WEPID_NONE)
	{
		return weaponId;
	}

	char prefixed[64];
	FormatEx(prefixed, sizeof(prefixed), "weapon_%s", weaponName);
	weaponId = L4D2_GetWeaponIdByWeaponName(prefixed);
	if (weaponId != WEPID_NONE)
	{
		return weaponId;
	}

	return WeaponNameToId(weaponName);
}

stock int Skills_GetClientActiveWeaponId(int client)
{
	if (!IsValidClient(client))
	{
		return WEPID_NONE;
	}

	int weapon = L4D_GetPlayerCurrentWeapon(client);
	if (weapon <= MaxClients || !IsValidEntity(weapon))
	{
		return WEPID_NONE;
	}

	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	return Skills_GetWeaponIdFromEventName(classname);
}

#include "l4d2_player_skills/event_store.sp"

#include "l4d2_player_skills/identity.sp"

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
	return g_cvSurvivorLimit != null ? g_cvSurvivorLimit.IntValue : L4D2_SKILLS_DEFAULT_SURVIVOR_LIMIT;
}

stock int Skills_GetConfiguredPlayerZombieLimit()
{
	return g_cvMaxPlayerZombies != null ? g_cvMaxPlayerZombies.IntValue : L4D2_SKILLS_DEFAULT_PLAYER_ZOMBIE_LIMIT;
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
 * @brief Returns expected maximum health for a special infected class.
 * @remarks For Tanks, the configured base health is contextualized by base mode
 *          and Coop difficulty. This differs from observed current health.
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
			int baseHealth = g_cvTankHealth != null ? g_cvTankHealth.IntValue : L4D2_SKILLS_DEFAULT_TANK_HEALTH;
			return Skills_ContextualizeTankHealth(baseHealth);
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
 * @brief Returns the configured minimum vertical height for JockeyHighLeap.
 *
 * @return               Configured Jockey high-leap threshold.
 */
stock float Skills_GetJockeyHighLeapHeightThreshold()
{
	return g_cvJockeyHighLeapHeight != null ? g_cvJockeyHighLeapHeight.FloatValue : L4D2_SKILLS_DEFAULT_JOCKEY_HIGH_LEAP_HEIGHT;
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
	if (zombieClass >= L4D2ZombieClass_Smoker && zombieClass <= L4D2ZombieClass_Tank)
	{
		// Left4DHooks stores the class-name table 0-based while the public zombie-class enum starts at 1.
		strcopy(buffer, maxlen, L4D2_GetZombieClassname(view_as<L4D2ZombieClassType>(view_as<int>(zombieClass) - 1)));
		if (buffer[0] != '\0')
		{
			buffer[0] = CharToUpper(buffer[0]);
		}
		return;
	}

	strcopy(buffer, maxlen, "Infected");
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
		case L4D2Skill_JockeyHighLeap: strcopy(buffer, maxlen, "JockeyHighLeap");
		case L4D2Skill_SmokerLedgeHang: strcopy(buffer, maxlen, "SmokerLedgeHang");
		case L4D2Skill_JockeyLedgeHang: strcopy(buffer, maxlen, "JockeyLedgeHang");
		case L4D2Skill_ChargerInstaKill: strcopy(buffer, maxlen, "ChargerInstaKill");
		case L4D2Skill_ChargerDeathSetup: strcopy(buffer, maxlen, "ChargerDeathSetup");
		case L4D2Skill_ChargerLedgeHang: strcopy(buffer, maxlen, "ChargerLedgeHang");
		case L4D2Skill_ChargerBowl: strcopy(buffer, maxlen, "ChargerBowl");
		case L4D2Skill_TankLedgeHang: strcopy(buffer, maxlen, "TankLedgeHang");
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
		case L4D2Skill_JockeySkeet: strcopy(buffer, maxlen, "JockeySkeet");
		case L4D2Skill_WitchCrown: strcopy(buffer, maxlen, "WitchCrown");
		default: strcopy(buffer, maxlen, "None");
	}
}

stock void Skills_GetWeaponDisplayName(int weaponId, char[] buffer, int maxlen)
{
	if (IsValidWeaponId(weaponId))
	{
		strcopy(buffer, maxlen, g_L4D2WeaponDisplayNames[weaponId]);
	}
	else
	{
		strcopy(buffer, maxlen, "Weapon");
	}
}

stock void Skills_GetHitgroupName(int hitgroup, char[] buffer, int maxlen)
{
	switch (hitgroup)
	{
		case HITGROUP_HEAD: strcopy(buffer, maxlen, "head");
		case HITGROUP_CHEST: strcopy(buffer, maxlen, "chest");
		case HITGROUP_STOMACH: strcopy(buffer, maxlen, "stomach");
		case HITGROUP_LEFTARM: strcopy(buffer, maxlen, "left arm");
		case HITGROUP_RIGHTARM: strcopy(buffer, maxlen, "right arm");
		case HITGROUP_LEFTLEG: strcopy(buffer, maxlen, "left leg");
		case HITGROUP_RIGHTLEG: strcopy(buffer, maxlen, "right leg");
		case HITGROUP_GEAR: strcopy(buffer, maxlen, "gear");
		default: strcopy(buffer, maxlen, "generic");
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
			case L4D2Skill_HunterSkeet, L4D2Skill_HunterSkeetMelee, L4D2Skill_HunterDeadstop:
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
			case L4D2Skill_JockeyJumpStop, L4D2Skill_JockeySkeetMelee, L4D2Skill_JockeySkeet:
			{
				zombieClass = L4D2ZombieClass_Jockey;
			}
			case L4D2Skill_ChargerLevel:
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
			case L4D2Skill_TankRockSkeet, L4D2Skill_TankDead:
			{
				zombieClass = L4D2ZombieClass_Tank;
			}
			case L4D2Skill_SpecialPinClear:
			{
				zombieClass = view_as<L4D2ZombieClassType>(g_SkillEvents[eventIndex].zombieClass);
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
			case L4D2Skill_JockeyHighLeap:
			{
				zombieClass = L4D2ZombieClass_Jockey;
			}
			case L4D2Skill_SmokerLedgeHang:
			{
				zombieClass = L4D2ZombieClass_Smoker;
			}
			case L4D2Skill_JockeyLedgeHang:
			{
				zombieClass = L4D2ZombieClass_Jockey;
			}
			case L4D2Skill_BoomerVomitLanded:
			{
				zombieClass = L4D2ZombieClass_Boomer;
			}
			case L4D2Skill_ChargerInstaKill, L4D2Skill_ChargerDeathSetup, L4D2Skill_ChargerLedgeHang, L4D2Skill_ChargerBowl:
			{
				zombieClass = L4D2ZombieClass_Charger;
			}
			case L4D2Skill_TankLedgeHang:
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
		case L4D2Skill_ChargerLevel, L4D2Skill_ChargerInstaKill, L4D2Skill_ChargerDeathSetup, L4D2Skill_ChargerLedgeHang, L4D2Skill_ChargerBowl:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Charger);
		}
		case L4D2Skill_SmokerTongueCut, L4D2Skill_SmokerSelfClear, L4D2Skill_SmokerLedgeHang:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Smoker);
		}
		case L4D2Skill_SmokerKill:
		{
			return Skills_IsZombieClassEnabledInCurrentContext(L4D2ZombieClass_Smoker);
		}
		case L4D2Skill_JockeyHighLeap, L4D2Skill_JockeyJumpStop, L4D2Skill_JockeySkeetMelee, L4D2Skill_JockeySkeet, L4D2Skill_JockeyLedgeHang:
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
		case L4D2Skill_TankLedgeHang:
		{
			return true;
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
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS || g_SkillEvents[eventIndex].id <= 0
		|| g_SkillEvents[eventIndex].pendingPublication)
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
		case L4D2Skill_SmokerSelfClear:
		{
			return (!g_SkillEvents[eventIndex].withShove && g_SkillEvents[eventIndex].headshot) ? 2 : 1;
		}
		case L4D2Skill_SpecialPinClear, L4D2Skill_HunterDeadstop:
		{
			return 1;
		}
		case L4D2Skill_SmokerKill, L4D2Skill_BoomerKill, L4D2Skill_HunterKill,
			L4D2Skill_SpitterKill, L4D2Skill_JockeyKill, L4D2Skill_ChargerKill:
		{
			return g_SkillEvents[eventIndex].headshot ? 2 : 1;
		}
		case L4D2Skill_HunterSkeet:
		{
			if (g_SkillEvents[eventIndex].perfect)
			{
				return 3;
			}

			return g_SkillEvents[eventIndex].assistsCount > 0 ? 1 : 2;
		}
		case L4D2Skill_HunterSkeetMelee:
		{
			if (g_SkillEvents[eventIndex].perfect)
			{
				return 3;
			}

			return g_SkillEvents[eventIndex].assistsCount > 0 ? 1 : 2;
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
		case L4D2Skill_JockeyHighLeap:
		{
			float threshold = Skills_GetJockeyHighLeapHeightThreshold();
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
		case L4D2Skill_JockeySkeet:
		{
			if (g_SkillEvents[eventIndex].perfect)
			{
				return 3;
			}

			return g_SkillEvents[eventIndex].assistsCount > 0 ? 1 : 2;
		}
		case L4D2Skill_JockeySkeetMelee:
		{
			if (g_SkillEvents[eventIndex].perfect)
			{
				return 3;
			}

			return g_SkillEvents[eventIndex].assistsCount > 0 ? 1 : 2;
		}
		case L4D2Skill_SmokerLedgeHang, L4D2Skill_JockeyLedgeHang, L4D2Skill_TankLedgeHang:
		{
			return 2;
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
		case L4D2Skill_ChargerLedgeHang:
		{
			return 2;
		}
		case L4D2Skill_ChargerBowl:
		{
			return g_SkillEvents[eventIndex].amount >= 3 ? 3 : 2;
		}
		case L4D2Skill_WitchCrown:
		{
			return g_SkillEvents[eventIndex].perfect ? 3 : 2;
		}
		case L4D2Skill_TankRockSkeet:
		{
			return 1;
		}
		case L4D2Skill_TankRockHit:
		{
			return 1;
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
