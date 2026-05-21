#if defined _l4d2_player_skills_detect_included
	#endinput
#endif
#define _l4d2_player_skills_detect_included

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

#define DCFLAG_FALL            (1 << 0)
#define DCFLAG_DROWN           (1 << 1)
#define DCFLAG_TRIGGER         (1 << 2)
#define DCFLAG_HURTLOTS        (1 << 3)
#define DCFLAG_AIRDEATH        (1 << 4)
#define DCFLAG_KILLEDBYOTHER   (1 << 5)
#define DCFLAG_DEADLY          (1 << 6)
#define DCFLAG_INCAP           (1 << 7)
#define DCFLAG_LEDGE           (1 << 8)

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

float g_fDetectBoomerSpawnTime[MAXPLAYERS + 1];
bool g_bDetectBoomerHitSomebody[MAXPLAYERS + 1];
int g_iDetectBoomerShoveCount[MAXPLAYERS + 1];
int g_iDetectBoomerVomitHits[MAXPLAYERS + 1];
bool g_bDetectIsHopping[MAXPLAYERS + 1];
bool g_bDetectHopCheck[MAXPLAYERS + 1];
int g_iDetectHops[MAXPLAYERS + 1];
float g_fDetectLastHop[MAXPLAYERS + 1][3];
float g_fDetectHopTopVelocity[MAXPLAYERS + 1];
bool g_bDetectLeapOriginSet[MAXPLAYERS + 1];
float g_fDetectLeapOrigin[MAXPLAYERS + 1][3];
int g_iDetectPinnedVictim[MAXPLAYERS + 1];
int g_iDetectPinnerByVictim[MAXPLAYERS + 1];
int g_iDetectPinnedClass[MAXPLAYERS + 1];
float g_fDetectSpecialClearTimeA[MAXPLAYERS + 1];
float g_fDetectSpecialClearTimeB[MAXPLAYERS + 1];

bool g_bDetectHunterPouncing[MAXPLAYERS + 1];
bool g_bDetectShotCounted[MAXPLAYERS + 1][MAXPLAYERS + 1];
float g_fDetectHunterLastShove[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDetectHunterSpawnHealth[MAXPLAYERS + 1];
int g_iDetectHunterLastHealth[MAXPLAYERS + 1];
int g_iDetectHunterLastAttacker[MAXPLAYERS + 1];
int g_iDetectHunterLastDamageType[MAXPLAYERS + 1];
int g_iDetectHunterLastHealthBeforeDamage[MAXPLAYERS + 1];
float g_fDetectHunterLastRawDamage[MAXPLAYERS + 1];
int g_iDetectChargerLastHealth[MAXPLAYERS + 1];
int g_iDetectChargerLastAttacker[MAXPLAYERS + 1];
int g_iDetectChargerLastDamageType[MAXPLAYERS + 1];
int g_iDetectChargerLastHealthBeforeDamage[MAXPLAYERS + 1];
float g_fDetectChargerLastRawDamage[MAXPLAYERS + 1];
int g_iDetectChargeOwner[MAXPLAYERS + 1];
bool g_bDetectChargeWasCarried[MAXPLAYERS + 1];
bool g_bDetectChargeSetupEmitted[MAXPLAYERS + 1];
float g_fDetectChargeStartTime[MAXPLAYERS + 1];
float g_fDetectChargeOrigin[MAXPLAYERS + 1][3];
int g_iDetectChargeFlags[MAXPLAYERS + 1];
int g_iDetectChargeMapDamage[MAXPLAYERS + 1];
float g_fDetectChargeLastMapDamageTime[MAXPLAYERS + 1];
float g_fDetectChargeIncapTime[MAXPLAYERS + 1];
int g_iDetectSmokerVictim[MAXPLAYERS + 1];
int g_iDetectSmokerOwnerByVictim[MAXPLAYERS + 1];
bool g_bDetectSmokerReached[MAXPLAYERS + 1];
bool g_bDetectSmokerShoved[MAXPLAYERS + 1];
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
ConVar g_cvDetectChargerHealth = null;
ConVar g_cvDetectHunterHighPounceHeight = null;
ConVar g_cvDetectJockeyHighPounceHeight = null;
ConVar g_cvDetectMaxPounceDistance = null;
ConVar g_cvDetectMinPounceDistance = null;
ConVar g_cvDetectMaxPounceDamage = null;
ConVar g_cvDetectInstaKillHeight = null;
ConVar g_cvDetectBHopMinStreak = null;
ConVar g_cvDetectBHopMinInitSpeed = null;
ConVar g_cvDetectBHopContSpeed = null;
float g_fDetectLastCarAlarm = 0.0;

void Detect_Init()
{
	g_smDetectCarAlarmTargets = new StringMap();
	g_smDetectCarGlassParents = new StringMap();
	g_smDetectCarPendingSurvivor = new StringMap();
	g_smDetectCarPendingReason = new StringMap();
	g_smDetectCarPendingInfected = new StringMap();
	g_smDetectCarPendingFlags = new StringMap();
	g_cvDetectPounceInterrupt = FindConVar("z_pounce_damage_interrupt");
	g_cvDetectChargerHealth = FindConVar("z_charger_health");
	g_cvDetectHunterHighPounceHeight = CreateConVar("l4d2_player_skills_hunter_high_pounce_height", "400", "Minimum vertical height for HunterHighPounce.");
	g_cvDetectJockeyHighPounceHeight = CreateConVar("l4d2_player_skills_jockey_high_pounce_height", "300", "Minimum vertical height for JockeyHighPounce.");
	g_cvDetectMaxPounceDistance = FindConVar("z_pounce_damage_range_max");
	g_cvDetectMinPounceDistance = FindConVar("z_pounce_damage_range_min");
	g_cvDetectMaxPounceDamage = FindConVar("z_hunter_max_pounce_bonus_damage");
	g_cvDetectInstaKillHeight = CreateConVar("l4d2_player_skills_charger_instakill_height", "400", "Minimum vertical drop for ChargerInstaKill.");
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
		g_fDetectBoomerSpawnTime[client] = 0.0;
		g_bDetectBoomerHitSomebody[client] = false;
		g_iDetectBoomerShoveCount[client] = 0;
		g_iDetectBoomerVomitHits[client] = 0;
		g_bDetectIsHopping[client] = false;
		g_bDetectHopCheck[client] = false;
		g_iDetectHops[client] = 0;
		g_fDetectLastHop[client][0] = 0.0;
		g_fDetectLastHop[client][1] = 0.0;
		g_fDetectLastHop[client][2] = 0.0;
		g_fDetectHopTopVelocity[client] = 0.0;
		g_bDetectLeapOriginSet[client] = false;
		g_fDetectLeapOrigin[client][0] = 0.0;
		g_fDetectLeapOrigin[client][1] = 0.0;
		g_fDetectLeapOrigin[client][2] = 0.0;
		g_iDetectPinnedVictim[client] = 0;
		g_iDetectPinnerByVictim[client] = 0;
		g_iDetectPinnedClass[client] = 0;
		g_fDetectSpecialClearTimeA[client] = -1.0;
		g_fDetectSpecialClearTimeB[client] = -1.0;
		g_bDetectHunterPouncing[client] = false;
		g_iDetectHunterSpawnHealth[client] = 0;
		g_iDetectHunterLastHealth[client] = 0;
		g_iDetectHunterLastAttacker[client] = 0;
		g_iDetectHunterLastDamageType[client] = 0;
		g_iDetectHunterLastHealthBeforeDamage[client] = 0;
		g_fDetectHunterLastRawDamage[client] = 0.0;
		g_iDetectChargerLastHealth[client] = 0;
		g_iDetectChargerLastAttacker[client] = 0;
		g_iDetectChargerLastDamageType[client] = 0;
		g_iDetectChargerLastHealthBeforeDamage[client] = 0;
		g_fDetectChargerLastRawDamage[client] = 0.0;
		g_iDetectChargeOwner[client] = 0;
		g_bDetectChargeWasCarried[client] = false;
		g_bDetectChargeSetupEmitted[client] = false;
		g_fDetectChargeStartTime[client] = 0.0;
		g_fDetectChargeOrigin[client][0] = 0.0;
		g_fDetectChargeOrigin[client][1] = 0.0;
		g_fDetectChargeOrigin[client][2] = 0.0;
		g_iDetectChargeFlags[client] = 0;
		g_iDetectChargeMapDamage[client] = 0;
		g_fDetectChargeLastMapDamageTime[client] = 0.0;
		g_fDetectChargeIncapTime[client] = 0.0;
		g_iDetectSmokerVictim[client] = 0;
		g_iDetectSmokerOwnerByVictim[client] = 0;
		g_bDetectSmokerReached[client] = false;
		g_bDetectSmokerShoved[client] = false;
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

void Detect_OnClientPutInServer(int client)
{
	if (client <= 0 || client > MaxClients)
	{
		return;
	}

	SDKHook(client, SDKHook_OnTakeDamage, Detect_OnTakeDamage_Client);
	SDKHook(client, SDKHook_OnTakeDamagePost, Detect_OnTakeDamagePost_Client);

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
	SDKUnhook(client, SDKHook_OnTakeDamage, Detect_OnTakeDamage_Client);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, Detect_OnTakeDamagePost_Client);

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

void Detect_OnGrabWithTonguePost(int victim, int attacker)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(victim) || !IsValidZombieClass(attacker, L4D2ZombieClass_Smoker))
	{
		return;
	}

	Detect_ResetSmoker(attacker);
	Detect_ClearSmokerVictim(victim);

	g_iDetectSmokerVictim[attacker] = victim;
	g_iDetectSmokerOwnerByVictim[victim] = attacker;
	g_bDetectSmokerReached[attacker] = false;
	g_bDetectSmokerShoved[attacker] = false;
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
	float threshold = g_cvDetectHunterHighPounceHeight != null ? g_cvDetectHunterHighPounceHeight.FloatValue : 400.0;
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
	g_bDetectLeapOriginSet[attacker] = false;
	g_fDetectLeapOrigin[attacker][0] = 0.0;
	g_fDetectLeapOrigin[attacker][1] = 0.0;
	g_fDetectLeapOrigin[attacker][2] = 0.0;
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
	}

	if (!Skills_IsEnabled() || !IsValidSurvivor(victim) || !IsValidZombieClass(attacker, L4D2ZombieClass_Charger))
	{
		return;
	}

	if (g_iDetectChargeOwner[victim] != attacker)
	{
		return;
	}

	if (bDeadlyCharge)
	{
		g_iDetectChargeFlags[victim] |= DCFLAG_DEADLY;
	}
}

void Detect_OnFatalFalling(int client)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_iDetectChargeOwner[client] <= 0)
	{
		return;
	}

	g_iDetectChargeFlags[client] |= DCFLAG_FALL;
}

void Detect_OnFalling(int client)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_iDetectChargeOwner[client] <= 0)
	{
		return;
	}

	g_iDetectChargeFlags[client] |= DCFLAG_FALL;
}

void Detect_OnLedgeGrabbedPost(int client)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_iDetectChargeOwner[client] <= 0)
	{
		return;
	}

	g_iDetectChargeFlags[client] |= DCFLAG_LEDGE;
	Detect_EmitChargerDeathSetup(client, false, true);
}

void Detect_OnIncapacitatedPost(int client, int attacker, int damagetype)
{
	if (!Skills_IsEnabled() || !IsValidSurvivor(client) || g_iDetectChargeOwner[client] <= 0)
	{
		return;
	}

	if (attacker > 0 && attacker != g_iDetectChargeOwner[client])
	{
		return;
	}

	g_iDetectChargeFlags[client] |= DCFLAG_INCAP;
	g_fDetectChargeIncapTime[client] = GetGameTime();

	if (damagetype & DMG_FALL)
	{
		g_iDetectChargeFlags[client] |= DCFLAG_FALL;
	}

	if (L4D_IsPlayerHangingFromLedge(client))
	{
		g_iDetectChargeFlags[client] |= DCFLAG_LEDGE;
	}

	Detect_EmitChargerDeathSetup(client, true, (g_iDetectChargeFlags[client] & DCFLAG_LEDGE) != 0);
}

void Detect_EventPlayerIncapacitatedStart(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(victim) || g_iDetectChargeOwner[victim] <= 0)
	{
		return;
	}

	g_iDetectChargeFlags[victim] |= DCFLAG_INCAP;
	g_fDetectChargeIncapTime[victim] = GetGameTime();

	if (L4D_IsPlayerHangingFromLedge(victim))
	{
		g_iDetectChargeFlags[victim] |= DCFLAG_LEDGE;
	}

	Detect_EmitChargerDeathSetup(victim, true, (g_iDetectChargeFlags[victim] & DCFLAG_LEDGE) != 0);
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

	if (IsValidSurvivor(victim) && g_iDetectChargeOwner[victim] > 0 && damage > 0)
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
		else if (attacker != g_iDetectChargeOwner[victim])
		{
			g_iDetectChargeFlags[victim] |= DCFLAG_KILLEDBYOTHER;
		}

		if (L4D_IsPlayerHangingFromLedge(victim))
		{
			g_iDetectChargeFlags[victim] |= DCFLAG_LEDGE;
		}
	}

	if (IsValidZombieClass(victim, L4D2ZombieClass_Charger) && IsValidSurvivor(attacker))
	{
		Detect_HandleChargerHurt(event, victim, attacker);
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

	int health = event.GetInt("health");
	if (damage <= 0)
	{
		return;
	}

	if (!g_bDetectShotCounted[victim][attacker])
	{
		g_iDetectHunterShots[victim][attacker]++;
		g_bDetectShotCounted[victim][attacker] = true;
	}

	if (g_iDetectHunterLastHealth[victim] > 0 && damage > g_iDetectHunterLastHealth[victim])
	{
		g_iDetectHunterOverkill[victim] = damage - g_iDetectHunterLastHealth[victim];
		damage = g_iDetectHunterLastHealth[victim];
	}

	if (g_iDetectHunterShotDmg[victim][attacker] > 0
		&& (GetGameTime() - g_fDetectHunterShotStart[victim][attacker]) > DETECT_SHOTGUN_BLAST_TIME)
	{
		g_iDetectHunterShotDmg[victim][attacker] = 0;
		g_fDetectHunterShotStart[victim][attacker] = 0.0;
	}

	if (g_bDetectHunterPouncing[victim] && (damageType & DMG_BUCKSHOT))
	{
		if (g_fDetectHunterShotStart[victim][attacker] == 0.0)
		{
			g_fDetectHunterShotStart[victim][attacker] = GetGameTime();
		}

		g_iDetectHunterShotDmg[victim][attacker] += damage;
		g_iDetectHunterShotDmgTeam[victim] += damage;

		if (health == 0)
		{
			g_bDetectHunterKilledPouncing[victim] = true;
		}
	}

	if (health > 0)
	{
		g_iDetectHunterDamage[victim][attacker] += damage;
		g_iDetectHunterLastHealth[victim] = health;
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
		if (g_iDetectChargeOwner[victim] > 0 && !L4D_IsPlayerIncapacitated(victim))
		{
			g_iDetectChargeFlags[victim] |= DCFLAG_AIRDEATH;
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
			&& g_iDetectSmokerVictim[victim] == attacker
			&& g_bDetectSmokerReached[victim])
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
		int hunterHealthBeforeDamage = g_iDetectHunterLastHealthBeforeDamage[victim] > 0
			? g_iDetectHunterLastHealthBeforeDamage[victim]
			: g_iDetectHunterLastHealth[victim];
		int hunterBaselineHealth = g_iDetectHunterSpawnHealth[victim] > 0
			? g_iDetectHunterSpawnHealth[victim]
			: hunterHealthBeforeDamage;
		int chipDamage = hunterBaselineHealth - hunterHealthBeforeDamage;
		if (chipDamage < 0)
		{
			chipDamage = 0;
		}

		float rawDamage = g_fDetectHunterLastRawDamage[victim];
		if (g_iDetectHunterLastAttacker[victim] != attacker)
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

		g_iDetectHunterDamage[victim][attacker] += g_iDetectHunterLastHealth[victim];

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
			g_iDetectHunterLastHealth[client] = g_iDetectHunterSpawnHealth[client];
		}
		else if (IsValidZombieClass(client, L4D2ZombieClass_Charger))
		{
			g_iDetectChargerLastHealth[client] = GetClientHealth(client);
		}

		return;
	}

	g_fDetectBoomerSpawnTime[client] = GetGameTime();
	g_bDetectBoomerHitSomebody[client] = false;
	g_iDetectBoomerShoveCount[client] = 0;
	g_iDetectBoomerVomitHits[client] = 0;
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
		g_iDetectBoomerShoveCount[victim]++;
	}
	else if (Detect_IsPinnedClass(victim) && Detect_IsValidTeamClear(attacker, victim))
	{
		Detect_EmitSpecialClear(attacker, victim, true);
	}
	else if (IsValidZombieClass(victim, L4D2ZombieClass_Smoker)
		&& g_iDetectSmokerVictim[victim] == attacker
		&& g_bDetectSmokerReached[victim])
	{
		g_bDetectSmokerShoved[victim] = true;
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

	g_bDetectBoomerHitSomebody[attacker] = true;

	if (!event.GetBool("exploded"))
	{
		if (g_iDetectBoomerVomitHits[attacker] == 0)
		{
			CreateTimer(L4D2_SKILLS_BOOMER_VOMIT_WINDOW, Detect_TimerBoomerVomitCheck, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
		}

		g_iDetectBoomerVomitHits[attacker]++;
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

	if (event.GetBool("splashedbile") || g_bDetectBoomerHitSomebody[boomer])
	{
		if (g_iDetectBoomerVomitHits[boomer] > 0)
		{
			Detect_EmitBoomerVomitLanded(boomer, g_iDetectBoomerVomitHits[boomer]);
		}

		Detect_ResetBoomer(boomer);
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker))
	{
		return;
	}

	float timeAlive = g_fDetectBoomerSpawnTime[boomer] > 0.0 ? (GetGameTime() - g_fDetectBoomerSpawnTime[boomer]) : 0.0;
	int eventId = Skills_CreateEvent(L4D2Skill_BoomerPop);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(attacker);
	g_SkillEvents[eventIndex].victim.Capture(boomer);
	g_SkillEvents[eventIndex].shoveCount = g_iDetectBoomerShoveCount[boomer];
	g_SkillEvents[eventIndex].timeA = timeAlive;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_BoomerPop);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	Detect_ResetBoomer(boomer);
}

Action Detect_TimerBoomerVomitCheck(Handle timer, any userid)
{
	int boomer = GetClientOfUserId(userid);
	if (!IsValidZombieClass(boomer, L4D2ZombieClass_Boomer))
	{
		return Plugin_Stop;
	}

	int amount = g_iDetectBoomerVomitHits[boomer];
	g_iDetectBoomerVomitHits[boomer] = 0;
	if (amount <= 0)
	{
		return Plugin_Stop;
	}

	Detect_EmitBoomerVomitLanded(boomer, amount);
	return Plugin_Stop;
}

Action Detect_TimerCheckHop(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidSurvivor(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		g_bDetectHopCheck[client] = true;
		CreateTimer(L4D2_SKILLS_HOPEND_CHECK_TIME, Detect_TimerCheckHopStreak, userid, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

Action Detect_TimerCheckHopStreak(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidSurvivor(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	if (g_bDetectHopCheck[client] && g_iDetectHops[client] > 0)
	{
		Detect_FinishBHopStreak(client);
	}

	return Plugin_Stop;
}

void Detect_EventTriggeredCarAlarm()
{
	g_fDetectLastCarAlarm = GetGameTime();
}

void Detect_EventChokeStart(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int smoker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) || !IsValidSurvivor(victim))
	{
		return;
	}

	g_iDetectSmokerVictim[smoker] = victim;
	g_iDetectSmokerOwnerByVictim[victim] = smoker;
	g_bDetectSmokerReached[smoker] = true;
	g_fDetectSpecialClearTimeA[smoker] = GetGameTime();
}

void Detect_EventTonguePullStopped(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int stopper = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!IsValidSurvivor(victim))
	{
		return;
	}

	int smoker = g_iDetectSmokerOwnerByVictim[victim];
	if (!IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		smoker = L4D_GetAttackerSmoker(victim);
	}

	bool hasReachedSmoker = false;
	if (IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		hasReachedSmoker = g_bDetectSmokerReached[smoker] || L4D_HasReachedSmoker(victim);
		if (hasReachedSmoker)
		{
			g_bDetectSmokerReached[smoker] = true;
		}
	}

	if (stopper == victim && IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) && !hasReachedSmoker)
	{
		int eventId = Skills_CreateEvent(L4D2Skill_SmokerTongueCut);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(victim);
			g_SkillEvents[eventIndex].victim.Capture(smoker);

			Action result = API_FireSkillDetected(eventId, L4D2Skill_SmokerTongueCut);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}
	else if (stopper != victim && IsValidSurvivor(stopper) && IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		float now = GetGameTime();
		int eventId = Skills_CreateEvent(L4D2Skill_SpecialPinClear);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(stopper);
			g_SkillEvents[eventIndex].victim.Capture(smoker);
			g_SkillEvents[eventIndex].zombieClass = L4D2ZombieClass_Smoker;
			g_SkillEvents[eventIndex].timeA = g_fDetectSpecialClearTimeA[smoker] >= 0.0 ? (now - g_fDetectSpecialClearTimeA[smoker]) : -1.0;
			g_SkillEvents[eventIndex].timeB = g_fDetectSpecialClearTimeB[smoker] >= 0.0 ? (now - g_fDetectSpecialClearTimeB[smoker]) : -1.0;
			g_SkillEvents[eventIndex].withShove = false;
			g_SkillEvents[eventIndex].pinVictim.Capture(victim);

			Action clearResult = API_FireSkillDetected(eventId, L4D2Skill_SpecialPinClear);
			if (clearResult < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}
	else if (stopper == victim && IsValidZombieClass(smoker, L4D2ZombieClass_Smoker) && hasReachedSmoker && g_bDetectSmokerShoved[smoker])
	{
		int eventId = Skills_CreateEvent(L4D2Skill_SmokerSelfClear);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(victim);
			g_SkillEvents[eventIndex].victim.Capture(smoker);
			g_SkillEvents[eventIndex].withShove = true;

			Action result = API_FireSkillDetected(eventId, L4D2Skill_SmokerSelfClear);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}

	if (IsValidZombieClass(smoker, L4D2ZombieClass_Smoker))
	{
		Detect_ClearPinStateByAttacker(smoker);
		Detect_ResetSmoker(smoker);
	}
	Detect_ClearSmokerVictim(victim);
}

void Detect_EventAbilityUse(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(client, L4D2ZombieClass_Hunter))
	{
		return;
	}

	char ability[64];
	event.GetString("ability", ability, sizeof(ability));
	if (StrEqual(ability, "ability_lunge"))
	{
		Detect_ResetHunter(client);
		g_bDetectHunterPouncing[client] = true;
		g_iDetectHunterLastHealth[client] = GetClientHealth(client);
		GetClientAbsOrigin(client, g_fDetectLeapOrigin[client]);
		g_bDetectLeapOriginSet[client] = true;
		CreateTimer(0.5, Timer_DetectHunterGroundedCheck, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Detect_OnTankRockReleasePost(int tank, int rock)
{
	if (!Skills_IsEnabled() || !IsValidEntity(rock) || rock <= MaxClients)
	{
		return;
	}

	int slot = Detect_FindRockSlot(rock);
	if (slot == -1)
	{
		slot = Detect_FindFreeRockSlot();
	}

	if (slot == -1)
	{
		return;
	}

	g_DetectRocks[slot].Reset();
	g_DetectRocks[slot].active = true;
	g_DetectRocks[slot].entityRef = EntIndexToEntRef(rock);
	g_DetectRocks[slot].tank.Capture(tank);
	g_DetectRocks[slot].releasedAt = GetGameTime();
	Boss_OnTankRockReleased(tank);
	SDKHook(rock, SDKHook_TraceAttack, Detect_TraceAttack_Rock);
}

void Detect_OnTankRockBounceTouchPost(int tank, int rock, int entity)
{
	if (tank < -1)
	{
		return;
	}

	int slot = Detect_FindRockSlot(rock);
	if (slot == -1)
	{
		return;
	}

	if (IsValidSurvivor(entity))
	{
		if (!g_DetectRocks[slot].hit)
		{
			int tankClient = g_DetectRocks[slot].tank.ResolveClient();
			if (tankClient > 0)
			{
				Boss_OnTankRockConnected(tankClient);
			}
			Detect_EmitTankRockHit(g_DetectRocks[slot].tank, entity);
			g_DetectRocks[slot].hit = true;
		}
	}

	g_DetectRocks[slot].touched = true;
}

void Detect_OnTankRockDetonate(int tank, int rock)
{
	if (tank < -1)
	{
		return;
	}

	Detect_QueueRockFinalize(rock);
}

int Detect_FindRockSlot(int rock)
{
	int rockRef = rock > 0 ? EntIndexToEntRef(rock) : INVALID_ENT_REFERENCE;
	for (int slot = 0; slot < L4D2_SKILLS_MAX_ROCKS; slot++)
	{
		if (g_DetectRocks[slot].active && g_DetectRocks[slot].entityRef == rockRef)
		{
			return slot;
		}
	}

	return -1;
}

int Detect_FindFreeRockSlot()
{
	for (int slot = 0; slot < L4D2_SKILLS_MAX_ROCKS; slot++)
	{
		if (!g_DetectRocks[slot].active)
		{
			return slot;
		}
	}

	return -1;
}

void Detect_FinalizeRock(int rock)
{
	int slot = Detect_FindRockSlot(rock);
	if (slot == -1)
	{
		return;
	}

	if (!g_DetectRocks[slot].touched
		&& !g_DetectRocks[slot].hit
		&& g_DetectRocks[slot].totalDamage > 0
		&& IsValidSurvivor(g_DetectRocks[slot].lastShooter))
	{
		Detect_EmitTankRockSkeet(g_DetectRocks[slot].lastShooter, g_DetectRocks[slot].tank);
	}

	int entity = EntRefToEntIndex(g_DetectRocks[slot].entityRef);
	if (entity > MaxClients && IsValidEntity(entity))
	{
		SDKUnhook(entity, SDKHook_TraceAttack, Detect_TraceAttack_Rock);
	}

	g_DetectRocks[slot].Reset();
}

void Detect_QueueRockFinalize(int rock)
{
	int slot = Detect_FindRockSlot(rock);
	if (slot == -1 || g_DetectRocks[slot].finalizeQueued)
	{
		return;
	}

	g_DetectRocks[slot].finalizeQueued = true;
	CreateTimer(L4D2_SKILLS_ROCK_FINALIZE_DELAY, Detect_TimerFinalizeRock, g_DetectRocks[slot].entityRef, TIMER_FLAG_NO_MAPCHANGE);
}

Action Detect_TimerFinalizeRock(Handle timer, any rockRef)
{
	int rock = EntRefToEntIndex(rockRef);
	if (rock == INVALID_ENT_REFERENCE)
	{
		for (int slot = 0; slot < L4D2_SKILLS_MAX_ROCKS; slot++)
		{
			if (g_DetectRocks[slot].active && g_DetectRocks[slot].entityRef == rockRef)
			{
				if (!g_DetectRocks[slot].touched
					&& !g_DetectRocks[slot].hit
					&& g_DetectRocks[slot].totalDamage > 0
					&& IsValidSurvivor(g_DetectRocks[slot].lastShooter))
				{
					Detect_EmitTankRockSkeet(g_DetectRocks[slot].lastShooter, g_DetectRocks[slot].tank);
				}

				g_DetectRocks[slot].Reset();
				break;
			}
		}

		return Plugin_Stop;
	}

	Detect_FinalizeRock(rock);
	return Plugin_Stop;
}

void Detect_MarkTankRockHit(int tank, int survivor)
{
	int slot = Detect_FindLatestRockByTank(tank);
	if (slot == -1)
	{
		return;
	}

	g_DetectRocks[slot].touched = true;
	if (!g_DetectRocks[slot].hit)
	{
		int tankClient = g_DetectRocks[slot].tank.ResolveClient();
		if (tankClient > 0)
		{
			Boss_OnTankRockConnected(tankClient);
		}
		Detect_EmitTankRockHit(g_DetectRocks[slot].tank, survivor);
		g_DetectRocks[slot].hit = true;
	}
}

int Detect_FindLatestRockByTank(int tank)
{
	int bestSlot = -1;
	float bestTime = 0.0;

	for (int slot = 0; slot < L4D2_SKILLS_MAX_ROCKS; slot++)
	{
		if (!g_DetectRocks[slot].active || g_DetectRocks[slot].touched)
		{
			continue;
		}

		if (!g_DetectRocks[slot].tank.IsSameRuntimePlayer(tank) && !g_DetectRocks[slot].tank.IsSamePersistentPlayer(tank))
		{
			continue;
		}

		if (bestSlot == -1 || g_DetectRocks[slot].releasedAt > bestTime)
		{
			bestSlot = slot;
			bestTime = g_DetectRocks[slot].releasedAt;
		}
	}

	return bestSlot;
}

Action Detect_TraceAttack_Rock(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!IsValidSurvivor(attacker))
	{
		return Plugin_Continue;
	}

	int slot = Detect_FindRockSlot(victim);
	if (slot == -1 || g_DetectRocks[slot].touched || g_DetectRocks[slot].hit)
	{
		return Plugin_Continue;
	}

	int roundedDamage = RoundToFloor(damage);
	if (roundedDamage > 0)
	{
		g_DetectRocks[slot].totalDamage += roundedDamage;
		g_DetectRocks[slot].lastShooter = attacker;
	}

	return Plugin_Continue;
}

void Detect_EmitTankRockSkeet(int shooter, L4D2PlayerRef tank)
{
	int eventId = Skills_CreateEvent(L4D2Skill_TankRockSkeet);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(shooter);
	g_SkillEvents[eventIndex].victim = tank;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_TankRockSkeet);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_EmitTankRockHit(L4D2PlayerRef tank, int survivor)
{
	int eventId = Skills_CreateEvent(L4D2Skill_TankRockHit);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor = tank;
	g_SkillEvents[eventIndex].victim.Capture(survivor);

	Action result = API_FireSkillDetected(eventId, L4D2Skill_TankRockHit);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
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

void Detect_EventPlayerJump(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(client) || !IsPlayerAlive(client))
	{
		return;
	}

	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	velocity[2] = 0.0;

	float newSpeed = GetVectorLength(velocity);
	g_bDetectHopCheck[client] = false;

	if (!g_bDetectIsHopping[client])
	{
		float minInitSpeed = g_cvDetectBHopMinInitSpeed != null ? g_cvDetectBHopMinInitSpeed.FloatValue : 150.0;
		if (newSpeed >= minInitSpeed)
		{
			g_fDetectHopTopVelocity[client] = newSpeed;
			g_bDetectIsHopping[client] = true;
			g_iDetectHops[client] = 0;
		}
	}
	else
	{
		float oldSpeed = GetVectorLength(g_fDetectLastHop[client]);
		float keepSpeed = g_cvDetectBHopContSpeed != null ? g_cvDetectBHopContSpeed.FloatValue : 300.0;
		if ((newSpeed - oldSpeed) > L4D2_SKILLS_HOP_ACCEL_THRESH || newSpeed >= keepSpeed)
		{
			g_iDetectHops[client]++;
			if (newSpeed > g_fDetectHopTopVelocity[client])
			{
				g_fDetectHopTopVelocity[client] = newSpeed;
			}
		}
		else
		{
			Detect_FinishBHopStreak(client);
		}
	}

	g_fDetectLastHop[client][0] = velocity[0];
	g_fDetectLastHop[client][1] = velocity[1];
	g_fDetectLastHop[client][2] = velocity[2];

	if (g_iDetectHops[client] != 0)
	{
		CreateTimer(L4D2_SKILLS_HOP_CHECK_TIME, Detect_TimerCheckHop, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Detect_EventPlayerJumpApex(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(client, L4D2ZombieClass_Hunter) && !IsValidZombieClass(client, L4D2ZombieClass_Jockey))
	{
		if (IsValidSurvivor(client) && g_bDetectIsHopping[client])
		{
			float velocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
			velocity[2] = 0.0;
			float length = GetVectorLength(velocity);
			if (length > g_fDetectHopTopVelocity[client])
			{
				g_fDetectHopTopVelocity[client] = length;
			}
		}
		return;
	}

	GetClientAbsOrigin(client, g_fDetectLeapOrigin[client]);
	g_bDetectLeapOriginSet[client] = true;
}

void Detect_EventJockeyRide(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int jockey = GetClientOfUserId(event.GetInt("userid"));
	int survivor = GetClientOfUserId(event.GetInt("victim"));
	if (!IsValidZombieClass(jockey, L4D2ZombieClass_Jockey) || !IsValidSurvivor(survivor))
	{
		return;
	}

	float height = Detect_GetLeapHeight(jockey, survivor);
	float threshold = g_cvDetectJockeyHighPounceHeight != null ? g_cvDetectJockeyHighPounceHeight.FloatValue : 300.0;
	bool reportedHigh = height >= threshold;
	if (!reportedHigh)
	{
		g_bDetectLeapOriginSet[jockey] = false;
		g_fDetectLeapOrigin[jockey][0] = 0.0;
		g_fDetectLeapOrigin[jockey][1] = 0.0;
		g_fDetectLeapOrigin[jockey][2] = 0.0;
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_JockeyHighPounce);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		g_SkillEvents[eventIndex].actor.Capture(jockey);
		g_SkillEvents[eventIndex].victim.Capture(survivor);
		g_SkillEvents[eventIndex].height = height;
		g_SkillEvents[eventIndex].reportedHigh = true;

		Action result = API_FireSkillDetected(eventId, L4D2Skill_JockeyHighPounce);
		if (result < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
	}

	g_bDetectLeapOriginSet[jockey] = false;
	g_fDetectLeapOrigin[jockey][0] = 0.0;
	g_fDetectLeapOrigin[jockey][1] = 0.0;
	g_fDetectLeapOrigin[jockey][2] = 0.0;
}

Action Timer_DetectHunterGroundedCheck(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		return Plugin_Continue;
	}

	if (client > 0)
	{
		g_bDetectHunterPouncing[client] = false;
	}

	return Plugin_Stop;
}

void Detect_ResetHunter(int hunter)
{
	g_bDetectHunterPouncing[hunter] = false;
	g_bDetectLeapOriginSet[hunter] = false;
	g_fDetectLeapOrigin[hunter][0] = 0.0;
	g_fDetectLeapOrigin[hunter][1] = 0.0;
	g_fDetectLeapOrigin[hunter][2] = 0.0;
	g_iDetectHunterSpawnHealth[hunter] = 0;
	g_iDetectHunterLastHealth[hunter] = 0;
	g_iDetectHunterLastAttacker[hunter] = 0;
	g_iDetectHunterLastDamageType[hunter] = 0;
	g_iDetectHunterLastHealthBeforeDamage[hunter] = 0;
	g_fDetectHunterLastRawDamage[hunter] = 0.0;
	g_iDetectHunterShotDmgTeam[hunter] = 0;
	g_iDetectHunterOverkill[hunter] = 0;
	g_bDetectHunterKilledPouncing[hunter] = false;

	for (int attacker = 1; attacker <= MaxClients; attacker++)
	{
		g_bDetectShotCounted[hunter][attacker] = false;
		g_fDetectHunterLastShove[hunter][attacker] = 0.0;
		g_iDetectHunterDamage[hunter][attacker] = 0;
		g_iDetectHunterShots[hunter][attacker] = 0;
		g_iDetectHunterShotDmg[hunter][attacker] = 0;
		g_fDetectHunterShotStart[hunter][attacker] = 0.0;
	}
}

float Detect_GetLeapHeight(int attacker, int victim)
{
	float attackerOrigin[3];
	float victimOrigin[3];

	if (g_bDetectLeapOriginSet[attacker])
	{
		attackerOrigin[0] = g_fDetectLeapOrigin[attacker][0];
		attackerOrigin[1] = g_fDetectLeapOrigin[attacker][1];
		attackerOrigin[2] = g_fDetectLeapOrigin[attacker][2];
	}
	else
	{
		GetClientAbsOrigin(attacker, attackerOrigin);
	}

	GetClientAbsOrigin(victim, victimOrigin);

	float height = attackerOrigin[2] - victimOrigin[2];
	return height > 0.0 ? height : 0.0;
}

float Detect_GetLeapDistance(int attacker, int victim)
{
	float attackerOrigin[3];
	float victimOrigin[3];

	if (g_bDetectLeapOriginSet[attacker])
	{
		attackerOrigin[0] = g_fDetectLeapOrigin[attacker][0];
		attackerOrigin[1] = g_fDetectLeapOrigin[attacker][1];
		attackerOrigin[2] = g_fDetectLeapOrigin[attacker][2];
	}
	else
	{
		GetClientAbsOrigin(attacker, attackerOrigin);
	}

	GetClientAbsOrigin(victim, victimOrigin);
	return GetVectorDistance(attackerOrigin, victimOrigin);
}

float Detect_CalculateHunterPounceDamage(float distance)
{
	float minDistance = g_cvDetectMinPounceDistance != null ? g_cvDetectMinPounceDistance.FloatValue : 300.0;
	float maxDistance = g_cvDetectMaxPounceDistance != null ? g_cvDetectMaxPounceDistance.FloatValue : 1000.0;
	float maxBonusDamage = g_cvDetectMaxPounceDamage != null ? g_cvDetectMaxPounceDamage.FloatValue : 24.0;

	if (distance <= minDistance)
	{
		return 1.0;
	}

	if (distance >= maxDistance || maxDistance <= minDistance)
	{
		return 1.0 + maxBonusDamage;
	}

	float ratio = (distance - minDistance) / (maxDistance - minDistance);
	return 1.0 + (ratio * maxBonusDamage);
}

void Detect_ResetBoomer(int boomer)
{
	if (boomer < 1 || boomer > MaxClients)
	{
		return;
	}

	g_fDetectBoomerSpawnTime[boomer] = 0.0;
	g_bDetectBoomerHitSomebody[boomer] = false;
	g_iDetectBoomerShoveCount[boomer] = 0;
	g_iDetectBoomerVomitHits[boomer] = 0;
}

void Detect_ResetBHop(int client)
{
	if (client < 1 || client > MaxClients)
	{
		return;
	}

	g_bDetectIsHopping[client] = false;
	g_bDetectHopCheck[client] = false;
	g_iDetectHops[client] = 0;
	g_fDetectLastHop[client][0] = 0.0;
	g_fDetectLastHop[client][1] = 0.0;
	g_fDetectLastHop[client][2] = 0.0;
	g_fDetectHopTopVelocity[client] = 0.0;
}

void Detect_EmitBoomerVomitLanded(int boomer, int amount)
{
	if (!IsValidZombieClass(boomer, L4D2ZombieClass_Boomer) || amount <= 0)
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_BoomerVomitLanded);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(boomer);
	g_SkillEvents[eventIndex].amount = amount;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_BoomerVomitLanded);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_FinishBHopStreak(int client)
{
	if (client < 1 || client > MaxClients)
	{
		return;
	}

	int minStreak = g_cvDetectBHopMinStreak != null ? g_cvDetectBHopMinStreak.IntValue : 3;
	if (g_iDetectHops[client] >= minStreak)
	{
		int eventId = Skills_CreateEvent(L4D2Skill_BunnyHopStreak);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(client);
			g_SkillEvents[eventIndex].streak = g_iDetectHops[client];
			g_SkillEvents[eventIndex].maxVelocity = g_fDetectHopTopVelocity[client];

			Action result = API_FireSkillDetected(eventId, L4D2Skill_BunnyHopStreak);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}

	Detect_ResetBHop(client);
}

void Detect_ResetCharger(int charger)
{
	if (charger < 1 || charger > MaxClients)
	{
		return;
	}

	g_iDetectChargerLastHealth[charger] = 0;
	g_iDetectChargerLastAttacker[charger] = 0;
	g_iDetectChargerLastDamageType[charger] = 0;
	g_iDetectChargerLastHealthBeforeDamage[charger] = 0;
	g_fDetectChargerLastRawDamage[charger] = 0.0;
}

void Detect_ResetChargeTrack(int survivor)
{
	if (survivor < 1 || survivor > MaxClients)
	{
		return;
	}

	g_iDetectChargeOwner[survivor] = 0;
	g_bDetectChargeWasCarried[survivor] = false;
	g_bDetectChargeSetupEmitted[survivor] = false;
	g_fDetectChargeStartTime[survivor] = 0.0;
	g_fDetectChargeOrigin[survivor][0] = 0.0;
	g_fDetectChargeOrigin[survivor][1] = 0.0;
	g_fDetectChargeOrigin[survivor][2] = 0.0;
	g_iDetectChargeFlags[survivor] = 0;
	g_iDetectChargeMapDamage[survivor] = 0;
	g_fDetectChargeLastMapDamageTime[survivor] = 0.0;
	g_fDetectChargeIncapTime[survivor] = 0.0;
}

void Detect_MarkChargeMapDamage(int victim, int damage, int damageType, bool byTrigger)
{
	if (victim < 1 || victim > MaxClients || damage <= 0)
	{
		return;
	}

	g_iDetectChargeMapDamage[victim] += damage;
	g_fDetectChargeLastMapDamageTime[victim] = GetGameTime();

	if (damageType & DMG_FALL)
	{
		g_iDetectChargeFlags[victim] |= DCFLAG_FALL;
	}

	if (damageType & DMG_DROWN)
	{
		g_iDetectChargeFlags[victim] |= DCFLAG_DROWN;
	}

	if (byTrigger)
	{
		g_iDetectChargeFlags[victim] |= DCFLAG_TRIGGER;
	}

	if (damage >= L4D2_SKILLS_CHARGE_MIN_MAP_DAMAGE)
	{
		g_iDetectChargeFlags[victim] |= DCFLAG_HURTLOTS;
	}
}

bool Detect_HasRecentChargeMapDamage(int victim)
{
	return victim >= 1
		&& victim <= MaxClients
		&& g_iDetectChargeMapDamage[victim] >= L4D2_SKILLS_CHARGE_MIN_MAP_DAMAGE
		&& g_fDetectChargeLastMapDamageTime[victim] > 0.0
		&& (GetGameTime() - g_fDetectChargeLastMapDamageTime[victim]) <= L4D2_SKILLS_CHARGE_MAP_RECHECK_WINDOW;
}

void Detect_FormatEntityKey(int entity, char[] buffer, int maxlen)
{
	FormatEx(buffer, maxlen, "%x", entity);
}

void Detect_RemoveCarAlarmTracking(int entity)
{
	if (g_smDetectCarAlarmTargets == null || g_smDetectCarGlassParents == null || g_smDetectCarPendingSurvivor == null)
	{
		return;
	}

	char key[16];
	Detect_FormatEntityKey(entity, key, sizeof(key));
	g_smDetectCarGlassParents.Remove(key);
	g_smDetectCarPendingSurvivor.Remove(key);
	if (g_smDetectCarPendingReason != null)
	{
		g_smDetectCarPendingReason.Remove(key);
	}
	if (g_smDetectCarPendingInfected != null)
	{
		g_smDetectCarPendingInfected.Remove(key);
	}
	if (g_smDetectCarPendingFlags != null)
	{
		g_smDetectCarPendingFlags.Remove(key);
	}
}

void Detect_ResetSmoker(int smoker)
{
	if (smoker < 1 || smoker > MaxClients)
	{
		return;
	}

	int victim = g_iDetectSmokerVictim[smoker];
	g_iDetectSmokerVictim[smoker] = 0;
	g_bDetectSmokerReached[smoker] = false;
	g_bDetectSmokerShoved[smoker] = false;

	if (victim > 0 && victim <= MaxClients && g_iDetectSmokerOwnerByVictim[victim] == smoker)
	{
		g_iDetectSmokerOwnerByVictim[victim] = 0;
	}
}

void Detect_ClearSmokerVictim(int victim)
{
	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	int smoker = g_iDetectSmokerOwnerByVictim[victim];
	g_iDetectSmokerOwnerByVictim[victim] = 0;

	if (smoker > 0 && smoker <= MaxClients && g_iDetectSmokerVictim[smoker] == victim)
	{
		g_iDetectSmokerVictim[smoker] = 0;
		g_bDetectSmokerReached[smoker] = false;
	}
}

void Detect_SetPinState(int attacker, int victim, int zombieClass, float timeA, float timeB)
{
	if (attacker < 1 || attacker > MaxClients || victim < 1 || victim > MaxClients)
	{
		return;
	}

	Detect_ClearPinStateByAttacker(attacker);
	Detect_ClearPinStateByVictim(victim);

	g_iDetectPinnedVictim[attacker] = victim;
	g_iDetectPinnerByVictim[victim] = attacker;
	g_iDetectPinnedClass[attacker] = zombieClass;
	g_fDetectSpecialClearTimeA[attacker] = timeA;
	g_fDetectSpecialClearTimeB[attacker] = timeB;
}

void Detect_ClearPinStateByAttacker(int attacker)
{
	if (attacker < 1 || attacker > MaxClients)
	{
		return;
	}

	int victim = g_iDetectPinnedVictim[attacker];
	g_iDetectPinnedVictim[attacker] = 0;
	g_iDetectPinnedClass[attacker] = 0;
	g_fDetectSpecialClearTimeA[attacker] = -1.0;
	g_fDetectSpecialClearTimeB[attacker] = -1.0;

	if (victim > 0 && victim <= MaxClients && g_iDetectPinnerByVictim[victim] == attacker)
	{
		g_iDetectPinnerByVictim[victim] = 0;
	}
}

void Detect_ClearPinStateByVictim(int victim)
{
	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	int attacker = g_iDetectPinnerByVictim[victim];
	g_iDetectPinnerByVictim[victim] = 0;

	if (attacker > 0 && attacker <= MaxClients && g_iDetectPinnedVictim[attacker] == victim)
	{
		g_iDetectPinnedVictim[attacker] = 0;
		g_iDetectPinnedClass[attacker] = 0;
		g_fDetectSpecialClearTimeA[attacker] = -1.0;
		g_fDetectSpecialClearTimeB[attacker] = -1.0;
	}
}

bool Detect_IsPinnedClass(int infected)
{
	return infected > 0 && infected <= MaxClients
		&& g_iDetectPinnedVictim[infected] > 0
		&& g_iDetectPinnedClass[infected] >= view_as<int>(L4D2ZombieClass_Smoker)
		&& g_iDetectPinnedClass[infected] <= view_as<int>(L4D2ZombieClass_Charger);
}

bool Detect_IsStillPinning(int infected, int victim)
{
	if (!IsValidInfected(infected) || !IsValidSurvivor(victim))
	{
		return false;
	}

	if (L4D2_GetSpecialInfectedDominatingMe(victim) == infected)
	{
		return true;
	}

	int currentVictim = L4D2_GetSurvivorVictim(infected);
	if (currentVictim == victim)
	{
		return true;
	}

	return IsValidZombieClass(infected, L4D2ZombieClass_Charger)
		&& L4D2_IsInQueuedPummel(infected)
		&& L4D2_GetQueuedPummelVictim(infected) == victim;
}

bool Detect_IsValidTeamClear(int clearer, int pinner)
{
	if (!IsValidSurvivor(clearer) || !Detect_IsPinnedClass(pinner))
	{
		return false;
	}

	int pinvictim = g_iDetectPinnedVictim[pinner];
	if (!IsValidSurvivor(pinvictim))
	{
		pinvictim = L4D2_GetSurvivorVictim(pinner);
		if (!IsValidSurvivor(pinvictim)
			&& IsValidZombieClass(pinner, L4D2ZombieClass_Charger)
			&& L4D2_IsInQueuedPummel(pinner))
		{
			pinvictim = L4D2_GetQueuedPummelVictim(pinner);
		}

		if (IsValidSurvivor(pinvictim))
		{
			Detect_SetPinState(pinner, pinvictim, GetClientZombieClass(pinner), g_fDetectSpecialClearTimeA[pinner], g_fDetectSpecialClearTimeB[pinner]);
		}
	}

	if (!IsValidSurvivor(pinvictim) || clearer == pinvictim)
	{
		return false;
	}

	if (!Detect_IsStillPinning(pinner, pinvictim))
	{
		Detect_ClearPinStateByAttacker(pinner);
		return false;
	}

	return true;
}

void Detect_EmitSpecialClear(int clearer, int pinner, bool withShove)
{
	if (!Detect_IsPinnedClass(pinner))
	{
		return;
	}

	int pinvictim = g_iDetectPinnedVictim[pinner];
	if (!IsValidSurvivor(pinvictim))
	{
		pinvictim = L4D2_GetSurvivorVictim(pinner);
		if (!IsValidSurvivor(pinvictim)
			&& IsValidZombieClass(pinner, L4D2ZombieClass_Charger)
			&& L4D2_IsInQueuedPummel(pinner))
		{
			pinvictim = L4D2_GetQueuedPummelVictim(pinner);
		}

		if (IsValidSurvivor(pinvictim))
		{
			Detect_SetPinState(pinner, pinvictim, GetClientZombieClass(pinner), g_fDetectSpecialClearTimeA[pinner], g_fDetectSpecialClearTimeB[pinner]);
		}
	}

	if (!IsValidSurvivor(clearer) || !IsValidSurvivor(pinvictim))
	{
		Detect_ClearPinStateByAttacker(pinner);
		return;
	}

	float now = GetGameTime();
	int eventId = Skills_CreateEvent(L4D2Skill_SpecialPinClear);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		Detect_ClearPinStateByAttacker(pinner);
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(clearer);
	g_SkillEvents[eventIndex].victim.Capture(pinner);
	g_SkillEvents[eventIndex].zombieClass = g_iDetectPinnedClass[pinner];
	g_SkillEvents[eventIndex].timeA = g_fDetectSpecialClearTimeA[pinner] >= 0.0 ? (now - g_fDetectSpecialClearTimeA[pinner]) : -1.0;
	g_SkillEvents[eventIndex].timeB = g_fDetectSpecialClearTimeB[pinner] >= 0.0 ? (now - g_fDetectSpecialClearTimeB[pinner]) : -1.0;
	g_SkillEvents[eventIndex].withShove = withShove;
	g_SkillEvents[eventIndex].pinVictim.Capture(pinvictim);

	Action result = API_FireSkillDetected(eventId, L4D2Skill_SpecialPinClear);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	Detect_ClearPinStateByAttacker(pinner);
}

void Detect_RecordChargeVictim(int charger, int victim, bool wasCarried)
{
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger) || !IsValidSurvivor(victim))
	{
		return;
	}

	g_iDetectChargeOwner[victim] = charger;
	g_bDetectChargeWasCarried[victim] = wasCarried;
	g_bDetectChargeSetupEmitted[victim] = false;
	g_fDetectChargeStartTime[victim] = GetGameTime();
	GetClientAbsOrigin(victim, g_fDetectChargeOrigin[victim]);
	g_iDetectChargeFlags[victim] = 0;
	g_iDetectChargeMapDamage[victim] = 0;
	g_fDetectChargeLastMapDamageTime[victim] = 0.0;
	g_fDetectChargeIncapTime[victim] = 0.0;
}

void Detect_EmitChargerDeathSetup(int victim, bool incapped, bool ledgeHang)
{
	if (!IsValidSurvivor(victim) || g_bDetectChargeSetupEmitted[victim])
	{
		return;
	}

	int charger = g_iDetectChargeOwner[victim];
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		return;
	}

	float startTime = g_fDetectChargeStartTime[victim];
	if (startTime <= 0.0 || (GetGameTime() - startTime) > L4D2_SKILLS_CHARGE_TRACK_WINDOW)
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_ChargerDeathSetup);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(charger);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = view_as<int>(L4D2ZombieClass_Charger);
	g_SkillEvents[eventIndex].wasCarried = g_bDetectChargeWasCarried[victim];
	g_SkillEvents[eventIndex].incapped = incapped;
	g_SkillEvents[eventIndex].ledgeHang = ledgeHang;

	g_bDetectChargeSetupEmitted[victim] = true;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_ChargerDeathSetup);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_CheckChargerInstaKill(Event event, int victim)
{
	int charger = g_iDetectChargeOwner[victim];
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	float startTime = g_fDetectChargeStartTime[victim];
	bool extendedChargeWindow = g_fDetectChargeIncapTime[victim] > 0.0
		|| (g_iDetectChargeFlags[victim] & (DCFLAG_INCAP | DCFLAG_LEDGE)) != 0;
	float maxTrackWindow = extendedChargeWindow ? L4D2_SKILLS_CHARGE_INCAP_WINDOW : L4D2_SKILLS_CHARGE_TRACK_WINDOW;
	if (startTime <= 0.0 || (GetGameTime() - startTime) > maxTrackWindow)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsValidInfected(attacker) && attacker != charger)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	if (attacker == charger
		&& (StrEqual(weapon, "charger_claw")
			|| StrEqual(weapon, "charger_pummel")
			|| StrEqual(weapon, "charger_impact")))
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	if ((g_iDetectChargeFlags[victim] & DCFLAG_KILLEDBYOTHER) != 0)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	float deathPos[3];
	GetClientAbsOrigin(victim, deathPos);

	float height = g_fDetectChargeOrigin[victim][2] - deathPos[2];
	float threshold = g_cvDetectInstaKillHeight != null ? g_cvDetectInstaKillHeight.FloatValue : 400.0;
	bool recentMapDamage = Detect_HasRecentChargeMapDamage(victim);
	bool mapDeathSignal = (g_iDetectChargeFlags[victim] & (DCFLAG_FALL | DCFLAG_DROWN | DCFLAG_TRIGGER | DCFLAG_DEADLY | DCFLAG_LEDGE)) != 0;
	bool chargeIncapContext = (g_iDetectChargeFlags[victim] & DCFLAG_INCAP) != 0;
	if (height < threshold && !recentMapDamage && !chargeIncapContext)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	if (!recentMapDamage
		&& attacker <= 0
		&& !mapDeathSignal
		&& !StrEqual(weapon, "world")
		&& !StrEqual(weapon, "trigger_hurt")
		&& !StrEqual(weapon, "worldspawn"))
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_ChargerInstaKill);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(charger);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = view_as<int>(L4D2ZombieClass_Charger);
	g_SkillEvents[eventIndex].height = height;
	g_SkillEvents[eventIndex].distance = GetVectorDistance(g_fDetectChargeOrigin[victim], deathPos);
	g_SkillEvents[eventIndex].wasCarried = g_bDetectChargeWasCarried[victim];
	g_SkillEvents[eventIndex].damage = g_iDetectChargeMapDamage[victim];
	g_SkillEvents[eventIndex].incapped = chargeIncapContext;
	g_SkillEvents[eventIndex].ledgeHang = (g_iDetectChargeFlags[victim] & DCFLAG_LEDGE) != 0;
	g_SkillEvents[eventIndex].fatalFall = (g_iDetectChargeFlags[victim] & DCFLAG_FALL) != 0;
	g_SkillEvents[eventIndex].deadlySlam = (g_iDetectChargeFlags[victim] & DCFLAG_DEADLY) != 0;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_ChargerInstaKill);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	Detect_ResetChargeTrack(victim);
}

bool Detect_IsChargerCharging(int charger)
{
	int abilityEnt = GetEntPropEnt(charger, Prop_Send, "m_customAbility");
	return IsValidEntity(abilityEnt) && GetEntProp(abilityEnt, Prop_Send, "m_isCharging") != 0;
}

bool Detect_IsSkeetWeaponMelee(const char[] weapon)
{
	L4D2WeaponId weaponId = Detect_GetWeaponIdFromEventName(weapon);
	return weaponId == L4D2WeaponId_Melee || weaponId == L4D2WeaponId_Chainsaw || StrEqual(weapon, "melee");
}

bool Detect_IsSkeetWeaponSniper(const char[] weapon)
{
	L4D2WeaponId weaponId = Detect_GetWeaponIdFromEventName(weapon);
	return weaponId == L4D2WeaponId_HuntingRifle
		|| weaponId == L4D2WeaponId_SniperMilitary
		|| weaponId == L4D2WeaponId_SniperAWP
		|| weaponId == L4D2WeaponId_SniperScout
		|| weaponId == L4D2WeaponId_PistolMagnum;
}

bool Detect_IsSkeetWeaponGL(const char[] weapon)
{
	L4D2WeaponId weaponId = Detect_GetWeaponIdFromEventName(weapon);
	return weaponId == L4D2WeaponId_GrenadeLauncher || StrEqual(weapon, "grenade_launcher_projectile");
}

L4D2WeaponId Detect_GetWeaponIdFromEventName(const char[] weapon)
{
	L4D2WeaponId weaponId = L4D2_GetWeaponIdByWeaponName(weapon);
	if (weaponId != L4D2WeaponId_None)
	{
		return weaponId;
	}

	char prefixed[64];
	FormatEx(prefixed, sizeof(prefixed), "weapon_%s", weapon);
	return L4D2_GetWeaponIdByWeaponName(prefixed);
}

Action Detect_OnTakeDamage_Client(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!Skills_IsEnabled() || !IsValidInfected(victim))
	{
		return Plugin_Continue;
	}

	L4D2ZombieClassType zombieClass = L4D2_GetPlayerZombieClass(victim);
	if (zombieClass == L4D2ZombieClass_Hunter)
	{
		g_iDetectHunterLastHealthBeforeDamage[victim] = GetClientHealth(victim);
		g_iDetectHunterLastAttacker[victim] = attacker;
		g_iDetectHunterLastDamageType[victim] = damagetype;
		g_fDetectHunterLastRawDamage[victim] = damage;
	}
	else if (zombieClass == L4D2ZombieClass_Charger)
	{
		g_iDetectChargerLastHealthBeforeDamage[victim] = GetClientHealth(victim);
		g_iDetectChargerLastAttacker[victim] = attacker;
		g_iDetectChargerLastDamageType[victim] = damagetype;
		g_fDetectChargerLastRawDamage[victim] = damage;
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
		g_iDetectHunterLastAttacker[victim] = attacker;
		g_iDetectHunterLastDamageType[victim] = damagetype;
		g_fDetectHunterLastRawDamage[victim] = damage;
	}
	else if (zombieClass == L4D2ZombieClass_Charger)
	{
		g_iDetectChargerLastAttacker[victim] = attacker;
		g_iDetectChargerLastDamageType[victim] = damagetype;
		g_fDetectChargerLastRawDamage[victim] = damage;
	}
}

void Detect_OnSpawn_CarAlarm(int entity)
{
	if (!IsValidEntity(entity) || g_smDetectCarAlarmTargets == null)
	{
		return;
	}

	char target[64];
	GetEntPropString(entity, Prop_Data, "m_iName", target, sizeof(target));
	if (target[0] != '\0')
	{
		g_smDetectCarAlarmTargets.SetValue(target, entity);
	}
}

void Detect_OnSpawn_CarGlass(int entity)
{
	if (!IsValidEntity(entity) || g_smDetectCarAlarmTargets == null || g_smDetectCarGlassParents == null)
	{
		return;
	}

	char parentName[64];
	GetEntPropString(entity, Prop_Data, "m_iParent", parentName, sizeof(parentName));
	if (parentName[0] == '\0')
	{
		return;
	}

	int parentEntity = -1;
	if (!g_smDetectCarAlarmTargets.GetValue(parentName, parentEntity) || !IsValidEntity(parentEntity))
	{
		return;
	}

	char glassKey[16];
	Detect_FormatEntityKey(entity, glassKey, sizeof(glassKey));
	g_smDetectCarGlassParents.SetValue(glassKey, parentEntity);
}

Action Detect_OnTakeDamage_CarAlarm(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidSurvivor(attacker))
	{
		return Plugin_Continue;
	}

	Detect_RecordCarAlarmAttempt(victim, attacker, inflictor, damage, damagetype, false, false);
	return Plugin_Continue;
}

Action Detect_OnTakeDamage_CarGlass(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidSurvivor(attacker) || g_smDetectCarGlassParents == null)
	{
		return Plugin_Continue;
	}

	char glassKey[16];
	Detect_FormatEntityKey(victim, glassKey, sizeof(glassKey));

	int parentEntity = -1;
	if (!g_smDetectCarGlassParents.GetValue(glassKey, parentEntity) || !IsValidEntity(parentEntity))
	{
		return Plugin_Continue;
	}

	Detect_RecordCarAlarmAttempt(parentEntity, attacker, inflictor, damage, damagetype, false, true);
	return Plugin_Continue;
}

Action Detect_OnTouch_CarAlarm(int entity, int client)
{
	if (!IsValidSurvivor(client))
	{
		return Plugin_Continue;
	}

	Detect_RecordCarAlarmAttempt(entity, client, 0, 0.0, DMG_CLUB, true, false);
	return Plugin_Continue;
}

Action Detect_OnTouch_CarGlass(int entity, int client)
{
	if (!IsValidSurvivor(client) || g_smDetectCarGlassParents == null)
	{
		return Plugin_Continue;
	}

	char glassKey[16];
	Detect_FormatEntityKey(entity, glassKey, sizeof(glassKey));

	int parentEntity = -1;
	if (!g_smDetectCarGlassParents.GetValue(glassKey, parentEntity) || !IsValidEntity(parentEntity))
	{
		return Plugin_Continue;
	}

	Detect_RecordCarAlarmAttempt(parentEntity, client, 0, 0.0, DMG_CLUB, true, true);
	return Plugin_Continue;
}

void Detect_RecordCarAlarmAttempt(int entity, int survivor, int inflictor, float damage, int damagetype, bool touched, bool throughGlass)
{
	if (!IsValidSurvivor(survivor) || g_smDetectCarPendingSurvivor == null || g_smDetectCarPendingReason == null || g_smDetectCarPendingInfected == null || g_smDetectCarPendingFlags == null)
	{
		return;
	}

	char key[16];
	Detect_FormatEntityKey(entity, key, sizeof(key));
	g_smDetectCarPendingSurvivor.SetValue(key, survivor);
	g_smDetectCarPendingInfected.SetValue(key, 0);

	int flags = throughGlass ? CARFLAG_INDIRECT : 0;
	int dominator = L4D2_GetSpecialInfectedDominatingMe(survivor);
	if (IsValidInfected(dominator))
	{
		flags |= CARFLAG_FORCED;
		g_smDetectCarPendingInfected.SetValue(key, dominator);
	}
	g_smDetectCarPendingFlags.SetValue(key, flags);

	if (touched)
	{
		g_smDetectCarPendingReason.SetValue(key, view_as<int>(L4D2CarAlarm_Touched));
		CreateTimer(0.01, Detect_TimerCheckCarAlarm, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	if (damagetype & DMG_BLAST)
	{
		flags |= CARFLAG_INDIRECT;
		g_smDetectCarPendingFlags.SetValue(key, flags);

		if (IsValidZombieClass(inflictor, L4D2ZombieClass_Boomer))
		{
			g_smDetectCarPendingReason.SetValue(key, view_as<int>(L4D2CarAlarm_Boomer));
			g_smDetectCarPendingInfected.SetValue(key, inflictor);
		}
		else
		{
			g_smDetectCarPendingReason.SetValue(key, view_as<int>(L4D2CarAlarm_Explosion));
		}

		CreateTimer(0.01, Detect_TimerCheckCarAlarm, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	if (damage == 0.0 && (damagetype & DMG_CLUB || damagetype & DMG_SLASH) && !(damagetype & DMG_SLOWBURN))
	{
		g_smDetectCarPendingReason.SetValue(key, view_as<int>(L4D2CarAlarm_Touched));
		CreateTimer(0.01, Detect_TimerCheckCarAlarm, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	g_smDetectCarPendingReason.SetValue(key, view_as<int>(L4D2CarAlarm_Hit));
	CreateTimer(0.01, Detect_TimerCheckCarAlarm, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

Action Detect_TimerCheckCarAlarm(Handle timer, any entityRef)
{
	int entity = EntRefToEntIndex(entityRef);
	if (entity == INVALID_ENT_REFERENCE || g_smDetectCarPendingSurvivor == null || g_smDetectCarPendingReason == null || g_smDetectCarPendingInfected == null || g_smDetectCarPendingFlags == null)
	{
		return Plugin_Stop;
	}

	char key[16];
	Detect_FormatEntityKey(entity, key, sizeof(key));

	int survivor = 0;
	if (!g_smDetectCarPendingSurvivor.GetValue(key, survivor))
	{
		return Plugin_Stop;
	}

	int pendingReason = view_as<int>(L4D2CarAlarm_Unknown);
	g_smDetectCarPendingReason.GetValue(key, pendingReason);

	int pendingInfected = 0;
	g_smDetectCarPendingInfected.GetValue(key, pendingInfected);

	int pendingFlags = 0;
	g_smDetectCarPendingFlags.GetValue(key, pendingFlags);

	g_smDetectCarPendingSurvivor.Remove(key);
	g_smDetectCarPendingReason.Remove(key);
	g_smDetectCarPendingInfected.Remove(key);
	g_smDetectCarPendingFlags.Remove(key);
	if ((GetGameTime() - g_fDetectLastCarAlarm) >= L4D2_SKILLS_CARALARM_WINDOW || !IsValidSurvivor(survivor))
	{
		return Plugin_Stop;
	}

	int infected = 0;
	if (pendingReason == view_as<int>(L4D2CarAlarm_Boomer) && IsValidZombieClass(pendingInfected, L4D2ZombieClass_Boomer))
	{
		infected = pendingInfected;
	}
	else if (IsValidInfected(pendingInfected))
	{
		infected = pendingInfected;
	}
	else
	{
		int dominator = L4D2_GetSpecialInfectedDominatingMe(survivor);
		if (IsValidInfected(dominator))
		{
			infected = dominator;
		}
	}

	int eventId = Skills_CreateEvent(L4D2Skill_CarAlarmTriggered);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return Plugin_Stop;
	}

	g_SkillEvents[eventIndex].actor.Capture(survivor);
	if (IsValidInfected(infected))
	{
		g_SkillEvents[eventIndex].victim.Capture(infected);
		g_SkillEvents[eventIndex].zombieClass = view_as<int>(GetClientZombieClass(infected));
	}
	g_SkillEvents[eventIndex].reason = pendingReason;
	g_SkillEvents[eventIndex].indirect = (pendingFlags & CARFLAG_INDIRECT) != 0;
	g_SkillEvents[eventIndex].forced = (pendingFlags & CARFLAG_FORCED) != 0;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_CarAlarmTriggered);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	return Plugin_Stop;
}

void Detect_HandleChargerHurt(Event event, int victim, int attacker)
{
	int damage = event.GetInt("dmg_health");
	int health = event.GetInt("health");
	int damageType = event.GetInt("type");
	if (damage <= 0)
	{
		return;
	}

	if (health == 0
		&& (damageType & DMG_CLUB || damageType & DMG_SLASH)
		&& Detect_IsChargerCharging(victim))
	{
		int chargerHealth = g_cvDetectChargerHealth != null ? g_cvDetectChargerHealth.IntValue : 600;
		int levelThreshold = RoundToFloor(float(chargerHealth) * 0.65);
		float rawDamage = g_fDetectChargerLastRawDamage[victim];
		if (g_iDetectChargerLastAttacker[victim] != attacker || !(g_iDetectChargerLastDamageType[victim] & (DMG_CLUB | DMG_SLASH)))
		{
			rawDamage = float(damage);
		}

		if (rawDamage > float(levelThreshold))
		{
			int eventId = Skills_CreateEvent(L4D2Skill_ChargerLevel);
			int eventIndex = Skills_GetEventIndex(eventId);
			if (eventIndex != -1)
			{
				g_SkillEvents[eventIndex].actor.Capture(attacker);
				g_SkillEvents[eventIndex].victim.Capture(victim);
				g_SkillEvents[eventIndex].damage = damage;
				g_SkillEvents[eventIndex].chipDamage = chargerHealth - damage;
				g_SkillEvents[eventIndex].wouldQualifyAtBaseline = rawDamage > float(damage);
				if (g_SkillEvents[eventIndex].chipDamage < 0)
				{
					g_SkillEvents[eventIndex].chipDamage = 0;
				}

				Action result = API_FireSkillDetected(eventId, L4D2Skill_ChargerLevel);
				if (result < Plugin_Handled)
				{
					Announce_Skill(eventId);
				}
			}
		}
	}

	if (health > 0)
	{
		g_iDetectChargerLastHealth[victim] = health;
	}
}
