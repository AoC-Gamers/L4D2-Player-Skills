#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <console_table>
#include <left4dhooks>
#include <l4d2util>
#include <l4d2_player_skills>

#undef REQUIRE_PLUGIN
#include <l4d2_player_stats>
#include <l4d_tank_control_eq>
#define REQUIRE_PLUGIN

#define MAX_MESSAGE_LENGTH 512
#include <colors>

#define LIBRARY_LEFT4DHOOKS "left4dhooks"
#define LOG_DIRECTORY "logs/l4d2_player_skills.log"
#define TRANSLATION_FILE "l4d2_player_skills.phrases"

#include "l4d2_player_skills/types.sp"

L4D2BossSessionData g_BossSessions[L4D2_SKILLS_MAX_BOSSES];
L4D2DamageEntry		g_BossDamage[L4D2_SKILLS_MAX_BOSSES][L4D2_SKILLS_MAX_DAMAGE_ENTRIES];
L4D2SkillEventData	g_SkillEvents[L4D2_SKILLS_MAX_EVENTS];
L4D2ApiSkillSummaryData g_SkillSummaries[L4D2_SKILLS_MAX_SUMMARIES];
L4D2ApiKillSummaryData g_KillSummaries[L4D2_SKILLS_MAX_SUMMARIES];
PlayerSkillsIdentityEntry g_IdentityCache[MAXPLAYERS + 1];
PlayerSkillsRuntimeState g_Runtime;

int	g_iBossSerial		= 0;
int g_iTankLifecycleSerial = 0;
int	g_iEventSerial		= 0;
int	g_iNextEventSlot	= 0;
int g_iSkillSummarySerial	= 0;
int g_iNextSkillSummarySlot	= 0;
int g_iKillSummarySerial	= 0;
int g_iNextKillSummarySlot	= 0;

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
ConVar	g_cvAnnounceKillMode		 = null;
ConVar	g_cvAnnounceSpecialClearMode = null;
ConVar	g_cvAnnounceTongueReleaseMode = null;
ConVar	g_cvShoveAttempt		 = null;
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
ConVar	g_cvJockeyHighLeapHeight = null;
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
		g_BossSessions[index].closedAt	 = 0.0;
		g_BossSessions[index].printed	 = false;
		if (type == L4D2Boss_Tank)
		{
			g_BossSessions[index].tank.lifecycleId = ++g_iTankLifecycleSerial;
		}

		int client						 = GetClientOfUserId(userid);
		if (IsValidClient(client))
		{
			this.UpdateOwnerSnapshot(client);
			if (type != L4D2Boss_Tank || !IsFakeClient(client))
			{
				this.RefreshOwner(client);
			}
		}
	}

	public void UpdateOwnerSnapshot(int client)
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

	public void CancelPendingTankBotControl()
	{
		if (!this.IsValid() || g_BossSessions[this.Index].type != L4D2Boss_Tank)
		{
			return;
		}

		g_BossSessions[this.Index].tank.pendingBotControl = false;
		g_BossSessions[this.Index].tank.pendingBotUserid = 0;
		g_BossSessions[this.Index].tank.pendingBotStartedAt = 0.0;
	}

	public void BeginPendingTankBotControl(int client, float startTime = 0.0)
	{
		if (!this.IsValid()
			|| g_BossSessions[this.Index].type != L4D2Boss_Tank
			|| !IsValidClient(client)
			|| !IsFakeClient(client))
		{
			return;
		}

		if (startTime <= 0.0)
		{
			startTime = GetGameTime();
		}

		this.UpdateOwnerSnapshot(client);

		int activeIndex = g_BossSessions[this.Index].tank.activeControlIndex;
		if (activeIndex >= 0
			&& activeIndex < L4D2_SKILLS_MAX_TANK_CONTROLS
			&& g_BossSessions[this.Index].tank.controls[activeIndex].active
			&& !g_BossSessions[this.Index].tank.controls[activeIndex].player.IsSamePersistentPlayer(client))
		{
			this.CloseActiveTankControl(startTime);
		}

		if (g_BossSessions[this.Index].tank.pendingBotControl
			&& g_BossSessions[this.Index].tank.pendingBotUserid == GetClientUserId(client))
		{
			if (g_BossSessions[this.Index].tank.pendingBotStartedAt <= 0.0
				|| startTime < g_BossSessions[this.Index].tank.pendingBotStartedAt)
			{
				g_BossSessions[this.Index].tank.pendingBotStartedAt = startTime;
			}

			return;
		}

		g_BossSessions[this.Index].tank.pendingBotControl = true;
		g_BossSessions[this.Index].tank.pendingBotUserid = GetClientUserId(client);
		g_BossSessions[this.Index].tank.pendingBotStartedAt = startTime;
	}

	public void CloseActiveTankControl(float endTime = 0.0)
	{
		if (!this.IsValid() || g_BossSessions[this.Index].type != L4D2Boss_Tank)
		{
			return;
		}

		int index = this.Index;
		int controlIndex = g_BossSessions[index].tank.activeControlIndex;
		if (controlIndex < 0 || controlIndex >= L4D2_SKILLS_MAX_TANK_CONTROLS)
		{
			return;
		}

		if (!g_BossSessions[index].tank.controls[controlIndex].active
			|| g_BossSessions[index].tank.controls[controlIndex].startedAt <= 0.0)
		{
			g_BossSessions[index].tank.activeControlIndex = -1;
			return;
		}

		if (endTime <= 0.0)
		{
			endTime = GetGameTime();
		}

		if (endTime < g_BossSessions[index].tank.controls[controlIndex].startedAt)
		{
			endTime = g_BossSessions[index].tank.controls[controlIndex].startedAt;
		}

		g_BossSessions[index].tank.controls[controlIndex].endedAt = endTime;
		g_BossSessions[index].tank.controls[controlIndex].controlTime +=
			endTime - g_BossSessions[index].tank.controls[controlIndex].startedAt;
		g_BossSessions[index].tank.controls[controlIndex].remainingHealth = g_BossSessions[index].lastHealth;
		g_BossSessions[index].tank.controls[controlIndex].startedAt = 0.0;
		g_BossSessions[index].tank.activeControlIndex = -1;
	}

		public void OpenTankControl(int client, float startTime = 0.0)
		{
			if (!this.IsValid() || g_BossSessions[this.Index].type != L4D2Boss_Tank || !IsValidClient(client))
			{
				return;
			}

			if (startTime <= 0.0)
			{
				startTime = GetGameTime();
			}

			int index = this.Index;
			int activeIndex = g_BossSessions[index].tank.activeControlIndex;
			if (activeIndex >= 0
				&& activeIndex < L4D2_SKILLS_MAX_TANK_CONTROLS
				&& g_BossSessions[index].tank.controls[activeIndex].active)
			{
				if (g_BossSessions[index].tank.controls[activeIndex].player.IsSamePersistentPlayer(client))
				{
					g_BossSessions[index].tank.controls[activeIndex].player.Capture(client);
					return;
				}

				this.CloseActiveTankControl();
			}

			if (g_BossSessions[index].tank.controlCount >= L4D2_SKILLS_MAX_TANK_CONTROLS)
			{
				int overflowIndex = L4D2_SKILLS_MAX_TANK_CONTROLS - 1;
			g_BossSessions[index].tank.controls[overflowIndex].mergedControls++;
			g_BossSessions[index].tank.controls[overflowIndex].active = true;
			g_BossSessions[index].tank.controls[overflowIndex].overflow = true;
			g_BossSessions[index].tank.controls[overflowIndex].player.Capture(client);
			g_BossSessions[index].tank.controls[overflowIndex].startedAt = startTime;
			g_BossSessions[index].tank.activeControlIndex = overflowIndex;
			return;
		}

		int controlIndex = g_BossSessions[index].tank.controlCount++;
		g_BossSessions[index].tank.controls[controlIndex].Reset();
		g_BossSessions[index].tank.controls[controlIndex].active = true;
		g_BossSessions[index].tank.controls[controlIndex].overflow = false;
		g_BossSessions[index].tank.controls[controlIndex].mergedControls = 1;
		g_BossSessions[index].tank.controls[controlIndex].player.Capture(client);
		g_BossSessions[index].tank.controls[controlIndex].startedAt = startTime;
		g_BossSessions[index].tank.activeControlIndex = controlIndex;
	}

	public void RecordTankRockThrown()
	{
		if (!this.IsValid() || g_BossSessions[this.Index].type != L4D2Boss_Tank)
		{
			return;
		}

		int controlIndex = g_BossSessions[this.Index].tank.activeControlIndex;
		if (controlIndex < 0 || controlIndex >= L4D2_SKILLS_MAX_TANK_CONTROLS)
		{
			return;
		}

		g_BossSessions[this.Index].tank.controls[controlIndex].rocksThrown++;
	}

	public void RecordTankRockHit()
	{
		if (!this.IsValid() || g_BossSessions[this.Index].type != L4D2Boss_Tank)
		{
			return;
		}

		int controlIndex = g_BossSessions[this.Index].tank.activeControlIndex;
		if (controlIndex < 0 || controlIndex >= L4D2_SKILLS_MAX_TANK_CONTROLS)
		{
			return;
		}

		g_BossSessions[this.Index].tank.controls[controlIndex].rocksHit++;
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

		this.UpdateOwnerSnapshot(client);

		if (g_BossSessions[this.Index].type == L4D2Boss_Tank)
		{
			if (IsFakeClient(client))
			{
				int activeIndex = g_BossSessions[this.Index].tank.activeControlIndex;
				if (activeIndex >= 0
					&& activeIndex < L4D2_SKILLS_MAX_TANK_CONTROLS
					&& g_BossSessions[this.Index].tank.controls[activeIndex].active
					&& g_BossSessions[this.Index].tank.controls[activeIndex].player.IsSamePersistentPlayer(client))
				{
					g_BossSessions[this.Index].tank.controls[activeIndex].player.Capture(client);
					this.CancelPendingTankBotControl();
					return;
				}

				this.BeginPendingTankBotControl(client);
				return;
			}

			this.CancelPendingTankBotControl();
			this.OpenTankControl(client);
		}
	}

	/**
	 * @brief Adds survivor damage to the current boss session.
	 *
	 * @param attacker      Survivor client index that dealt the damage.
	 * @param damage        Positive damage amount to accumulate.
	 *
	 * @noreturn
	 */
	public 	void AddDamage(int attacker, int damage, bool countShot = false)
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
		if (countShot)
		{
			g_BossDamage[index][entry].shots++;
		}
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
	RegPluginLibrary(LIBRARY_L4D2_PLAYER_SKILLS);
	API_CreateForwards();
	API_CreateNatives();
	return APLRes_Success;
}

#include "l4d2_player_skills/helpers.sp"
#include "l4d2_player_skills/api.sp"
#include "l4d2_player_skills/announce.sp"
#include "l4d2_player_skills/boss.sp"
#include "l4d2_player_skills/detect.sp"

void Skills_RefreshExternalLifecycleAvailability()
{
	g_Runtime.hasPlayerStats = LibraryExists(LIBRARY_L4D2PLAYERSTATS);
	g_Runtime.usesExternalLifecycle = Skills_CanUsePlayerStats();
}

void Skills_SyncLifecycleState()
{
	Skills_RefreshExternalLifecycleAvailability();
	Skills_RefreshModeContext();
	Skills_RefreshRoundLiveState();
}
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

	g_cvDebug			   			= CreateConVar("sm_skills_debug", "0", "Debug bitmask for l4d2_player_skills. 0=None 1=Core 2=Event 4=Detect 8=Boss 16=Pin 32=Physics 64=Api 128=Announce 255=all.");
	g_cvEnable			   			= CreateConVar("sm_skills_enable", "1", "Enable the l4d2_player_skills plugin.");
	g_cvAnnounceWitch				= CreateConVar("sm_skills_announce_witch", "7", "Bitmask for Witch announcements. 1=damage 2=misc 4=crown 7=all.");
	g_cvAnnounceTank				= CreateConVar("sm_skills_announce_tank", "15", "Bitmask for Tank announcements. 1=damage 2=rock_skeet 4=rock_hit 8=ledge_hang 15=all.");
	g_cvAnnounceHunter				= CreateConVar("sm_skills_announce_hunter", "63", "Bitmask for Hunter announcements. 1=skeet 2=skeet_melee 4=deadstop 8=high_pounce 16=special_clear 32=kill 63=all.");
	g_cvAnnounceSmoker				= CreateConVar("sm_skills_announce_smoker", "31", "Bitmask for Smoker announcements. 1=tongue_cut 2=self_clear 4=special_clear 8=kill 16=ledge_hang 31=all.");
	g_cvAnnounceBoomer				= CreateConVar("sm_skills_announce_boomer", "7", "Bitmask for Boomer announcements. 1=pop 2=vomit 4=kill 7=all.");
	g_cvAnnounceSpitter				= CreateConVar("sm_skills_announce_spitter", "1", "Bitmask for Spitter announcements. 1=kill 1=all.");
	g_cvAnnounceJockey				= CreateConVar("sm_skills_announce_jockey", "127", "Bitmask for Jockey announcements. 1=high_leap 2=special_clear 4=kill 8=jump_stop 16=skeet_melee 32=ledge_hang 64=skeet 127=all.");
	g_cvAnnounceCharger				= CreateConVar("sm_skills_announce_charger", "63", "Bitmask for Charger announcements. 1=level 2=insta_kill 4=death_setup 8=special_clear 16=kill 32=bowl 63=all.");
	g_cvAnnounceOther				= CreateConVar("sm_skills_announce_other", "3", "Bitmask for other announcements. 1=bunnyhop 2=car_alarm 3=all.");
	g_cvAnnounceKillMode			= CreateConVar("sm_skills_announce_kill_mode", "3", "Output mode for kill announcements. 1=console 2=chat 3=chat_headshot.");
	g_cvAnnounceSpecialClearMode	= CreateConVar("sm_skills_announce_specialclear_mode", "3", "Output mode for SpecialClear announcements. 1=console 2=chat 3=chat_headshot.");
	g_cvAnnounceTongueReleaseMode	= CreateConVar("sm_skills_announce_tongue_release_mode", "2", "Output mode for Smoker tongue-release announcements during pull/drag before choke pin. 0=disabled 1=console 2=chat 3=chat_headshot.");

	g_cvShoveAttempt			= CreateConVar("sm_skills_shove_attempt", "1", "Bitmask for shove-attempt announcements. 1=charger 2=tank 4=witch 7=all.");
	g_cvBoomerVomitMinTargets	= CreateConVar("sm_skills_boomer_vomit_min_targets", "3", "Minimum number of vomited survivors required to announce BoomerVomitLanded. 0=disabled.");
	g_cvWitchPrintMaxEntries	= CreateConVar("sm_skills_witch_print_max_entries", "4", "Maximum number of Witch damage entries to print before combining the rest as others.");
	
	g_cvHunterHighPounceHeight				= CreateConVar("sm_skills_hunter_pounce_height", "400", "Minimum vertical height for HunterHighPounce.");
	g_cvDetectHunterSkeetShotgunInterrupt	= CreateConVar("sm_skills_hunter_skeet_interrupt", "0", "Minimum shotgun blast damage required to classify HunterSkeet. Applies to shotgun skeets only. 0=disabled.");
	g_cvJockeyHighLeapHeight				= CreateConVar("sm_skills_jockey_leap_height", "300", "Minimum vertical height for JockeyHighLeap.");

	g_cvDetectInstaKillHeight	= CreateConVar("sm_skills_charger_instakill_height", "400", "Minimum vertical drop for ChargerInstaKill.");
	g_cvDetectDeathSetupHeight	= CreateConVar("sm_skills_charger_death_setup_height", "100", "Minimum vertical drop for ChargerDeathSetup incap classification.");
	g_cvChargerClawPrintMinHits = CreateConVar("sm_skills_charger_claw_hits", "4", "Minimum Charger claw hits required before printing the post-death claw summary. 0=disabled.");

	g_cvDetectBHopMinStreak		= CreateConVar("sm_skills_bhop_streak_min", "3", "Minimum amount of successful hops for BunnyHopStreak.");
	g_cvDetectBHopMinInitSpeed	= CreateConVar("sm_skills_bhop_init_speed", "150", "Minimum initial jump speed to start tracking BunnyHopStreak.");
	g_cvDetectBHopContSpeed		= CreateConVar("sm_skills_bhop_keep_speed", "300", "Minimum speed that keeps a hop streak even without acceleration.");

	g_cvHunterMaxPounceBonusDamage = FindConVar("z_hunter_max_pounce_bonus_damage");

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
	HookEvent("drag_begin", Event_DragBegin, EventHookMode_Post);
	HookEvent("drag_end", Event_DragEnd, EventHookMode_Post);
	HookEvent("tongue_pull_stopped", Event_TonguePullStopped, EventHookMode_Post);
	HookEvent("pounce_stopped", Event_PounceStopped, EventHookMode_Post);
	HookEvent("pounce_end", Event_PounceEnd, EventHookMode_Post);

	RegConsoleCmd("sm_skills", Command_Skills, "Print the detected skills summary in chat and the comparative skills table in console.");
	RegConsoleCmd("sm_skills_stats", Command_SkillsStats, "Print team skill stats to console. Usage: sm_skills_stats <surv|infect|all>.");

	AutoExecConfig(false, LIBRARY_L4D2_PLAYER_SKILLS);
	Boss_Init();

	if (!g_Runtime.isLate)
	{
		return;
	}

	g_Runtime.hasLeft4DHooks = LibraryExists(LIBRARY_LEFT4DHOOKS);
	g_Runtime.hasTankControlEq = LibraryExists(LIBRARY_L4D_TANK_CONTROL_EQ);
	Skills_SyncLifecycleState();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}

		Skills_CaptureIdentityForClient(client);
		Boss_OnClientPutInServer(client);
		Detect_OnClientPutInServer(client);
	}
}

public void OnAllPluginsLoaded()
{
	g_Runtime.hasLeft4DHooks = LibraryExists(LIBRARY_LEFT4DHOOKS);
	g_Runtime.hasTankControlEq = LibraryExists(LIBRARY_L4D_TANK_CONTROL_EQ);
	Skills_SyncLifecycleState();
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, LIBRARY_LEFT4DHOOKS) == 0)
	{
		g_Runtime.hasLeft4DHooks = true;
		Skills_SyncLifecycleState();
		return;
	}

	if (strcmp(name, LIBRARY_L4D_TANK_CONTROL_EQ) == 0)
	{
		g_Runtime.hasTankControlEq = true;
		return;
	}

	if (strcmp(name, LIBRARY_L4D2PLAYERSTATS) == 0)
	{
		Skills_SyncLifecycleState();
		Skills_Debug(PlayerSkillsDebug_Core, "PlayerStats available. Using external lifecycle=%d", Skills_UsesExternalLifecycle() ? 1 : 0);
		return;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, LIBRARY_LEFT4DHOOKS) == 0)
	{
		g_Runtime.hasLeft4DHooks = false;
		Skills_SyncLifecycleState();
		return;
	}

	if (strcmp(name, LIBRARY_L4D_TANK_CONTROL_EQ) == 0)
	{
		g_Runtime.hasTankControlEq = false;
		return;
	}

	if (strcmp(name, LIBRARY_L4D2PLAYERSTATS) == 0)
	{
		Skills_SyncLifecycleState();
		Skills_Debug(PlayerSkillsDebug_Core, "PlayerStats unavailable. Falling back to standalone lifecycle.");
		return;
	}
}

public void OnMapStart()
{
	g_Runtime.roundLive = false;
	Skills_ResetIdentityCache();
	Skills_ResetEvents();
	Boss_ResetAll();
	Detect_ResetAll();
}

public void OnMapEnd()
{
	g_Runtime.roundLive = false;
	Skills_ResetIdentityCache();
	Skills_ResetEvents();
	Boss_ResetAll();
	Detect_ResetAll();
}

public void OnConfigsExecuted()
{
	Skills_SyncLifecycleState();
}

public void L4D_OnGameModeChange(int gamemode)
{
	Skills_Debug(PlayerSkillsDebug_Event, "[L4D_OnGameModeChange] gamemode=%d", gamemode);
	Skills_SyncLifecycleState();
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

	if (!Skills_IsEnabled() || Skills_UsesExternalLifecycle() || g_Runtime.roundLive || g_Runtime.roundLiveSignal != PlayerSkillsRoundLiveSignal_SafeArea)
	{
		return;
	}

	g_Runtime.roundLive = true;
}

public void PlayerStats_OnRoundLive(int roundId)
{
	if (!Skills_UsesExternalLifecycle())
	{
		return;
	}

	Skills_Debug(PlayerSkillsDebug_Event, "[PlayerStats_OnRoundLive] round=%d", roundId);
	g_Runtime.roundLive = true;
}

public void PlayerStats_OnRoundEnded(int roundId, StatsEndType endType, int endReason)
{
	if (!Skills_UsesExternalLifecycle())
	{
		return;
	}

	Skills_Debug(PlayerSkillsDebug_Event, "[PlayerStats_OnRoundEnded] round=%d type=%d reason=%d", roundId, endType, endReason);
	Boss_OnRoundEnd();
	API_FinalizeSummaryFromCurrentState();
	Detect_OnRoundEnd();
	g_Runtime.roundLive = false;
}

public void OnClientPutInServer(int client)
{
	Skills_CaptureIdentityForClient(client);
	Boss_OnClientPutInServer(client);
	Detect_OnClientPutInServer(client);
}

public void OnClientDisconnect(int client)
{
	Skills_DetachIdentityClient(client);
	Boss_OnClientDisconnect(client);
	Detect_OnClientDisconnect(client);
}

public void OnClientSettingsChanged(int client)
{
	Skills_CaptureIdentityForClient(client);
}

public void OnClientTeam(int client, int oldTeam, int newTeam)
{
	Skills_CaptureIdentityForClient(client);
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

public void L4D_OnSpawnWitch_Post(int entity, const float vecPos[3], const float vecAng[3])
{
	Boss_OnSpawnWitchPost(entity);
}

public void L4D2_OnSpawnWitchBride_Post(int entity, const float vecPos[3], const float vecAng[3])
{
	Boss_OnSpawnWitchPost(entity);
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

	if (!Skills_UsesExternalLifecycle() && g_Runtime.roundLiveSignal == PlayerSkillsRoundLiveSignal_Immediate)
	{
		g_Runtime.roundLive = true;
	}
}

bool Skills_HasTankControlEq()
{
	return g_Runtime.hasTankControlEq;
}

bool Skills_HasTankControlEqSubstituteApi()
{
	return Skills_HasTankControlEq()
		&& GetFeatureStatus(FeatureType_Native, "TankControl_GetTankStartReason") == FeatureStatus_Available;
}

public void TankControl_OnTankStarted(int tankId, int client, bool isBot)
{
	if (Skills_HasTankControlEqSubstituteApi())
	{
		return;
	}

	if (!Skills_HasTankControlEq() || !IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}

	Skills_Debug(PlayerSkillsDebug_Boss,
		"TankControl_OnTankStarted received. tank_id=%d client=%d bot=%d",
		tankId,
		client,
		isBot);

	Boss_EnsureTankSession(client);
}

public void TankControl_OnTankStartedEx(int tankId, int client, bool isBot, TankControlStartReason startReason, int parentTankId)
{
	if (!Skills_HasTankControlEq() || !IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}

	Skills_Debug(PlayerSkillsDebug_Boss,
		"TankControl_OnTankStartedEx received. tank_id=%d client=%d bot=%d start=%d parent=%d",
		tankId,
		client,
		isBot,
		startReason,
		parentTankId);

	Boss_EnsureTankSession(client);
}

public void TankControl_OnTankControlChanged(int tankId, int oldClient, int newClient, bool oldWasBot, bool newWasBot)
{
	if (!Skills_HasTankControlEq() || !IsValidClient(newClient) || !IsPlayerAlive(newClient))
	{
		return;
	}

	Skills_Debug(PlayerSkillsDebug_Boss,
		"TankControl_OnTankControlChanged received. tank_id=%d old=%d new=%d oldBot=%d newBot=%d",
		tankId,
		oldClient,
		newClient,
		oldWasBot,
		newWasBot);

	Boss_EnsureTankSession(newClient);
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

	if (Skills_UsesExternalLifecycle())
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

	if (g_Runtime.baseMode != PlayerSkillsGameMode_Versus || Skills_UsesExternalLifecycle())
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

	Boss_EventPlayerHurt(event);
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

void Event_DragBegin(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventDragBegin(event);
}

void Event_DragEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!Skills_IsRoundLive())
	{
		return;
	}

	Detect_EventDragEnd(event);
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
				case L4D2Skill_TankDead, L4D2Skill_WitchDead, L4D2Skill_WitchIncap, L4D2Skill_TankRockHit:
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
				L4D2Skill_WitchCrown, "SkillsLabelCrown");

			Announce_PrintSkillsSummaryLine(client, counts,
				L4D2Skill_SmokerTongueCut, "SkillsLabelTongueCut",
				L4D2Skill_SmokerSelfClear, "SkillsLabelSelfClear",
				L4D2Skill_ChargerInstaKill, "SkillsLabelInstaKill",
				L4D2Skill_ChargerDeathSetup, "SkillsLabelDeathSetup",
				L4D2Skill_SpecialPinClear, "SkillsLabelPinClear",
				L4D2Skill_ChargerBowl, "SkillsLabelBowl");

			Announce_PrintSkillsSummaryLine(client, counts,
				L4D2Skill_HunterHighPounce, "SkillsLabelHunterHighPounce",
				L4D2Skill_JockeyHighLeap, "SkillsLabelJockeyHighLeap",
				L4D2Skill_JockeyJumpStop, "SkillsLabelJumpStop",
				L4D2Skill_JockeySkeetMelee, "SkillsLabelJockeySkeetMelee",
				L4D2Skill_JockeySkeet, "SkillsLabelJockeySkeet",
				L4D2Skill_CarAlarmTriggered, "SkillsLabelCarAlarm");

			Announce_PrintSkillsSummaryLine(client, counts,
				L4D2Skill_BunnyHopStreak, "SkillsLabelBHop",
				L4D2Skill_TankRockSkeet, "SkillsLabelRockSkeet",
				L4D2Skill_BoomerVomitLanded, "SkillsLabelVomit",
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
