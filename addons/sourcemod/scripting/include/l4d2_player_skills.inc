#if defined _l4d2_player_skills_included
	#endinput
#endif
#define _l4d2_player_skills_included

/**
 * The type of skill event detected by l4d2_player_skills.
 */
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
	L4D2Skill_ChargerBowl,
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
	L4D2Skill_JockeySkeet,
	L4D2Skill_WitchCrown,

	L4D2Skill_Size
}

/**
 * String names for L4D2SkillType values.
 * The array index matches the numeric enum value.
 */
stock char g_sL4D2SkillType[L4D2Skill_Size][] =
{
	"None",
	"HunterSkeet",
	"HunterSkeetMelee",
	"HunterDeadstop",
	"BoomerPop",
	"ChargerLevel",
	"TankDead",
	"WitchDead",
	"WitchIncap",
	"SmokerTongueCut",
	"SmokerSelfClear",
	"TankRockSkeet",
	"TankRockHit",
	"HunterHighPounce",
	"JockeyHighPounce",
	"ChargerInstaKill",
	"ChargerDeathSetup",
	"ChargerBowl",
	"SpecialPinClear",
	"BoomerVomitLanded",
	"BunnyHopStreak",
	"CarAlarmTriggered",
	"SmokerKill",
	"BoomerKill",
	"HunterKill",
	"SpitterKill",
	"JockeyKill",
	"ChargerKill",
	"JockeyJumpStop",
	"JockeySkeetMelee",
	"JockeySkeet",
	"WitchCrown"
};

/**
 * The type of boss damage session tracked by l4d2_player_skills.
 */
enum L4D2BossType
{
	L4D2Boss_None = 0,
	L4D2Boss_Tank,
	L4D2Boss_Witch
}

/**
 * Player reference slot inside a boss session payload.
 */
enum L4D2BossPlayerSlot
{
	L4D2BossPlayer_Owner = 0,
	L4D2BossPlayer_PendingOwner
}

/**
 * Player reference slot inside a skill event payload.
 */
enum L4D2SkillPlayerSlot
{
	L4D2SkillPlayer_Actor = 0,
	L4D2SkillPlayer_Victim,
	L4D2SkillPlayer_Assister,
	L4D2SkillPlayer_PinVictim
}

/**
 * Semantic origin of assist data inside a skill event payload.
 */
enum L4D2SkillAssistScope
{
	L4D2SkillAssistScope_None = 0,
	L4D2SkillAssistScope_LifeKill,
	L4D2SkillAssistScope_SkillWindow
}

/**
 * Semantic origin of damage data inside a skill event payload.
 */
enum L4D2SkillDamageScope
{
	L4D2SkillDamageScope_None = 0,
	L4D2SkillDamageScope_LifeKill,
	L4D2SkillDamageScope_SkillWindow
}

/**
 * Integer fields available through PlayerSkills_GetEventInt().
 */
enum L4D2SkillIntField
{
	L4D2SkillInt_Damage = 0,
	L4D2SkillInt_ChipDamage,
	L4D2SkillInt_Shots,
	L4D2SkillInt_ShoveCount,
	L4D2SkillInt_Amount,
	L4D2SkillInt_Streak,
	L4D2SkillInt_ZombieClass,
	L4D2SkillInt_Reason,
	L4D2SkillInt_Actor2,
	L4D2SkillInt_Victim2,
	L4D2SkillInt_Rating
}

/**
 * Float fields available through PlayerSkills_GetEventFloat().
 */
enum L4D2SkillFloatField
{
	L4D2SkillFloat_TimeA = 0,
	L4D2SkillFloat_TimeB,
	L4D2SkillFloat_CalculatedDamage,
	L4D2SkillFloat_Height,
	L4D2SkillFloat_Distance,
	L4D2SkillFloat_MaxVelocity,
	L4D2SkillFloat_CreatedAt
}

/**
 * Boolean fields available through PlayerSkills_GetEventBool().
 */
enum L4D2SkillBoolField
{
	L4D2SkillBool_WithShove = 0,
	L4D2SkillBool_Indirect,
	L4D2SkillBool_Forced,
	L4D2SkillBool_WasCarried,
	L4D2SkillBool_ReportedHigh,
	L4D2SkillBool_Incapped,
	L4D2SkillBool_LedgeHang,
	L4D2SkillBool_FatalFall,
	L4D2SkillBool_DeadlySlam,
	L4D2SkillBool_WouldQualifyAtBaseline, // deprecated, always false
	L4D2SkillBool_Crown,
	L4D2SkillBool_Startled,
	L4D2SkillBool_Perfect,
	L4D2SkillBool_Headshot,
	L4D2SkillBool_Sniper,
	L4D2SkillBool_GrenadeLauncher
}

/**
 * Reason used when a car alarm is triggered.
 */
enum L4D2CarAlarmReason
{
	L4D2CarAlarm_Unknown = 0,
	L4D2CarAlarm_Hit,
	L4D2CarAlarm_Touched,
	L4D2CarAlarm_Explosion,
	L4D2CarAlarm_Boomer
}

/**
 * @brief Called whenever a skill event is detected.
 * @remarks This is the main modern forward exposed by l4d2_player_skills.
 * @remarks Consumers should use the provided natives to inspect the event payload.
 *
 * @param eventId        Unique runtime identifier for the detected skill event.
 * @param type           The detected skill type.
 *
 * @return               Plugin_Continue to allow normal processing and announcing.
 *                       Plugin_Handled or higher to suppress built-in announce flow.
 */
forward Action PlayerSkills_OnSkillDetected(int eventId, L4D2SkillType type);

/**
 * @brief Called after a skill event has been announced by l4d2_player_skills.
 *
 * @param eventId        Unique runtime identifier for the detected skill event.
 * @param type           The announced skill type.
 *
 * @noreturn
 */
forward void PlayerSkills_OnSkillAnnounced(int eventId, L4D2SkillType type);

/**
 * @brief Called whenever a boss damage session is finalized.
 * @remarks Fires for Tank and Witch summaries before the built-in announcer prints.
 *
 * @param sessionId      Unique runtime identifier for the boss session.
 * @param type           The finalized boss type.
 *
 * @return               Plugin_Continue to allow normal announce flow.
 *                       Plugin_Handled or higher to suppress built-in announce flow.
 */
forward Action PlayerSkills_OnBossDamageFinalized(int sessionId, L4D2BossType type);

/**
 * @brief Called after a boss damage summary has been announced by l4d2_player_skills.
 *
 * @param sessionId      Unique runtime identifier for the boss session.
 * @param type           The announced boss type.
 *
 * @noreturn
 */
forward void PlayerSkills_OnBossDamageAnnounced(int sessionId, L4D2BossType type);

/**
 * @brief Called whenever a round or half summary is finalized.
 * @remarks Fires after the runtime skill/boss state has been frozen into a compact
 *          summary snapshot and before the next round start resets runtime state.
 * @remarks This forward is notification-only; use the summary natives to inspect payload.
 *
 * @param summaryId      Unique runtime identifier for the finalized summary.
 *
 * @noreturn
 */
forward void PlayerSkills_OnSummaryFinalized(int summaryId);

/**
 * @brief Returns whether a skill event identifier currently resolves to a valid event.
 *
 * @param eventId        Runtime skill event identifier.
 *
 * @return               True if the event is still available for inspection, false otherwise.
 */
native bool PlayerSkills_IsEventValid(int eventId);

/**
 * @brief Fills a KeyValues handle with the structured payload of a skill event.
 * @remarks The native rewinds the handle and writes an "event" section.
 * @remarks The payload includes event metadata, actor data, assists and
 *          a "skill_properties" subsection for context-specific fields.
 *          It includes `assist_scope` and `damage_scope` when applicable.
 *          It does not include boss damage tables.
 *
 * @param eventId        Runtime skill event identifier.
 * @param kv             KeyValues handle to populate.
 *
 * @return               True on success, false if the event or handle is invalid.
 */
native bool PlayerSkills_FillEventKeyValues(int eventId, Handle kv);

/**
 * @brief Returns the type of a skill event.
 *
 * @param eventId        Runtime skill event identifier.
 *
 * @return               A value from L4D2SkillType.
 */
native int PlayerSkills_GetEventType(int eventId);

/**
 * @brief Reads a generic integer field from a skill event.
 *
 * @param eventId        Runtime skill event identifier.
 * @param field          Integer field to retrieve.
 *
 * @return               The field value, or 0 when unavailable.
 */
native int PlayerSkills_GetEventInt(int eventId, L4D2SkillIntField field);

/**
 * @brief Reads a generic float field from a skill event.
 *
 * @param eventId        Runtime skill event identifier.
 * @param field          Float field to retrieve.
 *
 * @return               The field value, or 0.0 when unavailable.
 */
native float PlayerSkills_GetEventFloat(int eventId, L4D2SkillFloatField field);

/**
 * @brief Reads a generic boolean field from a skill event.
 *
 * @param eventId        Runtime skill event identifier.
 * @param field          Boolean field to retrieve.
 *
 * @return               The field value, or false when unavailable.
 */
native bool PlayerSkills_GetEventBool(int eventId, L4D2SkillBoolField field);

/**
 * @brief Returns the current client index for a player slot in an event.
 * @remarks This is a live runtime lookup and may return 0 if the player is no longer online.
 *
 * @param eventId        Runtime skill event identifier.
 * @param slot           Player slot to inspect.
 *
 * @return               Current client index, or 0 when unavailable.
 */
native int PlayerSkills_GetEventClient(int eventId, L4D2SkillPlayerSlot slot);

/**
 * @brief Returns the captured userid for a player slot in an event.
 *
 * @param eventId        Runtime skill event identifier.
 * @param slot           Player slot to inspect.
 *
 * @return               Captured userid, or 0 when unavailable.
 */
native int PlayerSkills_GetEventUserId(int eventId, L4D2SkillPlayerSlot slot);

/**
 * @brief Returns the captured Steam account id for a player slot in an event.
 * @remarks Bots generally return 0.
 *
 * @param eventId        Runtime skill event identifier.
 * @param slot           Player slot to inspect.
 *
 * @return               Captured account id, or 0 when unavailable.
 */
native int PlayerSkills_GetEventAccountId(int eventId, L4D2SkillPlayerSlot slot);

/**
 * @brief Returns whether the captured player slot belongs to a bot.
 *
 * @param eventId        Runtime skill event identifier.
 * @param slot           Player slot to inspect.
 *
 * @return               True if the captured player is a bot.
 */
native bool PlayerSkills_IsEventPlayerBot(int eventId, L4D2SkillPlayerSlot slot);

/**
 * @brief Copies the captured player name for a slot in an event.
 *
 * @param eventId        Runtime skill event identifier.
 * @param slot           Player slot to inspect.
 * @param buffer         Output buffer.
 * @param maxlen         Maximum size of the output buffer.
 *
 * @noreturn
 */
native void PlayerSkills_GetEventPlayerName(int eventId, L4D2SkillPlayerSlot slot, char[] buffer, int maxlen);

/**
 * @brief Copies the captured auth string for a slot in an event.
 * @remarks Bots typically resolve to "BOT".
 *
 * @param eventId        Runtime skill event identifier.
 * @param slot           Player slot to inspect.
 * @param buffer         Output buffer.
 * @param maxlen         Maximum size of the output buffer.
 *
 * @noreturn
 */
native void PlayerSkills_GetEventPlayerAuth(int eventId, L4D2SkillPlayerSlot slot, char[] buffer, int maxlen);

/**
 * @brief Returns how many assists are captured in a skill event.
 *
 * @param eventId        Runtime skill event identifier.
 *
 * @return               Assist count, or 0 when unavailable.
 */
native int PlayerSkills_GetEventAssistsCount(int eventId);

/**
 * @brief Returns the semantic source of assist data in a skill event.
 *
 * @param eventId        Runtime skill event identifier.
 *
 * @return               A value from L4D2SkillAssistScope.
 */
native int PlayerSkills_GetEventAssistScope(int eventId);

/**
 * @brief Returns the semantic source of damage data in a skill event.
 *
 * @param eventId        Runtime skill event identifier.
 *
 * @return               A value from L4D2SkillDamageScope.
 */
native int PlayerSkills_GetEventDamageScope(int eventId);

/**
 * @brief Returns the captured userid for one assist entry.
 *
 * @param eventId        Runtime skill event identifier.
 * @param assistIndex    Zero-based assist index.
 *
 * @return               Captured userid, or 0 when unavailable.
 */
native int PlayerSkills_GetEventAssistUserId(int eventId, int assistIndex);

/**
 * @brief Returns the captured Steam account id for one assist entry.
 * @remarks Bots generally return 0.
 *
 * @param eventId        Runtime skill event identifier.
 * @param assistIndex    Zero-based assist index.
 *
 * @return               Captured account id, or 0 when unavailable.
 */
native int PlayerSkills_GetEventAssistAccountId(int eventId, int assistIndex);

/**
 * @brief Returns whether one assist entry belongs to a bot.
 *
 * @param eventId        Runtime skill event identifier.
 * @param assistIndex    Zero-based assist index.
 *
 * @return               True if the captured assist player is a bot.
 */
native bool PlayerSkills_IsEventAssistBot(int eventId, int assistIndex);

/**
 * @brief Copies the captured player name for one assist entry.
 *
 * @param eventId        Runtime skill event identifier.
 * @param assistIndex    Zero-based assist index.
 * @param buffer         Output buffer.
 * @param maxlen         Maximum size of the output buffer.
 *
 * @noreturn
 */
native void PlayerSkills_GetEventAssistName(int eventId, int assistIndex, char[] buffer, int maxlen);

/**
 * @brief Returns the captured damage for one assist entry.
 *
 * @param eventId        Runtime skill event identifier.
 * @param assistIndex    Zero-based assist index.
 *
 * @return               Assist damage, or 0 when unavailable.
 */
native int PlayerSkills_GetEventAssistDamage(int eventId, int assistIndex);

/**
 * @brief Returns the captured shots for one assist entry.
 *
 * @param eventId        Runtime skill event identifier.
 * @param assistIndex    Zero-based assist index.
 *
 * @return               Assist shots, or 0 when unavailable.
 */
native int PlayerSkills_GetEventAssistShots(int eventId, int assistIndex);

/**
 * @brief Returns the captured weapon id for one assist entry.
 *
 * @param eventId        Runtime skill event identifier.
 * @param assistIndex    Zero-based assist index.
 *
 * @return               Weapon id, or WEPID_NONE/0 when unavailable.
 */
native int PlayerSkills_GetEventAssistWeaponId(int eventId, int assistIndex);

/**
 * @brief Returns the type of a boss session.
 *
 * @param sessionId      Runtime boss session identifier.
 *
 * @return               A value from L4D2BossType.
 */
native int PlayerSkills_GetBossType(int sessionId);

/**
 * @brief Returns the current client index for a player slot in a boss session.
 * @remarks This is a live runtime lookup and may return 0 if the player is no longer online.
 * @remarks The pending owner slot is primarily meaningful for Tanks during director offer/transfer flow.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param slot           Boss player slot to inspect.
 *
 * @return               Current client index, or 0 when unavailable.
 */
native int PlayerSkills_GetBossClient(int sessionId, L4D2BossPlayerSlot slot);

/**
 * @brief Returns the captured userid for a player slot in a boss session.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param slot           Boss player slot to inspect.
 *
 * @return               Captured userid, or 0 when unavailable.
 */
native int PlayerSkills_GetBossUserId(int sessionId, L4D2BossPlayerSlot slot);

/**
 * @brief Returns the captured Steam account id for a player slot in a boss session.
 * @remarks Bots generally return 0.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param slot           Boss player slot to inspect.
 *
 * @return               Captured account id, or 0 when unavailable.
 */
native int PlayerSkills_GetBossAccountId(int sessionId, L4D2BossPlayerSlot slot);

/**
 * @brief Returns whether the captured boss player slot belongs to a bot.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param slot           Boss player slot to inspect.
 *
 * @return               True if the captured player is a bot.
 */
native bool PlayerSkills_IsBossPlayerBot(int sessionId, L4D2BossPlayerSlot slot);

/**
 * @brief Copies the captured player name for a boss session slot.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param slot           Boss player slot to inspect.
 * @param buffer         Output buffer.
 * @param maxlen         Maximum size of the output buffer.
 *
 * @noreturn
 */
native void PlayerSkills_GetBossPlayerName(int sessionId, L4D2BossPlayerSlot slot, char[] buffer, int maxlen);

/**
 * @brief Copies the captured auth string for a boss session slot.
 * @remarks Bots typically resolve to "BOT".
 *
 * @param sessionId      Runtime boss session identifier.
 * @param slot           Boss player slot to inspect.
 * @param buffer         Output buffer.
 * @param maxlen         Maximum size of the output buffer.
 *
 * @noreturn
 */
native void PlayerSkills_GetBossPlayerAuth(int sessionId, L4D2BossPlayerSlot slot, char[] buffer, int maxlen);

/**
 * @brief Returns the configured maximum health for a boss session.
 *
 * @param sessionId      Runtime boss session identifier.
 *
 * @return               Maximum health, or 0 when unavailable.
 */
native int PlayerSkills_GetBossMaxHealth(int sessionId);

/**
 * @brief Returns the last tracked health for a boss session.
 * @remarks For escaped or in-progress bosses this is the most recent remaining health snapshot.
 *
 * @param sessionId      Runtime boss session identifier.
 *
 * @return               Last tracked health, or 0 when unavailable.
 */
native int PlayerSkills_GetBossLastHealth(int sessionId);

/**
 * @brief Returns total accumulated survivor damage in a boss session.
 *
 * @param sessionId      Runtime boss session identifier.
 *
 * @return               Total tracked damage, or 0 when unavailable.
 */
native int PlayerSkills_GetBossTotalDamage(int sessionId);

/**
 * @brief Returns whether a boss session is currently in stasis.
 * @remarks This is primarily meaningful for Tanks during control transfer flow.
 *
 * @param sessionId      Runtime boss session identifier.
 *
 * @return               True if the boss is currently marked as in stasis.
 */
native bool PlayerSkills_IsBossInStasis(int sessionId);

/**
 * @brief Returns the amount of active damage entries in a boss session.
 *
 * @param sessionId      Runtime boss session identifier.
 *
 * @return               Number of active damage entries, or 0 when unavailable.
 */
native int PlayerSkills_GetBossDamageEntryCount(int sessionId);

/**
 * @brief Returns the current client index for a boss damage entry.
 * @remarks This is a live runtime lookup and may return 0 if the player is no longer online.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param entry          Zero-based damage entry index.
 *
 * @return               Current client index, or 0 when unavailable.
 */
native int PlayerSkills_GetBossDamageEntryClient(int sessionId, int entry);

/**
 * @brief Returns the captured userid for a boss damage entry.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param entry          Zero-based damage entry index.
 *
 * @return               Captured userid, or 0 when unavailable.
 */
native int PlayerSkills_GetBossDamageEntryUserId(int sessionId, int entry);

/**
 * @brief Returns the captured Steam account id for a boss damage entry.
 * @remarks Bots generally return 0.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param entry          Zero-based damage entry index.
 *
 * @return               Captured account id, or 0 when unavailable.
 */
native int PlayerSkills_GetBossDamageEntryAccountId(int sessionId, int entry);

/**
 * @brief Returns the accumulated damage for a boss damage entry.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param entry          Zero-based damage entry index.
 *
 * @return               Accumulated damage, or 0 when unavailable.
 */
native int PlayerSkills_GetBossDamageEntryDamage(int sessionId, int entry);

/**
 * @brief Returns the accumulated shot count for a boss damage entry.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param entry          Zero-based damage entry index.
 *
 * @return               Accumulated shot count, or 0 when unavailable.
 */
native int PlayerSkills_GetBossDamageEntryShots(int sessionId, int entry);

/**
 * @brief Returns whether a boss damage entry belongs to a bot.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param entry          Zero-based damage entry index.
 *
 * @return               True if the captured player is a bot.
 */
native bool PlayerSkills_IsBossDamageEntryBot(int sessionId, int entry);

/**
 * @brief Copies the captured player name for a boss damage entry.
 *
 * @param sessionId      Runtime boss session identifier.
 * @param entry          Zero-based damage entry index.
 * @param buffer         Output buffer.
 * @param maxlen         Maximum size of the output buffer.
 *
 * @noreturn
 */
native void PlayerSkills_GetBossDamageEntryName(int sessionId, int entry, char[] buffer, int maxlen);

/**
 * @brief Copies the captured auth string for a boss damage entry.
 * @remarks Bots typically resolve to "BOT".
 *
 * @param sessionId      Runtime boss session identifier.
 * @param entry          Zero-based damage entry index.
 * @param buffer         Output buffer.
 * @param maxlen         Maximum size of the output buffer.
 *
 * @noreturn
 */
native void PlayerSkills_GetBossDamageEntryAuth(int sessionId, int entry, char[] buffer, int maxlen);

/**
 * @brief Returns whether a summary identifier currently resolves to a valid snapshot.
 *
 * @param summaryId      Runtime summary identifier.
 *
 * @return               True if the summary is still available, false otherwise.
 */
native bool PlayerSkills_IsSummaryValid(int summaryId);

/**
 * @brief Fills a KeyValues handle with the structured payload of a finalized summary.
 * @remarks The native rewinds the handle and writes a "summary" section.
 * @remarks The payload includes mode context, map name, total event count and
 *          aggregated per-actor skill counts. Infected bots are compacted into
 *          a single IA entry per team.
 *
 * @param summaryId      Runtime summary identifier.
 * @param kv             KeyValues handle to populate.
 *
 * @return               True on success, false if the summary or handle is invalid.
 */
native bool PlayerSkills_FillSummaryKeyValues(int summaryId, Handle kv);

public SharedPlugin __pl_l4d2_player_skills =
{
	name = "l4d2_player_skills",
	file = "l4d2_player_skills.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_player_skills_SetNTVOptional()
{
	MarkNativeAsOptional("PlayerSkills_IsEventValid");
	MarkNativeAsOptional("PlayerSkills_FillEventKeyValues");
	MarkNativeAsOptional("PlayerSkills_GetEventType");
	MarkNativeAsOptional("PlayerSkills_GetEventInt");
	MarkNativeAsOptional("PlayerSkills_GetEventFloat");
	MarkNativeAsOptional("PlayerSkills_GetEventBool");
	MarkNativeAsOptional("PlayerSkills_GetEventClient");
	MarkNativeAsOptional("PlayerSkills_GetEventUserId");
	MarkNativeAsOptional("PlayerSkills_GetEventAccountId");
	MarkNativeAsOptional("PlayerSkills_IsEventPlayerBot");
	MarkNativeAsOptional("PlayerSkills_GetEventPlayerName");
	MarkNativeAsOptional("PlayerSkills_GetEventPlayerAuth");
	MarkNativeAsOptional("PlayerSkills_GetBossType");
	MarkNativeAsOptional("PlayerSkills_GetBossClient");
	MarkNativeAsOptional("PlayerSkills_GetBossUserId");
	MarkNativeAsOptional("PlayerSkills_GetBossAccountId");
	MarkNativeAsOptional("PlayerSkills_IsBossPlayerBot");
	MarkNativeAsOptional("PlayerSkills_GetBossPlayerName");
	MarkNativeAsOptional("PlayerSkills_GetBossPlayerAuth");
	MarkNativeAsOptional("PlayerSkills_GetBossMaxHealth");
	MarkNativeAsOptional("PlayerSkills_GetBossLastHealth");
	MarkNativeAsOptional("PlayerSkills_GetBossTotalDamage");
	MarkNativeAsOptional("PlayerSkills_IsBossInStasis");
	MarkNativeAsOptional("PlayerSkills_GetBossDamageEntryCount");
	MarkNativeAsOptional("PlayerSkills_GetBossDamageEntryClient");
	MarkNativeAsOptional("PlayerSkills_GetBossDamageEntryUserId");
	MarkNativeAsOptional("PlayerSkills_GetBossDamageEntryAccountId");
	MarkNativeAsOptional("PlayerSkills_GetBossDamageEntryDamage");
	MarkNativeAsOptional("PlayerSkills_GetBossDamageEntryShots");
	MarkNativeAsOptional("PlayerSkills_IsBossDamageEntryBot");
	MarkNativeAsOptional("PlayerSkills_GetBossDamageEntryName");
	MarkNativeAsOptional("PlayerSkills_GetBossDamageEntryAuth");
	MarkNativeAsOptional("PlayerSkills_IsSummaryValid");
	MarkNativeAsOptional("PlayerSkills_FillSummaryKeyValues");
}
#endif
