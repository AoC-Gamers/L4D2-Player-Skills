#if defined _l4d2_player_skills_detect_included
	#endinput
#endif
#define _l4d2_player_skills_detect_included

// Main detector coordinator. This file keeps shared runtime state, reset/lifecycle
// flow, and the event wiring that feeds the subdomain-specific detect modules.

// Shared timing and tracking constants.
#define DETECT_SHOTGUN_BLAST_TIME 0.1
#define L4D2_SKILLS_MAX_ROCKS 32
#define L4D2_SKILLS_ROCK_FINALIZE_DELAY 0.1
#define L4D2_SKILLS_DEADSTOP_DOUBLE_TIME 0.2
#define L4D2_SKILLS_CHARGE_TRACK_WINDOW 6.0
#define L4D2_SKILLS_CHARGE_INCAP_WINDOW 12.0
#define L4D2_SKILLS_CHARGE_MAP_RECHECK_WINDOW 0.25
#define L4D2_SKILLS_CHARGE_MIN_MAP_DAMAGE 100
#define L4D2_SKILLS_BOOMER_VOMIT_WINDOW 2.25
#define L4D2_SKILLS_CARALARM_WINDOW 0.11
#define L4D2_SKILLS_HOP_CHECK_TIME 0.1
#define L4D2_SKILLS_HOPEND_CHECK_TIME 0.1
#define L4D2_SKILLS_HOP_ACCEL_THRESH 0.01
#define CARFLAG_INDIRECT        (1 << 0)
#define CARFLAG_FORCED          (1 << 1)

// Charger insta-kill / death-setup state flags.
#define DCFLAG_FALL            (1 << 0)
#define DCFLAG_DROWN           (1 << 1)
#define DCFLAG_TRIGGER         (1 << 2)
#define DCFLAG_HURTLOTS        (1 << 3)
#define DCFLAG_AIRDEATH        (1 << 4)
#define DCFLAG_KILLEDBYOTHER   (1 << 5)
#define DCFLAG_DEADLY          (1 << 6)
#define DCFLAG_INCAP           (1 << 7)
#define DCFLAG_LEDGE           (1 << 8)

/**
 * @brief Runtime track for one Tank rock entity.
 */
enum struct DetectRockTrack
{
	bool active;
	int entityRef;
	L4D2PlayerRef tank;
	int totalDamage;
	int lastShooter;
	bool touched;
	bool hit;
	bool finalizeQueued;
	float releasedAt;

	/**
	 * @brief Clears the tracked rock state.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.active = false;
		this.entityRef = INVALID_ENT_REFERENCE;
		this.tank.Reset();
		this.totalDamage = 0;
		this.lastShooter = 0;
		this.touched = false;
		this.hit = false;
		this.finalizeQueued = false;
		this.releasedAt = 0.0;
	}
}

/**
 * @brief Per-client Boomer state used for pop and vomit tracking.
 */
enum struct DetectBoomerState
{
	float spawnTime;
	bool hitSomebody;
	int shoveCount;
	int vomitHits;

	/**
	 * @brief Clears the tracked Boomer runtime state.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.spawnTime = 0.0;
		this.hitSomebody = false;
		this.shoveCount = 0;
		this.vomitHits = 0;
	}
}

/**
 * @brief Per-client bunny-hop streak state.
 */
enum struct DetectHopState
{
	bool isHopping;
	bool hopCheck;
	int hops;
	float lastHop[3];
	float topVelocity;

	/**
	 * @brief Clears the tracked hop runtime state.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.isHopping = false;
		this.hopCheck = false;
		this.hops = 0;
		this.lastHop[0] = 0.0;
		this.lastHop[1] = 0.0;
		this.lastHop[2] = 0.0;
		this.topVelocity = 0.0;
	}
}

/**
 * @brief Per-client leap origin snapshot for Hunter and Jockey skills.
 */
enum struct DetectLeapState
{
	bool originSet;
	float origin[3];

	/**
	 * @brief Clears the tracked leap origin state.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.originSet = false;
		this.origin[0] = 0.0;
		this.origin[1] = 0.0;
		this.origin[2] = 0.0;
	}
}

/**
 * @brief Per-client Smoker control state tied to one victim.
 */
enum struct DetectSmokerState
{
	int victim;
	bool reached;
	bool shoved;

	/**
	 * @brief Clears the tracked Smoker runtime state.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.victim = 0;
		this.reached = false;
		this.shoved = false;
	}
}

/**
 * @brief Last-damage snapshot used to classify Hunter and Charger kill events.
 */
enum struct DetectDamageSnapshot
{
	int lastHealth;
	int lastAttacker;
	int lastDamageType;
	int lastHealthBeforeDamage;
	float lastRawDamage;

	/**
	 * @brief Clears the tracked damage snapshot.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.lastHealth = 0;
		this.lastAttacker = 0;
		this.lastDamageType = 0;
		this.lastHealthBeforeDamage = 0;
		this.lastRawDamage = 0.0;
	}
}

/**
 * @brief Per-survivor Charger victim state used across carry, incap and death flow.
 */
enum struct DetectChargeVictimState
{
	int charger;
	bool wasCarried;
	bool setupEmitted;
	float startTime;
	float startOrigin[3];
	int flags;
	int mapDamage;
	float lastMapDamageTime;
	float incapTime;

	/**
	 * @brief Clears the tracked Charger victim state.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.charger = 0;
		this.wasCarried = false;
		this.setupEmitted = false;
		this.startTime = 0.0;
		this.startOrigin[0] = 0.0;
		this.startOrigin[1] = 0.0;
		this.startOrigin[2] = 0.0;
		this.flags = 0;
		this.mapDamage = 0;
		this.lastMapDamageTime = 0.0;
		this.incapTime = 0.0;
	}
}

// Shared detector runtime state.
DetectBoomerState g_DetectBoomer[MAXPLAYERS + 1];
DetectHopState g_DetectHop[MAXPLAYERS + 1];
DetectLeapState g_DetectLeap[MAXPLAYERS + 1];
DetectSmokerState g_DetectSmoker[MAXPLAYERS + 1];
DetectDamageSnapshot g_DetectHunterDamageSnapshot[MAXPLAYERS + 1];
DetectDamageSnapshot g_DetectChargerDamageSnapshot[MAXPLAYERS + 1];
DetectChargeVictimState g_DetectChargeVictim[MAXPLAYERS + 1];
int g_iDetectPinnedVictim[MAXPLAYERS + 1];
int g_iDetectPinnerByVictim[MAXPLAYERS + 1];
int g_iDetectPinnedClass[MAXPLAYERS + 1];
float g_fDetectSpecialClearTimeA[MAXPLAYERS + 1];
float g_fDetectSpecialClearTimeB[MAXPLAYERS + 1];

bool g_bDetectHunterPouncing[MAXPLAYERS + 1];
bool g_bDetectClientDamageHooked[MAXPLAYERS + 1];
bool g_bDetectShotCounted[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_fDetectHunterLastShove[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDetectHunterSpawnHealth[MAXPLAYERS + 1];
int g_iDetectSmokerOwnerByVictim[MAXPLAYERS + 1];
int g_iDetectHunterDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDetectHunterShots[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDetectHunterShotDmgTeam[MAXPLAYERS + 1];
int g_iDetectHunterShotDmg[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_fDetectHunterShotStart[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDetectHunterOverkill[MAXPLAYERS + 1];
bool g_bDetectHunterKilledPouncing[MAXPLAYERS + 1];
DetectRockTrack g_DetectRocks[L4D2_SKILLS_MAX_ROCKS];
StringMap g_smDetectCarAlarmTargets = null;
StringMap g_smDetectCarGlassParents = null;
StringMap g_smDetectCarPendingSurvivor = null;
StringMap g_smDetectCarPendingReason = null;
StringMap g_smDetectCarPendingInfected = null;
StringMap g_smDetectCarPendingFlags = null;
ConVar g_cvDetectPounceInterrupt = null;
ConVar g_cvDetectMaxPounceDistance = null;
ConVar g_cvDetectMinPounceDistance = null;
ConVar g_cvDetectInstaKillHeight = null;
ConVar g_cvDetectDeathSetupHeight = null;
ConVar g_cvDetectBHopMinStreak = null;
ConVar g_cvDetectBHopMinInitSpeed = null;
ConVar g_cvDetectBHopContSpeed = null;
float g_fDetectLastCarAlarm = 0.0;

// Initialization and reset.
void Detect_Init()
{
	g_smDetectCarAlarmTargets = new StringMap();
	g_smDetectCarGlassParents = new StringMap();
	g_smDetectCarPendingSurvivor = new StringMap();
	g_smDetectCarPendingReason = new StringMap();
	g_smDetectCarPendingInfected = new StringMap();
	g_smDetectCarPendingFlags = new StringMap();
	g_cvDetectPounceInterrupt = FindConVar("z_pounce_damage_interrupt");
	g_cvDetectMaxPounceDistance = FindConVar("z_pounce_damage_range_max");
	g_cvDetectMinPounceDistance = FindConVar("z_pounce_damage_range_min");
	g_cvDetectInstaKillHeight = CreateConVar("l4d2_player_skills_charger_instakill_height", "400", "Minimum vertical drop for ChargerInstaKill.");
	g_cvDetectDeathSetupHeight = CreateConVar("l4d2_player_skills_charger_death_setup_height", "100", "Minimum vertical drop for ChargerDeathSetup incap classification.");
	g_cvDetectBHopMinStreak = CreateConVar("l4d2_player_skills_bhop_streak_min", "3", "Minimum amount of successful hops for BunnyHopStreak.");
	g_cvDetectBHopMinInitSpeed = CreateConVar("l4d2_player_skills_bhop_init_speed", "150", "Minimum initial jump speed to start tracking BunnyHopStreak.");
	g_cvDetectBHopContSpeed = CreateConVar("l4d2_player_skills_bhop_keep_speed", "300", "Minimum speed that keeps a hop streak even without acceleration.");
	Detect_ResetAll();
}

void Detect_ResetAll()
{
	Detect_ResetRocks();
	if (g_smDetectCarAlarmTargets != null)
	{
		g_smDetectCarAlarmTargets.Clear();
	}
	if (g_smDetectCarGlassParents != null)
	{
		g_smDetectCarGlassParents.Clear();
	}
	if (g_smDetectCarPendingSurvivor != null)
	{
		g_smDetectCarPendingSurvivor.Clear();
	}
	if (g_smDetectCarPendingReason != null)
	{
		g_smDetectCarPendingReason.Clear();
	}
	if (g_smDetectCarPendingInfected != null)
	{
		g_smDetectCarPendingInfected.Clear();
	}
	if (g_smDetectCarPendingFlags != null)
	{
		g_smDetectCarPendingFlags.Clear();
	}
	g_fDetectLastCarAlarm = 0.0;

	for (int client = 1; client <= MaxClients; client++)
	{
		g_DetectBoomer[client].Reset();
		g_DetectHop[client].Reset();
		g_DetectLeap[client].Reset();
		g_iDetectPinnedVictim[client] = 0;
		g_iDetectPinnerByVictim[client] = 0;
		g_iDetectPinnedClass[client] = 0;
		g_fDetectSpecialClearTimeA[client] = -1.0;
		g_fDetectSpecialClearTimeB[client] = -1.0;
		g_bDetectHunterPouncing[client] = false;
		g_bDetectClientDamageHooked[client] = false;
		g_iDetectHunterSpawnHealth[client] = 0;
		g_DetectHunterDamageSnapshot[client].Reset();
		g_DetectChargerDamageSnapshot[client].Reset();
		g_DetectChargeVictim[client].Reset();
		g_DetectSmoker[client].Reset();
		g_iDetectSmokerOwnerByVictim[client] = 0;
		g_iDetectHunterShotDmgTeam[client] = 0;
		g_iDetectHunterOverkill[client] = 0;
		g_bDetectHunterKilledPouncing[client] = false;

		for (int attacker = 1; attacker <= MaxClients; attacker++)
		{
			g_bDetectShotCounted[client][attacker] = false;
			g_fDetectHunterLastShove[client][attacker] = 0.0;
			g_iDetectHunterDamage[client][attacker] = 0;
			g_iDetectHunterShots[client][attacker] = 0;
			g_iDetectHunterShotDmg[client][attacker] = 0;
			g_fDetectHunterShotStart[client][attacker] = 0.0;
		}
	}
}

void Detect_ResetRocks()
{
	for (int slot = 0; slot < L4D2_SKILLS_MAX_ROCKS; slot++)
	{
		g_DetectRocks[slot].Reset();
	}
}

// Client lifecycle.
void Detect_OnClientPutInServer(int client)
{
	if (client <= 0 || client > MaxClients)
	{
		return;
	}

	if (!g_bDetectClientDamageHooked[client])
	{
		SDKHook(client, SDKHook_OnTakeDamage, Detect_OnTakeDamage_Client);
		SDKHook(client, SDKHook_OnTakeDamagePost, Detect_OnTakeDamagePost_Client);
		g_bDetectClientDamageHooked[client] = true;
	}

	Detect_ResetBoomer(client);
	Detect_ResetBHop(client);
	Detect_ResetHunter(client);
	Detect_ResetCharger(client);
	Detect_ResetChargeTrack(client);
	Detect_ResetSmoker(client);
	Detect_ClearSmokerVictim(client);

	for (int victim = 1; victim <= MaxClients; victim++)
	{
		g_bDetectShotCounted[victim][client] = false;
		g_fDetectHunterLastShove[victim][client] = 0.0;
		g_iDetectHunterDamage[victim][client] = 0;
		g_iDetectHunterShots[victim][client] = 0;
		g_iDetectHunterShotDmg[victim][client] = 0;
		g_fDetectHunterShotStart[victim][client] = 0.0;
	}
}

void Detect_OnClientDisconnect(int client)
{
	if (client > 0 && client <= MaxClients && g_bDetectClientDamageHooked[client])
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, Detect_OnTakeDamage_Client);
		SDKUnhook(client, SDKHook_OnTakeDamagePost, Detect_OnTakeDamagePost_Client);
		g_bDetectClientDamageHooked[client] = false;
	}

	Detect_ClearPinStateByAttacker(client);
	Detect_ClearPinStateByVictim(client);
	Detect_ResetBoomer(client);
	Detect_ResetBHop(client);
	Detect_ResetHunter(client);
	Detect_ResetCharger(client);
	Detect_ResetChargeTrack(client);
	Detect_ResetSmoker(client);
	Detect_ClearSmokerVictim(client);

	for (int victim = 1; victim <= MaxClients; victim++)
	{
		g_bDetectShotCounted[victim][client] = false;
		g_fDetectHunterLastShove[victim][client] = 0.0;
		g_iDetectHunterDamage[victim][client] = 0;
		g_iDetectHunterShots[victim][client] = 0;
		g_iDetectHunterShotDmg[victim][client] = 0;
		g_fDetectHunterShotStart[victim][client] = 0.0;
	}
}

// Entity lifecycle and engine hooks.
void Detect_OnEntityCreated(int entity, const char[] classname)
{
	if (entity <= MaxClients)
	{
		return;
	}

	if (StrEqual(classname, "prop_car_alarm"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, Detect_OnTakeDamage_CarAlarm);
		SDKHook(entity, SDKHook_Touch, Detect_OnTouch_CarAlarm);
		SDKHook(entity, SDKHook_Spawn, Detect_OnSpawn_CarAlarm);
		return;
	}

	if (StrEqual(classname, "prop_car_glass"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, Detect_OnTakeDamage_CarGlass);
		SDKHook(entity, SDKHook_Touch, Detect_OnTouch_CarGlass);
		SDKHook(entity, SDKHook_Spawn, Detect_OnSpawn_CarGlass);
	}
}

// left4dhooks callbacks that feed shared state before delegating to submodules.
void Detect_OnGrabWithTonguePost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(victim) || !IsValidZombieClass(attacker, L4D2ZombieClass_Smoker))
	{
		return;
	}

	Detect_ResetSmoker(attacker);
	Detect_ClearSmokerVictim(victim);

	g_DetectSmoker[attacker].victim = victim;
	g_iDetectSmokerOwnerByVictim[victim] = attacker;
	g_DetectSmoker[attacker].reached = false;
	g_DetectSmoker[attacker].shoved = false;
	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Smoker, -1.0, GetGameTime());
}

void Detect_OnPouncedOnSurvivorPost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Hunter) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Hunter, -1.0, -1.0);

	float height = Detect_GetLeapHeight(attacker, victim);
	float threshold = g_cvHunterHighPounceHeight != null ? g_cvHunterHighPounceHeight.FloatValue : L4D2_SKILLS_DEFAULT_HUNTER_HIGH_POUNCE_HEIGHT;
	float distance = Detect_GetLeapDistance(attacker, victim);
	float calculatedDamage = Detect_CalculateHunterPounceDamage(distance);
	bool incapped = L4D_IsPlayerIncapacitated(victim);
	bool reportedHigh = height >= threshold;

	if (reportedHigh)
	{
		int eventId = Skills_CreateEvent(L4D2Skill_HunterHighPounce);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(attacker);
			g_SkillEvents[eventIndex].victim.Capture(victim);
			g_SkillEvents[eventIndex].damage = RoundToFloor(calculatedDamage);
			g_SkillEvents[eventIndex].calculatedDamage = calculatedDamage;
			g_SkillEvents[eventIndex].distance = distance;
			g_SkillEvents[eventIndex].height = height;
			g_SkillEvents[eventIndex].reportedHigh = true;
			g_SkillEvents[eventIndex].incapped = incapped;

			Action result = API_FireSkillDetected(eventId, L4D2Skill_HunterHighPounce);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}

	g_bDetectHunterPouncing[attacker] = false;
	g_DetectLeap[attacker].Reset();
}

void Detect_OnJockeyRidePost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Jockey) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Jockey, -1.0, -1.0);
}

void Detect_OnStartCarryingVictimPost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Charger) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_RecordChargeVictim(attacker, victim, true);
	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Charger, -1.0, GetGameTime());
}

void Detect_OnSlammedSurvivorPost(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge)
{
	if (bWallSlam)
	{
		// Wall slams do not currently change the emitted skill classification.
	}

	if (!Skills_IsEnabled() || !IsValidSurvivor(victim) || !IsValidZombieClass(attacker, L4D2ZombieClass_Charger))
	{
		return;
	}

	if (g_DetectChargeVictim[victim].charger != attacker)
	{
		return;
	}

	if (bDeadlyCharge)
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_DEADLY;
	}
}

void Detect_OnFatalFalling(int client)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_DetectChargeVictim[client].charger <= 0)
	{
		return;
	}

	g_DetectChargeVictim[client].flags |= DCFLAG_FALL;
}

void Detect_OnFalling(int client)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_DetectChargeVictim[client].charger <= 0)
	{
		return;
	}

	g_DetectChargeVictim[client].flags |= DCFLAG_FALL;
}

void Detect_OnLedgeGrabbedPost(int client)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_DetectChargeVictim[client].charger <= 0)
	{
		return;
	}

	g_DetectChargeVictim[client].flags |= DCFLAG_LEDGE;
	Detect_EmitChargerDeathSetup(client, false, true);
}

void Detect_OnIncapacitatedPost(int client, int attacker, int damagetype)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_DetectChargeVictim[client].charger <= 0)
	{
		return;
	}

	if (attacker > 0 && attacker != g_DetectChargeVictim[client].charger)
	{
		return;
	}

	g_DetectChargeVictim[client].flags |= DCFLAG_INCAP;
	g_DetectChargeVictim[client].incapTime = GetGameTime();

	if (damagetype & DMG_FALL)
	{
		g_DetectChargeVictim[client].flags |= DCFLAG_FALL;
	}

	if (L4D_IsPlayerHangingFromLedge(client))
	{
		g_DetectChargeVictim[client].flags |= DCFLAG_LEDGE;
	}

	Detect_EmitChargerDeathSetup(client, true, (g_DetectChargeVictim[client].flags & DCFLAG_LEDGE) != 0);
}

void Detect_EventPlayerIncapacitatedStart(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(victim) || g_DetectChargeVictim[victim].charger <= 0)
	{
		return;
	}

	g_DetectChargeVictim[victim].flags |= DCFLAG_INCAP;
	g_DetectChargeVictim[victim].incapTime = GetGameTime();

	if (L4D_IsPlayerHangingFromLedge(victim))
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_LEDGE;
	}

	Detect_EmitChargerDeathSetup(victim, true, (g_DetectChargeVictim[victim].flags & DCFLAG_LEDGE) != 0);
}

void Detect_OnPummelVictimPost(int attacker, int victim)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Charger) || !IsValidSurvivor(victim))
	{
		return;
	}

	if (g_iDetectPinnedVictim[attacker] != victim)
	{
		Detect_SetPinState(attacker, victim, L4D2ZombieClass_Charger, GetGameTime(), GetGameTime());
		return;
	}

	g_fDetectSpecialClearTimeA[attacker] = GetGameTime();
	if (g_fDetectSpecialClearTimeB[attacker] < 0.0)
	{
		g_fDetectSpecialClearTimeB[attacker] = GetGameTime();
	}
}

void Detect_EventChargerImpact(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int charger = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_RecordChargeVictim(charger, victim, false);
}

void Detect_EventChargerCarryEnd(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int charger = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		return;
	}

	int victim = g_iDetectPinnedVictim[charger];
	if (!IsValidSurvivor(victim))
	{
		return;
	}

	g_fDetectSpecialClearTimeB[charger] = GetGameTime();
}

void Detect_OnEntityShovedPost(int client, int entity, int weapon, const float vecDir[3], bool bIsHighPounce)
{
	if (weapon < 0 || vecDir[0] > 999999.0)
	{
		return;
	}

	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || !IsValidZombieClass(entity, L4D2ZombieClass_Hunter))
	{
		return;
	}

	if (!g_bDetectHunterPouncing[entity] && !bIsHighPounce)
	{
		return;
	}

	float now = GetGameTime();
	if (now - g_fDetectHunterLastShove[entity][client] <= L4D2_SKILLS_DEADSTOP_DOUBLE_TIME)
	{
		return;
	}

	g_fDetectHunterLastShove[entity][client] = now;
	g_bDetectHunterPouncing[entity] = false;

	int eventId = Skills_CreateEvent(L4D2Skill_HunterDeadstop);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(client);
	g_SkillEvents[eventIndex].victim.Capture(entity);
	g_SkillEvents[eventIndex].withShove = true;
	g_SkillEvents[eventIndex].reportedHigh = bIsHighPounce;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_HunterDeadstop);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_OnRoundStart()
{
	Detect_ResetAll();
}

void Detect_OnRoundEnd()
{
}

void Detect_OnEntityDestroyed(int entity)
{
	Detect_RemoveCarAlarmTracking(entity);
	Detect_QueueRockFinalize(entity);
}

void Detect_EventPlayerHurt(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("dmg_health");
	int damageType = event.GetInt("type");

	if (IsValidSurvivor(victim) && g_DetectChargeVictim[victim].charger > 0 && damage > 0)
	{
		bool byTrigger = false;
		char weapon[32];
		event.GetString("weapon", weapon, sizeof(weapon));
		if (StrEqual(weapon, "trigger_hurt"))
		{
			byTrigger = true;
		}

		if (!IsValidInfected(attacker))
		{
			Detect_MarkChargeMapDamage(victim, damage, damageType, byTrigger);
		}
		else if (attacker != g_DetectChargeVictim[victim].charger)
		{
			g_DetectChargeVictim[victim].flags |= DCFLAG_KILLEDBYOTHER;
		}

		if (L4D_IsPlayerHangingFromLedge(victim))
		{
			g_DetectChargeVictim[victim].flags |= DCFLAG_LEDGE;
		}
	}

	if (!IsValidZombieClass(victim, L4D2ZombieClass_Hunter) || !IsValidSurvivor(attacker))
	{
		if (IsValidSurvivor(victim) && IsValidTank(attacker))
		{
			char weapon[32];
			event.GetString("weapon", weapon, sizeof(weapon));
			if (StrEqual(weapon, "tank_rock"))
			{
				Detect_MarkTankRockHit(attacker, victim);
			}
		}

		return;
	}
}

void Detect_EventPlayerDeath(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsValidSurvivor(victim))
	{
		if (g_DetectChargeVictim[victim].charger > 0 && !L4D_IsPlayerIncapacitated(victim))
		{
			g_DetectChargeVictim[victim].flags |= DCFLAG_AIRDEATH;
		}

		Detect_CheckChargerInstaKill(event, victim);
		Detect_ClearPinStateByVictim(victim);
	}

	if (Detect_IsPinnedClass(victim))
	{
		if (Detect_IsValidTeamClear(attacker, victim))
		{
			Detect_EmitSpecialClear(attacker, victim, false);
		}
		else
		{
			Detect_ClearPinStateByAttacker(victim);
		}
	}

	if (IsValidZombieClass(victim, L4D2ZombieClass_Smoker))
	{
		if (IsValidSurvivor(attacker)
			&& g_DetectSmoker[victim].victim == attacker
			&& g_DetectSmoker[victim].reached)
		{
			int eventId = Skills_CreateEvent(L4D2Skill_SmokerSelfClear);
			int eventIndex = Skills_GetEventIndex(eventId);
			if (eventIndex != -1)
			{
				g_SkillEvents[eventIndex].actor.Capture(attacker);
				g_SkillEvents[eventIndex].victim.Capture(victim);
				g_SkillEvents[eventIndex].withShove = false;

				Action result = API_FireSkillDetected(eventId, L4D2Skill_SmokerSelfClear);
				if (result < Plugin_Handled)
				{
					Announce_Skill(eventId);
				}
			}
		}

		Detect_ClearPinStateByAttacker(victim);
		Detect_ResetSmoker(victim);
		return;
	}

	if (!IsValidZombieClass(victim, L4D2ZombieClass_Hunter))
	{
		return;
	}

	if (IsValidSurvivor(attacker))
	{
		char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));
		bool headshot = event.GetBool("headshot");
		int hunterHealthBeforeDamage = g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage > 0
			? g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage
			: g_DetectHunterDamageSnapshot[victim].lastHealth;
		int hunterBaselineHealth = g_iDetectHunterSpawnHealth[victim] > 0
			? g_iDetectHunterSpawnHealth[victim]
			: hunterHealthBeforeDamage;
		int chipDamage = hunterBaselineHealth - hunterHealthBeforeDamage;
		if (chipDamage < 0)
		{
			chipDamage = 0;
		}

		float rawDamage = g_DetectHunterDamageSnapshot[victim].lastRawDamage;
		if (g_DetectHunterDamageSnapshot[victim].lastAttacker != attacker)
		{
			rawDamage = float(hunterHealthBeforeDamage);
		}

		bool killedPouncing = g_bDetectHunterKilledPouncing[victim] || g_bDetectHunterPouncing[victim];

		if (killedPouncing && Detect_IsSkeetWeaponMelee(weapon))
		{
			int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeetMelee);
			int eventIndex = Skills_GetEventIndex(eventId);
			if (eventIndex != -1)
			{
				g_SkillEvents[eventIndex].actor.Capture(attacker);
				g_SkillEvents[eventIndex].victim.Capture(victim);
				g_SkillEvents[eventIndex].damage = hunterHealthBeforeDamage;
				g_SkillEvents[eventIndex].chipDamage = chipDamage;
				g_SkillEvents[eventIndex].shots = 1;
				g_SkillEvents[eventIndex].wouldQualifyAtBaseline = true;
				g_SkillEvents[eventIndex].perfect = (chipDamage == 0);
				g_SkillEvents[eventIndex].headshot = headshot;

				Action meleeResult = API_FireSkillDetected(eventId, L4D2Skill_HunterSkeetMelee);
				if (meleeResult < Plugin_Handled)
				{
					Announce_Skill(eventId);
				}
			}

			Detect_ResetHunter(victim);
			return;
		}

		bool sniperSkeet = killedPouncing && headshot && Detect_IsSkeetWeaponSniper(weapon);
		bool glSkeet = killedPouncing && Detect_IsSkeetWeaponGL(weapon);
		if (sniperSkeet || glSkeet)
		{
			bool qualifiesAtBaseline = rawDamage >= float(hunterBaselineHealth);
			if (qualifiesAtBaseline)
			{
				int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeet);
				int eventIndex = Skills_GetEventIndex(eventId);
				if (eventIndex != -1)
				{
					g_SkillEvents[eventIndex].actor.Capture(attacker);
					g_SkillEvents[eventIndex].victim.Capture(victim);
					g_SkillEvents[eventIndex].damage = hunterHealthBeforeDamage;
					g_SkillEvents[eventIndex].chipDamage = chipDamage;
					g_SkillEvents[eventIndex].shots = 1;
					g_SkillEvents[eventIndex].wouldQualifyAtBaseline = chipDamage > 0;
					g_SkillEvents[eventIndex].perfect = (chipDamage == 0);
					g_SkillEvents[eventIndex].headshot = headshot;
					g_SkillEvents[eventIndex].sniper = sniperSkeet;
					g_SkillEvents[eventIndex].grenadeLauncher = glSkeet;

					Action rangedResult = API_FireSkillDetected(eventId, L4D2Skill_HunterSkeet);
					if (rangedResult < Plugin_Handled)
					{
						Announce_Skill(eventId);
					}
				}
			}

			Detect_ResetHunter(victim);
			return;
		}

		if (g_bDetectHunterKilledPouncing[victim] && g_iDetectHunterShotDmgTeam[victim] > 0)
		{
			int interruptDamage = g_cvDetectPounceInterrupt != null ? g_cvDetectPounceInterrupt.IntValue : 150;
			int killerDamage = g_iDetectHunterShotDmg[victim][attacker];
			int teamDamage = g_iDetectHunterShotDmgTeam[victim];
			int shots = g_iDetectHunterShots[victim][attacker];
			int overkillDamage = g_iDetectHunterOverkill[victim];
			int potentialKillerDamage = killerDamage + overkillDamage;
			int potentialTeamDamage = teamDamage + overkillDamage;
			bool isSingleSkeet = potentialKillerDamage >= interruptDamage;
			bool isTeamSkeet = potentialTeamDamage > potentialKillerDamage && potentialTeamDamage >= interruptDamage;
			bool isOverkill = overkillDamage > 0 && (isSingleSkeet || isTeamSkeet);

			if (!isSingleSkeet && !isTeamSkeet)
			{
				Detect_ResetHunter(victim);
				return;
			}

			int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeet);
			int eventIndex = Skills_GetEventIndex(eventId);
			if (eventIndex != -1)
			{
				g_SkillEvents[eventIndex].actor.Capture(attacker);
				g_SkillEvents[eventIndex].victim.Capture(victim);
				g_SkillEvents[eventIndex].damage = isTeamSkeet ? potentialTeamDamage : potentialKillerDamage;
				g_SkillEvents[eventIndex].shots = shots;
				g_SkillEvents[eventIndex].wouldQualifyAtBaseline = isOverkill;
				g_SkillEvents[eventIndex].chipDamage = g_iDetectHunterDamage[victim][attacker] - killerDamage;
				g_SkillEvents[eventIndex].perfect = shots == 1 && g_SkillEvents[eventIndex].chipDamage == 0 && !isTeamSkeet;
				g_SkillEvents[eventIndex].headshot = headshot;

				if (isTeamSkeet)
				{
					int topAssister = 0;
					int topAssistDamage = 0;
					for (int i = 1; i <= MaxClients; i++)
					{
						if (i == attacker || !IsValidSurvivor(i))
						{
							continue;
						}

						if (g_iDetectHunterShotDmg[victim][i] > topAssistDamage)
						{
							topAssistDamage = g_iDetectHunterShotDmg[victim][i];
							topAssister = i;
						}
					}

					if (topAssister > 0)
					{
						g_SkillEvents[eventIndex].assister.Capture(topAssister);
					}
				}

				Action result = API_FireSkillDetected(eventId, g_SkillEvents[eventIndex].type);
				if (result < Plugin_Handled)
				{
					Announce_Skill(eventId);
				}
			}
		}
	}

	Detect_ResetHunter(victim);
}

void Detect_EventPlayerSpawn(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(client, L4D2ZombieClass_Boomer))
	{
		if (IsValidSurvivor(client))
		{
			Detect_ResetBHop(client);
		}

		if (IsValidZombieClass(client, L4D2ZombieClass_Hunter))
		{
			Detect_ResetHunter(client);
			g_iDetectHunterSpawnHealth[client] = GetClientHealth(client);
			g_DetectHunterDamageSnapshot[client].lastHealth = g_iDetectHunterSpawnHealth[client];
		}
		else if (IsValidZombieClass(client, L4D2ZombieClass_Charger))
		{
			g_DetectChargerDamageSnapshot[client].lastHealth = GetClientHealth(client);
		}

		return;
	}

	g_DetectBoomer[client].spawnTime = GetGameTime();
	g_DetectBoomer[client].hitSomebody = false;
	g_DetectBoomer[client].shoveCount = 0;
	g_DetectBoomer[client].vomitHits = 0;
}

void Detect_EventPlayerShoved(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker) || !IsValidInfected(victim))
	{
		return;
	}

	if (IsValidZombieClass(victim, L4D2ZombieClass_Boomer))
	{
		g_DetectBoomer[victim].shoveCount++;
	}
	else if (Detect_IsPinnedClass(victim) && Detect_IsValidTeamClear(attacker, victim))
	{
		Detect_EmitSpecialClear(attacker, victim, true);
	}
	else if (IsValidZombieClass(victim, L4D2ZombieClass_Smoker)
		&& g_DetectSmoker[victim].victim == attacker
		&& g_DetectSmoker[victim].reached)
	{
		g_DetectSmoker[victim].shoved = true;
	}
}

void Detect_EventPlayerNowIt(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!event.GetBool("by_boomer") || !IsValidZombieClass(attacker, L4D2ZombieClass_Boomer))
	{
		return;
	}

	g_DetectBoomer[attacker].hitSomebody = true;

	if (!event.GetBool("exploded"))
	{
		if (g_DetectBoomer[attacker].vomitHits == 0)
		{
			CreateTimer(L4D2_SKILLS_BOOMER_VOMIT_WINDOW, Detect_TimerBoomerVomitCheck, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
		}

		g_DetectBoomer[attacker].vomitHits++;
	}
}

void Detect_EventBoomerExploded(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int boomer = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(boomer, L4D2ZombieClass_Boomer))
	{
		return;
	}

	if (event.GetBool("splashedbile") || g_DetectBoomer[boomer].hitSomebody)
	{
		if (g_DetectBoomer[boomer].vomitHits > 0)
		{
			Detect_EmitBoomerVomitLanded(boomer, g_DetectBoomer[boomer].vomitHits);
		}

		Detect_ResetBoomer(boomer);
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker))
	{
		return;
	}

	float timeAlive = g_DetectBoomer[boomer].spawnTime > 0.0 ? (GetGameTime() - g_DetectBoomer[boomer].spawnTime) : 0.0;
	int eventId = Skills_CreateEvent(L4D2Skill_BoomerPop);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(attacker);
	g_SkillEvents[eventIndex].victim.Capture(boomer);
	g_SkillEvents[eventIndex].shoveCount = g_DetectBoomer[boomer].shoveCount;
	g_SkillEvents[eventIndex].timeA = timeAlive;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_BoomerPop);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	Detect_ResetBoomer(boomer);
}

void Detect_EventTriggeredCarAlarm()
{
	g_fDetectLastCarAlarm = GetGameTime();
}

void Detect_EventWeaponFire(Event event)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(attacker))
	{
		return;
	}

	for (int victim = 1; victim <= MaxClients; victim++)
	{
		g_bDetectShotCounted[victim][attacker] = false;
	}
}

// Client damage snapshots used by Hunter/Charger classification flows.
Action Detect_OnTakeDamage_Client(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!Skills_IsEnabled() || !IsValidInfected(victim))
	{
		return Plugin_Continue;
	}

	L4D2ZombieClassType zombieClass = L4D2_GetPlayerZombieClass(victim);
	if (zombieClass == L4D2ZombieClass_Hunter)
	{
		g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage = GetClientHealth(victim);
		g_DetectHunterDamageSnapshot[victim].lastAttacker = attacker;
		g_DetectHunterDamageSnapshot[victim].lastDamageType = damagetype;
		g_DetectHunterDamageSnapshot[victim].lastRawDamage = damage;
	}
	else if (zombieClass == L4D2ZombieClass_Charger)
	{
		g_DetectChargerDamageSnapshot[victim].lastHealthBeforeDamage = GetClientHealth(victim);
		g_DetectChargerDamageSnapshot[victim].lastAttacker = attacker;
		g_DetectChargerDamageSnapshot[victim].lastDamageType = damagetype;
		g_DetectChargerDamageSnapshot[victim].lastRawDamage = damage;
	}

	return Plugin_Continue;
}

void Detect_OnTakeDamagePost_Client(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if (!Skills_IsEnabled() || !IsValidInfected(victim))
	{
		return;
	}

	L4D2ZombieClassType zombieClass = L4D2_GetPlayerZombieClass(victim);
	if (zombieClass == L4D2ZombieClass_Hunter)
	{
		g_DetectHunterDamageSnapshot[victim].lastAttacker = attacker;
		g_DetectHunterDamageSnapshot[victim].lastDamageType = damagetype;
		g_DetectHunterDamageSnapshot[victim].lastRawDamage = damage;

		if (!IsValidSurvivor(attacker))
		{
			return;
		}

		int appliedDamage = RoundToFloor(damage);
		if (appliedDamage <= 0)
		{
			return;
		}

		if (!g_bDetectShotCounted[victim][attacker])
		{
			g_iDetectHunterShots[victim][attacker]++;
			g_bDetectShotCounted[victim][attacker] = true;
		}

		int healthBeforeDamage = g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage > 0
			? g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage
			: g_DetectHunterDamageSnapshot[victim].lastHealth;
		if (healthBeforeDamage > 0 && appliedDamage > healthBeforeDamage)
		{
			g_iDetectHunterOverkill[victim] = appliedDamage - healthBeforeDamage;
			appliedDamage = healthBeforeDamage;
		}

		if (g_iDetectHunterShotDmg[victim][attacker] > 0
			&& (GetGameTime() - g_fDetectHunterShotStart[victim][attacker]) > DETECT_SHOTGUN_BLAST_TIME)
		{
			g_iDetectHunterShotDmg[victim][attacker] = 0;
			g_fDetectHunterShotStart[victim][attacker] = 0.0;
		}

		int postHealth = GetClientHealth(victim);
		if (g_bDetectHunterPouncing[victim] && (damagetype & DMG_BUCKSHOT))
		{
			if (g_fDetectHunterShotStart[victim][attacker] == 0.0)
			{
				g_fDetectHunterShotStart[victim][attacker] = GetGameTime();
			}

			g_iDetectHunterShotDmg[victim][attacker] += appliedDamage;
			g_iDetectHunterShotDmgTeam[victim] += appliedDamage;

			if (postHealth <= 0)
			{
				g_bDetectHunterKilledPouncing[victim] = true;
			}
		}

		g_iDetectHunterDamage[victim][attacker] += appliedDamage;
		g_DetectHunterDamageSnapshot[victim].lastHealth = postHealth > 0 ? postHealth : 0;
	}
	else if (zombieClass == L4D2ZombieClass_Charger)
	{
		g_DetectChargerDamageSnapshot[victim].lastAttacker = attacker;
		g_DetectChargerDamageSnapshot[victim].lastDamageType = damagetype;
		g_DetectChargerDamageSnapshot[victim].lastRawDamage = damage;

		if (!IsValidSurvivor(attacker))
		{
			return;
		}

		int appliedDamage = RoundToFloor(damage);
		int postHealth = GetClientHealth(victim);
		Detect_HandleChargerHurt(victim, attacker, damagetype, appliedDamage, postHealth);
	}
}

// Subdomain modules included below this shared coordinator.
#include "l4d2_player_skills/detect_hunter.sp"
#include "l4d2_player_skills/detect_charger.sp"
#include "l4d2_player_skills/detect_caralarm.sp"
#include "l4d2_player_skills/detect_movement.sp"
#include "l4d2_player_skills/detect_rocks.sp"
#include "l4d2_player_skills/detect_smoker.sp"
