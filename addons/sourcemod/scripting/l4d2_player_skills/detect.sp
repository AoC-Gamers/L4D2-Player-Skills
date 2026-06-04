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
#define L4D2_SKILLS_CHARGER_LEVEL_GRACE_TIME 0.15
#define L4D2_SKILLS_BOOMER_VOMIT_WINDOW 2.25
#define L4D2_SKILLS_SI_KILL_ASSIST_WINDOW 5.0
#define L4D2_SKILLS_CARALARM_WINDOW 0.11
#define L4D2_SKILLS_HOP_CHECK_TIME 0.1
#define L4D2_SKILLS_HOPEND_CHECK_TIME 0.1
#define L4D2_SKILLS_HOP_ACCEL_THRESH 0.01
#define L4D2_SKILLS_HUNTER_POUNCE_GRACE_TIME 0.05
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
	bool dragging;
	bool shoved;
	bool pendingTongueCut;
	int pendingTongueCutReason;
	int pendingTongueCutWeaponId;

	/**
	 * @brief Clears the tracked Smoker runtime state.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.victim = 0;
		this.reached = false;
		this.dragging = false;
		this.shoved = false;
		this.pendingTongueCut = false;
		this.pendingTongueCutReason = 0;
		this.pendingTongueCutWeaponId = WEPID_NONE;
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
	bool killedAirbornePouncing;

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
		this.killedAirbornePouncing = false;
	}
}

/**
 * @brief Per-survivor Charger victim state used across carry, incap and death flow.
 */
enum struct DetectChargeVictimState
{
	int charger;
	L4D2PlayerRef assister;
	bool wasCarried;
	bool slamResolved;
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
		this.assister.Reset();
		this.wasCarried = false;
		this.slamResolved = false;
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

enum struct DetectShoveWindowEntry
{
	int attackerClient;
	float shovedAt;

	void Reset()
	{
		this.attackerClient = 0;
		this.shovedAt = 0.0;
	}
}

enum struct DetectShoveWindowState
{
	DetectShoveWindowEntry entries[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];

	void Reset()
	{
		for (int i = 0; i < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES; i++)
		{
			this.entries[i].Reset();
		}
	}
}

enum struct DetectChargerBowlState
{
	bool active;
	bool emitted;
	int carriedVictim;
	int impactedVictims[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	int impactedCount;

	void Reset()
	{
		this.active = false;
		this.emitted = false;
		this.carriedVictim = 0;
		this.impactedCount = 0;

		for (int i = 0; i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
		{
			this.impactedVictims[i] = 0;
		}
	}
}

enum struct DetectChargerClawState
{
	int totalHits;
	int totalDamage;
	int entryCount;
	int victimUserids[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int victimAccountIds[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	bool victimBots[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int victimSurvivorCharacters[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int victimHits[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int victimDamage[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];

	void Reset()
	{
		this.totalHits = 0;
		this.totalDamage = 0;
		this.entryCount = 0;

		for (int i = 0; i < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES; i++)
		{
			this.victimUserids[i] = 0;
			this.victimAccountIds[i] = 0;
			this.victimBots[i] = false;
			this.victimSurvivorCharacters[i] = L4D2Util_SurvivorCharacter_Invalid;
			this.victimHits[i] = 0;
			this.victimDamage[i] = 0;
		}
	}
}

enum struct DetectSiAssistState
{
	int attackerUserids[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int attackerAccountIds[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	bool attackerBots[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int attackerSurvivorCharacters[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int damage[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int shots[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int weaponId[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	float time[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	float lastShotTime[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];

	void Reset()
	{
		for (int i = 0; i < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES; i++)
		{
			this.attackerUserids[i] = 0;
			this.attackerAccountIds[i] = 0;
			this.attackerBots[i] = false;
			this.attackerSurvivorCharacters[i] = L4D2Util_SurvivorCharacter_Invalid;
			this.damage[i] = 0;
			this.shots[i] = 0;
			this.weaponId[i] = WEPID_NONE;
			this.time[i] = 0.0;
			this.lastShotTime[i] = 0.0;
		}
	}
}

enum struct DetectSiLifeEntry
{
	int damage;
	int shots;
	int weaponId;
	int previousDamage;
	int previousShots;
	bool shotCounted;
	bool lastShotHitHead;

	void Reset()
	{
		this.damage = 0;
		this.shots = 0;
		this.weaponId = WEPID_NONE;
		this.previousDamage = 0;
		this.previousShots = 0;
		this.shotCounted = false;
		this.lastShotHitHead = false;
	}
}

enum struct DetectSiLifeState
{
	int attackerClients[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int attackerUserids[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int attackerAccountIds[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	bool attackerBots[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int attackerSurvivorCharacters[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	DetectSiLifeEntry entries[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];

	void Reset()
	{
		for (int i = 0; i < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES; i++)
		{
			this.attackerClients[i] = 0;
			this.attackerUserids[i] = 0;
			this.attackerAccountIds[i] = 0;
			this.attackerBots[i] = false;
			this.attackerSurvivorCharacters[i] = L4D2Util_SurvivorCharacter_Invalid;
			this.entries[i].Reset();
		}
	}
}

enum struct DetectSiLifeContributorEntry
{
	L4D2PlayerRef player;
	int effectiveDamage;
	int rawDamage;
	int shots;
	int weaponId;

	void Reset()
	{
		this.player.Reset();
		this.effectiveDamage = 0;
		this.rawDamage = 0;
		this.shots = 0;
		this.weaponId = WEPID_NONE;
	}
}

enum struct DetectPendingDeathState
{
	bool queued;
	bool headshot;
	int attackerUserId;
	char weapon[64];

	void Reset()
	{
		this.queued = false;
		this.headshot = false;
		this.attackerUserId = 0;
		this.weapon[0] = '\0';
	}
}

enum struct DetectHunterShotWindowEntry
{
	int cumulativeDamage;
	int cumulativeShots;
	int activeBlastDamage;
	float activeBlastStart;
	bool shotCounted;

	void Reset()
	{
		this.cumulativeDamage = 0;
		this.cumulativeShots = 0;
		this.activeBlastDamage = 0;
		this.activeBlastStart = 0.0;
		this.shotCounted = false;
	}
}

enum struct DetectHunterShotWindowState
{
	int attackerClients[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	DetectHunterShotWindowEntry entries[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int teamBlastDamage;
	int overkillDamage;
	bool killedPouncing;

	void Reset()
	{
		this.teamBlastDamage = 0;
		this.overkillDamage = 0;
		this.killedPouncing = false;

		for (int i = 0; i < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES; i++)
		{
			this.attackerClients[i] = 0;
			this.entries[i].Reset();
		}
	}
}

enum struct DetectSkeetQualityWindowState
{
	bool active;
	int attackerClients[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int attackerUserids[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int attackerAccountIds[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	bool attackerBots[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int attackerSurvivorCharacters[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int damage[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int shots[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];

	void Reset()
	{
		this.active = false;

		for (int i = 0; i < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES; i++)
		{
			this.attackerClients[i] = 0;
			this.attackerUserids[i] = 0;
			this.attackerAccountIds[i] = 0;
			this.attackerBots[i] = false;
			this.attackerSurvivorCharacters[i] = L4D2Util_SurvivorCharacter_Invalid;
			this.damage[i] = 0;
			this.shots[i] = 0;
		}
	}
}

enum struct DetectPinRegistryState
{
	int pinnedVictimByAttacker[MAXPLAYERS + 1];
	int pinnerByVictim[MAXPLAYERS + 1];
	int pinnedClassByAttacker[MAXPLAYERS + 1];
	int smokerOwnerByVictim[MAXPLAYERS + 1];

	void Reset()
	{
		for (int client = 0; client <= MaxClients; client++)
		{
			this.pinnedVictimByAttacker[client] = 0;
			this.pinnerByVictim[client] = 0;
			this.pinnedClassByAttacker[client] = 0;
			this.smokerOwnerByVictim[client] = 0;
		}
	}
}

int Detect_GetSiAssistSlotCount()
{
	return Skills_GetTrackedSurvivorEntryCapacity();
}

// Short-lived interaction trackers should size to the functional mode space,
// not to MAXPLAYERS. Choose survivor-side, infected-side or per-class capacity
// depending on the interaction being modeled.

// Shared detector runtime state.
DetectBoomerState g_DetectBoomer[MAXPLAYERS + 1];
DetectHopState g_DetectHop[MAXPLAYERS + 1];
DetectLeapState g_DetectLeap[MAXPLAYERS + 1];
DetectSmokerState g_DetectSmoker[MAXPLAYERS + 1];
DetectDamageSnapshot g_DetectHunterDamageSnapshot[MAXPLAYERS + 1];
DetectDamageSnapshot g_DetectChargerDamageSnapshot[MAXPLAYERS + 1];
DetectChargeVictimState g_DetectChargeVictim[MAXPLAYERS + 1];
DetectChargerBowlState g_DetectChargerBowl[MAXPLAYERS + 1];
DetectChargerClawState g_DetectChargerClaw[MAXPLAYERS + 1];
DetectSiAssistState g_DetectSiAssist[MAXPLAYERS + 1];
DetectSiLifeState g_DetectSiLife[MAXPLAYERS + 1];
DetectPinRegistryState g_DetectPinRegistry;
int g_iDetectPendingBoomerKillEvent[MAXPLAYERS + 1];
float g_fDetectSpecialClearTimeA[MAXPLAYERS + 1];
float g_fDetectSpecialClearTimeB[MAXPLAYERS + 1];

int Detect_GetCurrentPinnedVictim(int infected)
{
	if (!IsValidInfected(infected))
	{
		return 0;
	}

	int victim = L4D2_GetSurvivorVictim(infected);
	if (IsValidSurvivor(victim))
	{
		return victim;
	}

	if (IsValidZombieClass(infected, L4D2ZombieClass_Charger) && L4D2_IsInQueuedPummel(infected))
	{
		victim = L4D2_GetQueuedPummelVictim(infected);
		if (IsValidSurvivor(victim))
		{
			return victim;
		}
	}

	victim = g_DetectPinRegistry.pinnedVictimByAttacker[infected];
	return IsValidSurvivor(victim) ? victim : 0;
}

int Detect_GetCurrentPinnedAttacker(int survivor)
{
	if (!IsValidSurvivor(survivor))
	{
		return 0;
	}

	int attacker = L4D2_GetInfectedAttacker(survivor);
	if (IsValidInfected(attacker))
	{
		return attacker;
	}

	attacker = g_DetectPinRegistry.pinnerByVictim[survivor];
	return IsValidInfected(attacker) ? attacker : 0;
}

void Detect_AttachPinnedInfectedAssistToEvent(int eventIndex, int actor, int survivor)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS || !IsValidSurvivor(survivor))
	{
		return;
	}

	int assister = Detect_GetCurrentPinnedAttacker(survivor);
	if (!IsValidInfected(assister) || assister == actor || g_SkillEvents[eventIndex].assistsCount > 0)
	{
		return;
	}

	g_SkillEvents[eventIndex].assistScope = L4D2SkillAssistScope_SkillWindow;
	g_SkillEvents[eventIndex].assists[0].Capture(assister);
	g_SkillEvents[eventIndex].assistsCount = 1;
	g_SkillEvents[eventIndex].assister = g_SkillEvents[eventIndex].assists[0];
}

bool g_bDetectHunterPouncing[MAXPLAYERS + 1];
float g_fDetectHunterPounceSeenAt[MAXPLAYERS + 1];
bool g_bDetectJockeyLeaping[MAXPLAYERS + 1];
float g_fDetectJockeyLeapSeenAt[MAXPLAYERS + 1];
bool g_bDetectJockeyKilledAirborneLeaping[MAXPLAYERS + 1];
bool g_bDetectChargerCharging[MAXPLAYERS + 1];
float g_fDetectChargerChargeSeenAt[MAXPLAYERS + 1];
bool g_bDetectChargerKilledMelee[MAXPLAYERS + 1];
bool g_bDetectChargerKilledCharging[MAXPLAYERS + 1];
bool g_bDetectClientDamageHooked[MAXPLAYERS + 1];
bool g_bDetectSuppressSiLifeKill[MAXPLAYERS + 1];
DetectShoveWindowState g_DetectHunterLastShove[MAXPLAYERS + 1];
DetectShoveWindowState g_DetectJockeyLastShove[MAXPLAYERS + 1];
int g_iDetectHunterSpawnHealth[MAXPLAYERS + 1];
DetectPendingDeathState g_DetectPendingHunterDeath[MAXPLAYERS + 1];
DetectPendingDeathState g_DetectPendingChargerDeath[MAXPLAYERS + 1];
int g_iDetectLastWeaponId[MAXPLAYERS + 1];
float g_fDetectLastWeaponFireTime[MAXPLAYERS + 1];
DetectHunterShotWindowState g_DetectHunterShotWindow[MAXPLAYERS + 1];
DetectSkeetQualityWindowState g_DetectSkeetQualityWindow[MAXPLAYERS + 1];
DetectRockTrack g_DetectRocks[L4D2_SKILLS_MAX_ROCKS];
StringMap g_smDetectCarAlarmTargets = null;
StringMap g_smDetectCarGlassParents = null;
StringMap g_smDetectCarPendingSurvivor = null;
StringMap g_smDetectCarPendingReason = null;
StringMap g_smDetectCarPendingInfected = null;
StringMap g_smDetectCarPendingFlags = null;
ConVar g_cvDetectHunterSkeetShotgunInterrupt = null;
ConVar g_cvDetectMaxPounceDistance = null;
ConVar g_cvDetectMinPounceDistance = null;
ConVar g_cvDetectInstaKillHeight = null;
ConVar g_cvDetectDeathSetupHeight = null;
ConVar g_cvDetectBHopMinStreak = null;
ConVar g_cvDetectBHopMinInitSpeed = null;
ConVar g_cvDetectBHopContSpeed = null;
float g_fDetectLastCarAlarm = 0.0;

int Detect_GetSiLifeSlotCount()
{
	return Skills_GetTrackedSurvivorEntryCapacity();
}

int Detect_GetShoveWindowSlotCount()
{
	return Skills_GetTrackedSurvivorEntryCapacity();
}

int Detect_FindShoveWindowSlot(DetectShoveWindowState state, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slotCount = Detect_GetShoveWindowSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (state.entries[i].attackerClient == attacker)
		{
			return i;
		}
	}

	return -1;
}

int Detect_FindOrCreateShoveWindowSlot(DetectShoveWindowState state, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slot = Detect_FindShoveWindowSlot(state, attacker);
	if (slot != -1)
	{
		return slot;
	}

	int slotCount = Detect_GetShoveWindowSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (state.entries[i].attackerClient == 0)
		{
			state.entries[i].attackerClient = attacker;
			state.entries[i].shovedAt = 0.0;
			return i;
		}
	}

	return -1;
}

void Detect_ResetShoveWindowEntryByAttacker(DetectShoveWindowState state, int attacker)
{
	int slot = Detect_FindShoveWindowSlot(state, attacker);
	if (slot == -1)
	{
		return;
	}

	state.entries[slot].Reset();
}

float Detect_GetLastShoveTime(DetectShoveWindowState state, int attacker)
{
	int slot = Detect_FindShoveWindowSlot(state, attacker);
	return slot == -1 ? 0.0 : state.entries[slot].shovedAt;
}

void Detect_SetLastShoveTime(DetectShoveWindowState state, int attacker, float shovedAt)
{
	int slot = Detect_FindOrCreateShoveWindowSlot(state, attacker);
	if (slot == -1)
	{
		return;
	}

	state.entries[slot].shovedAt = shovedAt;
}

int Detect_FindSiLifeSlot(int victim, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slotCount = Detect_GetSiLifeSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (g_DetectSiLife[victim].attackerClients[i] == attacker)
		{
			return i;
		}
	}

	return -1;
}

int Detect_FindOrCreateSiLifeSlot(int victim, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slot = Detect_FindSiLifeSlot(victim, attacker);
	if (slot != -1)
	{
		return slot;
	}

	int slotCount = Detect_GetSiLifeSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (g_DetectSiLife[victim].attackerClients[i] == 0
			&& g_DetectSiLife[victim].attackerUserids[i] == 0
			&& g_DetectSiLife[victim].attackerAccountIds[i] == 0
			&& !g_DetectSiLife[victim].attackerBots[i]
			&& g_DetectSiLife[victim].attackerSurvivorCharacters[i] == L4D2Util_SurvivorCharacter_Invalid)
		{
			g_DetectSiLife[victim].attackerClients[i] = attacker;
			g_DetectSiLife[victim].entries[i].Reset();
			return i;
		}
	}

	return -1;
}

void Detect_DetachSiLifeEntryByAttacker(int victim, int attacker)
{
	int slot = Detect_FindSiLifeSlot(victim, attacker);
	if (slot == -1)
	{
		return;
	}

	g_DetectSiLife[victim].attackerClients[slot] = 0;
	g_DetectSiLife[victim].entries[slot].shotCounted = false;
}

int Detect_GetHunterShotSlotCount()
{
	return Skills_GetTrackedSurvivorEntryCapacity();
}

int Detect_FindHunterShotWindowSlot(int victim, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slotCount = Detect_GetHunterShotSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (g_DetectHunterShotWindow[victim].attackerClients[i] == attacker)
		{
			return i;
		}
	}

	return -1;
}

int Detect_FindOrCreateHunterShotWindowSlot(int victim, int attacker)
{
	if (!IsValidSurvivor(attacker))
	{
		return -1;
	}

	int slot = Detect_FindHunterShotWindowSlot(victim, attacker);
	if (slot != -1)
	{
		return slot;
	}

	int slotCount = Detect_GetHunterShotSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (g_DetectHunterShotWindow[victim].attackerClients[i] == 0)
		{
			g_DetectHunterShotWindow[victim].attackerClients[i] = attacker;
			g_DetectHunterShotWindow[victim].entries[i].Reset();
			return i;
		}
	}

	return -1;
}

void Detect_ResetHunterShotWindowEntryByAttacker(int victim, int attacker)
{
	int slot = Detect_FindHunterShotWindowSlot(victim, attacker);
	if (slot == -1)
	{
		return;
	}

	g_DetectHunterShotWindow[victim].attackerClients[slot] = 0;
	g_DetectHunterShotWindow[victim].entries[slot].Reset();
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
		g_fDetectSpecialClearTimeA[client] = -1.0;
		g_fDetectSpecialClearTimeB[client] = -1.0;
		g_bDetectHunterPouncing[client] = false;
		g_fDetectHunterPounceSeenAt[client] = 0.0;
		g_bDetectJockeyLeaping[client] = false;
		g_fDetectJockeyLeapSeenAt[client] = 0.0;
		g_bDetectJockeyKilledAirborneLeaping[client] = false;
		g_bDetectChargerCharging[client] = false;
		g_fDetectChargerChargeSeenAt[client] = 0.0;
		g_bDetectChargerKilledMelee[client] = false;
		g_bDetectChargerKilledCharging[client] = false;
		g_bDetectClientDamageHooked[client] = false;
		g_iDetectHunterSpawnHealth[client] = 0;
		g_DetectPendingHunterDeath[client].Reset();
		g_DetectPendingChargerDeath[client].Reset();
		g_iDetectLastWeaponId[client] = WEPID_NONE;
		g_fDetectLastWeaponFireTime[client] = 0.0;
		g_DetectHunterDamageSnapshot[client].Reset();
		g_DetectChargerDamageSnapshot[client].Reset();
		g_DetectHunterShotWindow[client].Reset();
		g_DetectChargeVictim[client].Reset();
		g_DetectChargerBowl[client].Reset();
		g_DetectChargerClaw[client].Reset();
		g_DetectSiAssist[client].Reset();
		g_DetectSiLife[client].Reset();
		g_DetectSmoker[client].Reset();
		g_bDetectSuppressSiLifeKill[client] = false;
		g_iDetectPendingBoomerKillEvent[client] = 0;
		g_DetectHunterLastShove[client].Reset();
		g_DetectJockeyLastShove[client].Reset();
	}

	g_DetectPinRegistry.Reset();
}

void Detect_Shutdown()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (g_bDetectClientDamageHooked[client])
		{
			SDKUnhook(client, SDKHook_OnTakeDamage, Detect_OnTakeDamage_Client);
			SDKUnhook(client, SDKHook_OnTakeDamagePost, Detect_OnTakeDamagePost_Client);
			g_bDetectClientDamageHooked[client] = false;
		}
	}

	if (g_smDetectCarAlarmTargets != null)
	{
		delete g_smDetectCarAlarmTargets;
		g_smDetectCarAlarmTargets = null;
	}
	if (g_smDetectCarGlassParents != null)
	{
		delete g_smDetectCarGlassParents;
		g_smDetectCarGlassParents = null;
	}
	if (g_smDetectCarPendingSurvivor != null)
	{
		delete g_smDetectCarPendingSurvivor;
		g_smDetectCarPendingSurvivor = null;
	}
	if (g_smDetectCarPendingReason != null)
	{
		delete g_smDetectCarPendingReason;
		g_smDetectCarPendingReason = null;
	}
	if (g_smDetectCarPendingInfected != null)
	{
		delete g_smDetectCarPendingInfected;
		g_smDetectCarPendingInfected = null;
	}
	if (g_smDetectCarPendingFlags != null)
	{
		delete g_smDetectCarPendingFlags;
		g_smDetectCarPendingFlags = null;
	}
}

void Detect_ResetRocks()
{
	for (int slot = 0; slot < L4D2_SKILLS_MAX_ROCKS; slot++)
	{
		g_DetectRocks[slot].Reset();
	}
}

bool Detect_IsTrackableSiLifeKillClass(int client)
{
	if (!IsValidInfected(client))
	{
		return false;
	}

	switch (GetClientZombieClass(client))
	{
		case L4D2ZombieClass_Smoker, L4D2ZombieClass_Boomer, L4D2ZombieClass_Hunter, L4D2ZombieClass_Spitter, L4D2ZombieClass_Jockey, L4D2ZombieClass_Charger:
		{
			return true;
		}
	}

	return false;
}

bool Detect_DidSiLifeLastShotHitHead(int victim, int attacker)
{
	int slot = Detect_FindSiLifeSlot(victim, attacker);
	if (slot == -1)
	{
		return false;
	}

	return g_DetectSiLife[victim].entries[slot].lastShotHitHead;
}

bool Detect_CanUseSiLifeHeadshotFallback(int victim, int attacker)
{
	int slot = Detect_FindSiLifeSlot(victim, attacker);
	if (slot == -1)
	{
		return false;
	}

	// The hitgroup fallback is only trustworthy for real shot weapons. Fire,
	// splash and other continuous damage paths may report head hitgroups without
	// meaning "headshot" semantically.
	return Skills_IsRangedShotWeaponId(g_DetectSiLife[victim].entries[slot].weaponId);
}

bool Detect_ResolveHeadshot(int victim, int attacker, bool eventHeadshot)
{
	if (eventHeadshot)
	{
		return true;
	}

	return Detect_CanUseSiLifeHeadshotFallback(victim, attacker)
		&& Detect_DidSiLifeLastShotHitHead(victim, attacker);
}

void Detect_ResetSiLifeKillTrack(int infected)
{
	if (infected < 1 || infected > MaxClients)
	{
		return;
	}

	g_DetectSiAssist[infected].Reset();
	g_DetectSiLife[infected].Reset();
	g_bDetectSuppressSiLifeKill[infected] = false;
	g_iDetectPendingBoomerKillEvent[infected] = 0;
}

void Detect_MarkSiLifeKillSuppressed(int infected)
{
	if (infected < 1 || infected > MaxClients)
	{
		return;
	}

	g_bDetectSuppressSiLifeKill[infected] = true;
	g_iDetectPendingBoomerKillEvent[infected] = 0;
}

void Detect_CaptureSiLifeAttackerIdentity(int victim, int attacker)
{
	if (victim < 1 || victim > MaxClients || !IsValidSurvivor(attacker))
	{
		return;
	}

	int slot = Detect_FindOrCreateSiLifeSlot(victim, attacker);
	if (slot == -1)
	{
		return;
	}

	Skills_CaptureIdentityForClient(attacker);
	g_DetectSiLife[victim].attackerClients[slot] = attacker;
	g_DetectSiLife[victim].attackerUserids[slot] = GetClientUserId(attacker);
	g_DetectSiLife[victim].attackerAccountIds[slot] = IsFakeClient(attacker) ? 0 : GetSteamAccountID(attacker);
	g_DetectSiLife[victim].attackerBots[slot] = IsFakeClient(attacker);
	g_DetectSiLife[victim].attackerSurvivorCharacters[slot] = Skills_GetClientSurvivorCharacter(attacker);
}

int Detect_BuildSiLifeContributorSnapshot(int victim, L4D2ZombieClassType zombieClass, int killer, DetectSiLifeContributorEntry entries[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES], int &killerEntry)
{
	killerEntry = -1;
	for (int i = 0; i < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES; i++)
	{
		entries[i].Reset();
	}

	int count = 0;
	int maxHealth = Skills_GetSpecialMaxHealth(zombieClass);
	int remainingHealth = maxHealth > 0 ? maxHealth : 0;
	int killerSlot = Detect_FindSiLifeSlot(victim, killer);
	int slotCount = Detect_GetSiLifeSlotCount();

	for (int slot = 0; slot < slotCount && count < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES; slot++)
	{
		if (slot == killerSlot)
		{
			continue;
		}

		int rawDamage = g_DetectSiLife[victim].entries[slot].damage;
		if (rawDamage <= 0)
		{
			continue;
		}

		int effectiveDamage = rawDamage;
		if (maxHealth > 0)
		{
			if (remainingHealth <= 0)
			{
				continue;
			}

			if (effectiveDamage > remainingHealth)
			{
				effectiveDamage = remainingHealth;
			}
			remainingHealth -= effectiveDamage;
		}

		if (!Skills_TryBuildPlayerRefFromIdentity(
			g_DetectSiLife[victim].attackerAccountIds[slot],
			g_DetectSiLife[victim].attackerBots[slot],
			g_DetectSiLife[victim].attackerSurvivorCharacters[slot],
			g_DetectSiLife[victim].attackerUserids[slot],
			entries[count].player))
		{
			continue;
		}

		entries[count].effectiveDamage = effectiveDamage;
		entries[count].rawDamage = rawDamage;
		entries[count].shots = g_DetectSiLife[victim].entries[slot].shots;
		entries[count].weaponId = g_DetectSiLife[victim].entries[slot].weaponId;
		count++;
	}

	if (killerSlot != -1 && count < L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES)
	{
		int rawDamage = g_DetectSiLife[victim].entries[killerSlot].damage;
		if (rawDamage > 0)
		{
			int effectiveDamage = rawDamage;
			if (maxHealth > 0)
			{
				if (remainingHealth < 0)
				{
					remainingHealth = 0;
				}

				if (effectiveDamage > remainingHealth)
				{
					effectiveDamage = remainingHealth;
				}
			}

			if (Skills_TryBuildPlayerRefFromIdentity(
				g_DetectSiLife[victim].attackerAccountIds[killerSlot],
				g_DetectSiLife[victim].attackerBots[killerSlot],
				g_DetectSiLife[victim].attackerSurvivorCharacters[killerSlot],
				g_DetectSiLife[victim].attackerUserids[killerSlot],
				entries[count].player))
			{
				entries[count].effectiveDamage = effectiveDamage;
				entries[count].rawDamage = rawDamage;
				entries[count].shots = g_DetectSiLife[victim].entries[killerSlot].shots;
				entries[count].weaponId = g_DetectSiLife[victim].entries[killerSlot].weaponId;
				killerEntry = count;
				count++;
			}
		}
	}

	return count;
}

void Detect_LogHunterSkeetDecision(int hunter, int attacker, const char[] stage, const char[] detail)
{
	if (!Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		return;
	}

	char hunterName[64];
	char attackerName[64];
	if (IsValidClient(hunter))
	{
		if (IsFakeClient(hunter))
		{
			strcopy(hunterName, sizeof(hunterName), "Hunter (IA)");
		}
		else
		{
			FormatEx(hunterName, sizeof(hunterName), "Hunter (%N)", hunter);
		}
	}
	else
	{
		strcopy(hunterName, sizeof(hunterName), "Hunter");
	}
	if (IsValidClient(attacker))
	{
		FormatEx(attackerName, sizeof(attackerName), "%N", attacker);
	}
	else
	{
		strcopy(attackerName, sizeof(attackerName), "<none>");
	}

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Hunter skeet decision. hunter=%d hunter_name=%s attacker=%d attacker_name=%s stage=%s %s",
		hunter,
		hunterName,
		attacker,
		attackerName,
		stage,
		detail);
}

void Detect_LogSkeetQuality(int victim, int attacker, const char[] skillName, const char[] stage, int eventIndex)
{
	if (!Skills_IsDebugEnabled(PlayerSkillsDebug_Detect)
		|| eventIndex < 0
		|| eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return;
	}

	char victimName[64];
	char attackerName[64];
	if (IsValidClient(victim))
	{
		FormatEx(victimName, sizeof(victimName), "%N", victim);
	}
	else
	{
		strcopy(victimName, sizeof(victimName), "<none>");
	}

	if (IsValidClient(attacker))
	{
		FormatEx(attackerName, sizeof(attackerName), "%N", attacker);
	}
	else
	{
		strcopy(attackerName, sizeof(attackerName), "<none>");
	}

	int assistDamageTotal = 0;
	for (int i = 0; i < g_SkillEvents[eventIndex].assistsCount && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		assistDamageTotal += g_SkillEvents[eventIndex].assistDamage[i];
	}

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Skeet quality. skill=%s stage=%s victim=%d victim_name=%s attacker=%d attacker_name=%s actor_damage=%d shots=%d actor_chip=%d actor_chip_shots=%d assist_damage=%d assists=%d chip=%d perfect=%d",
		skillName,
		stage,
		victim,
		victimName,
		attacker,
		attackerName,
		g_SkillEvents[eventIndex].actorDamage,
		g_SkillEvents[eventIndex].shots,
		g_SkillEvents[eventIndex].actorChipDamage,
		g_SkillEvents[eventIndex].actorChipShots,
		assistDamageTotal,
		g_SkillEvents[eventIndex].assistsCount,
		g_SkillEvents[eventIndex].chipDamage,
		g_SkillEvents[eventIndex].perfect ? 1 : 0);
}

bool Detect_IsClientGrounded(int client)
{
	return client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& (GetEntityFlags(client) & FL_ONGROUND) != 0;
}

int Detect_GetClientGroundEntity(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return -1;
	}

	return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
}

float Detect_GetClientVerticalVelocity(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return 0.0;
	}

	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	return velocity[2];
}

float Detect_GetClientHorizontalVelocity(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return 0.0;
	}

	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	velocity[2] = 0.0;
	return GetVectorLength(velocity);
}

void Detect_LogJockeyLeapState(int jockey, const char[] stage)
{
	if (!Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		return;
	}

	float now = GetGameTime();
	float seenAt = (jockey > 0 && jockey <= MaxClients) ? g_fDetectJockeyLeapSeenAt[jockey] : 0.0;
	float age = seenAt > 0.0 ? now - seenAt : -1.0;
	bool validClient = jockey > 0 && jockey <= MaxClients && IsClientInGame(jockey);
	bool alive = validClient && IsPlayerAlive(jockey);
	int flags = validClient ? GetEntityFlags(jockey) : 0;
	bool onGround = Detect_IsClientGrounded(jockey);
	int groundEntity = Detect_GetClientGroundEntity(jockey);
	float velZ = Detect_GetClientVerticalVelocity(jockey);
	float velXY = Detect_GetClientHorizontalVelocity(jockey);
	bool effective = (jockey > 0 && jockey <= MaxClients) ? Detect_IsJockeyEffectivelyLeaping(jockey) : false;
	bool airborne = (jockey > 0 && jockey <= MaxClients) ? Detect_IsJockeyAirborneForSkeet(jockey) : false;
	bool active = (jockey > 0 && jockey <= MaxClients) ? Detect_IsJockeySkeetWindowActive(jockey) : false;
	bool qualityWindow = (jockey > 0 && jockey <= MaxClients) ? g_DetectSkeetQualityWindow[jockey].active : false;
	bool lethalAirborne = (jockey > 0 && jockey <= MaxClients) ? g_bDetectJockeyKilledAirborneLeaping[jockey] : false;

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Jockey leap state. stage=%s jockey=%d valid=%d alive=%d state=%d effective=%d airborne=%d active=%d quality_window=%d lethal_airborne=%d onground=%d ground_ent=%d flags=%d vel_z=%.2f vel_xy=%.2f seen_at=%.3f age=%.3f",
		stage,
		jockey,
		validClient ? 1 : 0,
		alive ? 1 : 0,
		(jockey > 0 && jockey <= MaxClients && g_bDetectJockeyLeaping[jockey]) ? 1 : 0,
		effective ? 1 : 0,
		airborne ? 1 : 0,
		active ? 1 : 0,
		qualityWindow ? 1 : 0,
		lethalAirborne ? 1 : 0,
		onGround ? 1 : 0,
		groundEntity,
		flags,
		velZ,
		velXY,
		seenAt,
		age);
}

void Detect_OpenSkeetQualityWindow(int victim)
{
	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	g_DetectSkeetQualityWindow[victim].Reset();
	g_DetectSkeetQualityWindow[victim].active = true;

	int slotCount = Detect_GetSiLifeSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		g_DetectSkeetQualityWindow[victim].attackerClients[i] = g_DetectSiLife[victim].attackerClients[i];
		g_DetectSkeetQualityWindow[victim].attackerUserids[i] = g_DetectSiLife[victim].attackerUserids[i];
		g_DetectSkeetQualityWindow[victim].attackerAccountIds[i] = g_DetectSiLife[victim].attackerAccountIds[i];
		g_DetectSkeetQualityWindow[victim].attackerBots[i] = g_DetectSiLife[victim].attackerBots[i];
		g_DetectSkeetQualityWindow[victim].attackerSurvivorCharacters[i] = g_DetectSiLife[victim].attackerSurvivorCharacters[i];
		g_DetectSkeetQualityWindow[victim].damage[i] = g_DetectSiLife[victim].entries[i].damage;
		g_DetectSkeetQualityWindow[victim].shots[i] = g_DetectSiLife[victim].entries[i].shots;
	}
}

void Detect_CloseSkeetQualityWindow(int victim)
{
	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	g_DetectSkeetQualityWindow[victim].Reset();
}

int Detect_GetSkeetQualitySnapshotDamageByAttacker(int victim, int attacker)
{
	if (victim < 1 || victim > MaxClients || !IsValidSurvivor(attacker) || !g_DetectSkeetQualityWindow[victim].active)
	{
		return 0;
	}

	int slotCount = Detect_GetSiLifeSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (Skills_IsClientMatchingIdentity(
			attacker,
			g_DetectSkeetQualityWindow[victim].attackerAccountIds[i],
			g_DetectSkeetQualityWindow[victim].attackerBots[i],
			g_DetectSkeetQualityWindow[victim].attackerSurvivorCharacters[i],
			g_DetectSkeetQualityWindow[victim].attackerUserids[i]))
		{
			return g_DetectSkeetQualityWindow[victim].damage[i];
		}
	}

	return 0;
}

int Detect_GetSkeetQualitySnapshotShotsByAttacker(int victim, int attacker)
{
	if (victim < 1 || victim > MaxClients || !IsValidSurvivor(attacker) || !g_DetectSkeetQualityWindow[victim].active)
	{
		return 0;
	}

	int slotCount = Detect_GetSiLifeSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (Skills_IsClientMatchingIdentity(
			attacker,
			g_DetectSkeetQualityWindow[victim].attackerAccountIds[i],
			g_DetectSkeetQualityWindow[victim].attackerBots[i],
			g_DetectSkeetQualityWindow[victim].attackerSurvivorCharacters[i],
			g_DetectSkeetQualityWindow[victim].attackerUserids[i]))
		{
			return g_DetectSkeetQualityWindow[victim].shots[i];
		}
	}

	return 0;
}

int Detect_GetSkeetQualityWindowDamageByAttacker(int victim, int attacker)
{
	int totalDamage = Detect_GetSiLifeDamageByAttacker(victim, attacker);
	int startDamage = Detect_GetSkeetQualitySnapshotDamageByAttacker(victim, attacker);
	int windowDamage = totalDamage - startDamage;
	return windowDamage > 0 ? windowDamage : 0;
}

int Detect_GetSkeetQualityWindowShotsByAttacker(int victim, int attacker)
{
	int totalShots = Detect_GetSiLifeShotsByAttacker(victim, attacker);
	int startShots = Detect_GetSkeetQualitySnapshotShotsByAttacker(victim, attacker);
	int windowShots = totalShots - startShots;
	return windowShots > 0 ? windowShots : 0;
}

void Detect_SetJockeyLeaping(int jockey, bool state)
{
	g_bDetectJockeyLeaping[jockey] = state;
	if (state)
	{
		g_fDetectJockeyLeapSeenAt[jockey] = GetGameTime();
	}

	Detect_LogJockeyLeapState(jockey, state ? "set_true" : "set_false");
}

bool Detect_IsJockeyEffectivelyLeaping(int jockey)
{
	if (g_bDetectJockeyLeaping[jockey])
	{
		g_fDetectJockeyLeapSeenAt[jockey] = GetGameTime();
		return true;
	}

	return g_fDetectJockeyLeapSeenAt[jockey] > 0.0
		&& (GetGameTime() - g_fDetectJockeyLeapSeenAt[jockey]) <= L4D2_SKILLS_HUNTER_POUNCE_GRACE_TIME;
}

bool Detect_IsJockeyAirborneForSkeet(int jockey)
{
	return jockey > 0
		&& jockey <= MaxClients
		&& IsClientInGame(jockey)
		&& IsPlayerAlive(jockey)
		&& !Detect_IsClientGrounded(jockey);
}

bool Detect_IsJockeySkeetWindowActive(int jockey)
{
	return Detect_IsJockeyEffectivelyLeaping(jockey)
		&& Detect_IsJockeyAirborneForSkeet(jockey);
}

bool Detect_DidJockeyDieAirborneForSkeet(int jockey)
{
	return jockey > 0
		&& jockey <= MaxClients
		&& g_bDetectJockeyKilledAirborneLeaping[jockey];
}

void Detect_ResetJockeyLeapState(int jockey)
{
	Detect_LogJockeyLeapState(jockey, "reset_before");
	g_bDetectJockeyLeaping[jockey] = false;
	g_fDetectJockeyLeapSeenAt[jockey] = 0.0;
	g_bDetectJockeyKilledAirborneLeaping[jockey] = false;
	g_DetectLeap[jockey].Reset();
	g_DetectJockeyLastShove[jockey].Reset();
	Detect_CloseSkeetQualityWindow(jockey);
	Detect_LogJockeyLeapState(jockey, "reset_after");
}

void Detect_TryEmitHunterSkeetMelee(int hunter, int attacker, bool headshot, int hunterHealthBeforeDamage)
{
	Detect_LogHunterSkeetDecision(hunter, attacker, "melee", "classified_as=HunterSkeetMelee");
	int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeetMelee);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		g_SkillEvents[eventIndex].actor.Capture(attacker);
		g_SkillEvents[eventIndex].victim.Capture(hunter);
		g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
		g_SkillEvents[eventIndex].damage = hunterHealthBeforeDamage;
		g_SkillEvents[eventIndex].actorDamage = hunterHealthBeforeDamage;
		g_SkillEvents[eventIndex].shots = 1;
		int meleeAssistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, hunter, attacker);
		g_SkillEvents[eventIndex].perfect = (g_SkillEvents[eventIndex].chipDamage == 0) && meleeAssistsFound == 0;
		g_SkillEvents[eventIndex].headshot = headshot;
		Detect_LogSkeetQuality(hunter, attacker, "HunterSkeetMelee", "melee_emit", eventIndex);

		Action meleeResult = API_FireSkillDetected(eventId, L4D2Skill_HunterSkeetMelee);
		if (meleeResult < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
	}

	Detect_MarkSiLifeKillSuppressed(hunter);
}

void Detect_TryEmitHunterSkeetRanged(int hunter, int attacker, bool headshot, const char[] weapon, int hunterHealthBeforeDamage, int hunterBaselineHealth, float rawDamage)
{
	bool sniperSkeet = headshot && Detect_IsSkeetWeaponSniper(weapon);
	bool glSkeet = Detect_IsSkeetWeaponGL(weapon);
	L4D2WeaponId rangedWeaponId = view_as<L4D2WeaponId>(Skills_GetWeaponIdFromEventName(weapon));
	bool qualifiesAtBaseline = rawDamage >= float(hunterBaselineHealth);
	char hunterDecision[256];
	FormatEx(hunterDecision, sizeof(hunterDecision),
		"sniper=%d gl=%d qualifies_at_baseline=%d raw=%.1f baseline=%d",
		sniperSkeet ? 1 : 0,
		glSkeet ? 1 : 0,
		qualifiesAtBaseline ? 1 : 0,
		rawDamage,
		hunterBaselineHealth);
	Detect_LogHunterSkeetDecision(hunter, attacker, "ranged", hunterDecision);
	if (!qualifiesAtBaseline)
	{
		return;
	}

	Detect_LogHunterSkeetDecision(hunter, attacker, "ranged", "classified_as=HunterSkeet");
	int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeet);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		g_SkillEvents[eventIndex].actor.Capture(attacker);
		g_SkillEvents[eventIndex].victim.Capture(hunter);
		g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
		g_SkillEvents[eventIndex].damage = hunterHealthBeforeDamage;
		g_SkillEvents[eventIndex].actorDamage = hunterHealthBeforeDamage;
		g_SkillEvents[eventIndex].actorWeaponId = rangedWeaponId;
		g_SkillEvents[eventIndex].shots = 1;
		g_SkillEvents[eventIndex].headshot = headshot;
		g_SkillEvents[eventIndex].sniper = sniperSkeet;
		g_SkillEvents[eventIndex].grenadeLauncher = glSkeet;
		int pounceAssistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, hunter, attacker);
		g_SkillEvents[eventIndex].perfect = (g_SkillEvents[eventIndex].chipDamage == 0) && pounceAssistsFound == 0;
		Detect_LogSkeetQuality(hunter, attacker, "HunterSkeet", "ranged_emit", eventIndex);

		Action rangedResult = API_FireSkillDetected(eventId, L4D2Skill_HunterSkeet);
		if (rangedResult < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
	}

	Detect_MarkSiLifeKillSuppressed(hunter);
}

void Detect_TryEmitHunterSkeetShotgun(int hunter, int attacker, bool headshot)
{
	int interruptDamage = g_cvDetectHunterSkeetShotgunInterrupt != null ? g_cvDetectHunterSkeetShotgunInterrupt.IntValue : 0;
	int killerDamage = Detect_GetHunterBlastDamageByAttacker(hunter, attacker);
	int teamDamage = g_DetectHunterShotWindow[hunter].teamBlastDamage;
	int shots = Detect_GetHunterShotCountByAttacker(hunter, attacker);
	int overkillDamage = g_DetectHunterShotWindow[hunter].overkillDamage;
	int potentialKillerDamage = killerDamage + overkillDamage;
	int potentialTeamDamage = teamDamage + overkillDamage;
	bool interruptDisabled = interruptDamage <= 0;
	bool isSingleSkeet = interruptDisabled || potentialKillerDamage >= interruptDamage;
	bool isTeamSkeet = !interruptDisabled && potentialTeamDamage > potentialKillerDamage && potentialTeamDamage >= interruptDamage;
	char hunterDecision[256];
	FormatEx(hunterDecision, sizeof(hunterDecision),
		"interrupt=%d disabled=%d killer_damage=%d team_damage=%d overkill=%d potential_killer=%d potential_team=%d single=%d team=%d",
		interruptDamage,
		interruptDisabled ? 1 : 0,
		killerDamage,
		teamDamage,
		overkillDamage,
		potentialKillerDamage,
		potentialTeamDamage,
		isSingleSkeet ? 1 : 0,
		isTeamSkeet ? 1 : 0);
	Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun", hunterDecision);

	if (!(isSingleSkeet || isTeamSkeet))
	{
		Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun", "classified_as=none");
		return;
	}

	Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun", isTeamSkeet ? "classified_as=HunterSkeet(team)" : "classified_as=HunterSkeet(single)");
	int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeet);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		g_SkillEvents[eventIndex].actor.Capture(attacker);
		g_SkillEvents[eventIndex].victim.Capture(hunter);
		g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
		g_SkillEvents[eventIndex].damage = isTeamSkeet ? potentialTeamDamage : potentialKillerDamage;
		g_SkillEvents[eventIndex].actorDamage = potentialKillerDamage;
		g_SkillEvents[eventIndex].actorWeaponId = Detect_GetLastWeaponId(attacker);
		g_SkillEvents[eventIndex].shots = shots;
		g_SkillEvents[eventIndex].headshot = headshot;
		int pounceAssistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, hunter, attacker);
		g_SkillEvents[eventIndex].perfect = shots == 1
			&& g_SkillEvents[eventIndex].chipDamage == 0
			&& pounceAssistsFound == 0
			&& !isTeamSkeet;
		Detect_LogSkeetQuality(hunter, attacker, "HunterSkeet", isTeamSkeet ? "shotgun_team_emit" : "shotgun_emit", eventIndex);

		Action result = API_FireSkillDetected(eventId, g_SkillEvents[eventIndex].type);
		if (result < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
	}

	Detect_MarkSiLifeKillSuppressed(hunter);
}

void Detect_TryEmitHunterSkeetShotgunFallback(int hunter, int attacker, bool headshot, int hunterHealthBeforeDamage)
{
	// Some shotgun kills land entirely through life-kill accounting without a
	// stable blast window. Keep this fallback so single-shot skeets survive
	// event ordering differences instead of degrading to HunterKill.
	int interruptDamage = g_cvDetectHunterSkeetShotgunInterrupt != null ? g_cvDetectHunterSkeetShotgunInterrupt.IntValue : 0;
	int killerLifeDamage = Detect_GetSiLifeDamageByAttacker(hunter, attacker);
	int killerLifeShots = Detect_GetSiLifeShotsByAttacker(hunter, attacker);
	bool interruptDisabled = interruptDamage <= 0;
	char hunterDecision[256];
	FormatEx(hunterDecision, sizeof(hunterDecision),
		"fallback_shotgun life_damage=%d life_shots=%d interrupt=%d disabled=%d",
		killerLifeDamage,
		killerLifeShots,
		interruptDamage,
		interruptDisabled ? 1 : 0);
	Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun_fallback", hunterDecision);

	if (!(killerLifeShots == 1 && (interruptDisabled || killerLifeDamage >= interruptDamage)))
	{
		return;
	}

	Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun_fallback", "classified_as=HunterSkeet(single_lifekill)");
	int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeet);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		int fallbackEffectiveDamage = hunterHealthBeforeDamage > 0
			? hunterHealthBeforeDamage
			: Skills_GetSpecialMaxHealth(L4D2ZombieClass_Hunter);
		g_SkillEvents[eventIndex].actor.Capture(attacker);
		g_SkillEvents[eventIndex].victim.Capture(hunter);
		g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
		g_SkillEvents[eventIndex].damage = fallbackEffectiveDamage;
		g_SkillEvents[eventIndex].actorDamage = fallbackEffectiveDamage;
		g_SkillEvents[eventIndex].actorWeaponId = Detect_GetSiLifeWeaponIdByAttacker(hunter, attacker);
		g_SkillEvents[eventIndex].shots = killerLifeShots;
		g_SkillEvents[eventIndex].headshot = headshot;
		int pounceAssistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, hunter, attacker);
		g_SkillEvents[eventIndex].perfect = killerLifeShots == 1
			&& g_SkillEvents[eventIndex].chipDamage == 0
			&& pounceAssistsFound == 0;
		Detect_LogSkeetQuality(hunter, attacker, "HunterSkeet", "shotgun_fallback_emit", eventIndex);

		Action fallbackResult = API_FireSkillDetected(eventId, L4D2Skill_HunterSkeet);
		if (fallbackResult < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
	}

	Detect_MarkSiLifeKillSuppressed(hunter);
}

Action Detect_TimerAnnounceBoomerKill(Handle timer, any userid)
{
	// BoomerPop is decided in boomer_exploded, while the generic kill summary is
	// built from player_death. Delay the plain kill briefly so Pop can suppress it.
	if (!Skills_IsRoundLive())
	{
		return Plugin_Stop;
	}

	int boomer = GetClientOfUserId(userid);
	if (boomer < 1 || boomer > MaxClients)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Boomer kill timer aborted. userid=%d boomer=%d reason=invalid_client",
			userid,
			boomer);
		return Plugin_Stop;
	}

	int eventId = g_iDetectPendingBoomerKillEvent[boomer];

	if (eventId <= 0)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Boomer kill timer aborted. boomer=%d event=%d pending=%d",
			boomer,
			eventId,
			g_iDetectPendingBoomerKillEvent[boomer]);
		return Plugin_Stop;
	}

	g_iDetectPendingBoomerKillEvent[boomer] = 0;
	Skills_Debug(PlayerSkillsDebug_Detect,
		"Boomer kill timer firing. boomer=%d event=%d valid=%d",
		boomer,
		eventId,
		Skills_IsEventValid(eventId) ? 1 : 0);

	if (Skills_IsEventValid(eventId))
	{
		Announce_Skill(eventId);
	}

	Detect_ResetSiLifeKillTrack(boomer);

	return Plugin_Stop;
}

Action Detect_TimerEvaluateHunterDeath(Handle timer, any userid)
{
	// Hunter death is evaluated out-of-frame because shotgun pellets, pounce-end
	// state and player_death ordering are not stable in the same tick.
	if (!Skills_IsRoundLive())
	{
		return Plugin_Stop;
	}

	int hunter = GetClientOfUserId(userid);
	if (hunter < 1 || hunter > MaxClients)
	{
		return Plugin_Stop;
	}

	if (!g_DetectPendingHunterDeath[hunter].queued)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter death timer aborted. hunter=%d userid=%d reason=not_pending",
			hunter,
			userid);
		return Plugin_Stop;
	}

	g_DetectPendingHunterDeath[hunter].queued = false;
	bool headshot = Detect_ResolveHeadshot(
		hunter,
		GetClientOfUserId(g_DetectPendingHunterDeath[hunter].attackerUserId),
		g_DetectPendingHunterDeath[hunter].headshot);
	g_DetectPendingHunterDeath[hunter].headshot = false;

	int attacker = GetClientOfUserId(g_DetectPendingHunterDeath[hunter].attackerUserId);
	g_DetectPendingHunterDeath[hunter].attackerUserId = 0;
	char weapon[64];
	strcopy(weapon, sizeof(weapon), g_DetectPendingHunterDeath[hunter].weapon);
	g_DetectPendingHunterDeath[hunter].weapon[0] = '\0';

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Hunter death timer firing. hunter=%d attacker=%d pending=%d",
		hunter,
		attacker,
		g_DetectPendingHunterDeath[hunter].queued ? 1 : 0);

	if (!IsValidZombieClass(hunter, L4D2ZombieClass_Hunter))
	{
		Detect_ResetHunter(hunter);
		Detect_ResetSiLifeKillTrack(hunter);
		return Plugin_Stop;
	}

	bool shouldEmitSiLifeKill = IsValidSurvivor(attacker) && Detect_IsTrackableSiLifeKillClass(hunter);
	int hunterHealthBeforeDamage = 0;
	bool hunterWasPouncingAtDeath = false;

	if (shouldEmitSiLifeKill)
	{
		hunterHealthBeforeDamage = g_DetectHunterDamageSnapshot[hunter].lastHealthBeforeDamage > 0
			? g_DetectHunterDamageSnapshot[hunter].lastHealthBeforeDamage
			: g_DetectHunterDamageSnapshot[hunter].lastHealth;
		int hunterBaselineHealth = g_iDetectHunterSpawnHealth[hunter] > 0
			? g_iDetectHunterSpawnHealth[hunter]
			: hunterHealthBeforeDamage;
		if (hunterBaselineHealth <= 0)
		{
			hunterBaselineHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Hunter);
		}
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter decision source. hunter=%d attacker=%d lastHealthBefore=%d lastHealth=%d spawnHealth=%d chosenHealthBefore=%d chosenBaseline=%d",
			hunter,
			attacker,
			g_DetectHunterDamageSnapshot[hunter].lastHealthBeforeDamage,
			g_DetectHunterDamageSnapshot[hunter].lastHealth,
			g_iDetectHunterSpawnHealth[hunter],
			hunterHealthBeforeDamage,
			hunterBaselineHealth);
		int legacyChipDamage = hunterBaselineHealth - hunterHealthBeforeDamage;
		if (legacyChipDamage < 0)
		{
			legacyChipDamage = 0;
		}
		int snapshotChipDamage = Detect_GetSkeetQualitySnapshotDamageByAttacker(hunter, attacker);
		int snapshotChipShots = Detect_GetSkeetQualitySnapshotShotsByAttacker(hunter, attacker);

		float rawDamage = g_DetectHunterDamageSnapshot[hunter].lastRawDamage;
		if (g_DetectHunterDamageSnapshot[hunter].lastAttacker != attacker)
		{
			rawDamage = float(hunterHealthBeforeDamage);
		}

		bool killedPouncing = g_DetectHunterDamageSnapshot[hunter].killedAirbornePouncing
			|| g_DetectHunterShotWindow[hunter].killedPouncing
			|| Detect_IsHunterSkeetWindowActive(hunter);
		hunterWasPouncingAtDeath = killedPouncing;
		char hunterDecision[256];
		FormatEx(hunterDecision, sizeof(hunterDecision),
			"weapon=%s headshot=%d killedPouncing=%d health_before=%d baseline=%d legacy_chip=%d snapshot_chip=%d snapshot_shots=%d raw=%.1f team_shot=%d killer_shot=%d shots=%d",
			weapon,
			headshot ? 1 : 0,
			killedPouncing ? 1 : 0,
			hunterHealthBeforeDamage,
			hunterBaselineHealth,
			legacyChipDamage,
			snapshotChipDamage,
			snapshotChipShots,
			rawDamage,
			g_DetectHunterShotWindow[hunter].teamBlastDamage,
			Detect_GetHunterBlastDamageByAttacker(hunter, attacker),
			Detect_GetHunterShotCountByAttacker(hunter, attacker));
		Detect_LogHunterSkeetDecision(hunter, attacker, "start", hunterDecision);

		if (killedPouncing && Detect_IsSkeetWeaponMelee(weapon))
		{
			Detect_TryEmitHunterSkeetMelee(hunter, attacker, headshot, hunterHealthBeforeDamage);
		}

		bool sniperSkeet = killedPouncing && headshot && Detect_IsSkeetWeaponSniper(weapon);
		bool glSkeet = killedPouncing && Detect_IsSkeetWeaponGL(weapon);
		if (!g_bDetectSuppressSiLifeKill[hunter] && (sniperSkeet || glSkeet))
		{
			Detect_TryEmitHunterSkeetRanged(hunter, attacker, headshot, weapon, hunterHealthBeforeDamage, hunterBaselineHealth, rawDamage);
		}

		if (!g_bDetectSuppressSiLifeKill[hunter] && hunterWasPouncingAtDeath && g_DetectHunterShotWindow[hunter].teamBlastDamage > 0)
		{
			Detect_TryEmitHunterSkeetShotgun(hunter, attacker, headshot);
		}

		if (!g_bDetectSuppressSiLifeKill[hunter]
			&& killedPouncing
			&& Skills_IsShotgunWeaponId(Skills_GetWeaponIdFromEventName(weapon))
			&& g_DetectHunterShotWindow[hunter].teamBlastDamage == 0)
		{
			Detect_TryEmitHunterSkeetShotgunFallback(hunter, attacker, headshot, hunterHealthBeforeDamage);
		}

		Detect_LogHunterSkeetDecision(hunter, attacker, "fallback", g_bDetectSuppressSiLifeKill[hunter] ? "classified_as=suppressed" : "classified_as=HunterKill");
		if (!g_bDetectSuppressSiLifeKill[hunter])
		{
			Detect_EmitHunterLifeKill(
				hunter,
				attacker,
				hunterHealthBeforeDamage > 0 ? hunterHealthBeforeDamage : Skills_GetSpecialMaxHealth(L4D2ZombieClass_Hunter),
				headshot);
		}
	}

	Detect_ResetHunter(hunter);
	Detect_ResetSiLifeKillTrack(hunter);
	return Plugin_Stop;
}

Action Detect_TimerEvaluateChargerDeath(Handle timer, any userid)
{
	// ChargerLevel and the generic ChargerKill compete for the same death.
	// Delay the simple kill so the richer level classification resolves first.
	if (!Skills_IsRoundLive())
	{
		return Plugin_Stop;
	}

	int charger = GetClientOfUserId(userid);
	if (charger < 1 || charger > MaxClients)
	{
		return Plugin_Stop;
	}

	if (!g_DetectPendingChargerDeath[charger].queued)
	{
		return Plugin_Stop;
	}

	g_DetectPendingChargerDeath[charger].queued = false;
	int attacker = GetClientOfUserId(g_DetectPendingChargerDeath[charger].attackerUserId);
	g_DetectPendingChargerDeath[charger].attackerUserId = 0;
	bool headshot = Detect_ResolveHeadshot(charger, attacker, g_DetectPendingChargerDeath[charger].headshot);
	g_DetectPendingChargerDeath[charger].headshot = false;

	if (IsValidZombieClass(charger, L4D2ZombieClass_Charger)
		&& IsValidSurvivor(attacker)
		&& !g_bDetectSuppressSiLifeKill[charger])
	{
		if (Detect_TryEmitChargerLevelFromDeath(charger, attacker))
		{
			if (Detect_ShouldAnnounceChargerClawSummary(charger))
			{
				Announce_ChargerClawSummary(charger);
			}
			Detect_ResetCharger(charger);
			Detect_ResetSiLifeKillTrack(charger);
			return Plugin_Stop;
		}

		int pinvictim = Detect_GetCurrentPinnedVictim(charger);
		if (!IsValidSurvivor(pinvictim))
		{
			pinvictim = g_DetectPinRegistry.pinnedVictimByAttacker[charger];
		}
		if (IsValidSurvivor(pinvictim) && attacker != pinvictim)
		{
			Detect_EmitSpecialClear(attacker, charger, false, true, headshot);
			Detect_MarkSiLifeKillSuppressed(charger);
			Detect_ClearPinStateByAttacker(charger);
		}

		if (!g_bDetectSuppressSiLifeKill[charger])
		{
			Detect_EmitSiLifeKill(charger, attacker, headshot);
		}
	}

	if (Detect_ShouldAnnounceChargerClawSummary(charger))
	{
		Announce_ChargerClawSummary(charger);
	}

	Detect_ResetCharger(charger);
	Detect_ResetSiLifeKillTrack(charger);
	return Plugin_Stop;
}

void Detect_FindSiAssistSlots(int victim, int attacker, int &slot, int &emptySlot, int &weakestSlot)
{
	slot = -1;
	emptySlot = -1;
	weakestSlot = 0;

	int slotCount = Detect_GetSiAssistSlotCount();
	for (int i = 0; i < slotCount; i++)
	{
		if (Skills_IsClientMatchingIdentity(
			attacker,
			g_DetectSiAssist[victim].attackerAccountIds[i],
			g_DetectSiAssist[victim].attackerBots[i],
			g_DetectSiAssist[victim].attackerSurvivorCharacters[i],
			g_DetectSiAssist[victim].attackerUserids[i]))
		{
			slot = i;
			break;
		}

		if (g_DetectSiAssist[victim].attackerUserids[i] == 0
			&& g_DetectSiAssist[victim].attackerAccountIds[i] == 0
			&& !g_DetectSiAssist[victim].attackerBots[i]
			&& g_DetectSiAssist[victim].attackerSurvivorCharacters[i] == L4D2Util_SurvivorCharacter_Invalid)
		{
			if (emptySlot == -1)
			{
				emptySlot = i;
			}
			continue;
		}

		if (g_DetectSiAssist[victim].damage[i] < g_DetectSiAssist[victim].damage[weakestSlot])
		{
			weakestSlot = i;
		}
	}
}

void Detect_ApplySiLifeShot(int victim, int attacker, int hitgroup, bool countRealShots, int &assistShots)
{
	int slot = Detect_FindSiLifeSlot(victim, attacker);
	if (slot == -1)
	{
		return;
	}

	if (countRealShots)
	{
		g_DetectSiLife[victim].entries[slot].lastShotHitHead = (hitgroup == HITGROUP_HEAD);

		if (!g_DetectSiLife[victim].entries[slot].shotCounted)
		{
			g_DetectSiLife[victim].entries[slot].previousShots = g_DetectSiLife[victim].entries[slot].shots;
			g_DetectSiLife[victim].entries[slot].shots++;
			assistShots++;
			g_DetectSiLife[victim].entries[slot].shotCounted = true;
		}
		else if (hitgroup == HITGROUP_HEAD)
		{
			g_DetectSiLife[victim].entries[slot].lastShotHitHead = true;
		}

		return;
	}

	// Non-shot damage sources (fire, bleed-like ticks, splash follow-up) may
	// still report a head hitgroup, but they should not promote Headshot as a
	// kill property. Clear the fallback flag so only real shot events survive.
	g_DetectSiLife[victim].entries[slot].lastShotHitHead = false;
	g_DetectSiLife[victim].entries[slot].previousShots = g_DetectSiLife[victim].entries[slot].shots;
	g_DetectSiLife[victim].entries[slot].shots++;
	assistShots++;
}

void Detect_InitSiAssistSlot(int victim, int slot, int attacker, int damage, int weaponId, float now)
{
	Skills_CaptureIdentityForClient(attacker);
	g_DetectSiAssist[victim].attackerUserids[slot] = GetClientUserId(attacker);
	g_DetectSiAssist[victim].attackerAccountIds[slot] = IsFakeClient(attacker) ? 0 : GetSteamAccountID(attacker);
	g_DetectSiAssist[victim].attackerBots[slot] = IsFakeClient(attacker);
	g_DetectSiAssist[victim].attackerSurvivorCharacters[slot] = Skills_GetClientSurvivorCharacter(attacker);
	g_DetectSiAssist[victim].damage[slot] = damage;
	g_DetectSiAssist[victim].shots[slot] = 0;
	g_DetectSiAssist[victim].weaponId[slot] = weaponId;
	g_DetectSiAssist[victim].time[slot] = now;
	g_DetectSiAssist[victim].lastShotTime[slot] = 0.0;
}

void Detect_SortSiAssistSlotsByDamage(int victim)
{
	int slotCount = Detect_GetSiAssistSlotCount();
	for (int pass = 0; pass < slotCount - 1; pass++)
	{
		for (int i = 0; i < slotCount - 1 - pass; i++)
		{
			if (g_DetectSiAssist[victim].damage[i + 1] <= g_DetectSiAssist[victim].damage[i])
			{
				continue;
			}

			int attackerUserIdTemp = g_DetectSiAssist[victim].attackerUserids[i];
			int attackerAccountIdTemp = g_DetectSiAssist[victim].attackerAccountIds[i];
			bool attackerBotTemp = g_DetectSiAssist[victim].attackerBots[i];
			int attackerCharacterTemp = g_DetectSiAssist[victim].attackerSurvivorCharacters[i];
			int damageTemp = g_DetectSiAssist[victim].damage[i];
			int shotsTemp = g_DetectSiAssist[victim].shots[i];
			int weaponIdTemp = g_DetectSiAssist[victim].weaponId[i];
			float timeTemp = g_DetectSiAssist[victim].time[i];
			float lastShotTimeTemp = g_DetectSiAssist[victim].lastShotTime[i];

			g_DetectSiAssist[victim].attackerUserids[i] = g_DetectSiAssist[victim].attackerUserids[i + 1];
			g_DetectSiAssist[victim].attackerAccountIds[i] = g_DetectSiAssist[victim].attackerAccountIds[i + 1];
			g_DetectSiAssist[victim].attackerBots[i] = g_DetectSiAssist[victim].attackerBots[i + 1];
			g_DetectSiAssist[victim].attackerSurvivorCharacters[i] = g_DetectSiAssist[victim].attackerSurvivorCharacters[i + 1];
			g_DetectSiAssist[victim].damage[i] = g_DetectSiAssist[victim].damage[i + 1];
			g_DetectSiAssist[victim].shots[i] = g_DetectSiAssist[victim].shots[i + 1];
			g_DetectSiAssist[victim].weaponId[i] = g_DetectSiAssist[victim].weaponId[i + 1];
			g_DetectSiAssist[victim].time[i] = g_DetectSiAssist[victim].time[i + 1];
			g_DetectSiAssist[victim].lastShotTime[i] = g_DetectSiAssist[victim].lastShotTime[i + 1];

			g_DetectSiAssist[victim].attackerUserids[i + 1] = attackerUserIdTemp;
			g_DetectSiAssist[victim].attackerAccountIds[i + 1] = attackerAccountIdTemp;
			g_DetectSiAssist[victim].attackerBots[i + 1] = attackerBotTemp;
			g_DetectSiAssist[victim].attackerSurvivorCharacters[i + 1] = attackerCharacterTemp;
			g_DetectSiAssist[victim].damage[i + 1] = damageTemp;
			g_DetectSiAssist[victim].shots[i + 1] = shotsTemp;
			g_DetectSiAssist[victim].weaponId[i + 1] = weaponIdTemp;
			g_DetectSiAssist[victim].time[i + 1] = timeTemp;
			g_DetectSiAssist[victim].lastShotTime[i + 1] = lastShotTimeTemp;
		}
	}
}

void Detect_RecordSiLifeKillDamage(int victim, int attacker, int damage, int weaponId, int damageType, int hitgroup = HITGROUP_GENERIC)
{
	if (!Detect_IsTrackableSiLifeKillClass(victim) || !IsValidSurvivor(attacker) || damage <= 0)
	{
		return;
	}

	Detect_CaptureSiLifeAttackerIdentity(victim, attacker);
	int lifeSlot = Detect_FindSiLifeSlot(victim, attacker);
	if (lifeSlot == -1)
	{
		return;
	}

	bool countRealShots = Skills_IsRangedShotWeaponId(weaponId)
		|| (damageType & DMG_BUCKSHOT) != 0
		|| (damageType & DMG_BULLET) != 0;
	bool startingLogicalHit = countRealShots
		? !g_DetectSiLife[victim].entries[lifeSlot].shotCounted
		: true;

	if (startingLogicalHit)
	{
		g_DetectSiLife[victim].entries[lifeSlot].previousDamage = g_DetectSiLife[victim].entries[lifeSlot].damage;
	}

	g_DetectSiLife[victim].entries[lifeSlot].damage += damage;
	g_DetectSiLife[victim].entries[lifeSlot].weaponId = weaponId;

	float now = GetGameTime();

	int slot;
	int emptySlot;
	int weakestSlot;
	Detect_FindSiAssistSlots(victim, attacker, slot, emptySlot, weakestSlot);
	int slotCount = Detect_GetSiAssistSlotCount();

	if (slot != -1)
	{
		g_DetectSiAssist[victim].damage[slot] += damage;
		Detect_ApplySiLifeShot(victim, attacker, hitgroup, countRealShots, g_DetectSiAssist[victim].shots[slot]);
		g_DetectSiAssist[victim].weaponId[slot] = weaponId;
		g_DetectSiAssist[victim].time[slot] = now;
	}
	else if (emptySlot != -1)
	{
		Detect_InitSiAssistSlot(victim, emptySlot, attacker, damage, weaponId, now);
		Detect_ApplySiLifeShot(victim, attacker, hitgroup, countRealShots, g_DetectSiAssist[victim].shots[emptySlot]);
	}
	else if (damage > g_DetectSiAssist[victim].damage[weakestSlot])
	{
		Detect_InitSiAssistSlot(victim, weakestSlot, attacker, damage, weaponId, now);
		Detect_ApplySiLifeShot(victim, attacker, hitgroup, countRealShots, g_DetectSiAssist[victim].shots[weakestSlot]);
	}

	Detect_SortSiAssistSlotsByDamage(victim);

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		char hitgroupName[32];
		Skills_GetHitgroupName(hitgroup, hitgroupName, sizeof(hitgroupName));
		char summary[256];
		summary[0] = '\0';
		for (int i = 0; i < slotCount; i++)
		{
			if (g_DetectSiAssist[victim].attackerUserids[i] == 0
				&& g_DetectSiAssist[victim].attackerAccountIds[i] == 0
				&& !g_DetectSiAssist[victim].attackerBots[i]
				&& g_DetectSiAssist[victim].attackerSurvivorCharacters[i] == L4D2Util_SurvivorCharacter_Invalid)
			{
				continue;
			}

			char segment[64];
			FormatEx(segment, sizeof(segment), "%s%s%d:%d/%d",
				summary[0] == '\0' ? "" : " ",
				g_DetectSiAssist[victim].attackerAccountIds[i] > 0 ? "a:" :
					(g_DetectSiAssist[victim].attackerBots[i] ? "b:" : "u:"),
				g_DetectSiAssist[victim].attackerAccountIds[i] > 0
					? g_DetectSiAssist[victim].attackerAccountIds[i]
					: (g_DetectSiAssist[victim].attackerBots[i]
						? g_DetectSiAssist[victim].attackerSurvivorCharacters[i]
						: g_DetectSiAssist[victim].attackerUserids[i]),
				g_DetectSiAssist[victim].damage[i],
				g_DetectSiAssist[victim].shots[i]);
			StrCat(summary, sizeof(summary), segment);
		}

		Skills_Debug(PlayerSkillsDebug_Detect,
			"SI life kill damage recorded. victim=%d attacker=%d damage=%d weapon=%d damagetype=%d hitgroup=%d(%s) counted=%d summary=%s",
			victim,
			attacker,
			damage,
			weaponId,
			damageType,
			hitgroup,
			hitgroupName,
			g_DetectSiLife[victim].entries[lifeSlot].shotCounted ? 1 : 0,
			summary);
	}
}

L4D2SkillType Detect_GetSiLifeKillSkillType(L4D2ZombieClassType zombieClass)
{
	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker: return L4D2Skill_SmokerKill;
		case L4D2ZombieClass_Boomer: return L4D2Skill_BoomerKill;
		case L4D2ZombieClass_Hunter: return L4D2Skill_HunterKill;
		case L4D2ZombieClass_Spitter: return L4D2Skill_SpitterKill;
		case L4D2ZombieClass_Jockey: return L4D2Skill_JockeyKill;
		case L4D2ZombieClass_Charger: return L4D2Skill_ChargerKill;
	}

	return L4D2Skill_None;
}

int Detect_GetSiLifeDamageByAttacker(int victim, int client)
{
	int slot = Detect_FindSiLifeSlot(victim, client);
	if (slot == -1)
	{
		return 0;
	}

	return g_DetectSiLife[victim].entries[slot].damage;
}

int Detect_GetSiLifeShotsByAttacker(int victim, int client)
{
	int slot = Detect_FindSiLifeSlot(victim, client);
	if (slot == -1)
	{
		return 0;
	}

	return g_DetectSiLife[victim].entries[slot].shots;
}

int Detect_GetSiLifePreviousDamageByAttacker(int victim, int client)
{
	int slot = Detect_FindSiLifeSlot(victim, client);
	if (slot == -1)
	{
		return 0;
	}

	return g_DetectSiLife[victim].entries[slot].previousDamage;
}

int Detect_GetSiLifePreviousShotsByAttacker(int victim, int client)
{
	int slot = Detect_FindSiLifeSlot(victim, client);
	if (slot == -1)
	{
		return 0;
	}

	return g_DetectSiLife[victim].entries[slot].previousShots;
}

int Detect_GetSiLifeWeaponIdByAttacker(int victim, int client)
{
	int slot = Detect_FindSiLifeSlot(victim, client);
	if (slot == -1)
	{
		return WEPID_NONE;
	}

	return g_DetectSiLife[victim].entries[slot].weaponId;
}

int Detect_GetHunterBlastDamageByAttacker(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	int slot = Detect_FindHunterShotWindowSlot(victim, client);
	return slot != -1 ? g_DetectHunterShotWindow[victim].entries[slot].activeBlastDamage : 0;
}

int Detect_GetHunterShotCountByAttacker(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	int slot = Detect_FindHunterShotWindowSlot(victim, client);
	return slot != -1 ? g_DetectHunterShotWindow[victim].entries[slot].cumulativeShots : 0;
}

int Detect_WriteSiTrackAssistsToEventAsSkillWindow(int eventIndex, int victim, int actor)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return 0;
	}

	int assistsFound = 0;
	int maxAssists = L4D2_SKILLS_MAX_EVENT_ASSISTS;
	if (g_cvSurvivorLimit != null && g_cvSurvivorLimit.IntValue > 1 && g_cvSurvivorLimit.IntValue - 1 < maxAssists)
	{
		maxAssists = g_cvSurvivorLimit.IntValue - 1;
	}
	int slotCount = Detect_GetSiAssistSlotCount();

	for (int i = 0; i < slotCount && assistsFound < maxAssists; i++)
	{
		if (g_DetectSiAssist[victim].attackerUserids[i] == 0
			&& g_DetectSiAssist[victim].attackerAccountIds[i] == 0
			&& !g_DetectSiAssist[victim].attackerBots[i]
			&& g_DetectSiAssist[victim].attackerSurvivorCharacters[i] == L4D2Util_SurvivorCharacter_Invalid)
		{
			continue;
		}

		if (Skills_IsClientMatchingIdentity(
			actor,
			g_DetectSiAssist[victim].attackerAccountIds[i],
			g_DetectSiAssist[victim].attackerBots[i],
			g_DetectSiAssist[victim].attackerSurvivorCharacters[i],
			g_DetectSiAssist[victim].attackerUserids[i]))
		{
			continue;
		}

		int assistDamage = g_DetectSiAssist[victim].damage[i];
		if (assistDamage <= 0)
		{
			continue;
		}

		if (!Skills_TryBuildPlayerRefFromIdentity(
			g_DetectSiAssist[victim].attackerAccountIds[i],
			g_DetectSiAssist[victim].attackerBots[i],
			g_DetectSiAssist[victim].attackerSurvivorCharacters[i],
			g_DetectSiAssist[victim].attackerUserids[i],
			g_SkillEvents[eventIndex].assists[assistsFound]))
		{
			continue;
		}

		g_SkillEvents[eventIndex].assistDamage[assistsFound] = assistDamage;
		g_SkillEvents[eventIndex].assistShots[assistsFound] = g_DetectSiAssist[victim].shots[i];
		g_SkillEvents[eventIndex].assistWeaponId[assistsFound] = g_DetectSiAssist[victim].weaponId[i];
		assistsFound++;
	}

	g_SkillEvents[eventIndex].assistsCount = assistsFound;
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	if (assistsFound > 0)
	{
		g_SkillEvents[eventIndex].assistScope = L4D2SkillAssistScope_SkillWindow;
		g_SkillEvents[eventIndex].assister = g_SkillEvents[eventIndex].assists[0];
		g_SkillEvents[eventIndex].assisterDamage = g_SkillEvents[eventIndex].assistDamage[0];
		g_SkillEvents[eventIndex].assisterShots = g_SkillEvents[eventIndex].assistShots[0];
		g_SkillEvents[eventIndex].assisterWeaponId = g_SkillEvents[eventIndex].assistWeaponId[0];
	}

	return assistsFound;
}

int Detect_FillSkeetQualityFromLifeSnapshot(int eventIndex, int victim, int actor)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return 0;
	}

	int assistsFound = Detect_WriteSiTrackAssistsToEventAsSkillWindow(eventIndex, victim, actor);
	int assistDamageTotal = 0;
	for (int i = 0; i < g_SkillEvents[eventIndex].assistsCount && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		assistDamageTotal += g_SkillEvents[eventIndex].assistDamage[i];
	}

	g_SkillEvents[eventIndex].actorChipDamage = Detect_GetSkeetQualitySnapshotDamageByAttacker(victim, actor);
	g_SkillEvents[eventIndex].actorChipShots = Detect_GetSkeetQualitySnapshotShotsByAttacker(victim, actor);
	g_SkillEvents[eventIndex].chipDamage = g_SkillEvents[eventIndex].actorChipDamage + assistDamageTotal;
	return assistsFound;
}

int Detect_WriteLifeKillAssistsToEvent(int eventIndex, DetectSiLifeContributorEntry entries[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES], int entryCount, int killerEntry)
{
	int assistsFound = 0;
	int maxAssists = L4D2_SKILLS_MAX_EVENT_ASSISTS;
	if (g_cvSurvivorLimit != null && g_cvSurvivorLimit.IntValue > 1 && g_cvSurvivorLimit.IntValue - 1 < maxAssists)
	{
		maxAssists = g_cvSurvivorLimit.IntValue - 1;
	}

	for (int i = 0; i < entryCount; i++)
	{
		if (i == killerEntry)
		{
			continue;
		}

		int assistDamage = entries[i].effectiveDamage;
		if (assistDamage <= 0)
		{
			continue;
		}

		if (assistsFound >= maxAssists || assistsFound >= L4D2_SKILLS_MAX_EVENT_ASSISTS)
		{
			break;
		}

		g_SkillEvents[eventIndex].assists[assistsFound] = entries[i].player;
		g_SkillEvents[eventIndex].assistDamage[assistsFound] = assistDamage;
		g_SkillEvents[eventIndex].assistShots[assistsFound] = entries[i].shots;
		g_SkillEvents[eventIndex].assistWeaponId[assistsFound] = entries[i].weaponId;
		assistsFound++;
	}

	g_SkillEvents[eventIndex].assistsCount = assistsFound;
	if (assistsFound > 0)
	{
		g_SkillEvents[eventIndex].assister = g_SkillEvents[eventIndex].assists[0];
		g_SkillEvents[eventIndex].assisterDamage = g_SkillEvents[eventIndex].assistDamage[0];
		g_SkillEvents[eventIndex].assisterShots = g_SkillEvents[eventIndex].assistShots[0];
		g_SkillEvents[eventIndex].assisterWeaponId = g_SkillEvents[eventIndex].assistWeaponId[0];
	}

	return assistsFound;
}

bool Detect_BuildLifeKillEventPayload(int eventId, L4D2ZombieClassType zombieClass, int victim, int killer, bool headshot, int &eventIndex, int &assistsFound)
{
	eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		assistsFound = 0;
		return false;
	}

	DetectSiLifeContributorEntry contributors[L4D2_SKILLS_MAX_TRACKED_SURVIVOR_ENTRIES];
	int killerEntry = -1;
	int contributorCount = Detect_BuildSiLifeContributorSnapshot(victim, zombieClass, killer, contributors, killerEntry);
	if (killerEntry == -1 || contributorCount <= 0)
	{
		assistsFound = 0;
		return false;
	}

	g_SkillEvents[eventIndex].actor = contributors[killerEntry].player;
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = zombieClass;
	g_SkillEvents[eventIndex].assistScope = L4D2SkillAssistScope_LifeKill;
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_LifeKill;
	g_SkillEvents[eventIndex].actorWeaponId = contributors[killerEntry].weaponId;
	g_SkillEvents[eventIndex].actorDamage = contributors[killerEntry].effectiveDamage;
	g_SkillEvents[eventIndex].damage = g_SkillEvents[eventIndex].actorDamage;
	g_SkillEvents[eventIndex].shots = contributors[killerEntry].shots;
	g_SkillEvents[eventIndex].headshot = Detect_ResolveHeadshot(victim, killer, headshot);

	assistsFound = Detect_WriteLifeKillAssistsToEvent(eventIndex, contributors, contributorCount, killerEntry);
	return true;
}

void Detect_DebugLifeKillPayload(const char[] label, int eventId, L4D2SkillType type, int victim, int killer, int actorDamage, int shots, bool headshot, int assistsFound, int healthBeforeDamage = 0)
{
	if (!Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		return;
	}

	char assistsSummary[256];
	assistsSummary[0] = '\0';
	int eventIndex = Skills_GetEventIndex(eventId);
	for (int i = 0; i < assistsFound; i++)
	{
		char segment[72];
		FormatEx(segment, sizeof(segment), "%s%d:%d/%d",
			assistsSummary[0] == '\0' ? "" : " ",
			g_SkillEvents[eventIndex].assists[i].client,
			g_SkillEvents[eventIndex].assistDamage[i],
			g_SkillEvents[eventIndex].assistShots[i]);
		StrCat(assistsSummary, sizeof(assistsSummary), segment);
	}

	if (healthBeforeDamage > 0)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"%s. event=%d type=%d victim=%d killer=%d health_before=%d killer_dmg=%d killer_shots=%d headshot=%d assists=%d [%s]",
			label,
			eventId,
			type,
			victim,
			killer,
			healthBeforeDamage,
			actorDamage,
			shots,
			headshot ? 1 : 0,
			assistsFound,
			assistsSummary);
		return;
	}

	Skills_Debug(PlayerSkillsDebug_Detect,
		"%s. event=%d type=%d victim=%d killer=%d dmg=%d shots=%d headshot=%d assists=%d [%s]",
		label,
		eventId,
		type,
		victim,
		killer,
		actorDamage,
		shots,
		headshot ? 1 : 0,
		assistsFound,
		assistsSummary);
}

void Detect_EmitSiLifeKill(int victim, int killer, bool headshot = false)
{
	if (!Detect_IsTrackableSiLifeKillClass(victim) || !IsValidSurvivor(killer))
	{
		return;
	}

	L4D2ZombieClassType zombieClass = GetClientZombieClass(victim);
	L4D2SkillType type = Detect_GetSiLifeKillSkillType(zombieClass);
	if (type == L4D2Skill_None)
	{
		return;
	}

	int eventId = Skills_CreateEvent(type);
	int eventIndex;
	int assistsFound;
	if (!Detect_BuildLifeKillEventPayload(eventId, zombieClass, victim, killer, headshot, eventIndex, assistsFound))
	{
		return;
	}

	Detect_DebugLifeKillPayload("SI life kill payload", eventId, type, victim, killer, g_SkillEvents[eventIndex].actorDamage, g_SkillEvents[eventIndex].shots, g_SkillEvents[eventIndex].headshot, assistsFound);

	Action result = API_FireSkillDetected(eventId, type);
	if (result < Plugin_Handled)
	{
		if (type == L4D2Skill_BoomerKill)
		{
			g_iDetectPendingBoomerKillEvent[victim] = eventId;
			Skills_Debug(PlayerSkillsDebug_Detect,
				"Boomer kill queued. boomer=%d event=%d delay=0.10",
				victim,
				eventId);

			CreateTimer(0.10, Detect_TimerAnnounceBoomerKill, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			Announce_Skill(eventId);
		}
	}
}


void Detect_EmitHunterLifeKill(int victim, int killer, int hunterHealthBeforeDamage, bool headshot = false)
{
	if (!IsValidSurvivor(killer))
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_HunterKill);
	int eventIndex;
	int assistsFound;
	if (!Detect_BuildLifeKillEventPayload(eventId, L4D2ZombieClass_Hunter, victim, killer, headshot, eventIndex, assistsFound))
	{
		return;
	}

	if (g_SkillEvents[eventIndex].actorDamage <= 0)
	{
		g_SkillEvents[eventIndex].actorDamage = hunterHealthBeforeDamage;
		g_SkillEvents[eventIndex].damage = hunterHealthBeforeDamage;
		if (g_SkillEvents[eventIndex].shots <= 0)
		{
			g_SkillEvents[eventIndex].shots = 1;
		}
	}

	Detect_DebugLifeKillPayload("Hunter life kill payload", eventId, L4D2Skill_HunterKill, victim, killer, g_SkillEvents[eventIndex].actorDamage, g_SkillEvents[eventIndex].shots, g_SkillEvents[eventIndex].headshot, assistsFound, hunterHealthBeforeDamage);

	Action result = API_FireSkillDetected(eventId, L4D2Skill_HunterKill);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

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
	Detect_ResetJockeyLeapState(client);
	Detect_ResetCharger(client);
	Detect_ResetChargeTrack(client);
	Detect_ResetSiLifeKillTrack(client);
	Detect_ResetSmoker(client);
	Detect_ClearSmokerVictim(client);

	for (int victim = 1; victim <= MaxClients; victim++)
	{
		int lifeSlot = Detect_FindSiLifeSlot(victim, client);
		if (lifeSlot != -1)
		{
			g_DetectSiLife[victim].entries[lifeSlot].shotCounted = false;
		}
		Detect_ResetShoveWindowEntryByAttacker(g_DetectHunterLastShove[victim], client);
		Detect_ResetShoveWindowEntryByAttacker(g_DetectJockeyLastShove[victim], client);
		Detect_ResetHunterShotWindowEntryByAttacker(victim, client);
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
	Detect_ResetJockeyLeapState(client);
	Detect_ResetCharger(client);
	Detect_ResetChargeTrack(client);
	Detect_ResetSiLifeKillTrack(client);
	Detect_ResetSmoker(client);
	Detect_ClearSmokerVictim(client);

	for (int victim = 1; victim <= MaxClients; victim++)
	{
		Detect_DetachSiLifeEntryByAttacker(victim, client);
		Detect_ResetShoveWindowEntryByAttacker(g_DetectHunterLastShove[victim], client);
		Detect_ResetShoveWindowEntryByAttacker(g_DetectJockeyLastShove[victim], client);
		Detect_ResetHunterShotWindowEntryByAttacker(victim, client);
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
	g_DetectPinRegistry.smokerOwnerByVictim[victim] = attacker;
	g_DetectSmoker[attacker].reached = false;
	g_DetectSmoker[attacker].shoved = false;
	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Smoker, -1.0, GetGameTime());

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear tongue_grab hook. smoker=%d victim=%d",
			attacker,
			victim);
	}
}

void Detect_OnPouncedOnSurvivorPost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Hunter) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Hunter, -1.0, -1.0);

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear lunge_pounce hook. hunter=%d victim=%d",
			attacker,
			victim);
	}

	float height = Detect_GetLeapHeight(attacker, victim);
	float threshold = g_cvHunterHighPounceHeight != null ? g_cvHunterHighPounceHeight.FloatValue : L4D2_SKILLS_DEFAULT_HUNTER_HIGH_POUNCE_HEIGHT;
	float distance = Detect_GetLeapDistance(attacker, victim);
	float calculatedDamage = Detect_CalculateHunterPounceDamage(distance);
	bool incapped = L4D_IsPlayerIncapacitated(victim);
	if (incapped)
	{
		if (height >= threshold)
		{
			Announce_HunterIncapPounce(attacker, victim, RoundToFloor(calculatedDamage), height);
		}
		Detect_SetHunterPouncing(attacker, false);
		g_DetectLeap[attacker].Reset();
		return;
	}
	bool reportedHigh = height >= threshold;

	if (reportedHigh)
	{
		int eventId = Skills_CreateEvent(L4D2Skill_HunterHighPounce);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(attacker);
			g_SkillEvents[eventIndex].victim.Capture(victim);
			g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
			g_SkillEvents[eventIndex].damage = RoundToFloor(calculatedDamage);
			g_SkillEvents[eventIndex].actorDamage = g_SkillEvents[eventIndex].damage;
			g_SkillEvents[eventIndex].calculatedDamage = calculatedDamage;
			g_SkillEvents[eventIndex].distance = distance;
			g_SkillEvents[eventIndex].height = height;
			g_SkillEvents[eventIndex].reportedHigh = true;
			g_SkillEvents[eventIndex].incapped = incapped;
			Detect_AttachPinnedInfectedAssistToEvent(eventIndex, attacker, victim);

			Action result = API_FireSkillDetected(eventId, L4D2Skill_HunterHighPounce);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}

	Detect_SetHunterPouncing(attacker, false);
	g_DetectLeap[attacker].Reset();
}

void Detect_OnJockeyRidePost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Jockey) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Jockey, -1.0, -1.0);

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear jockey_ride hook. jockey=%d victim=%d",
			attacker,
			victim);
	}
}

void Detect_OnStartCarryingVictimPost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Charger) || !IsValidSurvivor(victim))
	{
		return;
	}

	Detect_RecordChargeVictim(attacker, victim, true);
	Detect_SetPinState(attacker, victim, L4D2ZombieClass_Charger, -1.0, GetGameTime());

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear charger_carry_start hook. charger=%d victim=%d",
			attacker,
			victim);
	}
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

	g_DetectChargeVictim[victim].slamResolved = true;

	if (bDeadlyCharge)
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_DEADLY;
	}

	Detect_TryEmitPendingChargerDeathSetup(victim);
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
}

void Detect_EmitGenericLedgeHang(L4D2SkillType type, int attacker, int victim, int zombieClass)
{
	if (!IsValidSurvivor(victim) || !IsValidInfected(attacker))
	{
		return;
	}

	int eventId = Skills_CreateEvent(type);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(attacker);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = zombieClass;
	g_SkillEvents[eventIndex].ledgeHang = true;

	Action result = API_FireSkillDetected(eventId, type);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_EventPlayerLedgeGrab(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(victim))
	{
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidInfected(attacker))
	{
		attacker = Detect_GetCurrentPinnedAttacker(victim);
		if (!IsValidInfected(attacker))
		{
			attacker = Detect_FindSmokerByVictim(victim);
		}
	}

	if (g_DetectChargeVictim[victim].charger > 0)
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_LEDGE;
		Detect_EmitChargerLedgeHang(victim);
		return;
	}

	if (IsValidZombieClass(attacker, L4D2ZombieClass_Smoker))
	{
		Detect_EmitGenericLedgeHang(L4D2Skill_SmokerLedgeHang, attacker, victim, L4D2ZombieClass_Smoker);
		return;
	}

	if (IsValidZombieClass(attacker, L4D2ZombieClass_Jockey))
	{
		Detect_EmitGenericLedgeHang(L4D2Skill_JockeyLedgeHang, attacker, victim, L4D2ZombieClass_Jockey);
		return;
	}

	if (IsValidTank(attacker))
	{
		Boss_RecordTankLedgeHang(attacker);
		Detect_EmitGenericLedgeHang(L4D2Skill_TankLedgeHang, attacker, victim, L4D2ZombieClass_Tank);
	}
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
		Detect_EmitChargerLedgeHang(client);
	}
	Detect_TryEmitPendingChargerDeathSetup(client);
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
		Detect_EmitChargerLedgeHang(victim);
	}
	Detect_TryEmitPendingChargerDeathSetup(victim);
}

void Detect_OnPummelVictimPost(int attacker, int victim)
{
	if (!Skills_IsEnabled() || !IsValidZombieClass(attacker, L4D2ZombieClass_Charger) || !IsValidSurvivor(victim))
	{
		return;
	}

	if (Detect_GetCurrentPinnedVictim(attacker) != victim)
	{
		Detect_SetPinState(attacker, victim, L4D2ZombieClass_Charger, GetGameTime(), GetGameTime());
		return;
	}

	g_fDetectSpecialClearTimeA[attacker] = GetGameTime();
	if (g_fDetectSpecialClearTimeB[attacker] < 0.0)
	{
		g_fDetectSpecialClearTimeB[attacker] = GetGameTime();
	}

	if (g_DetectChargeVictim[victim].charger == attacker)
	{
		g_DetectChargeVictim[victim].slamResolved = true;
		Detect_TryEmitPendingChargerDeathSetup(victim);
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

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger impact event. charger=%d victim=%d state_charging=%d effective_charging=%d",
			charger,
			victim,
			Detect_IsChargerCharging(charger) ? 1 : 0,
			Detect_IsChargerEffectivelyCharging(charger) ? 1 : 0);
	}

	bool countedBowlImpact = Detect_RecordChargerBowlImpact(charger, victim);
	if (countedBowlImpact && Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger bowl impact recorded. charger=%d victim=%d impacted=%d",
			charger,
			victim,
			g_DetectChargerBowl[charger].impactedCount);
	}

	Detect_RecordChargeVictim(charger, victim, false);
}

void Detect_EventPounceStopped(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int clearer = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	int hunter = Detect_GetCurrentPinnedAttacker(victim);
	if (!IsValidZombieClass(hunter, L4D2ZombieClass_Hunter))
	{
		return;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear pounce_stopped event. clearer=%d victim=%d pin_pinner=%d pin_victim=%d",
			clearer,
			victim,
			Detect_GetCurrentPinnedAttacker(victim),
			Detect_GetCurrentPinnedVictim(hunter));
	}
}

void Detect_EventPounceEnd(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int hunter = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	bool trackedHunter = IsValidZombieClass(hunter, L4D2ZombieClass_Hunter);
	if (!trackedHunter && IsValidSurvivor(victim))
	{
		int pinner = Detect_GetCurrentPinnedAttacker(victim);
		trackedHunter = IsValidZombieClass(pinner, L4D2ZombieClass_Hunter);
	}

	if (!trackedHunter)
	{
		return;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear pounce_end event. hunter=%d victim=%d pin_victim=%d",
			hunter,
			victim,
			Detect_GetCurrentPinnedVictim(hunter));
	}
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

	int victim = Detect_GetCurrentPinnedVictim(charger);
	if (!IsValidSurvivor(victim))
	{
		return;
	}

	g_fDetectSpecialClearTimeB[charger] = GetGameTime();

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear charger_carry_end event. charger=%d victim=%d timeB=%.3f pin_victim=%d",
			charger,
			victim,
			g_fDetectSpecialClearTimeB[charger],
			Detect_GetCurrentPinnedVictim(charger));
	}
}

void Detect_EventChargerPummelStart(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int charger = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear charger_pummel_start event. charger=%d victim=%d pin_victim=%d timeA=%.3f timeB=%.3f",
			charger,
			victim,
			charger >= 1 && charger <= MaxClients ? g_DetectPinRegistry.pinnedVictimByAttacker[charger] : 0,
			charger >= 1 && charger <= MaxClients ? g_fDetectSpecialClearTimeA[charger] : -1.0,
			charger >= 1 && charger <= MaxClients ? g_fDetectSpecialClearTimeB[charger] : -1.0);
	}

	Detect_CheckChargerBowl(charger);
}

void Detect_EventChargerPummelEnd(Event event)
{
	int eventRef = view_as<int>(event);
	if (!Skills_IsEnabled())
	{
		return;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear charger_pummel_end event. eventref=%d",
			eventRef);
	}
}

void Detect_EventJockeyRideEnd(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int jockey = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	int rescuer = GetClientOfUserId(event.GetInt("rescuer"));
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear jockey_ride_end event. jockey=%d victim=%d rescuer=%d pin_victim=%d",
			jockey,
			victim,
			rescuer,
			jockey >= 1 && jockey <= MaxClients ? g_DetectPinRegistry.pinnedVictimByAttacker[jockey] : 0);
	}
}

void Detect_OnEntityShovedPost(int client, int entity, int weapon, const float vecDir[3], bool bIsHighPounce)
{
	if (weapon < 0 || vecDir[0] > 999999.0)
	{
		return;
	}

	if (!Skills_IsEnabled() || !IsValidSurvivor(client))
	{
		return;
	}

	Announce_ShoveAttempt(client, entity);

	if (IsValidZombieClass(entity, L4D2ZombieClass_Jockey))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Jockey jump-stop check. jockey=%d attacker=%d leaping=%d",
			entity,
			client,
			Detect_IsJockeyEffectivelyLeaping(entity) ? 1 : 0);

		if (!Detect_IsJockeyEffectivelyLeaping(entity))
		{
			return;
		}

		float now = GetGameTime();
		if (now - Detect_GetLastShoveTime(g_DetectJockeyLastShove[entity], client) <= L4D2_SKILLS_DEADSTOP_DOUBLE_TIME)
		{
			return;
		}

		Detect_SetLastShoveTime(g_DetectJockeyLastShove[entity], client, now);
		Detect_SetJockeyLeaping(entity, false);

		int eventId = Skills_CreateEvent(L4D2Skill_JockeyJumpStop);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex == -1)
		{
			return;
		}

		g_SkillEvents[eventIndex].actor.Capture(client);
		g_SkillEvents[eventIndex].victim.Capture(entity);
		g_SkillEvents[eventIndex].withShove = true;

		Action result = API_FireSkillDetected(eventId, L4D2Skill_JockeyJumpStop);
		if (result < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
		return;
	}

	if (!IsValidZombieClass(entity, L4D2ZombieClass_Hunter))
	{
		return;
	}

	if (!Detect_IsHunterEffectivelyPouncing(entity) && !bIsHighPounce)
	{
		return;
	}

	float now = GetGameTime();
	if (now - Detect_GetLastShoveTime(g_DetectHunterLastShove[entity], client) <= L4D2_SKILLS_DEADSTOP_DOUBLE_TIME)
	{
		return;
	}

	Detect_SetLastShoveTime(g_DetectHunterLastShove[entity], client, now);
	Detect_SetHunterPouncing(entity, false);

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
	int hitgroup = event.GetInt("hitgroup");
	char weapon[32];
	event.GetString("weapon", weapon, sizeof(weapon));
	int weaponId = Skills_GetWeaponIdFromEventName(weapon);

	// Some indirect/projectile damage paths (notably GL splash and throwables)
	// can reach player_hurt without a useful weapon string. Fall back to the
	// attacker's most recent weapon_fire so the damage is still attributed to
	// the correct survivor.
	if (weaponId == WEPID_NONE && IsValidSurvivor(attacker))
	{
		int lastWeaponId = Detect_GetLastWeaponId(attacker);
		float lastWeaponFireTime = Detect_GetLastWeaponFireTime(attacker);
		float delta = GetGameTime() - lastWeaponFireTime;
		if (lastWeaponId != WEPID_NONE
			&& (Skills_IsRangedShotWeaponId(lastWeaponId)
				|| lastWeaponId == WEPID_MOLOTOV
				|| lastWeaponId == WEPID_PIPE_BOMB
				|| lastWeaponId == WEPID_VOMITJAR)
			&& delta >= 0.0
			&& delta <= 0.20)
		{
			weaponId = lastWeaponId;
		}
	}

	if (damage > 0 && IsValidSurvivor(attacker) && Detect_IsTrackableSiLifeKillClass(victim))
	{
		Detect_RecordSiLifeKillDamage(victim, attacker, damage, weaponId, damageType, hitgroup);
	}

	if (damage > 0 && IsValidSurvivor(victim) && IsValidZombieClass(attacker, L4D2ZombieClass_Charger))
	{
		Detect_RecordChargerClawHitFromDamage(victim, attacker, event.GetInt("entityid"), float(damage), damageType, weaponId);
	}

	if (IsValidSurvivor(victim) && g_DetectChargeVictim[victim].charger > 0 && damage > 0)
	{
		bool byTrigger = false;
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
			if (StrEqual(weapon, "tank_rock"))
			{
				Detect_MarkTankRockHit(attacker, victim);
			}
		}

		return;
	}
}

void Detect_HandleSmokerDeath(Event event, int victim, int attacker, bool shouldEmitSiLifeKill)
{
	int pinvictim = Detect_GetSmokerVictimFromState(victim);
	int trackedVictim = g_DetectSmoker[victim].victim;
	bool ownsTrackedVictim = IsValidSurvivor(attacker) && trackedVictim == attacker;
	bool isVictimKiller = IsValidSurvivor(attacker) && (pinvictim == attacker || ownsTrackedVictim);
	bool emitSpecialClearByKill = false;
	bool emitSelfClear = false;
	bool emitDeferredTongueCut = false;
	bool dragging = g_DetectSmoker[victim].dragging;

	if (isVictimKiller && g_DetectSmoker[victim].pendingTongueCut)
	{
		emitSelfClear = true;
		emitDeferredTongueCut = !emitSelfClear;
	}
	else if (isVictimKiller && (g_DetectSmoker[victim].reached || dragging || ownsTrackedVictim))
	{
		emitSelfClear = true;
	}
	else if (IsValidSurvivor(attacker) && IsValidSurvivor(pinvictim) && attacker != pinvictim)
	{
		emitSpecialClearByKill = true;
	}

	if (emitSelfClear)
	{
		int eventId = Skills_CreateEvent(L4D2Skill_SmokerSelfClear);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(attacker);
			g_SkillEvents[eventIndex].victim.Capture(victim);
			g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
			g_SkillEvents[eventIndex].withShove = false;
			g_SkillEvents[eventIndex].actorWeaponId = Detect_GetSiLifeWeaponIdByAttacker(victim, attacker);
			g_SkillEvents[eventIndex].damage = Detect_GetSiLifeDamageByAttacker(victim, attacker);
			g_SkillEvents[eventIndex].actorDamage = g_SkillEvents[eventIndex].damage;
			g_SkillEvents[eventIndex].shots = Detect_GetSiLifeShotsByAttacker(victim, attacker);
			g_SkillEvents[eventIndex].headshot = Detect_ResolveHeadshot(victim, attacker, event.GetBool("headshot"));
			Detect_WriteSiTrackAssistsToEventAsSkillWindow(eventIndex, victim, attacker);

			Action result = API_FireSkillDetected(eventId, L4D2Skill_SmokerSelfClear);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}

		Detect_MarkSiLifeKillSuppressed(victim);
	}
	else if (emitSpecialClearByKill)
	{
		Detect_EmitSpecialClear(attacker, victim, false, true, event.GetBool("headshot"));
		Detect_MarkSiLifeKillSuppressed(victim);
	}
	else if (emitDeferredTongueCut)
	{
		Detect_EmitSmokerTongueCut(attacker, victim);
	}

	Detect_ClearPinStateByAttacker(victim);
	Detect_ResetSmoker(victim);
	if (shouldEmitSiLifeKill && !g_bDetectSuppressSiLifeKill[victim])
	{
		Detect_EmitSiLifeKill(victim, attacker);
	}
	Detect_ResetSiLifeKillTrack(victim);
}

void Detect_TryEmitJockeyMeleeSkeet(Event event, int victim, int attacker, bool shouldEmitSiLifeKill)
{
	if (!IsValidZombieClass(victim, L4D2ZombieClass_Jockey) || !shouldEmitSiLifeKill || !IsValidSurvivor(attacker))
	{
		return;
	}

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	Skills_Debug(PlayerSkillsDebug_Detect,
		"Jockey melee-skeet check. jockey=%d attacker=%d weapon=%s leaping=%d airborne=%d active=%d quality_window=%d damage=%d",
		victim,
		attacker,
		weapon,
		Detect_IsJockeyEffectivelyLeaping(victim) ? 1 : 0,
		Detect_IsJockeyAirborneForSkeet(victim) ? 1 : 0,
		Detect_IsJockeySkeetWindowActive(victim) ? 1 : 0,
		g_DetectSkeetQualityWindow[victim].active ? 1 : 0,
		event.GetInt("dmg_health"));
	Detect_LogJockeyLeapState(victim, "melee_check");
	if ((Detect_IsJockeySkeetWindowActive(victim) || Detect_DidJockeyDieAirborneForSkeet(victim)) && Detect_IsSkeetWeaponMelee(weapon))
	{
		int eventId = Skills_CreateEvent(L4D2Skill_JockeySkeetMelee);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(attacker);
			g_SkillEvents[eventIndex].victim.Capture(victim);
			g_SkillEvents[eventIndex].zombieClass = L4D2ZombieClass_Jockey;
			g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
			g_SkillEvents[eventIndex].damage = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Jockey);
			g_SkillEvents[eventIndex].actorDamage = g_SkillEvents[eventIndex].damage;
			g_SkillEvents[eventIndex].shots = 1;
			int assistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, victim, attacker);
			g_SkillEvents[eventIndex].perfect = g_SkillEvents[eventIndex].chipDamage == 0
				&& assistsFound == 0;
			Detect_LogSkeetQuality(victim, attacker, "JockeySkeetMelee", "melee_emit", eventIndex);

			Action result = API_FireSkillDetected(eventId, L4D2Skill_JockeySkeetMelee);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}

		Detect_MarkSiLifeKillSuppressed(victim);
	}
}

void Detect_TryEmitJockeyRangedSkeet(Event event, int victim, int attacker, bool shouldEmitSiLifeKill)
{
	if (!IsValidZombieClass(victim, L4D2ZombieClass_Jockey) || !shouldEmitSiLifeKill || !IsValidSurvivor(attacker))
	{
		return;
	}

	Detect_LogJockeyLeapState(victim, "ranged_check");
	if (!Detect_IsJockeySkeetWindowActive(victim) && !Detect_DidJockeyDieAirborneForSkeet(victim))
	{
		return;
	}

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	L4D2WeaponId weaponId = view_as<L4D2WeaponId>(Skills_GetWeaponIdFromEventName(weapon));
	bool headshot = Detect_ResolveHeadshot(victim, attacker, event.GetBool("headshot"));
	bool grenadeLauncher = weaponId == L4D2WeaponId_GrenadeLauncher;
	bool shotgun = Skills_IsShotgunWeaponId(view_as<int>(weaponId));
	bool sniperHeadshot = headshot && (
		weaponId == L4D2WeaponId_HuntingRifle
		|| weaponId == L4D2WeaponId_SniperMilitary
		|| weaponId == L4D2WeaponId_SniperAWP
		|| weaponId == L4D2WeaponId_SniperScout
		|| weaponId == L4D2WeaponId_PistolMagnum);
	if (!grenadeLauncher && !sniperHeadshot && !shotgun)
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_JockeySkeet);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	int maxHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Jockey);
	g_SkillEvents[eventIndex].actor.Capture(attacker);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = L4D2ZombieClass_Jockey;
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	g_SkillEvents[eventIndex].damage = maxHealth;
	g_SkillEvents[eventIndex].actorDamage = Detect_GetSkeetQualityWindowDamageByAttacker(victim, attacker);
	g_SkillEvents[eventIndex].shots = Detect_GetSkeetQualityWindowShotsByAttacker(victim, attacker);
	g_SkillEvents[eventIndex].headshot = headshot;
	g_SkillEvents[eventIndex].sniper = sniperHeadshot;
	g_SkillEvents[eventIndex].grenadeLauncher = grenadeLauncher;
	g_SkillEvents[eventIndex].actorWeaponId = view_as<int>(weaponId);
	int assistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, victim, attacker);
	g_SkillEvents[eventIndex].perfect = g_SkillEvents[eventIndex].shots == 1
		&& g_SkillEvents[eventIndex].chipDamage == 0
		&& assistsFound == 0;
	Detect_LogSkeetQuality(victim, attacker, "JockeySkeet", "ranged_emit", eventIndex);

	Action result = API_FireSkillDetected(eventId, L4D2Skill_JockeySkeet);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	Detect_MarkSiLifeKillSuppressed(victim);
}

void Detect_HandleNonHunterSiDeath(Event event, int victim, int attacker, bool shouldEmitSiLifeKill)
{
	Detect_TryEmitJockeyMeleeSkeet(event, victim, attacker, shouldEmitSiLifeKill);
	Detect_TryEmitJockeyRangedSkeet(event, victim, attacker, shouldEmitSiLifeKill);

	if (IsValidZombieClass(victim, L4D2ZombieClass_Jockey))
	{
		Detect_ResetJockeyLeapState(victim);
	}

	bool pendingBoomerKill = IsValidZombieClass(victim, L4D2ZombieClass_Boomer)
		&& shouldEmitSiLifeKill
		&& !g_bDetectSuppressSiLifeKill[victim];
	bool pendingChargerKill = IsValidZombieClass(victim, L4D2ZombieClass_Charger)
		&& shouldEmitSiLifeKill
		&& !g_bDetectSuppressSiLifeKill[victim];
	if (pendingChargerKill && Detect_TryEmitChargerLevelFromDeath(victim, attacker))
	{
		if (Detect_ShouldAnnounceChargerClawSummary(victim))
		{
			Announce_ChargerClawSummary(victim);
		}
		Detect_ResetCharger(victim);
		Detect_ResetSiLifeKillTrack(victim);
		return;
	}
	if (pendingChargerKill)
	{
		g_DetectPendingChargerDeath[victim].queued = true;
		g_DetectPendingChargerDeath[victim].attackerUserId = GetClientUserId(attacker);
		g_DetectPendingChargerDeath[victim].headshot = Detect_ResolveHeadshot(victim, attacker, event.GetBool("headshot"));
		CreateTimer(0.1, Detect_TimerEvaluateChargerDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	if (shouldEmitSiLifeKill && !g_bDetectSuppressSiLifeKill[victim])
	{
		Detect_EmitSiLifeKill(victim, attacker, Detect_ResolveHeadshot(victim, attacker, event.GetBool("headshot")));
	}
	if (IsValidZombieClass(victim, L4D2ZombieClass_Charger) && Detect_ShouldAnnounceChargerClawSummary(victim))
	{
		Announce_ChargerClawSummary(victim);
		Detect_ResetCharger(victim);
	}
	if (!pendingBoomerKill)
	{
		Detect_ResetSiLifeKillTrack(victim);
	}
}

void Detect_HandleHunterDeath(Event event, int victim, int attacker, bool shouldEmitSiLifeKill)
{
	if (shouldEmitSiLifeKill)
	{
		char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));
		g_DetectPendingHunterDeath[victim].queued = true;
		g_DetectPendingHunterDeath[victim].headshot = Detect_ResolveHeadshot(victim, attacker, event.GetBool("headshot"));
		g_DetectPendingHunterDeath[victim].attackerUserId = GetClientUserId(attacker);
		strcopy(g_DetectPendingHunterDeath[victim].weapon, sizeof(g_DetectPendingHunterDeath[].weapon), weapon);
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter death queued. hunter=%d attacker=%d delay=0.10 weapon=%s headshot=%d team_shot=%d killer_shot=%d",
			victim,
			attacker,
			weapon,
			g_DetectPendingHunterDeath[victim].headshot ? 1 : 0,
			g_DetectHunterShotWindow[victim].teamBlastDamage,
			Detect_GetHunterBlastDamageByAttacker(victim, attacker));
		CreateTimer(0.1, Detect_TimerEvaluateHunterDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	Detect_ResetHunter(victim);
	Detect_ResetSiLifeKillTrack(victim);
}

void Detect_EventPlayerDeath(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	bool shouldEmitSiLifeKill = IsValidSurvivor(attacker) && Detect_IsTrackableSiLifeKillClass(victim);
	int pinvictim = 0;
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
		pinvictim = Detect_GetCurrentPinnedVictim(victim);
		if (!IsValidSurvivor(pinvictim))
		{
			pinvictim = g_DetectPinRegistry.pinnedVictimByAttacker[victim];
		}

		if (!IsValidZombieClass(victim, L4D2ZombieClass_Smoker)
			&& !IsValidZombieClass(victim, L4D2ZombieClass_Charger)
			&& IsValidSurvivor(attacker)
			&& IsValidSurvivor(pinvictim)
			&& attacker != pinvictim)
		{
			Detect_EmitSpecialClear(attacker, victim, false, true, event.GetBool("headshot"));
			Detect_MarkSiLifeKillSuppressed(victim);
			Detect_ClearPinStateByAttacker(victim);
		}
		else if (!IsValidZombieClass(victim, L4D2ZombieClass_Smoker)
			&& !IsValidZombieClass(victim, L4D2ZombieClass_Charger))
		{
			if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
			{
				Skills_Debug(PlayerSkillsDebug_Detect,
					"SpecialClear suppressed by kill hierarchy. pinner=%d attacker=%d class=%d pinvictim=%d",
					victim,
					attacker,
					g_DetectPinRegistry.pinnedClassByAttacker[victim],
					g_DetectPinRegistry.pinnedVictimByAttacker[victim]);
			}

			Detect_ClearPinStateByAttacker(victim);
		}
	}

	shouldEmitSiLifeKill = shouldEmitSiLifeKill && !g_bDetectSuppressSiLifeKill[victim];

	if (IsValidZombieClass(victim, L4D2ZombieClass_Smoker))
	{
		Detect_HandleSmokerDeath(event, victim, attacker, shouldEmitSiLifeKill);
		return;
	}

	if (!IsValidZombieClass(victim, L4D2ZombieClass_Hunter))
	{
		Detect_HandleNonHunterSiDeath(event, victim, attacker, shouldEmitSiLifeKill);
		return;
	}

	Detect_HandleHunterDeath(event, victim, attacker, shouldEmitSiLifeKill);
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
			g_iDetectHunterSpawnHealth[client] = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Hunter);
			g_DetectHunterDamageSnapshot[client].lastHealth = g_iDetectHunterSpawnHealth[client];
			Skills_Debug(PlayerSkillsDebug_Detect,
				"Hunter spawn baseline set. hunter=%d spawn_health=%d",
				client,
				g_iDetectHunterSpawnHealth[client]);
		}
		else if (IsValidZombieClass(client, L4D2ZombieClass_Charger))
		{
			g_DetectChargerDamageSnapshot[client].lastHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Charger);
		}

		if (IsValidInfected(client))
		{
			Detect_ResetSiLifeKillTrack(client);
		}

		return;
	}

	Detect_ResetSiLifeKillTrack(client);
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

	bool shouldDebugShove = IsValidZombieClass(victim, L4D2ZombieClass_Hunter)
		|| IsValidZombieClass(victim, L4D2ZombieClass_Jockey)
		|| IsValidZombieClass(victim, L4D2ZombieClass_Smoker);
	if (shouldDebugShove && Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear player_shoved event. attacker=%d victim=%d pinnedClass=%d pinvictim=%d pinnerByVictim=%d",
			attacker,
			victim,
			g_DetectPinRegistry.pinnedClassByAttacker[victim],
			g_DetectPinRegistry.pinnedVictimByAttacker[victim],
			g_DetectPinRegistry.pinnerByVictim[victim]);
	}

	if (IsValidZombieClass(victim, L4D2ZombieClass_Boomer))
	{
		g_DetectBoomer[victim].shoveCount++;
	}
	else if (Detect_IsPinnedClass(victim)
		&& !IsValidZombieClass(victim, L4D2ZombieClass_Charger)
		&& !IsValidZombieClass(victim, L4D2ZombieClass_Smoker)
		&& Detect_IsValidTeamClear(attacker, victim))
	{
		Detect_EmitSpecialClear(attacker, victim, true);
	}
	else if (IsValidZombieClass(victim, L4D2ZombieClass_Smoker)
		&& Detect_GetSmokerVictimFromState(victim) == attacker)
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
	if (timeAlive > L4D2_SKILLS_COMPETITIVE_POP_MAX_TIME)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Ignoring boomer pop outside allowed window. boomer=%d attacker=%d time_alive=%.2f max=%.2f",
			boomer, attacker, timeAlive, L4D2_SKILLS_COMPETITIVE_POP_MAX_TIME);
		Detect_ResetBoomer(boomer);
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_BoomerPop);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(attacker);
	g_SkillEvents[eventIndex].victim.Capture(boomer);
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	g_SkillEvents[eventIndex].shoveCount = g_DetectBoomer[boomer].shoveCount;
	g_SkillEvents[eventIndex].timeA = timeAlive;
	g_SkillEvents[eventIndex].headshot = Detect_ResolveHeadshot(boomer, attacker, event.GetBool("headshot"));
	Detect_WriteSiTrackAssistsToEventAsSkillWindow(eventIndex, boomer, attacker);

	Action result = API_FireSkillDetected(eventId, L4D2Skill_BoomerPop);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	// Preserve simple-kill suppression until player_death so a BoomerPop does not
	// also emit the generic kill summary for the same infected death.
	Detect_MarkSiLifeKillSuppressed(boomer);
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

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	g_iDetectLastWeaponId[attacker] = Skills_GetWeaponIdFromEventName(weapon);
	g_fDetectLastWeaponFireTime[attacker] = GetGameTime();

	// Reset per-shot gates on weapon_fire rather than player_hurt so multi-pellet
	// weapons and splash ticks can still collapse into one logical shot.
	for (int victim = 1; victim <= MaxClients; victim++)
	{
		int lifeSlot = Detect_FindSiLifeSlot(victim, attacker);
		if (lifeSlot != -1)
		{
			g_DetectSiLife[victim].entries[lifeSlot].shotCounted = false;
		}
		int slot = Detect_FindHunterShotWindowSlot(victim, attacker);
		if (slot != -1)
		{
			g_DetectHunterShotWindow[victim].entries[slot].shotCounted = false;
		}
	}
}

int Detect_GetLastWeaponId(int client)
{
	return (client > 0 && client <= MaxClients) ? g_iDetectLastWeaponId[client] : WEPID_NONE;
}

float Detect_GetLastWeaponFireTime(int client)
{
	return (client > 0 && client <= MaxClients) ? g_fDetectLastWeaponFireTime[client] : 0.0;
}

// Client damage snapshots used by Hunter/Charger classification flows.
Action Detect_OnTakeDamage_Client(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	bool roundLive = Skills_IsRoundLive();
	bool validInfected = IsValidInfected(victim);
	bool debugDamageHook = roundLive || validInfected;
	if (debugDamageHook && Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		int team = IsValidClient(victim) ? GetClientTeam(victim) : -1;
		int zombieClass = IsValidClient(victim) ? view_as<int>(L4D2_GetPlayerZombieClass(victim)) : -1;
		Skills_Debug(PlayerSkillsDebug_Detect,
			"OnTakeDamage enter. victim=%d attacker=%d inflictor=%d damage=%.1f damagetype=%d round_live=%d valid_infected=%d team=%d zombie_class=%d alive=%d",
			victim,
			attacker,
			inflictor,
			damage,
			damagetype,
			roundLive ? 1 : 0,
			validInfected ? 1 : 0,
			team,
			zombieClass,
			(IsValidClient(victim) && IsPlayerAlive(victim)) ? 1 : 0);
	}

	if (!roundLive || !validInfected)
	{
		if (roundLive)
		{
			int chargerWeaponId = IsValidZombieClass(attacker, L4D2ZombieClass_Charger) ? WEPID_CHARGER_CLAW : WEPID_NONE;
			Detect_RecordChargerClawHitFromDamage(victim, attacker, inflictor, damage, damagetype, chargerWeaponId);
		}

		return Plugin_Continue;
	}

	L4D2ZombieClassType zombieClass = L4D2_GetPlayerZombieClass(victim);
	if (zombieClass == L4D2ZombieClass_Hunter)
	{
		g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage = GetClientHealth(victim);
		g_DetectHunterDamageSnapshot[victim].lastAttacker = attacker;
		g_DetectHunterDamageSnapshot[victim].lastDamageType = damagetype;
		g_DetectHunterDamageSnapshot[victim].lastRawDamage = damage;
		if (g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage > 0
			&& RoundToFloor(damage) >= g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage
			&& Detect_IsHunterSkeetWindowActive(victim))
		{
			g_DetectHunterDamageSnapshot[victim].killedAirbornePouncing = true;
		}
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"Hunter pre-damage snapshot. hunter=%d attacker=%d current_health=%d raw=%.1f damagetype=%d spawn_health=%d last_health=%d lethal_airborne=%d",
				victim,
				attacker,
				g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage,
				damage,
				damagetype,
				g_iDetectHunterSpawnHealth[victim],
				g_DetectHunterDamageSnapshot[victim].lastHealth,
				g_DetectHunterDamageSnapshot[victim].killedAirbornePouncing ? 1 : 0);
		}
	}
	else if (zombieClass == L4D2ZombieClass_Charger)
	{
		g_DetectChargerDamageSnapshot[victim].lastHealthBeforeDamage = GetClientHealth(victim);
		g_DetectChargerDamageSnapshot[victim].lastAttacker = attacker;
		g_DetectChargerDamageSnapshot[victim].lastDamageType = damagetype;
		g_DetectChargerDamageSnapshot[victim].lastRawDamage = damage;
	}
	else if (zombieClass == L4D2ZombieClass_Jockey)
	{
		int healthBeforeDamage = GetClientHealth(victim);
		if (healthBeforeDamage > 0
			&& RoundToFloor(damage) >= healthBeforeDamage
			&& Detect_IsJockeySkeetWindowActive(victim))
		{
			g_bDetectJockeyKilledAirborneLeaping[victim] = true;
		}
	}

	return Plugin_Continue;
}

void Detect_HandleHunterDamagePost(int victim, int attacker, float damage, int damagetype)
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

	int slot = Detect_FindOrCreateHunterShotWindowSlot(victim, attacker);
	if (slot == -1)
	{
		return;
	}

	if (!g_DetectHunterShotWindow[victim].entries[slot].shotCounted)
	{
		g_DetectHunterShotWindow[victim].entries[slot].cumulativeShots++;
		g_DetectHunterShotWindow[victim].entries[slot].shotCounted = true;
	}

	int healthBeforeDamage = g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage > 0
		? g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage
		: g_DetectHunterDamageSnapshot[victim].lastHealth;
	if (healthBeforeDamage > 0 && appliedDamage > healthBeforeDamage)
	{
		g_DetectHunterShotWindow[victim].overkillDamage = appliedDamage - healthBeforeDamage;
		appliedDamage = healthBeforeDamage;
	}

	if (g_DetectHunterShotWindow[victim].entries[slot].activeBlastDamage > 0
		&& (GetGameTime() - g_DetectHunterShotWindow[victim].entries[slot].activeBlastStart) > DETECT_SHOTGUN_BLAST_TIME)
	{
		g_DetectHunterShotWindow[victim].entries[slot].activeBlastDamage = 0;
		g_DetectHunterShotWindow[victim].entries[slot].activeBlastStart = 0.0;
	}

	int postHealth = GetClientHealth(victim);
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		bool airbornePouncing = Detect_IsHunterSkeetWindowActive(victim);
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter post-damage snapshot. hunter=%d attacker=%d applied=%d pre=%d post=%d raw=%.1f pouncing=%d effective_pouncing=%d airborne_pouncing=%d team_shot=%d killer_shot=%d",
			victim,
			attacker,
			appliedDamage,
			healthBeforeDamage,
			postHealth,
			damage,
			g_bDetectHunterPouncing[victim] ? 1 : 0,
			Detect_IsHunterEffectivelyPouncing(victim) ? 1 : 0,
			airbornePouncing ? 1 : 0,
			g_DetectHunterShotWindow[victim].teamBlastDamage,
			g_DetectHunterShotWindow[victim].entries[slot].activeBlastDamage);
	}

	bool airbornePouncing = Detect_IsHunterSkeetWindowActive(victim);
	if (postHealth <= 0 && airbornePouncing)
	{
		g_DetectHunterDamageSnapshot[victim].killedAirbornePouncing = true;
	}

	bool shotgunBlast = (damagetype & DMG_BUCKSHOT) != 0;
	if (!shotgunBlast
		&& IsValidSurvivor(attacker)
		&& Skills_IsShotgunWeaponId(g_iDetectLastWeaponId[attacker])
		&& (GetGameTime() - g_fDetectLastWeaponFireTime[attacker]) <= DETECT_SHOTGUN_BLAST_TIME)
	{
		shotgunBlast = true;
	}

	if (airbornePouncing && shotgunBlast)
	{
		if (g_DetectHunterShotWindow[victim].entries[slot].activeBlastStart == 0.0)
		{
			g_DetectHunterShotWindow[victim].entries[slot].activeBlastStart = GetGameTime();
		}

		g_DetectHunterShotWindow[victim].entries[slot].activeBlastDamage += appliedDamage;
		g_DetectHunterShotWindow[victim].teamBlastDamage += appliedDamage;

		if (postHealth <= 0)
		{
			g_DetectHunterShotWindow[victim].killedPouncing = true;
		}
	}

	g_DetectHunterShotWindow[victim].entries[slot].cumulativeDamage += appliedDamage;
	g_DetectHunterDamageSnapshot[victim].lastHealth = postHealth > 0 ? postHealth : 0;
}

void Detect_OnTakeDamagePost_Client(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	bool roundLive = Skills_IsRoundLive();
	bool validInfected = IsValidInfected(victim);
	bool debugDamageHook = roundLive || validInfected;
	if (debugDamageHook && Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		int team = IsValidClient(victim) ? GetClientTeam(victim) : -1;
		int zombieClass = IsValidClient(victim) ? view_as<int>(L4D2_GetPlayerZombieClass(victim)) : -1;
		Skills_Debug(PlayerSkillsDebug_Detect,
			"OnTakeDamagePost enter. victim=%d attacker=%d inflictor=%d damage=%.1f damagetype=%d round_live=%d valid_infected=%d team=%d zombie_class=%d alive=%d",
			victim,
			attacker,
			inflictor,
			damage,
			damagetype,
			roundLive ? 1 : 0,
			validInfected ? 1 : 0,
			team,
			zombieClass,
			(IsValidClient(victim) && IsPlayerAlive(victim)) ? 1 : 0);
	}

	if (!roundLive || !validInfected)
	{
		return;
	}

	L4D2ZombieClassType zombieClass = L4D2_GetPlayerZombieClass(victim);
	if (zombieClass == L4D2ZombieClass_Hunter)
	{
		Detect_HandleHunterDamagePost(victim, attacker, damage, damagetype);
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
