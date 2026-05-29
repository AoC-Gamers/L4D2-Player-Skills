#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <console_table>
#include <left4dhooks>
#include <l4d2util_weapons>
#include <l4d2util_constants>

#define MAX_MESSAGE_LENGTH 512
#include <colors>

#define LIBRARY_LEFT4DHOOKS "left4dhooks"
#define LOG_DIRECTORY "logs/l4d2_player_skills.log"
#define TRANSLATION_FILE "l4d2_player_skills.phrases"

#include "l4d2_player_skills/types.sp"

L4D2BossSessionData g_BossSessions[L4D2_SKILLS_MAX_BOSSES];
L4D2DamageEntry		g_BossDamage[L4D2_SKILLS_MAX_BOSSES][L4D2_SKILLS_MAX_DAMAGE_ENTRIES];
L4D2SkillEventData	g_SkillEvents[L4D2_SKILLS_MAX_EVENTS];
L4D2SkillSummaryData g_SkillSummaries[L4D2_SKILLS_MAX_SUMMARIES];
PlayerSkillsRuntimeState g_Runtime;

int	g_iBossSerial		= 0;
int	g_iEventSerial		= 0;
int	g_iNextEventSlot	= 0;
int g_iSummarySerial	= 0;
int g_iNextSummarySlot	= 0;

ConVar	g_cvEnable				 = null;
ConVar	g_cvDebug				 = null;
ConVar	g_cvAnnounceWitch		 = null;
ConVar	g_cvAnnounceTank		 = null;
ConVar	g_cvAnnounceHunter		 = null;
ConVar	g_cvAnnounceSmoker		 = null;
ConVar	g_cvAnnounceBoomer		 = null;
ConVar	g_cvAnnounceSpitter		 = null;
ConVar	g_cvAnnounceJockey		 = null;
ConVar	g_cvAnnounceCharger		 = null;
ConVar	g_cvAnnounceOther		 = null;
ConVar	g_cvBoomerVomitMinTargets = null;
ConVar	g_cvBoomerHealth		 = null;
ConVar	g_cvSmokerHealth		 = null;
ConVar	g_cvHunterHealth		 = null;
ConVar	g_cvHunterMaxPounceBonusDamage = null;
ConVar	g_cvSpitterHealth		 = null;
ConVar	g_cvJockeyHealth		 = null;
ConVar	g_cvChargerHealth		 = null;
ConVar	g_cvTankHealth			 = null;
ConVar	g_cvWitchHealth			 = null;
ConVar	g_cvSurvivorLimit		 = null;
ConVar	g_cvMaxPlayerZombies	 = null;
ConVar	g_cvVersusBoomerLimit	 = null;
ConVar	g_cvVersusSmokerLimit	 = null;
ConVar	g_cvVersusHunterLimit	 = null;
ConVar	g_cvVersusSpitterLimit	 = null;
ConVar	g_cvVersusJockeyLimit	 = null;
ConVar	g_cvVersusChargerLimit	 = null;
ConVar	g_cvHunterHighPounceHeight = null;
ConVar	g_cvJockeyHighPounceHeight = null;
ConVar	g_cvWitchPrintMaxEntries = null;
ConVar	g_cvChargerClawPrintMinHits = null;
bool	g_bWitchPrintOnIncap	 = true;
char	g_sDebugLogPath[PLATFORM_MAX_PATH];

/**
 * @brief Lightweight runtime wrapper over a boss session slot.
 * @remarks Exposes helpers to initialize, reset and update tracked Tank/Witch
 *          sessions stored in g_BossSessions.
 */
methodmap L4D2BossSession
{
	/**
	 * @brief Wraps a raw boss session slot index.
	 *
	 * @param index         Zero-based slot in g_BossSessions.
	 */
	public L4D2BossSession(int index)
	{
		return view_as<L4D2BossSession>(index);
	}

	property int Index
	{
		/**
		 * @brief Returns the raw slot index represented by this wrapper.
		 */
		public get()
		{
			return view_as<int>(this);
		}
	}

	/**
	 * @brief Checks whether the wrapped session slot is currently in use.
	 *
	 * @return              True if the slot contains a valid runtime session.
	 */
	public bool IsValid()
	{
		int index = this.Index;
		return index >= 0 && index < L4D2_SKILLS_MAX_BOSSES && g_BossSessions[index].id > 0;
	}

	/**
	 * @brief Clears the session and all captured damage entries for this slot.
	 *
	 * @noreturn
	 */
	public void Reset()
	{
		int index = this.Index;
		g_BossSessions[index].Reset();

		for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
		{
			g_BossDamage[index][entry].Reset();
		}
	}

	/**
	 * @brief Starts a new boss session in the wrapped slot.
	 *
	 * @param type          Boss type to track.
	 * @param entity        Current entity index for the boss.
	 * @param userid        Userid of the current controller when applicable.
	 * @param maxHealth     Baseline maximum health for the session.
	 *
	 * @noreturn
	 */
	public void Start(L4D2BossType type, int entity, int userid, int maxHealth)
	{
		int index = this.Index;

		this.Reset();

		g_BossSessions[index].id		 = ++g_iBossSerial;
		g_BossSessions[index].type		 = type;
		g_BossSessions[index].state		 = L4D2BossState_Active;
		g_BossSessions[index].entity	 = entity;
		g_BossSessions[index].entRef	 = entity > 0 ? EntIndexToEntRef(entity) : INVALID_ENT_REFERENCE;
		g_BossSessions[index].userid	 = userid;
		g_BossSessions[index].maxHealth	 = maxHealth;
		g_BossSessions[index].lastHealth = maxHealth;
		g_BossSessions[index].startedAt	 = GetGameTime();
		g_BossSessions[index].printed	 = false;

		int client						 = GetClientOfUserId(userid);
		if (IsValidClient(client))
		{
			g_BossSessions[index].owner.Capture(client);
		}
	}

	/**
	 * @brief Refreshes the owner snapshot for a player-controlled boss.
	 *
	 * @param client        Client index of the current controller.
	 *
	 * @noreturn
	 */
	public 	void RefreshOwner(int client)
	{
		if (!this.IsValid() || !IsValidClient(client))
		{
			return;
		}

		g_BossSessions[this.Index].userid = GetClientUserId(client);
		g_BossSessions[this.Index].entity = client;
		g_BossSessions[this.Index].entRef = EntIndexToEntRef(client);
		g_BossSessions[this.Index].owner.Capture(client);
	}

	/**
	 * @brief Adds survivor damage to the current boss session.
	 *
	 * @param attacker      Survivor client index that dealt the damage.
	 * @param damage        Positive damage amount to accumulate.
	 *
	 * @noreturn
	 */
	public 	void AddDamage(int attacker, int damage)
	{
		if (!this.IsValid() || !IsValidSurvivor(attacker) || damage <= 0)
		{
			return;
		}

		int index = this.Index;
		int entry = Boss_FindOrCreateDamageEntry(index, attacker);
		if (entry == -1)
		{
			return;
		}

		if (!g_BossDamage[index][entry].active)
		{
			g_BossDamage[index][entry].active = true;
			g_BossDamage[index][entry].player.Capture(attacker);
		}

		g_BossDamage[index][entry].damage += damage;
		g_BossSessions[index].totalDamage += damage;
	}
}

public Plugin myinfo =
{
	name		= "L4D2 Player Skills",
	author		= "lechuga",
	description = "Skill detection, boss damage tracking and public API for competitive L4D2.",
	version		= "1.0.0",
	url			= "https://github.com/AoC-Gamers/L4D2-Player-Skills"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_Runtime.isLate = late;
	RegPluginLibrary("l4d2_player_skills");
	API_CreateForwards();
	API_CreateNatives();
	return APLRes_Success;
}

#include "l4d2_player_skills/helpers.sp"
#include "l4d2_player_skills/api.sp"
#include "l4d2_player_skills/announce.sp"
#include "l4d2_player_skills/boss.sp"
#include "l4d2_player_skills/detect.sp"
#include "l4d2_player_skills/detect_hunter.sp"
#include "l4d2_player_skills/detect_charger.sp"
#include "l4d2_player_skills/detect_caralarm.sp"
#include "l4d2_player_skills/detect_movement.sp"
#include "l4d2_player_skills/detect_rocks.sp"
#include "l4d2_player_skills/detect_smoker.sp"

public void OnPluginStart()
{
	L4D2Weapons_Init();
	LoadPluginTranslations();
	BuildPath(Path_SM, g_sDebugLogPath, sizeof(g_sDebugLogPath), LOG_DIRECTORY);

	g_smDetectCarAlarmTargets = new StringMap();
	g_smDetectCarGlassParents = new StringMap();
	g_smDetectCarPendingSurvivor = new StringMap();
	g_smDetectCarPendingReason = new StringMap();
	g_smDetectCarPendingInfected = new StringMap();
	g_smDetectCarPendingFlags = new StringMap();

	g_cvDebug			   		= CreateConVar("l4d2_player_skills_debug", "255", "Debug bitmask for l4d2_player_skills. 0=None 1=Core 2=Event 4=Detect 8=Boss 16=Pin 32=Physics 64=Api 128=Announce 255=all.");
	g_cvEnable			   		= CreateConVar("l4d2_player_skills_enable", "1", "Enable the l4d2_player_skills plugin.");
	g_cvAnnounceWitch			= CreateConVar("l4d2_player_skills_announce_wich", "7", "Bitmask for Witch announcements. 1=damage 2=misc 4=crown 7=all.");
	g_cvAnnounceTank			= CreateConVar("l4d2_player_skills_announce_tank", "15", "Bitmask for Tank announcements. 1=damage 2=rock_skeet 4=rock_hit 8=ledge_hang 15=all.");
	g_cvAnnounceHunter			= CreateConVar("l4d2_player_skills_announce_hunter", "63", "Bitmask for Hunter announcements. 1=skeet 2=skeet_melee 4=deadstop 8=high_pounce 16=special_clear 32=kill 63=all.");
	g_cvAnnounceSmoker			= CreateConVar("l4d2_player_skills_announce_smoker", "31", "Bitmask for Smoker announcements. 1=tongue_cut 2=self_clear 4=special_clear 8=kill 16=ledge_hang 31=all.");
	g_cvAnnounceBoomer			= CreateConVar("l4d2_player_skills_announce_boomer", "7", "Bitmask for Boomer announcements. 1=pop 2=vomit 4=kill 7=all.");
	g_cvAnnounceSpitter			= CreateConVar("l4d2_player_skills_announce_spitter", "1", "Bitmask for Spitter announcements. 1=kill 1=all.");
	g_cvAnnounceJockey			= CreateConVar("l4d2_player_skills_announce_jockey", "63", "Bitmask for Jockey announcements. 1=high_pounce 2=special_clear 4=kill 8=jump_stop 16=skeet_melee 32=ledge_hang 63=all.");
	g_cvAnnounceCharger			= CreateConVar("l4d2_player_skills_announce_charger", "63", "Bitmask for Charger announcements. 1=level 2=insta_kill 4=death_setup 8=special_clear 16=kill 32=bowl 63=all.");
	g_cvAnnounceOther			= CreateConVar("l4d2_player_skills_announce_other", "3", "Bitmask for other announcements. 1=bunnyhop 2=car_alarm 3=all.");
	g_cvBoomerVomitMinTargets	= CreateConVar("l4d2_player_skills_boomer_vomit_min_targets", "3", "Minimum number of vomited survivors required to announce BoomerVomitLanded. 0=disabled.");
	g_cvWitchPrintMaxEntries	= CreateConVar("l4d2_player_skills_witch_print_max_entries", "4", "Maximum number of Witch damage entries to print before combining the rest as others.");
	g_cvHunterHighPounceHeight	= CreateConVar("l4d2_player_skills_hunter_high_pounce_height", "400", "Minimum vertical height for HunterHighPounce.");
	g_cvJockeyHighPounceHeight	= CreateConVar("l4d2_player_skills_jockey_high_pounce_height", "300", "Minimum vertical height for JockeyHighPounce.");
	g_cvDetectInstaKillHeight	= CreateConVar("l4d2_player_skills_charger_instakill_height", "400", "Minimum vertical drop for ChargerInstaKill.");
	g_cvDetectDeathSetupHeight	= CreateConVar("l4d2_player_skills_charger_death_setup_height", "100", "Minimum vertical drop for ChargerDeathSetup incap classification.");
	g_cvChargerClawPrintMinHits = CreateConVar("l4d2_player_skills_charger_claw_print_min_hits", "0", "Minimum Charger claw hits required to print a life summary. 0=disabled.");
	g_cvDetectBHopMinStreak		= CreateConVar("l4d2_player_skills_bhop_streak_min", "3", "Minimum amount of successful hops for BunnyHopStreak.");
	g_cvDetectBHopMinInitSpeed	= CreateConVar("l4d2_player_skills_bhop_init_speed", "150", "Minimum initial jump speed to start tracking BunnyHopStreak.");
	g_cvDetectBHopContSpeed		= CreateConVar("l4d2_player_skills_bhop_keep_speed", "300", "Minimum speed that keeps a hop streak even without acceleration.");

	g_cvHunterMaxPounceBonusDamage = FindConVar("z_hunter_max_pounce_bonus_damage");

	g_cvDetectPounceInterrupt 	= FindConVar("z_pounce_damage_interrupt");
	g_cvDetectMaxPounceDistance = FindConVar("z_pounce_damage_range_max");
	g_cvDetectMinPounceDistance = FindConVar("z_pounce_damage_range_min");

	g_cvBoomerHealth	   = FindConVar("z_exploding_health");
	g_cvSmokerHealth	   = FindConVar("z_gas_health");
	g_cvHunterHealth	   = FindConVar("z_hunter_health");
	g_cvSpitterHealth	   = FindConVar("z_spitter_health");
	g_cvJockeyHealth	   = FindConVar("z_jockey_health");
	g_cvChargerHealth	   = FindConVar("z_charger_health");
	g_cvTankHealth		   = FindConVar("z_tank_health");
	g_cvWitchHealth		   = FindConVar("z_witch_health");

	g_cvSurvivorLimit      = FindConVar("survivor_limit");
	g_cvMaxPlayerZombies   = FindConVar("z_max_player_zombies");
	g_cvVersusBoomerLimit  = FindConVar("z_versus_boomer_limit");
	g_cvVersusSmokerLimit  = FindConVar("z_versus_smoker_limit");
	g_cvVersusHunterLimit  = FindConVar("z_versus_hunter_limit");
	g_cvVersusSpitterLimit = FindConVar("z_versus_spitter_limit");
	g_cvVersusJockeyLimit  = FindConVar("z_versus_jockey_limit");
	g_cvVersusChargerLimit = FindConVar("z_versus_charger_limit");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_start", Event_ScavengeRoundStart, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_finished", Event_ScavengeRoundFinished, EventHookMode_PostNoCopy);
	HookEvent("ability_use", Event_AbilityUse, EventHookMode_Post);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	HookEvent("player_jump", Event_PlayerJump, EventHookMode_Post);
	HookEvent("player_jump_apex", Event_PlayerJumpApex, EventHookMode_Post);
	HookEvent("jockey_ride", Event_JockeyRide, EventHookMode_Post);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd, EventHookMode_Post);
	HookEvent("jockey_punched", Event_JockeyPunched, EventHookMode_Post);
	HookEvent("jockey_killed", Event_JockeyKilled, EventHookMode_Post);
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_incapacitated_start", Event_PlayerIncapacitatedStart, EventHookMode_Post);
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab, EventHookMode_Post);
	HookEvent("player_shoved", Event_PlayerShoved, EventHookMode_Post);
	HookEvent("player_now_it", Event_PlayerNowIt, EventHookMode_Post);
	HookEvent("boomer_exploded", Event_BoomerExploded, EventHookMode_Post);
	HookEvent("charger_charge_start", Event_ChargerChargeStart, EventHookMode_Post);
	HookEvent("charger_charge_end", Event_ChargerChargeEnd, EventHookMode_Post);
	HookEvent("charger_killed", Event_ChargerKilled, EventHookMode_Post);
	HookEvent("charger_carry_start", Event_ChargerCarryStart, EventHookMode_Post);
	HookEvent("charger_impact", Event_ChargerImpact, EventHookMode_Post);
	HookEvent("charger_carry_end", Event_ChargerCarryEnd, EventHookMode_Post);
	HookEvent("charger_pummel_start", Event_ChargerPummelStart, EventHookMode_Post);
	HookEvent("charger_pummel_end", Event_ChargerPummelEnd, EventHookMode_Post);
	HookEvent("triggered_car_alarm", Event_TriggeredCarAlarm, EventHookMode_Post);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);
	HookEvent("choke_start", Event_ChokeStart, EventHookMode_Post);
	HookEvent("choke_stopped", Event_ChokeStopped, EventHookMode_Post);
	HookEvent("tongue_pull_stopped", Event_TonguePullStopped, EventHookMode_Post);
	HookEvent("pounce_stopped", Event_PounceStopped, EventHookMode_Post);
	HookEvent("pounce_end", Event_PounceEnd, EventHookMode_Post);

	RegConsoleCmd("sm_skills", Command_Skills, "Print the detected skills summary in chat and the comparative skills table in console.");
	RegConsoleCmd("sm_skills_stats", Command_SkillsStats, "Print team skill stats to console. Usage: sm_skills_stats <surv|infect|all>.");

	AutoExecConfig(false, "l4d2_player_skills");
	Boss_Init();

	if (!g_Runtime.isLate)
	{
		return;
	}

	g_Runtime.hasLeft4DHooks = LibraryExists(LIBRARY_LEFT4DHOOKS);
	Skills_RefreshModeContext();
	Skills_RefreshRoundLiveState();
}

public void OnAllPluginsLoaded()
{
	g_Runtime.hasLeft4DHooks = LibraryExists(LIBRARY_LEFT4DHOOKS);
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, LIBRARY_LEFT4DHOOKS) != 0)
	{
		return;
	}

	g_Runtime.hasLeft4DHooks = true;
	Skills_RefreshModeContext();
	Skills_RefreshRoundLiveState();
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, LIBRARY_LEFT4DHOOKS) != 0)
	{
		return;
	}

	g_Runtime.hasLeft4DHooks = false;
	Skills_RefreshModeContext();
	Skills_RefreshRoundLiveState();
}

public void OnMapStart()
{
	g_Runtime.roundLive = false;
	Skills_ResetEvents();
	Boss_ResetAll();
	Detect_ResetAll();
}

public void OnMapEnd()
{
	g_Runtime.roundLive = false;
	Skills_ResetEvents();
	Boss_ResetAll();
	Detect_ResetAll();
}

public void OnConfigsExecuted()
{
	Skills_RefreshModeContext();
	Skills_RefreshRoundLiveState();
}

public void L4D_OnGameModeChange(int gamemode)
{
	Skills_Debug(PlayerSkillsDebug_Event, "[L4D_OnGameModeChange] gamemode=%d", gamemode);
	Skills_RefreshModeContext();
	Skills_RefreshRoundLiveState();
}

public void OnPluginEnd()
{
	g_Runtime.roundLive = false;
	Boss_Shutdown();
	Detect_Shutdown();
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	Skills_Debug(PlayerSkillsDebug_Event, "[L4D_OnFirstSurvivorLeftSafeArea_Post] client=%d", client);

	if (!Skills_IsEnabled() || g_Runtime.roundLive || g_Runtime.roundLiveSignal != PlayerSkillsRoundLiveSignal_SafeArea)
	{
		return;
	}

	g_Runtime.roundLive = true;
}

public void OnClientPutInServer(int client)
{
	Boss_OnClientPutInServer(client);
	Detect_OnClientPutInServer(client);
}

public void OnClientDisconnect(int client)
{
	Boss_OnClientDisconnect(client);
	Detect_OnClientDisconnect(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	Boss_OnEntityCreated(entity, classname);
	Detect_OnEntityCreated(entity, classname);
}

public void OnEntityDestroyed(int entity)
{
	Detect_OnEntityDestroyed(entity);
}

public void L4D_OnWitchSetHarasser(int witch, int victim)
{
	Boss_OnWitchSetHarasser(witch, victim);
}

public void L4D_OnGrabWithTongue_Post(int victim, int attacker)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnGrabWithTonguePost(victim, attacker);
}

public void L4D_OnPouncedOnSurvivor_Post(int victim, int attacker)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnPouncedOnSurvivorPost(victim, attacker);
}

public void L4D2_OnJockeyRide_Post(int victim, int attacker)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnJockeyRidePost(victim, attacker);
}

public void L4D2_OnStartCarryingVictim_Post(int victim, int attacker)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnStartCarryingVictimPost(victim, attacker);
}

public void L4D2_OnSlammedSurvivor_Post(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnSlammedSurvivorPost(victim, attacker, bWallSlam, bDeadlyCharge);
}

public Action L4D_OnFatalFalling(int client, int camera)
{
	if (!Skills_IsRoundLive())
	{
		return Plugin_Continue;
	}

	Detect_OnFatalFalling(client);
	return Plugin_Continue;
}

public void L4D_OnFalling(int client)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnFalling(client);
}

public void L4D_OnLedgeGrabbed_Post(int client)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnLedgeGrabbedPost(client);
}

public void L4D_OnIncapacitated_Post(int client, int inflictor, int attacker, float damage, int damagetype, int weapon)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnIncapacitatedPost(client, attacker, damagetype);
}

public void L4D2_OnPummelVictim_Post(int attacker, int victim)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnPummelVictimPost(attacker, victim);
}

public void L4D_OnReplaceTank(int tank, int newtank)
{
	Boss_OnReplaceTank(tank, newtank);
}

public Action L4D_OnTryOfferingTankBot(int tank, bool &enterStasis)
{
	Boss_OnTryOfferingTankBot(tank, enterStasis);
	return Plugin_Continue;
}

public void L4D_OnTryOfferingTankBot_Post(int tank, bool enterStasis)
{
	Boss_OnTryOfferingTankBotPost(tank, enterStasis);
}

public void L4D_OnTryOfferingTankBot_PostHandled(int tank, bool enterStasis)
{
	Boss_OnTryOfferingTankBotPostHandled(tank, enterStasis);
}

public void L4D_OnEnterStasis(int tank)
{
	Boss_OnEnterStasis(tank);
}

public void L4D_OnLeaveStasis(int tank)
{
	Boss_OnLeaveStasis(tank);
}

public void L4D2_OnEntityShoved_Post(int client, int entity, int weapon, const float vecDir[3], bool bIsHighPounce)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnEntityShovedPost(client, entity, weapon, vecDir, bIsHighPounce);
}

public void L4D_TankRock_OnRelease_Post(int tank, int rock, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnTankRockReleasePost(tank, rock);
}

public void L4D_TankRock_BounceTouch_Post(int tank, int rock, int entity)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnTankRockBounceTouchPost(tank, rock, entity);
}

public void L4D_TankRock_OnDetonate(int tank, int rock)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_OnTankRockDetonate(tank, rock);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	char objective[64];
	event.GetString("objective", objective, sizeof(objective));
	Skills_Debug(PlayerSkillsDebug_Event, "[%s] timelimit=%d fraglimit=%d objective=%s",
		name,
		event.GetInt("timelimit"),
		event.GetInt("fraglimit"),
		objective);

	if (!Skills_ShouldHandleRoundStartEvent(name))
	{
		return;
	}

	g_Runtime.roundLive = false;
	Boss_OnRoundStart();
	Detect_OnRoundStart();

	if (g_Runtime.roundLiveSignal == PlayerSkillsRoundLiveSignal_Immediate)
	{
		g_Runtime.roundLive = true;
	}
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	char message[128];
	event.GetString("message", message, sizeof(message));
	Skills_Debug(PlayerSkillsDebug_Event, "[%s] winner=%d reason=%d message=%s time=%.1f", name, event.GetInt("winner"), event.GetInt("reason"), message, event.GetFloat("time"));

	if (g_Runtime.baseMode == PlayerSkillsGameMode_Versus)
	{
		return;
	}

	if (!Skills_ShouldHandleRoundEndEvent(name))
	{
		return;
	}

	Boss_OnRoundEnd();
	API_FinalizeSummaryFromCurrentState();
	Detect_OnRoundEnd();
	g_Runtime.roundLive = false;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	Skills_Debug(PlayerSkillsDebug_Event, "[L4D2_OnEndVersusModeRound_Post]");

	if (g_Runtime.baseMode != PlayerSkillsGameMode_Versus)
	{
		return;
	}

	Boss_OnRoundEnd();
	API_FinalizeSummaryFromCurrentState();
	Detect_OnRoundEnd();
	g_Runtime.roundLive = false;
}

void Event_ScavengeRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Skills_Debug(PlayerSkillsDebug_Event, "[%s] round=%d firsthalf=%d",
		name,
		event.GetInt("round"),
		event.GetBool("firsthalf"));
	Event_RoundStart(event, name, dontBroadcast);
}

void Event_ScavengeRoundFinished(Event event, const char[] name, bool dontBroadcast)
{
	Skills_Debug(PlayerSkillsDebug_Event, "[%s]", name);
	Event_RoundEnd(event, name, dontBroadcast);
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Boss_EventTankSpawn(event);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventPlayerHurt(event);
}

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventAbilityUse(event);
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventWeaponFire(event);
}

void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventPlayerJump(event);
}

void Event_PlayerJumpApex(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventPlayerJumpApex(event);
}

void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventJockeyRide(event);
}

void Event_JockeyPunched(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventJockeyPunched(event);
}

void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventJockeyRideEnd(event);
}

void Event_JockeyKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventJockeyKilled(event);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerSpawn(event);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Boss_EventPlayerDeath(event);
	Detect_EventPlayerDeath(event);
}

void Event_PlayerIncapacitatedStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Boss_EventPlayerIncapacitatedStart(event);
	Detect_EventPlayerIncapacitatedStart(event);
}

void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventPlayerLedgeGrab(event);
}

void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventPlayerShoved(event);
}

void Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventPlayerNowIt(event);
}

void Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventBoomerExploded(event);
}

void Event_ChargerChargeStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventChargerChargeStart(event);
}

void Event_ChargerChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventChargerChargeEnd(event);
}

void Event_ChargerKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventChargerKilled(event);
}

void Event_ChargerCarryStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventChargerCarryStart(event);
}

void Event_ChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventChargerImpact(event);
}

void Event_ChargerCarryEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventChargerCarryEnd(event);
}

void Event_ChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventChargerPummelStart(event);
}

void Event_ChargerPummelEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventChargerPummelEnd(event);
}

void Event_TriggeredCarAlarm(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventTriggeredCarAlarm();
}

void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Boss_EventWitchKilled(event);
}

void Event_ChokeStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventChokeStart(event);
}

void Event_ChokeStopped(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventChokeStopped(event);
}

void Event_TonguePullStopped(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventTonguePullStopped(event);
}

void Event_PounceStopped(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventPounceStopped(event);
}

void Event_PounceEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventPounceEnd(event);
}

Action Command_Skills(int client, int args)
{
	if (client <= 0 || !IsValidClient(client))
	{
		Announce_ReplyCommand(client, "%t sm_skills is in-game only.", "Tag");
		return Plugin_Handled;
	}

	if (!Skills_IsEnabled())
	{
		Announce_ReplyCommand(client, "%t {red}Plugin disabled.{default}", "Tag");
		return Plugin_Handled;
	}

	int target = client;
	bool explicitAll = false;
	if (args >= 1)
	{
		char pattern[MAX_TARGET_LENGTH];
		GetCmdArg(1, pattern, sizeof(pattern));

		if (StrEqual(pattern, "all", false))
		{
			explicitAll = true;
		}
		else
		{
			int targets[1];
			char targetNameArg[MAX_TARGET_LENGTH];
			bool targetNameMl = false;
			int found = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetNameArg, sizeof(targetNameArg), targetNameMl);
			if (found != 1)
			{
				ReplyToTargetError(client, found);
				return Plugin_Handled;
			}

			target = targets[0];
		}
	}

	if (!explicitAll)
	{
		char targetName[MAX_NAME_LENGTH];
		GetClientName(target, targetName, sizeof(targetName));

		int counts[L4D2Skill_Size];
		int total = 0;

		for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
		{
			if (g_SkillEvents[index].id <= 0 || !g_SkillEvents[index].actor.IsSamePersistentPlayer(target) || !Skills_IsSkillEventEnabledInCurrentMode(index))
			{
				continue;
			}

			switch (g_SkillEvents[index].type)
			{
				case L4D2Skill_WitchDead:
				{
					if (!g_SkillEvents[index].crown)
					{
						continue;
					}
				}

				case L4D2Skill_TankDead, L4D2Skill_WitchIncap, L4D2Skill_TankRockHit:
				{
					continue;
				}
			}

			counts[g_SkillEvents[index].type]++;
			total++;
		}

		if (total <= 0)
		{
			Announce_ReplyCommand(client, "%t %t", "Tag", "SkillsSummaryEmpty", targetName);
		}
		else
		{
			Announce_ReplyCommand(client, "%t %t", "Tag", "SkillsSummaryHeader", targetName);

			Announce_PrintSkillsSummaryLine(client, counts,
				L4D2Skill_HunterSkeet, "SkillsLabelSkeet",
				L4D2Skill_HunterSkeetMelee, "SkillsLabelSkeetMelee",
				L4D2Skill_HunterDeadstop, "SkillsLabelDeadstop",
				L4D2Skill_BoomerPop, "SkillsLabelPop",
				L4D2Skill_ChargerLevel, "SkillsLabelLevel",
				L4D2Skill_WitchDead, "SkillsLabelCrown");

			Announce_PrintSkillsSummaryLine(client, counts,
				L4D2Skill_SmokerTongueCut, "SkillsLabelTongueCut",
				L4D2Skill_SmokerSelfClear, "SkillsLabelSelfClear",
				L4D2Skill_ChargerInstaKill, "SkillsLabelInstaKill",
				L4D2Skill_ChargerDeathSetup, "SkillsLabelDeathSetup",
				L4D2Skill_SpecialPinClear, "SkillsLabelPinClear",
				L4D2Skill_ChargerBowl, "SkillsLabelBowl");

			Announce_PrintSkillsSummaryLine(client, counts,
				L4D2Skill_HunterHighPounce, "SkillsLabelHunterHighPounce",
				L4D2Skill_JockeyHighPounce, "SkillsLabelJockeyHighPounce",
				L4D2Skill_JockeyJumpStop, "SkillsLabelJumpStop",
				L4D2Skill_JockeySkeetMelee, "SkillsLabelJockeySkeetMelee",
				L4D2Skill_BoomerVomitLanded, "SkillsLabelVomit",
				L4D2Skill_CarAlarmTriggered, "SkillsLabelCarAlarm");

			Announce_PrintSkillsSummaryLine(client, counts,
				L4D2Skill_BunnyHopStreak, "SkillsLabelBHop",
				L4D2Skill_TankRockSkeet, "SkillsLabelRockSkeet",
				L4D2Skill_None, "",
				L4D2Skill_None, "",
				L4D2Skill_None, "",
				L4D2Skill_None, "");
		}
	}

	L4DTeam clientTeam = GetClientL4DTeam(client);
	L4DTeam targetTeam = explicitAll ? clientTeam : GetClientL4DTeam(target);
	bool showSurvivor = false;
	bool showInfected = false;
	int survivorFocus = 0;
	int infectedFocus = 0;

	if (explicitAll)
	{
		showSurvivor = true;
		showInfected = true;
		if (clientTeam == L4DTeam_Survivor)
		{
			survivorFocus = client;
		}
		else if (clientTeam == L4DTeam_Infected)
		{
			infectedFocus = client;
		}
	}
	else if (targetTeam == L4DTeam_Survivor || targetTeam == L4DTeam_Infected)
	{
		if (clientTeam == targetTeam)
		{
			showSurvivor = (targetTeam == L4DTeam_Survivor);
			showInfected = (targetTeam == L4DTeam_Infected);
		}
		else
		{
			showSurvivor = true;
			showInfected = true;
		}

		if (showSurvivor)
		{
			survivorFocus = (targetTeam == L4DTeam_Survivor) ? target : ((clientTeam == L4DTeam_Survivor) ? client : 0);
		}
		if (showInfected)
		{
			infectedFocus = (targetTeam == L4DTeam_Infected) ? target : ((clientTeam == L4DTeam_Infected) ? client : 0);
		}
	}

	if (!showSurvivor && !showInfected)
	{
		Announce_ReplyCommand(client, "%t %t", "Tag", "SkillsComparableTableUnavailable");
		return Plugin_Handled;
	}

	if (showSurvivor)
	{
		Announce_RenderSkillsTeamTable(client, L4DTeam_Survivor, survivorFocus);
	}
	if (showInfected)
	{
		Announce_RenderSkillsTeamTable(client, L4DTeam_Infected, infectedFocus);
	}

	return Plugin_Handled;
}

Action Command_SkillsStats(int client, int args)
{
	if (client <= 0 || !IsValidClient(client))
	{
		Announce_ReplyCommand(client, "%t sm_skills_stats is in-game only.", "Tag");
		return Plugin_Handled;
	}

	if (!Skills_IsEnabled())
	{
		Announce_ReplyCommand(client, "%t {red}Plugin disabled.{default}", "Tag");
		return Plugin_Handled;
	}

	bool showSurvivor = false;
	bool showInfected = false;

	if (args >= 1)
	{
		char scope[16];
		GetCmdArg(1, scope, sizeof(scope));

		if (StrEqual(scope, "surv", false) || StrEqual(scope, "survivor", false) || StrEqual(scope, "survivors", false))
		{
			showSurvivor = true;
		}
		else if (StrEqual(scope, "infect", false) || StrEqual(scope, "infected", false))
		{
			showInfected = true;
		}
		else if (StrEqual(scope, "all", false))
		{
			showSurvivor = true;
			showInfected = true;
		}
		else
		{
			Announce_ReplyCommand(client, "%t %t", "Tag", "SkillsStatsUsage");
			return Plugin_Handled;
		}
	}
	else
	{
		L4DTeam clientTeam = GetClientL4DTeam(client);
		if (clientTeam == L4DTeam_Survivor)
		{
			showSurvivor = true;
		}
		else if (clientTeam == L4DTeam_Infected)
		{
			showInfected = true;
		}
		else
		{
			showSurvivor = true;
			showInfected = true;
		}
	}

	if (!showSurvivor && !showInfected)
	{
		Announce_ReplyCommand(client, "%t %t", "Tag", "SkillsComparableTableUnavailable");
		return Plugin_Handled;
	}

	Announce_NotifyConsoleDelivery(client);

	if (showSurvivor)
	{
		Announce_RenderSkillsTeamTable(client, L4DTeam_Survivor, GetClientL4DTeam(client) == L4DTeam_Survivor ? client : 0);
	}
	if (showInfected)
	{
		Announce_RenderSkillsTeamTable(client, L4DTeam_Infected, GetClientL4DTeam(client) == L4DTeam_Infected ? client : 0);
	}

	return Plugin_Handled;
}
