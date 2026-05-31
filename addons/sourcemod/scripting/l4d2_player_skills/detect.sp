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
	int assister;
	bool wasCarried;
	bool setupEmitted;
	bool setupQueued;
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
		this.assister = 0;
		this.wasCarried = false;
		this.setupEmitted = false;
		this.setupQueued = false;
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
	int victimHits[MAXPLAYERS + 1];
	int victimDamage[MAXPLAYERS + 1];

	void Reset()
	{
		this.totalHits = 0;
		this.totalDamage = 0;

		for (int i = 1; i <= MaxClients; i++)
		{
			this.victimHits[i] = 0;
			this.victimDamage[i] = 0;
		}
	}
}

enum struct DetectSiAssistState
{
	int attacker[MAXPLAYERS + 1];
	int damage[MAXPLAYERS + 1];
	int shots[MAXPLAYERS + 1];
	int weaponId[MAXPLAYERS + 1];
	float time[MAXPLAYERS + 1];
	float lastShotTime[MAXPLAYERS + 1];

	void Reset()
	{
		for (int i = 0; i <= MaxClients; i++)
		{
			this.attacker[i] = 0;
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
	DetectSiLifeEntry byAttacker[MAXPLAYERS + 1];

	void Reset()
	{
		for (int attacker = 0; attacker <= MaxClients; attacker++)
		{
			this.byAttacker[attacker].Reset();
		}
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
	DetectHunterShotWindowEntry byAttacker[MAXPLAYERS + 1];
	int teamBlastDamage;
	int overkillDamage;
	bool killedPouncing;

	void Reset()
	{
		this.teamBlastDamage = 0;
		this.overkillDamage = 0;
		this.killedPouncing = false;

		for (int attacker = 0; attacker <= MaxClients; attacker++)
		{
			this.byAttacker[attacker].Reset();
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
	int slotCount = Skills_GetConfiguredSurvivorLimit();
	if (slotCount < 1)
	{
		slotCount = L4D2_SKILLS_DEFAULT_SURVIVOR_LIMIT;
	}
	if (slotCount > MaxClients)
	{
		slotCount = MaxClients;
	}

	return slotCount;
}

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

bool g_bDetectHunterPouncing[MAXPLAYERS + 1];
float g_fDetectHunterPounceSeenAt[MAXPLAYERS + 1];
bool g_bDetectJockeyLeaping[MAXPLAYERS + 1];
float g_fDetectJockeyLeapSeenAt[MAXPLAYERS + 1];
bool g_bDetectChargerCharging[MAXPLAYERS + 1];
float g_fDetectChargerChargeSeenAt[MAXPLAYERS + 1];
bool g_bDetectChargerKilledMelee[MAXPLAYERS + 1];
bool g_bDetectChargerKilledCharging[MAXPLAYERS + 1];
bool g_bDetectClientDamageHooked[MAXPLAYERS + 1];
bool g_bDetectSuppressSiLifeKill[MAXPLAYERS + 1];
float g_fDetectHunterLastShove[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_fDetectJockeyLastShove[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDetectHunterSpawnHealth[MAXPLAYERS + 1];
DetectPendingDeathState g_DetectPendingHunterDeath[MAXPLAYERS + 1];
DetectPendingDeathState g_DetectPendingChargerDeath[MAXPLAYERS + 1];
int g_iDetectLastWeaponId[MAXPLAYERS + 1];
float g_fDetectLastWeaponFireTime[MAXPLAYERS + 1];
DetectHunterShotWindowState g_DetectHunterShotWindow[MAXPLAYERS + 1];
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
		for (int attacker = 1; attacker <= MaxClients; attacker++)
		{
			g_fDetectHunterLastShove[client][attacker] = 0.0;
			g_fDetectJockeyLastShove[client][attacker] = 0.0;
		}
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
	if (victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients)
	{
		return false;
	}

	return g_DetectSiLife[victim].byAttacker[attacker].lastShotHitHead;
}

bool Detect_CanUseSiLifeHeadshotFallback(int victim, int attacker)
{
	if (victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients)
	{
		return false;
	}

	// The hitgroup fallback is only trustworthy for real shot weapons. Fire,
	// splash and other continuous damage paths may report head hitgroups without
	// meaning "headshot" semantically.
	return Skills_IsRangedShotWeaponId(g_DetectSiLife[victim].byAttacker[attacker].weaponId);
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

void Detect_SetJockeyLeaping(int jockey, bool state)
{
	g_bDetectJockeyLeaping[jockey] = state;
	if (state)
	{
		g_fDetectJockeyLeapSeenAt[jockey] = GetGameTime();
	}
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

void Detect_ResetJockeyLeapState(int jockey)
{
	g_bDetectJockeyLeaping[jockey] = false;
	g_fDetectJockeyLeapSeenAt[jockey] = 0.0;
	g_DetectLeap[jockey].Reset();

	for (int attacker = 1; attacker <= MaxClients; attacker++)
	{
		g_fDetectJockeyLastShove[jockey][attacker] = 0.0;
	}
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
		int meleeAssistsFound = Detect_FillHunterSkeetPriorDamage(eventIndex, hunter, attacker, hunterHealthBeforeDamage, 1);
		g_SkillEvents[eventIndex].perfect = (g_SkillEvents[eventIndex].chipDamage == 0) && meleeAssistsFound == 0;
		g_SkillEvents[eventIndex].headshot = headshot;

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
		Detect_MarkSiLifeKillSuppressed(hunter);
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
		int pounceAssistsFound = Detect_FillHunterSkeetPriorDamage(eventIndex, hunter, attacker, hunterHealthBeforeDamage, 1);
		g_SkillEvents[eventIndex].perfect = (g_SkillEvents[eventIndex].chipDamage == 0) && pounceAssistsFound == 0;

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
	int interruptDamage = g_cvDetectPounceInterrupt != null ? g_cvDetectPounceInterrupt.IntValue : 150;
	int killerDamage = Detect_GetHunterBlastDamageByAttacker(hunter, attacker);
	int teamDamage = g_DetectHunterShotWindow[hunter].teamBlastDamage;
	int shots = Detect_GetHunterShotCountByAttacker(hunter, attacker);
	int overkillDamage = g_DetectHunterShotWindow[hunter].overkillDamage;
	int potentialKillerDamage = killerDamage + overkillDamage;
	int potentialTeamDamage = teamDamage + overkillDamage;
	bool isSingleSkeet = potentialKillerDamage >= interruptDamage;
	bool isTeamSkeet = potentialTeamDamage > potentialKillerDamage && potentialTeamDamage >= interruptDamage;
	char hunterDecision[256];
	FormatEx(hunterDecision, sizeof(hunterDecision),
		"interrupt=%d killer_damage=%d team_damage=%d overkill=%d potential_killer=%d potential_team=%d single=%d team=%d",
		interruptDamage,
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
		int pounceAssistsFound = Detect_FillHunterSkeetPriorDamage(eventIndex, hunter, attacker, potentialKillerDamage, shots);
		g_SkillEvents[eventIndex].perfect = shots == 1
			&& g_SkillEvents[eventIndex].chipDamage == 0
			&& pounceAssistsFound == 0
			&& !isTeamSkeet;

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
	int interruptDamage = g_cvDetectPounceInterrupt != null ? g_cvDetectPounceInterrupt.IntValue : 150;
	int killerLifeDamage = Detect_GetSiLifeDamageByAttacker(hunter, attacker);
	int killerLifeShots = Detect_GetSiLifeShotsByAttacker(hunter, attacker);
	char hunterDecision[256];
	FormatEx(hunterDecision, sizeof(hunterDecision),
		"fallback_shotgun life_damage=%d life_shots=%d interrupt=%d",
		killerLifeDamage,
		killerLifeShots,
		interruptDamage);
	Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun_fallback", hunterDecision);

	if (!(killerLifeShots == 1 && killerLifeDamage >= interruptDamage))
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
		int pounceAssistsFound = Detect_FillHunterSkeetPriorDamageFromLifeSnapshot(eventIndex, hunter, attacker);
		g_SkillEvents[eventIndex].perfect = killerLifeShots == 1
			&& g_SkillEvents[eventIndex].chipDamage == 0
			&& pounceAssistsFound == 0;

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
		int chipDamage = hunterBaselineHealth - hunterHealthBeforeDamage;
		if (chipDamage < 0)
		{
			chipDamage = 0;
		}

		float rawDamage = g_DetectHunterDamageSnapshot[hunter].lastRawDamage;
		if (g_DetectHunterDamageSnapshot[hunter].lastAttacker != attacker)
		{
			rawDamage = float(hunterHealthBeforeDamage);
		}

		bool killedPouncing = g_DetectHunterShotWindow[hunter].killedPouncing || Detect_IsHunterEffectivelyPouncing(hunter);
		hunterWasPouncingAtDeath = killedPouncing;
		char hunterDecision[256];
		FormatEx(hunterDecision, sizeof(hunterDecision),
			"weapon=%s headshot=%d killedPouncing=%d health_before=%d baseline=%d chip=%d raw=%.1f team_shot=%d killer_shot=%d shots=%d",
			weapon,
			headshot ? 1 : 0,
			killedPouncing ? 1 : 0,
			hunterHealthBeforeDamage,
			hunterBaselineHealth,
			chipDamage,
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
			Detect_EmitSpecialClear(attacker, charger, false, true);
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
		if (g_DetectSiAssist[victim].attacker[i] == attacker)
		{
			slot = i;
			break;
		}

		if (g_DetectSiAssist[victim].attacker[i] == 0)
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
	if (countRealShots)
	{
		g_DetectSiLife[victim].byAttacker[attacker].lastShotHitHead = (hitgroup == HITGROUP_HEAD);

		if (!g_DetectSiLife[victim].byAttacker[attacker].shotCounted)
		{
			g_DetectSiLife[victim].byAttacker[attacker].previousShots = g_DetectSiLife[victim].byAttacker[attacker].shots;
			g_DetectSiLife[victim].byAttacker[attacker].shots++;
			assistShots++;
			g_DetectSiLife[victim].byAttacker[attacker].shotCounted = true;
		}
		else if (hitgroup == HITGROUP_HEAD)
		{
			g_DetectSiLife[victim].byAttacker[attacker].lastShotHitHead = true;
		}

		return;
	}

	// Non-shot damage sources (fire, bleed-like ticks, splash follow-up) may
	// still report a head hitgroup, but they should not promote Headshot as a
	// kill property. Clear the fallback flag so only real shot events survive.
	g_DetectSiLife[victim].byAttacker[attacker].lastShotHitHead = false;
	g_DetectSiLife[victim].byAttacker[attacker].previousShots = g_DetectSiLife[victim].byAttacker[attacker].shots;
	g_DetectSiLife[victim].byAttacker[attacker].shots++;
	assistShots++;
}

void Detect_InitSiAssistSlot(int victim, int slot, int attacker, int damage, int weaponId, float now)
{
	g_DetectSiAssist[victim].attacker[slot] = attacker;
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

			int attackerTemp = g_DetectSiAssist[victim].attacker[i];
			int damageTemp = g_DetectSiAssist[victim].damage[i];
			int shotsTemp = g_DetectSiAssist[victim].shots[i];
			int weaponIdTemp = g_DetectSiAssist[victim].weaponId[i];
			float timeTemp = g_DetectSiAssist[victim].time[i];
			float lastShotTimeTemp = g_DetectSiAssist[victim].lastShotTime[i];

			g_DetectSiAssist[victim].attacker[i] = g_DetectSiAssist[victim].attacker[i + 1];
			g_DetectSiAssist[victim].damage[i] = g_DetectSiAssist[victim].damage[i + 1];
			g_DetectSiAssist[victim].shots[i] = g_DetectSiAssist[victim].shots[i + 1];
			g_DetectSiAssist[victim].weaponId[i] = g_DetectSiAssist[victim].weaponId[i + 1];
			g_DetectSiAssist[victim].time[i] = g_DetectSiAssist[victim].time[i + 1];
			g_DetectSiAssist[victim].lastShotTime[i] = g_DetectSiAssist[victim].lastShotTime[i + 1];

			g_DetectSiAssist[victim].attacker[i + 1] = attackerTemp;
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

	g_DetectSiLife[victim].byAttacker[attacker].previousDamage = g_DetectSiLife[victim].byAttacker[attacker].damage;
	g_DetectSiLife[victim].byAttacker[attacker].damage += damage;
	g_DetectSiLife[victim].byAttacker[attacker].weaponId = weaponId;

	float now = GetGameTime();
	bool countRealShots = Skills_IsRangedShotWeaponId(weaponId)
		|| (damageType & DMG_BUCKSHOT) != 0
		|| (damageType & DMG_BULLET) != 0;

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
			if (g_DetectSiAssist[victim].attacker[i] == 0)
			{
				continue;
			}

			char segment[64];
			FormatEx(segment, sizeof(segment), "%s%d:%d/%d",
				summary[0] == '\0' ? "" : " ",
				g_DetectSiAssist[victim].attacker[i],
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
			g_DetectSiLife[victim].byAttacker[attacker].shotCounted ? 1 : 0,
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
	if (client <= 0)
	{
		return 0;
	}

	return g_DetectSiLife[victim].byAttacker[client].damage;
}

int Detect_GetSiLifeShotsByAttacker(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	return g_DetectSiLife[victim].byAttacker[client].shots;
}

int Detect_GetSiLifePreviousDamageByAttacker(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	return g_DetectSiLife[victim].byAttacker[client].previousDamage;
}

int Detect_GetSiLifePreviousShotsByAttacker(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	return g_DetectSiLife[victim].byAttacker[client].previousShots;
}

int Detect_GetSiLifeWeaponIdByAttacker(int victim, int client)
{
	if (client <= 0)
	{
		return WEPID_NONE;
	}

	return g_DetectSiLife[victim].byAttacker[client].weaponId;
}

void Detect_BuildSiLifeEffectiveDamageByAttacker(int victim, L4D2ZombieClassType zombieClass, int killer, int effectiveDamage[MAXPLAYERS + 1])
{
	for (int client = 1; client <= MaxClients; client++)
	{
		effectiveDamage[client] = 0;
	}

	int maxHealth = Skills_GetSpecialMaxHealth(zombieClass);
	if (maxHealth <= 0)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			effectiveDamage[client] = Detect_GetSiLifeDamageByAttacker(victim, client);
		}
		return;
	}

	int remainingHealth = maxHealth;

	for (int assister = 1; assister <= MaxClients; assister++)
	{
		if (!IsValidSurvivor(assister) || assister == killer)
		{
			continue;
		}

		int assistRawDamage = Detect_GetSiLifeDamageByAttacker(victim, assister);
		if (assistRawDamage <= 0 || remainingHealth <= 0)
		{
			continue;
		}

		int appliedDamage = assistRawDamage;
		if (appliedDamage > remainingHealth)
		{
			appliedDamage = remainingHealth;
		}

		effectiveDamage[assister] = appliedDamage;
		remainingHealth -= appliedDamage;
	}

	if (IsValidSurvivor(killer) && remainingHealth > 0)
	{
		int killerRawDamage = Detect_GetSiLifeDamageByAttacker(victim, killer);
		if (killerRawDamage > 0)
		{
			effectiveDamage[killer] = killerRawDamage > remainingHealth ? remainingHealth : killerRawDamage;
		}
	}
}

int Detect_GetHunterBlastDamageByAttacker(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	return g_DetectHunterShotWindow[victim].byAttacker[client].activeBlastDamage;
}

int Detect_GetHunterShotCountByAttacker(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	return g_DetectHunterShotWindow[victim].byAttacker[client].cumulativeShots;
}

int Detect_FillHunterSkeetPriorDamage(int eventIndex, int victim, int actor, int actorWindowDamage, int actorWindowShots)
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

	int actorLifeDamage = Detect_GetSiLifeDamageByAttacker(victim, actor);
	int actorLifeShots = Detect_GetSiLifeShotsByAttacker(victim, actor);
	int actorChipDamage = actorLifeDamage - actorWindowDamage;
	if (actorChipDamage < 0)
	{
		actorChipDamage = 0;
	}

	int actorChipShots = actorLifeShots - actorWindowShots;
	if (actorChipShots < 0)
	{
		actorChipShots = 0;
	}

	g_SkillEvents[eventIndex].actorChipDamage = actorChipDamage;
	g_SkillEvents[eventIndex].actorChipShots = actorChipShots;
	g_SkillEvents[eventIndex].chipDamage = actorChipDamage + assistDamageTotal;
	return assistsFound;
}

int Detect_FillHunterSkeetPriorDamageFromLifeSnapshot(int eventIndex, int victim, int actor)
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

	g_SkillEvents[eventIndex].actorChipDamage = Detect_GetSiLifePreviousDamageByAttacker(victim, actor);
	g_SkillEvents[eventIndex].actorChipShots = Detect_GetSiLifePreviousShotsByAttacker(victim, actor);
	g_SkillEvents[eventIndex].chipDamage = g_SkillEvents[eventIndex].actorChipDamage + assistDamageTotal;
	return assistsFound;
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
		int assister = g_DetectSiAssist[victim].attacker[i];
		if (!IsValidSurvivor(assister) || assister == actor)
		{
			continue;
		}

		int assistDamage = g_DetectSiAssist[victim].damage[i];
		if (assistDamage <= 0)
		{
			continue;
		}

		g_SkillEvents[eventIndex].assists[assistsFound].Capture(assister);
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

int Detect_WriteLifeKillAssistsToEvent(int eventIndex, int victim, int killer, const int effectiveDamage[MAXPLAYERS + 1])
{
	int assistsFound = 0;
	int maxAssists = L4D2_SKILLS_MAX_EVENT_ASSISTS;
	if (g_cvSurvivorLimit != null && g_cvSurvivorLimit.IntValue > 1 && g_cvSurvivorLimit.IntValue - 1 < maxAssists)
	{
		maxAssists = g_cvSurvivorLimit.IntValue - 1;
	}

	for (int assister = 1; assister <= MaxClients; assister++)
	{
		if (!IsValidSurvivor(assister) || assister == killer)
		{
			continue;
		}

		int assistDamage = effectiveDamage[assister];
		if (assistDamage <= 0)
		{
			continue;
		}

		if (assistsFound >= maxAssists || assistsFound >= L4D2_SKILLS_MAX_EVENT_ASSISTS)
		{
			break;
		}

		g_SkillEvents[eventIndex].assists[assistsFound].Capture(assister);
		g_SkillEvents[eventIndex].assistDamage[assistsFound] = assistDamage;
		g_SkillEvents[eventIndex].assistShots[assistsFound] = Detect_GetSiLifeShotsByAttacker(victim, assister);
		g_SkillEvents[eventIndex].assistWeaponId[assistsFound] = Detect_GetSiLifeWeaponIdByAttacker(victim, assister);
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

bool Detect_BuildLifeKillEventPayload(int eventId, L4D2ZombieClassType zombieClass, int victim, int killer, bool headshot, const int effectiveDamage[MAXPLAYERS + 1], int &eventIndex, int &assistsFound)
{
	eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		assistsFound = 0;
		return false;
	}

	g_SkillEvents[eventIndex].actor.Capture(killer);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = zombieClass;
	g_SkillEvents[eventIndex].assistScope = L4D2SkillAssistScope_LifeKill;
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_LifeKill;
	g_SkillEvents[eventIndex].actorWeaponId = Detect_GetSiLifeWeaponIdByAttacker(victim, killer);
	g_SkillEvents[eventIndex].actorDamage = effectiveDamage[killer];
	g_SkillEvents[eventIndex].damage = g_SkillEvents[eventIndex].actorDamage;
	g_SkillEvents[eventIndex].shots = Detect_GetSiLifeShotsByAttacker(victim, killer);
	g_SkillEvents[eventIndex].headshot = Detect_ResolveHeadshot(victim, killer, headshot);

	assistsFound = Detect_WriteLifeKillAssistsToEvent(eventIndex, victim, killer, effectiveDamage);
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

	int effectiveDamage[MAXPLAYERS + 1];
	Detect_BuildSiLifeEffectiveDamageByAttacker(victim, zombieClass, killer, effectiveDamage);

	int eventId = Skills_CreateEvent(type);
	int eventIndex;
	int assistsFound;
	if (!Detect_BuildLifeKillEventPayload(eventId, zombieClass, victim, killer, headshot, effectiveDamage, eventIndex, assistsFound))
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

	int effectiveDamage[MAXPLAYERS + 1];
	Detect_BuildSiLifeEffectiveDamageByAttacker(victim, L4D2ZombieClass_Hunter, killer, effectiveDamage);

	int eventId = Skills_CreateEvent(L4D2Skill_HunterKill);
	int eventIndex;
	int assistsFound;
	if (!Detect_BuildLifeKillEventPayload(eventId, L4D2ZombieClass_Hunter, victim, killer, headshot, effectiveDamage, eventIndex, assistsFound))
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
		g_DetectSiLife[victim].byAttacker[client].shotCounted = false;
		g_fDetectHunterLastShove[victim][client] = 0.0;
		g_fDetectJockeyLastShove[victim][client] = 0.0;
		g_DetectHunterShotWindow[victim].byAttacker[client].Reset();
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
		g_DetectSiLife[victim].byAttacker[client].shotCounted = false;
		g_fDetectHunterLastShove[victim][client] = 0.0;
		g_fDetectJockeyLastShove[victim][client] = 0.0;
		g_DetectHunterShotWindow[victim].byAttacker[client].Reset();
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
	if (!g_DetectChargeVictim[client].setupQueued)
	{
		g_DetectChargeVictim[client].setupQueued = true;
		CreateTimer(0.25, Detect_TimerEmitChargerDeathSetup, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
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
	if (!g_DetectChargeVictim[victim].setupQueued)
	{
		g_DetectChargeVictim[victim].setupQueued = true;
		CreateTimer(0.25, Detect_TimerEmitChargerDeathSetup, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
	}
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
		if (now - g_fDetectJockeyLastShove[entity][client] <= L4D2_SKILLS_DEADSTOP_DOUBLE_TIME)
		{
			return;
		}

		g_fDetectJockeyLastShove[entity][client] = now;
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
	if (now - g_fDetectHunterLastShove[entity][client] <= L4D2_SKILLS_DEADSTOP_DOUBLE_TIME)
	{
		return;
	}

	g_fDetectHunterLastShove[entity][client] = now;
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
	bool isVictimKiller = IsValidSurvivor(attacker) && pinvictim == attacker;
	bool emitSpecialClearByKill = false;
	bool emitSelfClear = false;
	bool emitDeferredTongueCut = false;

	if (isVictimKiller && g_DetectSmoker[victim].pendingTongueCut)
	{
		emitSelfClear = true;
		emitDeferredTongueCut = !emitSelfClear;
	}
	else if (isVictimKiller && g_DetectSmoker[victim].reached)
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
		Detect_EmitSpecialClear(attacker, victim, false, true);
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
		"Jockey melee-skeet check. jockey=%d attacker=%d weapon=%s leaping=%d damage=%d",
		victim,
		attacker,
		weapon,
		Detect_IsJockeyEffectivelyLeaping(victim) ? 1 : 0,
		event.GetInt("dmg_health"));
	if (Detect_IsJockeyEffectivelyLeaping(victim) && Detect_IsSkeetWeaponMelee(weapon))
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
			g_SkillEvents[eventIndex].perfect = true;

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

	if (!Detect_IsJockeyEffectivelyLeaping(victim))
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

	int effectiveDamage[MAXPLAYERS + 1];
	Detect_BuildSiLifeEffectiveDamageByAttacker(victim, L4D2ZombieClass_Jockey, attacker, effectiveDamage);

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
	g_SkillEvents[eventIndex].actorDamage = effectiveDamage[attacker];
	g_SkillEvents[eventIndex].shots = Detect_GetSiLifeShotsByAttacker(victim, attacker);
	g_SkillEvents[eventIndex].headshot = headshot;
	g_SkillEvents[eventIndex].sniper = sniperHeadshot;
	g_SkillEvents[eventIndex].grenadeLauncher = grenadeLauncher;
	g_SkillEvents[eventIndex].actorWeaponId = view_as<int>(weaponId);
	g_SkillEvents[eventIndex].actorChipDamage = Detect_GetSiLifePreviousDamageByAttacker(victim, attacker);
	g_SkillEvents[eventIndex].actorChipShots = Detect_GetSiLifePreviousShotsByAttacker(victim, attacker);

	int assistsFound = Detect_WriteSiTrackAssistsToEventAsSkillWindow(eventIndex, victim, attacker);
	int assistDamageTotal = 0;
	for (int i = 0; i < assistsFound && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		assistDamageTotal += g_SkillEvents[eventIndex].assistDamage[i];
	}
	g_SkillEvents[eventIndex].chipDamage = g_SkillEvents[eventIndex].actorChipDamage + assistDamageTotal;

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
			g_DetectHunterShotWindow[victim].byAttacker[attacker].activeBlastDamage);
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
			Detect_EmitSpecialClear(attacker, victim, false, true);
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
		g_DetectSiLife[victim].byAttacker[attacker].shotCounted = false;
		g_DetectHunterShotWindow[victim].byAttacker[attacker].shotCounted = false;
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
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
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
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"Hunter pre-damage snapshot. hunter=%d attacker=%d current_health=%d raw=%.1f damagetype=%d spawn_health=%d last_health=%d",
				victim,
				attacker,
				g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage,
				damage,
				damagetype,
				g_iDetectHunterSpawnHealth[victim],
				g_DetectHunterDamageSnapshot[victim].lastHealth);
		}
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

	if (!g_DetectHunterShotWindow[victim].byAttacker[attacker].shotCounted)
	{
		g_DetectHunterShotWindow[victim].byAttacker[attacker].cumulativeShots++;
		g_DetectHunterShotWindow[victim].byAttacker[attacker].shotCounted = true;
	}

	int healthBeforeDamage = g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage > 0
		? g_DetectHunterDamageSnapshot[victim].lastHealthBeforeDamage
		: g_DetectHunterDamageSnapshot[victim].lastHealth;
	if (healthBeforeDamage > 0 && appliedDamage > healthBeforeDamage)
	{
		g_DetectHunterShotWindow[victim].overkillDamage = appliedDamage - healthBeforeDamage;
		appliedDamage = healthBeforeDamage;
	}

	if (g_DetectHunterShotWindow[victim].byAttacker[attacker].activeBlastDamage > 0
		&& (GetGameTime() - g_DetectHunterShotWindow[victim].byAttacker[attacker].activeBlastStart) > DETECT_SHOTGUN_BLAST_TIME)
	{
		g_DetectHunterShotWindow[victim].byAttacker[attacker].activeBlastDamage = 0;
		g_DetectHunterShotWindow[victim].byAttacker[attacker].activeBlastStart = 0.0;
	}

	int postHealth = GetClientHealth(victim);
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter post-damage snapshot. hunter=%d attacker=%d applied=%d pre=%d post=%d raw=%.1f pouncing=%d effective_pouncing=%d team_shot=%d killer_shot=%d",
			victim,
			attacker,
			appliedDamage,
			healthBeforeDamage,
			postHealth,
			damage,
			g_bDetectHunterPouncing[victim] ? 1 : 0,
			Detect_IsHunterEffectivelyPouncing(victim) ? 1 : 0,
			g_DetectHunterShotWindow[victim].teamBlastDamage,
			g_DetectHunterShotWindow[victim].byAttacker[attacker].activeBlastDamage);
	}

	bool shotgunBlast = (damagetype & DMG_BUCKSHOT) != 0;
	if (!shotgunBlast
		&& IsValidSurvivor(attacker)
		&& Skills_IsShotgunWeaponId(g_iDetectLastWeaponId[attacker])
		&& (GetGameTime() - g_fDetectLastWeaponFireTime[attacker]) <= DETECT_SHOTGUN_BLAST_TIME)
	{
		shotgunBlast = true;
	}

	if (Detect_IsHunterEffectivelyPouncing(victim) && shotgunBlast)
	{
		if (g_DetectHunterShotWindow[victim].byAttacker[attacker].activeBlastStart == 0.0)
		{
			g_DetectHunterShotWindow[victim].byAttacker[attacker].activeBlastStart = GetGameTime();
		}

		g_DetectHunterShotWindow[victim].byAttacker[attacker].activeBlastDamage += appliedDamage;
		g_DetectHunterShotWindow[victim].teamBlastDamage += appliedDamage;

		if (postHealth <= 0)
		{
			g_DetectHunterShotWindow[victim].killedPouncing = true;
		}
	}

	g_DetectHunterShotWindow[victim].byAttacker[attacker].cumulativeDamage += appliedDamage;
	g_DetectHunterDamageSnapshot[victim].lastHealth = postHealth > 0 ? postHealth : 0;
}

void Detect_OnTakeDamagePost_Client(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	bool roundLive = Skills_IsRoundLive();
	bool validInfected = IsValidInfected(victim);
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
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
