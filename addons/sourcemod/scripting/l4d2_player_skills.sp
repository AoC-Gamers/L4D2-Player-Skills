#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>
#include <left4dhooks>

#include "l4d2_player_skills/types.sp"

L4D2BossSessionData g_BossSessions[L4D2_SKILLS_MAX_BOSSES];
L4D2DamageEntry		g_BossDamage[L4D2_SKILLS_MAX_BOSSES][L4D2_SKILLS_MAX_DAMAGE_ENTRIES];
L4D2SkillEventData	g_SkillEvents[L4D2_SKILLS_MAX_EVENTS];

int	g_iBossSerial		= 0;
int	g_iEventSerial		= 0;
int	g_iNextEventSlot	= 0;

ConVar	g_cvEnable				 = null;
ConVar	g_cvDebug				 = null;
ConVar	g_cvAnnounceSkills		 = null;
ConVar	g_cvAnnounceBossDamage	 = null;
ConVar	g_cvWitchHealth			 = null;

int		g_iWitchPrintMinimum	 = 0;
int		g_iWitchPrintMaxLines	 = 0;
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

public void OnPluginStart()
{
	BuildPath(Path_SM, g_sDebugLogPath, sizeof(g_sDebugLogPath), "logs/l4d2_player_skills_debug.log");
	LoadTranslations("l4d2_player_skills.phrases");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("ability_use", Event_AbilityUse, EventHookMode_Post);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	HookEvent("player_jump", Event_PlayerJump, EventHookMode_Post);
	HookEvent("player_jump_apex", Event_PlayerJumpApex, EventHookMode_Post);
	HookEvent("jockey_ride", Event_JockeyRide, EventHookMode_Post);
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_incapacitated_start", Event_PlayerIncapacitatedStart, EventHookMode_Post);
	HookEvent("player_shoved", Event_PlayerShoved, EventHookMode_Post);
	HookEvent("player_now_it", Event_PlayerNowIt, EventHookMode_Post);
	HookEvent("boomer_exploded", Event_BoomerExploded, EventHookMode_Post);
	HookEvent("charger_impact", Event_ChargerImpact, EventHookMode_Post);
	HookEvent("charger_carry_end", Event_ChargerCarryEnd, EventHookMode_Post);
	HookEvent("triggered_car_alarm", Event_TriggeredCarAlarm, EventHookMode_Post);
	HookEvent("infected_hurt", Event_InfectedHurt, EventHookMode_Post);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);
	HookEvent("choke_start", Event_ChokeStart, EventHookMode_Post);
	HookEvent("tongue_pull_stopped", Event_TonguePullStopped, EventHookMode_Post);

	g_cvEnable			   = CreateConVar("l4d2_player_skills_enable", "1", "Enable the l4d2_player_skills plugin.");
	g_cvDebug			   = CreateConVar("l4d2_player_skills_debug", "0", "Debug bitmask for l4d2_player_skills. 0=None 1=Core 2=Detect 4=Boss 8=Pin 16=Physics 32=Api 64=Announce.");
	g_cvAnnounceSkills	   = CreateConVar("l4d2_player_skills_announce_skills", "1", "Announce detected skills in chat.");
	g_cvAnnounceBossDamage = CreateConVar("l4d2_player_skills_announce_boss_damage", "1", "Announce boss damage summaries in chat.");

	g_cvWitchHealth		   = FindConVar("z_witch_health");

	AutoExecConfig(false, "l4d2_player_skills");

	API_Init();
	Announce_Init();
	Boss_Init();
	Detect_Init();
}

public void OnMapStart()
{
	Skills_ResetEvents();
	Boss_ResetAll();
	Detect_ResetAll();
}

public void OnMapEnd()
{
	Skills_ResetEvents();
	Boss_ResetAll();
	Detect_ResetAll();
}

public void OnPluginEnd()
{
	Skills_ResetEvents();
	Boss_ResetAll();
	Detect_ResetAll();
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
	Detect_OnGrabWithTonguePost(victim, attacker);
}

public void L4D_OnPouncedOnSurvivor_Post(int victim, int attacker)
{
	Detect_OnPouncedOnSurvivorPost(victim, attacker);
}

public void L4D2_OnJockeyRide_Post(int victim, int attacker)
{
	Detect_OnJockeyRidePost(victim, attacker);
}

public void L4D2_OnStartCarryingVictim_Post(int victim, int attacker)
{
	Detect_OnStartCarryingVictimPost(victim, attacker);
}

public void L4D2_OnSlammedSurvivor_Post(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge)
{
	Detect_OnSlammedSurvivorPost(victim, attacker, bWallSlam, bDeadlyCharge);
}

public Action L4D_OnFatalFalling(int client, int camera)
{
	Detect_OnFatalFalling(client);
	return Plugin_Continue;
}

public void L4D_OnFalling(int client)
{
	Detect_OnFalling(client);
}

public void L4D_OnLedgeGrabbed_Post(int client)
{
	Detect_OnLedgeGrabbedPost(client);
}

public void L4D_OnIncapacitated_Post(int client, int inflictor, int attacker, float damage, int damagetype, int weapon)
{
	Detect_OnIncapacitatedPost(client, attacker, damagetype);
}

public void L4D2_OnPummelVictim_Post(int attacker, int victim)
{
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
	Detect_OnEntityShovedPost(client, entity, weapon, vecDir, bIsHighPounce);
}

public void L4D_TankRock_OnRelease_Post(int tank, int rock, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
	Detect_OnTankRockReleasePost(tank, rock);
}

public void L4D_TankRock_BounceTouch_Post(int tank, int rock, int entity)
{
	Detect_OnTankRockBounceTouchPost(tank, rock, entity);
}

public void L4D_TankRock_OnDetonate(int tank, int rock)
{
	Detect_OnTankRockDetonate(tank, rock);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Boss_OnRoundStart();
	Detect_OnRoundStart();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Boss_OnRoundEnd();
	Detect_OnRoundEnd();
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Boss_EventTankSpawn(event);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	Boss_EventPlayerHurt(event);
	Detect_EventPlayerHurt(event);
}

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventAbilityUse(event);
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventWeaponFire(event);
}

void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerJump(event);
}

void Event_PlayerJumpApex(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerJumpApex(event);
}

void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventJockeyRide(event);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerSpawn(event);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Boss_EventPlayerDeath(event);
	Detect_EventPlayerDeath(event);
}

void Event_PlayerIncapacitatedStart(Event event, const char[] name, bool dontBroadcast)
{
	Boss_EventPlayerIncapacitatedStart(event);
	Detect_EventPlayerIncapacitatedStart(event);
}

void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerShoved(event);
}

void Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerNowIt(event);
}

void Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventBoomerExploded(event);
}

void Event_ChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventChargerImpact(event);
}

void Event_ChargerCarryEnd(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventChargerCarryEnd(event);
}

void Event_TriggeredCarAlarm(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventTriggeredCarAlarm();
}

void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	Boss_EventInfectedHurt(event);
}

void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	Boss_EventWitchKilled(event);
}

void Event_ChokeStart(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventChokeStart(event);
}

void Event_TonguePullStopped(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventTonguePullStopped(event);
}

#include "l4d2_player_skills/helpers.sp"
#include "l4d2_player_skills/api.sp"
#include "l4d2_player_skills/announce.sp"
#include "l4d2_player_skills/boss.sp"
#include "l4d2_player_skills/detect.sp"
