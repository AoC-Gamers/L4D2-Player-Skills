#if defined _l4d2_player_skills_types_included
	#endinput
#endif
#define _l4d2_player_skills_types_included

#define L4D2_SKILLS_MAX_BOSSES		   64
#define L4D2_SKILLS_MAX_DAMAGE_ENTRIES 32
#define L4D2_SKILLS_MAX_EVENTS		   256
#define L4D2_SKILLS_MAX_EVENT_ASSISTS  8
#define L4D2_SKILLS_MAX_SUMMARIES	   16
#define L4D2_SKILLS_MAX_SUMMARY_ENTRIES 24
#define L4D2_SKILLS_SHOTGUN_BLAST_TIME 0.1
#define L4D2_SKILLS_DEFAULT_BOOMER_HEALTH 50
#define L4D2_SKILLS_DEFAULT_SMOKER_HEALTH 250
#define L4D2_SKILLS_DEFAULT_HUNTER_HEALTH 250
#define L4D2_SKILLS_DEFAULT_SPITTER_HEALTH 100
#define L4D2_SKILLS_DEFAULT_JOCKEY_HEALTH 325
#define L4D2_SKILLS_DEFAULT_CHARGER_HEALTH 600
#define L4D2_SKILLS_DEFAULT_TANK_HEALTH 4000
#define L4D2_SKILLS_DEFAULT_WITCH_HEALTH 1000
#define L4D2_SKILLS_DEFAULT_HUNTER_MAX_POUNCE_BONUS_DAMAGE 24.0
#define L4D2_SKILLS_DEFAULT_HUNTER_HIGH_POUNCE_HEIGHT 400.0
#define L4D2_SKILLS_DEFAULT_JOCKEY_HIGH_POUNCE_HEIGHT 300.0

enum L4D2SkillType
{
	L4D2Skill_None = 0,
	L4D2Skill_HunterSkeet,
	L4D2Skill_HunterSkeetMelee,
	L4D2Skill_HunterDeadstop,
	L4D2Skill_BoomerPop,
	L4D2Skill_ChargerLevel,
	L4D2Skill_TankDead,
	L4D2Skill_WitchDead,
	L4D2Skill_WitchIncap,
	L4D2Skill_SmokerTongueCut,
	L4D2Skill_SmokerSelfClear,
	L4D2Skill_TankRockSkeet,
	L4D2Skill_TankRockHit,
	L4D2Skill_HunterHighPounce,
	L4D2Skill_JockeyHighPounce,
	L4D2Skill_ChargerInstaKill,
	L4D2Skill_ChargerDeathSetup,
	L4D2Skill_SpecialPinClear,
	L4D2Skill_BoomerVomitLanded,
	L4D2Skill_BunnyHopStreak,
	L4D2Skill_CarAlarmTriggered,
	L4D2Skill_SmokerKill,
	L4D2Skill_BoomerKill,
	L4D2Skill_HunterKill,
	L4D2Skill_SpitterKill,
	L4D2Skill_JockeyKill,
	L4D2Skill_ChargerKill,
	L4D2Skill_JockeyJumpStop,
	L4D2Skill_JockeySkeetMelee,

	L4D2Skill_Size
}

enum L4D2BossType
{
	L4D2Boss_None = 0,
	L4D2Boss_Tank,
	L4D2Boss_Witch
}

enum L4D2BossState
{
	L4D2BossState_None = 0,
	L4D2BossState_Active,
	L4D2BossState_Dead,
	L4D2BossState_Escaped,
	L4D2BossState_Printed
}

enum L4D2CarAlarmReason
{
	L4D2CarAlarm_Unknown = 0,
	L4D2CarAlarm_Hit,
	L4D2CarAlarm_Touched,
	L4D2CarAlarm_Explosion,
	L4D2CarAlarm_Boomer
}

enum PlayerSkillsDebugCategory
{
	PlayerSkillsDebug_None		= 0,
	PlayerSkillsDebug_Core		= 1 << 0,
	PlayerSkillsDebug_Event		= 1 << 1,
	PlayerSkillsDebug_Detect	= 1 << 2,
	PlayerSkillsDebug_Boss		= 1 << 3,
	PlayerSkillsDebug_Pin		= 1 << 4,
	PlayerSkillsDebug_Physics	= 1 << 5,
	PlayerSkillsDebug_Api		= 1 << 6,
	PlayerSkillsDebug_Announce	= 1 << 7
}

enum PlayerSkillsAnnounceHunterFlag
{
	PlayerSkillsAnnounceHunter_None = 0,
	PlayerSkillsAnnounceHunter_Skeet = 1 << 0,
	PlayerSkillsAnnounceHunter_SkeetMelee = 1 << 1,
	PlayerSkillsAnnounceHunter_Deadstop = 1 << 2,
	PlayerSkillsAnnounceHunter_HighPounce = 1 << 3,
	PlayerSkillsAnnounceHunter_SpecialClear = 1 << 4,
	PlayerSkillsAnnounceHunter_Kill = 1 << 5
}

enum PlayerSkillsAnnounceSmokerFlag
{
	PlayerSkillsAnnounceSmoker_None = 0,
	PlayerSkillsAnnounceSmoker_TongueCut = 1 << 0,
	PlayerSkillsAnnounceSmoker_SelfClear = 1 << 1,
	PlayerSkillsAnnounceSmoker_SpecialClear = 1 << 2,
	PlayerSkillsAnnounceSmoker_Kill = 1 << 3
}

enum PlayerSkillsAnnounceBoomerFlag
{
	PlayerSkillsAnnounceBoomer_None = 0,
	PlayerSkillsAnnounceBoomer_Pop = 1 << 0,
	PlayerSkillsAnnounceBoomer_Vomit = 1 << 1,
	PlayerSkillsAnnounceBoomer_Kill = 1 << 2
}

enum PlayerSkillsAnnounceSpitterFlag
{
	PlayerSkillsAnnounceSpitter_None = 0,
	PlayerSkillsAnnounceSpitter_Kill = 1 << 0
}

enum PlayerSkillsAnnounceJockeyFlag
{
	PlayerSkillsAnnounceJockey_None = 0,
	PlayerSkillsAnnounceJockey_HighPounce = 1 << 0,
	PlayerSkillsAnnounceJockey_SpecialClear = 1 << 1,
	PlayerSkillsAnnounceJockey_Kill = 1 << 2,
	PlayerSkillsAnnounceJockey_JumpStop = 1 << 3,
	PlayerSkillsAnnounceJockey_SkeetMelee = 1 << 4
}

enum PlayerSkillsAnnounceChargerFlag
{
	PlayerSkillsAnnounceCharger_None = 0,
	PlayerSkillsAnnounceCharger_Level = 1 << 0,
	PlayerSkillsAnnounceCharger_InstaKill = 1 << 1,
	PlayerSkillsAnnounceCharger_DeathSetup = 1 << 2,
	PlayerSkillsAnnounceCharger_SpecialClear = 1 << 3,
	PlayerSkillsAnnounceCharger_Kill = 1 << 4
}

enum PlayerSkillsAnnounceOtherFlag
{
	PlayerSkillsAnnounceOther_None = 0,
	PlayerSkillsAnnounceOther_BunnyHop = 1 << 0,
	PlayerSkillsAnnounceOther_CarAlarm = 1 << 1
}

enum PlayerSkillsAnnounceBossFlag
{
	PlayerSkillsAnnounceBoss_None = 0,
	PlayerSkillsAnnounceBoss_Damage = 1 << 0,
	PlayerSkillsAnnounceBoss_Misc = 1 << 1,
	PlayerSkillsAnnounceBoss_Crown = 1 << 2,
	PlayerSkillsAnnounceBoss_RockSkeet = 1 << 2,
	PlayerSkillsAnnounceBoss_RockHit = 1 << 3
}

enum PlayerSkillsGameMode
{
	PlayerSkillsGameMode_Unknown = 0,
	PlayerSkillsGameMode_Coop,
	PlayerSkillsGameMode_Versus,
	PlayerSkillsGameMode_Survival,
	PlayerSkillsGameMode_Scavenge
}

enum PlayerSkillsSiPoolFlag
{
	PlayerSkillsSiPool_None = 0,
	PlayerSkillsSiPool_Smoker = 1 << 0,
	PlayerSkillsSiPool_Boomer = 1 << 1,
	PlayerSkillsSiPool_Hunter = 1 << 2,
	PlayerSkillsSiPool_Spitter = 1 << 3,
	PlayerSkillsSiPool_Jockey = 1 << 4,
	PlayerSkillsSiPool_Charger = 1 << 5
}

enum PlayerSkillsVersusContextType
{
	PlayerSkillsVersusContext_None = 0,
	PlayerSkillsVersusContext_Versus1v1,
	PlayerSkillsVersusContext_Versus2v2,
	PlayerSkillsVersusContext_Versus3v3,
	PlayerSkillsVersusContext_Versus4v4,
	PlayerSkillsVersusContext_CustomTeamVersus
}

enum PlayerSkillsRoundStartSignalType
{
	PlayerSkillsRoundStartSignal_None = 0,
	PlayerSkillsRoundStartSignal_GenericRoundStart,
	PlayerSkillsRoundStartSignal_ScavengeRoundStart
}

enum PlayerSkillsRoundEndSignalType
{
	PlayerSkillsRoundEndSignal_None = 0,
	PlayerSkillsRoundEndSignal_GenericRoundEnd,
	PlayerSkillsRoundEndSignal_ScavengeRoundFinished
}

enum PlayerSkillsRoundLiveSignalType
{
	PlayerSkillsRoundLiveSignal_None = 0,
	PlayerSkillsRoundLiveSignal_Immediate,
	PlayerSkillsRoundLiveSignal_SafeArea
}

enum PlayerSkillsCvarScope
{
	PlayerSkillsCvarScope_Global = 0,
	PlayerSkillsCvarScope_Coop,
	PlayerSkillsCvarScope_Versus,
	PlayerSkillsCvarScope_Survival,
	PlayerSkillsCvarScope_Scavenge
}

enum struct PlayerSkillsModeContextData
{
	PlayerSkillsGameMode baseMode;
	bool isVersusMode;
	int configuredSurvivorLimit;
	int configuredPlayerZombieLimit;
	int siPoolMask;
	int enabledSiClassCount;
	int versusTeamSize;
	PlayerSkillsVersusContextType versusContext;

	void Reset()
	{
		this.baseMode = PlayerSkillsGameMode_Unknown;
		this.isVersusMode = false;
		this.configuredSurvivorLimit = 0;
		this.configuredPlayerZombieLimit = 0;
		this.siPoolMask = view_as<int>(PlayerSkillsSiPool_None);
		this.enabledSiClassCount = 0;
		this.versusTeamSize = 0;
		this.versusContext = PlayerSkillsVersusContext_None;
	}
}

enum struct PlayerSkillsLifecyclePolicyData
{
	PlayerSkillsRoundStartSignalType roundStartSignal;
	PlayerSkillsRoundEndSignalType roundEndSignal;
	PlayerSkillsRoundLiveSignalType roundLiveSignal;

	void Reset()
	{
		this.roundStartSignal = PlayerSkillsRoundStartSignal_None;
		this.roundEndSignal = PlayerSkillsRoundEndSignal_None;
		this.roundLiveSignal = PlayerSkillsRoundLiveSignal_None;
	}
}

enum struct PlayerSkillsRuntimeState
{
	PlayerSkillsGameMode baseMode;
	bool hasLeft4DHooks;
	bool isLate;
	bool roundLive;
	int configuredSurvivorLimit;
	int configuredPlayerZombieLimit;
	int siPoolMask;
	int enabledSiClassCount;
	int versusTeamSize;
	PlayerSkillsVersusContextType versusContext;
	PlayerSkillsRoundStartSignalType roundStartSignal;
	PlayerSkillsRoundEndSignalType roundEndSignal;
	PlayerSkillsRoundLiveSignalType roundLiveSignal;

	void Reset()
	{
		this.baseMode = PlayerSkillsGameMode_Unknown;
		this.hasLeft4DHooks = false;
		this.isLate = false;
		this.roundLive = false;
		this.configuredSurvivorLimit = 0;
		this.configuredPlayerZombieLimit = 0;
		this.siPoolMask = view_as<int>(PlayerSkillsSiPool_None);
		this.enabledSiClassCount = 0;
		this.versusTeamSize = 0;
		this.versusContext = PlayerSkillsVersusContext_None;
		this.roundStartSignal = PlayerSkillsRoundStartSignal_None;
		this.roundEndSignal = PlayerSkillsRoundEndSignal_None;
		this.roundLiveSignal = PlayerSkillsRoundLiveSignal_None;
	}
}

/**
 * @brief Snapshot of a player identity captured at event time.
 * @remarks Stores both runtime and persistent identifiers so the plugin can
 *          keep references after disconnects or slot changes.
 */
enum struct L4D2PlayerRef
{
	int	 client;
	int	 userid;
	int	 accountId;
	bool bot;
	int	 character;
	char name[MAX_NAME_LENGTH];
	char auth[32];

	/**
	 * @brief Clears the captured player snapshot.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.client	   = 0;
		this.userid	   = 0;
		this.accountId = 0;
		this.bot	   = false;
		this.character = -1;
		this.name[0]   = '\0';
		this.auth[0]   = '\0';
	}

	/**
	 * @brief Captures the current runtime identity of a client.
	 * @remarks Bots resolve to accountId 0 and auth string "BOT".
	 *
	 * @param client         Client index to snapshot.
	 *
	 * @noreturn
	 */
	void Capture(int client)
	{
		this.Reset();

		if (!IsValidClient(client))
		{
			return;
		}

		this.client	   = client;
		this.userid	   = GetClientUserId(client);
		this.bot	   = IsFakeClient(client);
		this.accountId = this.bot ? 0 : GetSteamAccountID(client);
		this.character = (L4D_GetClientTeam(client) == L4DTeam_Survivor) ? GetEntProp(client, Prop_Send, "m_survivorCharacter") : -1;

		GetClientName(client, this.name, sizeof(this.name));

		if (this.bot)
		{
			strcopy(this.auth, sizeof(this.auth), "BOT");
			return;
		}

		if (!GetClientAuthId(client, AuthId_Steam2, this.auth, sizeof(this.auth), true))
		{
			strcopy(this.auth, sizeof(this.auth), "UNKNOWN");
		}
	}

	/**
	 * @brief Clears the runtime client binding while keeping persistent identity fields.
	 *
	 * @noreturn
	 */
	void DetachClient()
	{
		this.client = 0;
		this.userid = 0;
	}

	/**
	 * @brief Checks whether the captured userid still resolves to a live client.
	 *
	 * @return               True if the referenced player is still online.
	 */
	bool IsOnline()
	{
		int current = GetClientOfUserId(this.userid);
		return IsValidClient(current);
	}

	/**
	 * @brief Resolves the captured userid back to a live client index.
	 *
	 * @return               Client index, or 0 if the player is offline.
	 */
	int ResolveClient()
	{
		int current = GetClientOfUserId(this.userid);
		return IsValidClient(current) ? current : 0;
	}

	/**
	 * @brief Checks whether a live client matches this runtime snapshot.
	 *
	 * @param client         Client index to compare.
	 *
	 * @return               True if the userid matches the captured runtime user.
	 */
	bool IsSameRuntimePlayer(int client)
	{
		return IsValidClient(client) && this.userid > 0 && GetClientUserId(client) == this.userid;
	}

	/**
	 * @brief Checks whether a live client matches this persistent identity.
	 * @remarks Human players compare by Steam account id. Survivor bots compare by
	 *          survivor character so bot/player replacement keeps the same identity.
	 *
	 * @param client         Client index to compare.
	 *
	 * @return               True if the client matches the captured identity.
	 */
	bool IsSamePersistentPlayer(int client)
	{
		if (!IsValidClient(client))
		{
			return false;
		}

		if (this.bot || IsFakeClient(client))
		{
			if (!this.bot || !IsFakeClient(client))
			{
				return false;
			}

			if (L4D_GetClientTeam(client) != L4DTeam_Survivor || this.character < 0)
			{
				return false;
			}

			return GetEntProp(client, Prop_Send, "m_survivorCharacter") == this.character;
		}

		int accountId = GetSteamAccountID(client);
		if (this.accountId > 0 && accountId > 0)
		{
			return this.accountId == accountId;
		}

		char auth[32];
		if (!GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth), true))
		{
			return false;
		}

		return this.auth[0] != '\0' && strcmp(this.auth, auth) == 0;
	}
}

/**
 * @brief Aggregated damage contribution entry for one player against a boss.
 */
enum struct L4D2DamageEntry
{
	bool		  active;
	L4D2PlayerRef player;
	int			  damage;
	int			  shots;

	/**
	 * @brief Clears the captured boss damage entry.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.active = false;
		this.player.Reset();
		this.damage = 0;
		this.shots	= 0;
	}
}

/**
 * @brief Runtime state tracked for one Tank or Witch damage session.
 * @remarks Holds ownership, health, timing and contextual boss data reused by
 *          announces, score tables and public API queries.
 */
enum struct L4D2BossSessionData
{
	int			  id;
	L4D2BossType  type;
	L4D2BossState state;
	int			  entity;
	int			  entRef;
	int			  userid;
	L4D2PlayerRef owner;
	int			  maxHealth;
	int			  lastHealth;
	int			  totalDamage;
	float		  startedAt;
	int			  rocksThrown;
	int			  rocksHit;
	int			  incaps;
	int			  kills;
	bool		  printed;
	bool		  startled;
	L4D2PlayerRef harasser;
	bool		  crownDetected;
	L4D2PlayerRef crowner;
	int			  lastHealthBeforeDamage;
	float		  lastShotTime;
	float		  lastBlastStartTime;
	int			  lastShotAttacker;
	int			  lastShotDamage;
	float		  lastShotRawDamage;
	int			  lastBlastDamage;
	float		  lastBlastRawDamage;
	int			  lastDamageType;
	bool		  lastShotIsShotgun;
	bool		  inStasis;
	L4D2PlayerRef pendingOwner;

	/**
	 * @brief Clears the runtime state for a boss damage session.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.id	 					= 0;
		this.type	 				= L4D2Boss_None;
		this.state	 				= L4D2BossState_None;
		this.entity 				= -1;
		this.entRef 				= INVALID_ENT_REFERENCE;
		this.userid 				= 0;
		this.owner.Reset();
		this.maxHealth	  			= 0;
		this.lastHealth  			= 0;
		this.totalDamage 			= 0;
		this.startedAt	  			= 0.0;
		this.rocksThrown 			= 0;
		this.rocksHit	  			= 0;
		this.incaps	  				= 0;
		this.kills		  			= 0;
		this.printed	  			= false;
		this.startled	  			= false;
		this.harasser.Reset();
		this.crownDetected 			= false;
		this.crowner.Reset();
		this.lastHealthBeforeDamage = 0;
		this.lastShotTime			= 0.0;
		this.lastBlastStartTime	 	= 0.0;
		this.lastShotAttacker		= 0;
		this.lastShotDamage		 	= 0;
		this.lastShotRawDamage		= 0.0;
		this.lastBlastDamage		= 0;
		this.lastBlastRawDamage	 	= 0.0;
		this.lastDamageType		 	= 0;
		this.lastShotIsShotgun		 = false;
		this.inStasis				 = false;
		this.pendingOwner.Reset();
	}
}

/**
 * @brief Canonical in-memory payload for one detected skill event.
 * @remarks This structure is filled by detection code and then consumed by the
 *          announcer, the legacy wrapper and the public API.
 */
enum struct L4D2SkillEventData
{
	int			  id;
	L4D2SkillType type;
	L4D2PlayerRef actor;
	L4D2PlayerRef victim;
	L4D2PlayerRef assister;
	L4D2PlayerRef assists[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	L4D2PlayerRef pinVictim;
	int			  actor2;
	int			  victim2;
	int			  assistsCount;
	int			  actorWeaponId;
	int			  actorDamage;
	int			  assisterDamage;
	int			  assisterWeaponId;
	int			  assistDamage[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	int			  assistWeaponId[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	int			  assisterShots;
	int			  assistShots[L4D2_SKILLS_MAX_EVENT_ASSISTS];
	int			  damage;
	int			  chipDamage;
	int			  shots;
	int			  shoveCount;
	int			  amount;
	int			  streak;
	int			  zombieClass;
	int			  reason;
	bool		  withShove;
	bool		  indirect;
	bool		  forced;
	bool		  wasCarried;
	bool		  crown;
	bool		  startled;
	bool		  reportedHigh;
	bool		  incapped;
	bool		  ledgeHang;
	bool		  fatalFall;
	bool		  deadlySlam;
	bool		  wouldQualifyAtBaseline;
	bool		  perfect;
	bool		  headshot;
	bool		  sniper;
	bool		  grenadeLauncher;
	float		  calculatedDamage;
	float		  timeA;
	float		  timeB;
	float		  height;
	float		  distance;
	float		  maxVelocity;
	float		  createdAt;

	/**
	 * @brief Clears the runtime payload stored for one skill event.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.id						= 0;
		this.type					= L4D2Skill_None;
		this.actor.Reset();
		this.victim.Reset();
		this.assister.Reset();
		this.pinVictim.Reset();
		this.actor2					= 0;
		this.victim2				= 0;
		this.assistsCount			= 0;
		this.actorWeaponId			= WEPID_NONE;
		this.actorDamage			= 0;
		this.assisterDamage			= 0;
		this.assisterWeaponId		= WEPID_NONE;
		this.assisterShots			= 0;
		this.damage					= 0;
		this.chipDamage			 	= 0;
		this.shots					= 0;
		this.shoveCount			 	= 0;
		this.amount				 	= 0;
		this.streak				 	= 0;
		this.zombieClass			= 0;
		this.reason				 	= 0;
		this.withShove				= false;
		this.indirect				= false;
		this.forced				 	= false;
		this.wasCarried			 	= false;
		this.crown					= false;
		this.startled				= false;
		this.reportedHigh			= false;
		this.incapped				= false;
		this.ledgeHang				= false;
		this.fatalFall				= false;
		this.deadlySlam			 	= false;
		this.wouldQualifyAtBaseline	= false;
		this.perfect				= false;
		this.headshot				= false;
		this.sniper					= false;
		this.grenadeLauncher		= false;
		this.calculatedDamage		= 0.0;
		this.timeA					= 0.0;
		this.timeB					= 0.0;
		this.height					= 0.0;
		this.distance				= 0.0;
		this.maxVelocity			= 0.0;
		this.createdAt				= 0.0;

		for (int i = 0; i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
		{
			this.assists[i].Reset();
			this.assistDamage[i] = 0;
			this.assistWeaponId[i] = WEPID_NONE;
			this.assistShots[i] = 0;
		}
	}
}

enum struct L4D2SkillSummaryEntryData
{
	bool active;
	L4DTeam team;
	L4D2PlayerRef player;
	int counts[L4D2Skill_Size];

	void Reset()
	{
		this.active = false;
		this.team = L4DTeam_Unassigned;
		this.player.Reset();

		for (int i = 0; i < view_as<int>(L4D2Skill_Size); i++)
		{
			this.counts[i] = 0;
		}
	}
}

enum struct L4D2SkillSummaryData
{
	int id;
	char map[64];
	PlayerSkillsGameMode baseMode;
	int configuredSurvivorLimit;
	int configuredPlayerZombieLimit;
	int siPoolMask;
	int enabledSiClassCount;
	int versusTeamSize;
	PlayerSkillsVersusContextType versusContext;
	PlayerSkillsRoundStartSignalType roundStartSignal;
	PlayerSkillsRoundEndSignalType roundEndSignal;
	PlayerSkillsRoundLiveSignalType roundLiveSignal;
	int totalEvents;
	float createdAt;
	L4D2SkillSummaryEntryData entries[L4D2_SKILLS_MAX_SUMMARY_ENTRIES];

	void Reset()
	{
		this.id = 0;
		this.map[0] = '\0';
		this.baseMode = PlayerSkillsGameMode_Unknown;
		this.configuredSurvivorLimit = 0;
		this.configuredPlayerZombieLimit = 0;
		this.siPoolMask = view_as<int>(PlayerSkillsSiPool_None);
		this.enabledSiClassCount = 0;
		this.versusTeamSize = 0;
		this.versusContext = PlayerSkillsVersusContext_None;
		this.roundStartSignal = PlayerSkillsRoundStartSignal_None;
		this.roundEndSignal = PlayerSkillsRoundEndSignal_None;
		this.roundLiveSignal = PlayerSkillsRoundLiveSignal_None;
		this.totalEvents = 0;
		this.createdAt = 0.0;

		for (int i = 0; i < L4D2_SKILLS_MAX_SUMMARY_ENTRIES; i++)
		{
			this.entries[i].Reset();
		}
	}
}
