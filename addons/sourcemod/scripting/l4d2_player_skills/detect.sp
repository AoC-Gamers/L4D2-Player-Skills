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

enum struct DetectSiAssistState
{
	int attacker[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	int damage[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	int shots[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	int weaponId[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	float time[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	float lastShotTime[L4D2_SKILLS_MAX_EVENT_ASSISTS];

	void Reset()
	{
		for (int i = 0; i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
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

// Shared detector runtime state.
DetectBoomerState g_DetectBoomer[MAXPLAYERS + 1];
DetectHopState g_DetectHop[MAXPLAYERS + 1];
DetectLeapState g_DetectLeap[MAXPLAYERS + 1];
DetectSmokerState g_DetectSmoker[MAXPLAYERS + 1];
DetectDamageSnapshot g_DetectHunterDamageSnapshot[MAXPLAYERS + 1];
DetectDamageSnapshot g_DetectChargerDamageSnapshot[MAXPLAYERS + 1];
DetectChargeVictimState g_DetectChargeVictim[MAXPLAYERS + 1];
DetectSiAssistState g_DetectSiAssist[MAXPLAYERS + 1];
int g_iDetectPinnedVictim[MAXPLAYERS + 1];
int g_iDetectPinnerByVictim[MAXPLAYERS + 1];
int g_iDetectPinnedClass[MAXPLAYERS + 1];
int g_iDetectPendingBoomerKillEvent[MAXPLAYERS + 1];
float g_fDetectSpecialClearTimeA[MAXPLAYERS + 1];
float g_fDetectSpecialClearTimeB[MAXPLAYERS + 1];

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
bool g_bDetectShotCounted[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bDetectHunterShotCounted[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bDetectPendingHunterDeathEval[MAXPLAYERS + 1];
bool g_bDetectPendingHunterDeathHeadshot[MAXPLAYERS + 1];
bool g_bDetectPendingChargerDeathEval[MAXPLAYERS + 1];
float g_fDetectHunterLastShove[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_fDetectJockeyLastShove[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDetectHunterSpawnHealth[MAXPLAYERS + 1];
int g_iDetectPendingHunterDeathAttackerUserId[MAXPLAYERS + 1];
int g_iDetectPendingChargerDeathAttackerUserId[MAXPLAYERS + 1];
int g_iDetectSmokerOwnerByVictim[MAXPLAYERS + 1];
int g_iDetectHunterDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDetectHunterShots[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDetectHunterShotDmgTeam[MAXPLAYERS + 1];
int g_iDetectHunterShotDmg[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_fDetectHunterShotStart[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDetectHunterOverkill[MAXPLAYERS + 1];
bool g_bDetectHunterKilledPouncing[MAXPLAYERS + 1];
char g_sDetectPendingHunterDeathWeapon[MAXPLAYERS + 1][64];
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
		g_iDetectPinnedVictim[client] = 0;
		g_iDetectPinnerByVictim[client] = 0;
		g_iDetectPinnedClass[client] = 0;
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
		g_bDetectPendingHunterDeathEval[client] = false;
		g_bDetectPendingHunterDeathHeadshot[client] = false;
		g_bDetectPendingChargerDeathEval[client] = false;
		g_iDetectHunterSpawnHealth[client] = 0;
		g_iDetectPendingHunterDeathAttackerUserId[client] = 0;
		g_iDetectPendingChargerDeathAttackerUserId[client] = 0;
		g_sDetectPendingHunterDeathWeapon[client][0] = '\0';
		g_DetectHunterDamageSnapshot[client].Reset();
		g_DetectChargerDamageSnapshot[client].Reset();
		g_DetectChargeVictim[client].Reset();
		g_DetectSiAssist[client].Reset();
		g_DetectSmoker[client].Reset();
		g_iDetectSmokerOwnerByVictim[client] = 0;
		g_bDetectSuppressSiLifeKill[client] = false;
		g_iDetectPendingBoomerKillEvent[client] = 0;
		g_iDetectHunterShotDmgTeam[client] = 0;
		g_iDetectHunterOverkill[client] = 0;
		g_bDetectHunterKilledPouncing[client] = false;

		for (int attacker = 1; attacker <= MaxClients; attacker++)
		{
			g_bDetectShotCounted[client][attacker] = false;
			g_bDetectHunterShotCounted[client][attacker] = false;
			g_fDetectHunterLastShove[client][attacker] = 0.0;
			g_fDetectJockeyLastShove[client][attacker] = 0.0;
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

void Detect_ResetSiLifeKillTrack(int infected)
{
	if (infected < 1 || infected > MaxClients)
	{
		return;
	}

	g_DetectSiAssist[infected].Reset();
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

Action Detect_TimerAnnounceBoomerKill(Handle timer, any userid)
{
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
	int hunter = GetClientOfUserId(userid);
	if (hunter < 1 || hunter > MaxClients)
	{
		return Plugin_Stop;
	}

	if (!g_bDetectPendingHunterDeathEval[hunter])
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter death timer aborted. hunter=%d userid=%d reason=not_pending",
			hunter,
			userid);
		return Plugin_Stop;
	}

	g_bDetectPendingHunterDeathEval[hunter] = false;
	bool headshot = g_bDetectPendingHunterDeathHeadshot[hunter];
	g_bDetectPendingHunterDeathHeadshot[hunter] = false;

	int attacker = GetClientOfUserId(g_iDetectPendingHunterDeathAttackerUserId[hunter]);
	g_iDetectPendingHunterDeathAttackerUserId[hunter] = 0;
	char weapon[64];
	strcopy(weapon, sizeof(weapon), g_sDetectPendingHunterDeathWeapon[hunter]);
	g_sDetectPendingHunterDeathWeapon[hunter][0] = '\0';

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Hunter death timer firing. hunter=%d attacker=%d pending=%d",
		hunter,
		attacker,
		g_bDetectPendingHunterDeathEval[hunter] ? 1 : 0);

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

		bool killedPouncing = g_bDetectHunterKilledPouncing[hunter] || Detect_IsHunterEffectivelyPouncing(hunter);
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
			g_iDetectHunterShotDmgTeam[hunter],
			Detect_GetHunterPounceDamage(hunter, attacker),
			Detect_GetHunterPounceShots(hunter, attacker));
		Detect_LogHunterSkeetDecision(hunter, attacker, "start", hunterDecision);

		if (killedPouncing && Detect_IsSkeetWeaponMelee(weapon))
		{
			Detect_LogHunterSkeetDecision(hunter, attacker, "melee", "classified_as=HunterSkeetMelee");
			int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeetMelee);
			int eventIndex = Skills_GetEventIndex(eventId);
			if (eventIndex != -1)
			{
				g_SkillEvents[eventIndex].actor.Capture(attacker);
				g_SkillEvents[eventIndex].victim.Capture(hunter);
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

			Detect_MarkSiLifeKillSuppressed(hunter);
		}

		bool sniperSkeet = killedPouncing && headshot && Detect_IsSkeetWeaponSniper(weapon);
		bool glSkeet = killedPouncing && Detect_IsSkeetWeaponGL(weapon);
		if (!g_bDetectSuppressSiLifeKill[hunter] && (sniperSkeet || glSkeet))
		{
			bool qualifiesAtBaseline = rawDamage >= float(hunterBaselineHealth);
			FormatEx(hunterDecision, sizeof(hunterDecision),
				"sniper=%d gl=%d qualifies_at_baseline=%d raw=%.1f baseline=%d",
				sniperSkeet ? 1 : 0,
				glSkeet ? 1 : 0,
				qualifiesAtBaseline ? 1 : 0,
				rawDamage,
				hunterBaselineHealth);
			Detect_LogHunterSkeetDecision(hunter, attacker, "ranged", hunterDecision);
			if (qualifiesAtBaseline)
			{
				Detect_LogHunterSkeetDecision(hunter, attacker, "ranged", "classified_as=HunterSkeet");
				int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeet);
				int eventIndex = Skills_GetEventIndex(eventId);
				if (eventIndex != -1)
				{
					g_SkillEvents[eventIndex].actor.Capture(attacker);
					g_SkillEvents[eventIndex].victim.Capture(hunter);
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

			Detect_MarkSiLifeKillSuppressed(hunter);
		}

		if (!g_bDetectSuppressSiLifeKill[hunter] && hunterWasPouncingAtDeath && g_iDetectHunterShotDmgTeam[hunter] > 0)
		{
			int interruptDamage = g_cvDetectPounceInterrupt != null ? g_cvDetectPounceInterrupt.IntValue : 150;
			int killerDamage = Detect_GetHunterPounceDamage(hunter, attacker);
			int teamDamage = g_iDetectHunterShotDmgTeam[hunter];
			int shots = Detect_GetHunterPounceShots(hunter, attacker);
			int overkillDamage = g_iDetectHunterOverkill[hunter];
			int potentialKillerDamage = killerDamage + overkillDamage;
			int potentialTeamDamage = teamDamage + overkillDamage;
			bool isSingleSkeet = potentialKillerDamage >= interruptDamage;
			bool isTeamSkeet = potentialTeamDamage > potentialKillerDamage && potentialTeamDamage >= interruptDamage;
			bool isOverkill = overkillDamage > 0 && (isSingleSkeet || isTeamSkeet);
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

			if (isSingleSkeet || isTeamSkeet)
			{
				Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun", isTeamSkeet ? "classified_as=HunterSkeet(team)" : "classified_as=HunterSkeet(single)");
				int eventId = Skills_CreateEvent(L4D2Skill_HunterSkeet);
				int eventIndex = Skills_GetEventIndex(eventId);
				if (eventIndex != -1)
				{
					g_SkillEvents[eventIndex].actor.Capture(attacker);
					g_SkillEvents[eventIndex].victim.Capture(hunter);
					g_SkillEvents[eventIndex].damage = isTeamSkeet ? potentialTeamDamage : potentialKillerDamage;
					g_SkillEvents[eventIndex].shots = shots;
					g_SkillEvents[eventIndex].wouldQualifyAtBaseline = isOverkill;
					g_SkillEvents[eventIndex].chipDamage = Detect_GetHunterLifeDamage(hunter, attacker) - killerDamage;
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

							if (Detect_GetHunterPounceDamage(hunter, i) > topAssistDamage)
							{
								topAssistDamage = Detect_GetHunterPounceDamage(hunter, i);
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

				Detect_MarkSiLifeKillSuppressed(hunter);
			}
			else
			{
				Detect_LogHunterSkeetDecision(hunter, attacker, "shotgun", "classified_as=none");
			}
		}

		Detect_LogHunterSkeetDecision(hunter, attacker, "fallback", g_bDetectSuppressSiLifeKill[hunter] ? "classified_as=suppressed" : "classified_as=HunterKill");
		if (!g_bDetectSuppressSiLifeKill[hunter])
		{
			Detect_EmitHunterLifeKill(
				hunter,
				attacker,
				hunterHealthBeforeDamage > 0 ? hunterHealthBeforeDamage : Skills_GetSpecialMaxHealth(L4D2ZombieClass_Hunter));
		}
	}

	Detect_ResetHunter(hunter);
	Detect_ResetSiLifeKillTrack(hunter);
	return Plugin_Stop;
}

Action Detect_TimerEvaluateChargerDeath(Handle timer, any userid)
{
	int charger = GetClientOfUserId(userid);
	if (charger < 1 || charger > MaxClients)
	{
		return Plugin_Stop;
	}

	if (!g_bDetectPendingChargerDeathEval[charger])
	{
		return Plugin_Stop;
	}

	g_bDetectPendingChargerDeathEval[charger] = false;
	int attacker = GetClientOfUserId(g_iDetectPendingChargerDeathAttackerUserId[charger]);
	g_iDetectPendingChargerDeathAttackerUserId[charger] = 0;

	if (IsValidZombieClass(charger, L4D2ZombieClass_Charger)
		&& IsValidSurvivor(attacker)
		&& !g_bDetectSuppressSiLifeKill[charger])
	{
		Detect_EmitSiLifeKill(charger, attacker);
	}

	Detect_ResetCharger(charger);
	Detect_ResetSiLifeKillTrack(charger);
	return Plugin_Stop;
}

void Detect_RecordSiLifeKillDamage(int victim, int attacker, int damage, int weaponId, int damageType)
{
	if (!Detect_IsTrackableSiLifeKillClass(victim) || !IsValidSurvivor(attacker) || damage <= 0)
	{
		return;
	}

	float now = GetGameTime();
	bool countRealShots = Skills_IsRangedShotWeaponId(weaponId)
		|| (damageType & DMG_BUCKSHOT) != 0
		|| (damageType & DMG_BULLET) != 0;

	int slot = -1;
	int staleSlot = -1;
	int weakestSlot = 0;

	for (int i = 0; i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		if (g_DetectSiAssist[victim].attacker[i] == attacker)
		{
			slot = i;
			break;
		}

		if (g_DetectSiAssist[victim].attacker[i] == 0)
		{
			if (staleSlot == -1)
			{
				staleSlot = i;
			}
			continue;
		}

		if ((now - g_DetectSiAssist[victim].time[i]) > L4D2_SKILLS_SI_KILL_ASSIST_WINDOW && staleSlot == -1)
		{
			staleSlot = i;
		}

		if (g_DetectSiAssist[victim].damage[i] < g_DetectSiAssist[victim].damage[weakestSlot])
		{
			weakestSlot = i;
		}
	}

	if (slot != -1)
	{
		g_DetectSiAssist[victim].damage[slot] += damage;
		if (countRealShots)
		{
			if (!g_bDetectShotCounted[victim][attacker])
			{
				g_DetectSiAssist[victim].shots[slot]++;
				g_bDetectShotCounted[victim][attacker] = true;
			}
		}
		else
		{
			g_DetectSiAssist[victim].shots[slot]++;
		}
		g_DetectSiAssist[victim].weaponId[slot] = weaponId;
		g_DetectSiAssist[victim].time[slot] = now;
	}
	else if (staleSlot != -1)
	{
		g_DetectSiAssist[victim].attacker[staleSlot] = attacker;
		g_DetectSiAssist[victim].damage[staleSlot] = damage;
		g_DetectSiAssist[victim].shots[staleSlot] = 0;
		g_DetectSiAssist[victim].weaponId[staleSlot] = weaponId;
		g_DetectSiAssist[victim].time[staleSlot] = now;
		g_DetectSiAssist[victim].lastShotTime[staleSlot] = 0.0;
		if (countRealShots)
		{
			if (!g_bDetectShotCounted[victim][attacker])
			{
				g_DetectSiAssist[victim].shots[staleSlot] = 1;
				g_bDetectShotCounted[victim][attacker] = true;
			}
		}
		else
		{
			g_DetectSiAssist[victim].shots[staleSlot] = 1;
		}
	}
	else if (damage > g_DetectSiAssist[victim].damage[weakestSlot])
	{
		g_DetectSiAssist[victim].attacker[weakestSlot] = attacker;
		g_DetectSiAssist[victim].damage[weakestSlot] = damage;
		g_DetectSiAssist[victim].shots[weakestSlot] = 0;
		g_DetectSiAssist[victim].weaponId[weakestSlot] = weaponId;
		g_DetectSiAssist[victim].time[weakestSlot] = now;
		g_DetectSiAssist[victim].lastShotTime[weakestSlot] = 0.0;
		if (countRealShots)
		{
			if (!g_bDetectShotCounted[victim][attacker])
			{
				g_DetectSiAssist[victim].shots[weakestSlot] = 1;
				g_bDetectShotCounted[victim][attacker] = true;
			}
		}
		else
		{
			g_DetectSiAssist[victim].shots[weakestSlot] = 1;
		}
	}

	for (int pass = 0; pass < L4D2_SKILLS_MAX_EVENT_ASSISTS - 1; pass++)
	{
		for (int i = 0; i < L4D2_SKILLS_MAX_EVENT_ASSISTS - 1 - pass; i++)
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

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		char summary[256];
		summary[0] = '\0';
		for (int i = 0; i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
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
			"SI life kill damage recorded. victim=%d attacker=%d damage=%d weapon=%d damagetype=%d counted=%d summary=%s",
			victim,
			attacker,
			damage,
			weaponId,
			damageType,
			g_bDetectShotCounted[victim][attacker] ? 1 : 0,
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

int Detect_GetSiLifeContributorDamage(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	for (int i = 0; i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		if (g_DetectSiAssist[victim].attacker[i] == client)
		{
			return g_DetectSiAssist[victim].damage[i];
		}
	}

	return 0;
}

int Detect_GetSiLifeContributorShots(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	for (int i = 0; i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		if (g_DetectSiAssist[victim].attacker[i] == client)
		{
			return g_DetectSiAssist[victim].shots[i];
		}
	}

	return 0;
}

int Detect_GetSiLifeContributorWeaponId(int victim, int client)
{
	if (client <= 0)
	{
		return WEPID_NONE;
	}

	for (int i = 0; i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		if (g_DetectSiAssist[victim].attacker[i] == client)
		{
			return g_DetectSiAssist[victim].weaponId[i];
		}
	}

	return WEPID_NONE;
}

int Detect_GetHunterLifeDamage(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	return g_iDetectHunterDamage[victim][client];
}

int Detect_GetHunterLifeShots(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	return g_iDetectHunterShots[victim][client];
}

int Detect_GetHunterPounceDamage(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	return g_iDetectHunterShotDmg[victim][client];
}

int Detect_GetHunterPounceShots(int victim, int client)
{
	if (client <= 0)
	{
		return 0;
	}

	return g_iDetectHunterShots[victim][client];
}

void Detect_EmitSiLifeKill(int victim, int killer)
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
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(killer);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = zombieClass;
	g_SkillEvents[eventIndex].actorWeaponId = Detect_GetSiLifeContributorWeaponId(victim, killer);
	g_SkillEvents[eventIndex].actorDamage = Detect_GetSiLifeContributorDamage(victim, killer);
	g_SkillEvents[eventIndex].damage = g_SkillEvents[eventIndex].actorDamage;
	g_SkillEvents[eventIndex].shots = Detect_GetSiLifeContributorShots(victim, killer);

	int contributors[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	for (int i = 0; i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		contributors[i] = g_DetectSiAssist[victim].attacker[i];
	}
	int assistsFound = 0;
	int maxAssists = L4D2_SKILLS_MAX_EVENT_ASSISTS;
	if (g_cvSurvivorLimit != null && g_cvSurvivorLimit.IntValue > 1 && g_cvSurvivorLimit.IntValue - 1 < maxAssists)
	{
		maxAssists = g_cvSurvivorLimit.IntValue - 1;
	}

	for (int i = 0; i < sizeof(contributors); i++)
	{
		int assister = contributors[i];
		if (!IsValidSurvivor(assister) || assister == killer)
		{
			continue;
		}

		int assistDamage = Detect_GetSiLifeContributorDamage(victim, assister);
		if (assistDamage <= 0)
		{
			continue;
		}

		if (assistsFound >= maxAssists)
		{
			break;
		}

		g_SkillEvents[eventIndex].assists[assistsFound].Capture(assister);
		g_SkillEvents[eventIndex].assistDamage[assistsFound] = assistDamage;
		g_SkillEvents[eventIndex].assistShots[assistsFound] = Detect_GetSiLifeContributorShots(victim, assister);
		g_SkillEvents[eventIndex].assistWeaponId[assistsFound] = Detect_GetSiLifeContributorWeaponId(victim, assister);
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

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		char assistsSummary[256];
		assistsSummary[0] = '\0';
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

		Skills_Debug(PlayerSkillsDebug_Detect,
			"SI life kill payload. event=%d type=%d victim=%d killer=%d dmg=%d shots=%d assists=%d [%s]",
			eventId,
			type,
			victim,
			killer,
			g_SkillEvents[eventIndex].actorDamage,
			g_SkillEvents[eventIndex].shots,
			assistsFound,
			assistsSummary);
	}

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


void Detect_EmitHunterLifeKill(int victim, int killer, int hunterHealthBeforeDamage)
{
	if (!IsValidSurvivor(killer))
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_HunterKill);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(killer);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = L4D2ZombieClass_Hunter;
	g_SkillEvents[eventIndex].actorDamage = Detect_GetHunterLifeDamage(victim, killer);
	g_SkillEvents[eventIndex].damage = g_SkillEvents[eventIndex].actorDamage;
	g_SkillEvents[eventIndex].shots = Detect_GetHunterLifeShots(victim, killer);

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

		int assistDamage = Detect_GetHunterLifeDamage(victim, assister);
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
		g_SkillEvents[eventIndex].assistShots[assistsFound] = Detect_GetHunterLifeShots(victim, assister);
		g_SkillEvents[eventIndex].assistWeaponId[assistsFound] = WEPID_NONE;
		assistsFound++;
	}

	g_SkillEvents[eventIndex].assistsCount = assistsFound;
	if (assistsFound > 0)
	{
		g_SkillEvents[eventIndex].assister = g_SkillEvents[eventIndex].assists[0];
		g_SkillEvents[eventIndex].assisterDamage = g_SkillEvents[eventIndex].assistDamage[0];
		g_SkillEvents[eventIndex].assisterShots = g_SkillEvents[eventIndex].assistShots[0];
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

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		char assistsSummary[256];
		assistsSummary[0] = '\0';
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

		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter life kill payload. event=%d victim=%d killer=%d health_before=%d killer_dmg=%d killer_shots=%d assists=%d [%s]",
			eventId,
			victim,
			killer,
			hunterHealthBeforeDamage,
			g_SkillEvents[eventIndex].actorDamage,
			g_SkillEvents[eventIndex].shots,
			assistsFound,
			assistsSummary);
	}

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
		g_bDetectShotCounted[victim][client] = false;
		g_bDetectHunterShotCounted[victim][client] = false;
		g_fDetectHunterLastShove[victim][client] = 0.0;
		g_fDetectJockeyLastShove[victim][client] = 0.0;
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
	Detect_ResetJockeyLeapState(client);
	Detect_ResetCharger(client);
	Detect_ResetChargeTrack(client);
	Detect_ResetSiLifeKillTrack(client);
	Detect_ResetSmoker(client);
	Detect_ClearSmokerVictim(client);

	for (int victim = 1; victim <= MaxClients; victim++)
	{
		g_bDetectShotCounted[victim][client] = false;
		g_fDetectHunterLastShove[victim][client] = 0.0;
		g_fDetectJockeyLastShove[victim][client] = 0.0;
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

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger impact event. charger=%d victim=%d tracked_raw=%d tracked_effective=%d",
			charger,
			victim,
			Detect_IsChargerCharging(charger) ? 1 : 0,
			Detect_IsChargerEffectivelyCharging(charger) ? 1 : 0);
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

	if (!Skills_IsEnabled() || !IsValidSurvivor(client))
	{
		return;
	}

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
	char weapon[32];
	event.GetString("weapon", weapon, sizeof(weapon));
	int weaponId = Skills_GetWeaponIdFromEventName(weapon);

	if (damage > 0 && IsValidSurvivor(attacker) && Detect_IsTrackableSiLifeKillClass(victim))
	{
		Detect_RecordSiLifeKillDamage(victim, attacker, damage, weaponId, damageType);
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

void Detect_EventPlayerDeath(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	bool shouldEmitSiLifeKill = IsValidSurvivor(attacker) && Detect_IsTrackableSiLifeKillClass(victim);
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

			Detect_MarkSiLifeKillSuppressed(victim);
		}

		Detect_ClearPinStateByAttacker(victim);
		Detect_ResetSmoker(victim);
		if (shouldEmitSiLifeKill && !g_bDetectSuppressSiLifeKill[victim])
		{
			Detect_EmitSiLifeKill(victim, attacker);
		}
		Detect_ResetSiLifeKillTrack(victim);
		return;
	}

	if (!IsValidZombieClass(victim, L4D2ZombieClass_Hunter))
	{
		if (IsValidZombieClass(victim, L4D2ZombieClass_Jockey))
		{
		if (shouldEmitSiLifeKill && IsValidSurvivor(attacker))
		{
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

			Detect_ResetJockeyLeapState(victim);
		}

		bool pendingBoomerKill = IsValidZombieClass(victim, L4D2ZombieClass_Boomer)
			&& shouldEmitSiLifeKill
			&& !g_bDetectSuppressSiLifeKill[victim];
		bool pendingChargerKill = IsValidZombieClass(victim, L4D2ZombieClass_Charger)
			&& shouldEmitSiLifeKill
			&& !g_bDetectSuppressSiLifeKill[victim];
		if (pendingChargerKill)
		{
			g_bDetectPendingChargerDeathEval[victim] = true;
			g_iDetectPendingChargerDeathAttackerUserId[victim] = GetClientUserId(attacker);
			CreateTimer(0.1, Detect_TimerEvaluateChargerDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
		if (shouldEmitSiLifeKill && !g_bDetectSuppressSiLifeKill[victim])
		{
			Detect_EmitSiLifeKill(victim, attacker);
		}
		if (!pendingBoomerKill)
		{
			Detect_ResetSiLifeKillTrack(victim);
		}
		return;
	}

	if (shouldEmitSiLifeKill)
	{
		char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));
		g_bDetectPendingHunterDeathEval[victim] = true;
		g_bDetectPendingHunterDeathHeadshot[victim] = event.GetBool("headshot");
		g_iDetectPendingHunterDeathAttackerUserId[victim] = GetClientUserId(attacker);
		strcopy(g_sDetectPendingHunterDeathWeapon[victim], sizeof(g_sDetectPendingHunterDeathWeapon[]), weapon);
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Hunter death queued. hunter=%d attacker=%d delay=0.10 weapon=%s headshot=%d team_shot=%d killer_shot=%d",
			victim,
			attacker,
			weapon,
			g_bDetectPendingHunterDeathHeadshot[victim] ? 1 : 0,
			g_iDetectHunterShotDmgTeam[victim],
			g_iDetectHunterShotDmg[victim][attacker]);
		CreateTimer(0.1, Detect_TimerEvaluateHunterDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	Detect_ResetHunter(victim);
	Detect_ResetSiLifeKillTrack(victim);
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
	g_SkillEvents[eventIndex].shoveCount = g_DetectBoomer[boomer].shoveCount;
	g_SkillEvents[eventIndex].timeA = timeAlive;

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

	for (int victim = 1; victim <= MaxClients; victim++)
	{
		g_bDetectShotCounted[victim][attacker] = false;
		g_bDetectHunterShotCounted[victim][attacker] = false;
	}
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

		if (!g_bDetectHunterShotCounted[victim][attacker])
		{
			g_iDetectHunterShots[victim][attacker]++;
			g_bDetectHunterShotCounted[victim][attacker] = true;
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
				g_iDetectHunterShotDmgTeam[victim],
				g_iDetectHunterShotDmg[victim][attacker]);
		}

		if (Detect_IsHunterEffectivelyPouncing(victim) && (damagetype & DMG_BUCKSHOT))
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
