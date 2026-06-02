#if defined _l4d2_player_stats_included
	#endinput
#endif
#define _l4d2_player_stats_included

#define LIBRARY_L4D2PLAYERSTATS "l4d2_player_stats"

enum StatsModeProperty
{
	StatsModeProperty_BaseMode = 0,
	StatsModeProperty_HasBosses,
	StatsModeProperty_HasRoundHalves,
	StatsModeProperty_SeriesScope,
	StatsModeProperty_EnabledSiClassCount,
	StatsModeProperty_VersusTeamSize,
	StatsModeProperty_RoundEndSignal,
	StatsModeProperty_RoundStartSignal,
	StatsModeProperty_RestartPolicy
}

enum StatsEndType
{
	StatsEndType_None = 0,
	StatsEndType_Half,
	StatsEndType_Round,
	StatsEndType_Match
}

/**
 * Called when the current round enters live state.
 *
 * This marks the effective start of sensitive progress counting.
 *
 * @param roundId	Current round identifier.
 */
forward void PlayerStats_OnRoundLive(int roundId);

/**
 * Called after the current round snapshot reaches a terminal lifecycle point.
 *
 * `endType` describes whether the terminal point corresponds to a half, a
 * normal round snapshot closure, or a higher-level match closure.
 *
 * @param roundId	Finalized round identifier.
 * @param endType	StatsEndType value.
 * @param endReason	PlayerStats round-end reason id.
 */
forward void PlayerStats_OnRoundEnded(int roundId, StatsEndType endType, int endReason);

/**
 * Called after a survivor slot is substituted by a different human.
 *
 * The provided `substitutionId` remains valid until the fixed-size
 * substitution snapshot buffer overwrites that entry.
 *
 * Return `Plugin_Handled` to stop automatic snapshot rehydration. In that
 * case the incoming player starts with a clean slot unless another plugin
 * explicitly applies a snapshot through a native.
 *
 * @param substitutionId	Stable snapshot identifier in `accountid:timestamp` format.
 * @param roundId			Current round identifier.
 * @param slot				Survivor round slot that was replaced.
 * @param incomingClient	Incoming survivor client that is taking the slot.
 */
forward Action PlayerStats_OnPlayerSubstituted(const char[] substitutionId, int roundId, int slot, int incomingClient);

/**
 * Returns whether the current round snapshot is active.
 *
 * @return			True if a round snapshot is active, otherwise false.
 */
native bool PlayerStats_IsRoundActive();

/**
 * Returns whether the current round snapshot is live.
 *
 * Live means the round has crossed its effective progress-start signal.
 *
 * @return			True if the current round is live, otherwise false.
 */
native bool PlayerStats_IsRoundLive();

/**
 * Returns the identifier of the current round snapshot.
 *
 * Returns `0` when no round snapshot is available.
 *
 * @return			Current round identifier, or `0` if unavailable.
 */
native int PlayerStats_GetRoundId();

/**
 * Returns whether a player slot is valid for the specified round snapshot.
 *
 * @param roundId		Round identifier to validate against.
 * @param slot			Round slot index.
 * @return				True if the slot exists in that round snapshot.
 */
native bool PlayerStats_IsRoundPlayerSlotValid(int roundId, int slot);

/**
 * Returns the current client index bound to a round slot.
 *
 * This native is only meaningful for the currently active round snapshot.
 * Finalized round snapshots do not guarantee a live client binding.
 *
 * @param roundId		Round identifier to resolve against.
 * @param slot			Round slot index.
 * @return				Client index, or `0` if unavailable.
 */
native int PlayerStats_GetRoundPlayerClient(int roundId, int slot);

/**
 * Returns a property of the current mode profile.
 *
 * This exposes the runtime-resolved mode/lifecycle context without requiring
 * consumers to parse the round KeyValues payload.
 *
 * @param property		Property enum from StatsModeProperty.
 * @return				Integer value for the requested property.
 */
native int PlayerStats_GetCurrentModeProperty(StatsModeProperty property);

/**
 * Writes the current round snapshot into a KeyValues handle.
 *
 * The target handle is populated with a `round` root block that includes
 * round context and aggregate totals.
 *
 * @param roundId		Round identifier to export.
 * @param kv			KeyValues handle to populate.
 * @return				True on success, otherwise false.
 */
native bool PlayerStats_FillRoundKeyValues(int roundId, Handle kv);

/**
 * Writes a round player snapshot into a KeyValues handle.
 *
 * The target handle is populated with a `player` root block for the specified
 * round slot, including identity and tracked stat domains.
 *
 * @param roundId		Round identifier to export.
 * @param slot			Round slot index to export.
 * @param kv			KeyValues handle to populate.
 * @return				True on success, otherwise false.
 */
native bool PlayerStats_FillRoundPlayerKeyValues(int roundId, int slot, Handle kv);

/**
 * Applies a stored substitution snapshot to a live round slot.
 *
 * This native is intended for plugins that intercept substitution flow and
 * want to rehydrate a slot manually after returning `Plugin_Handled` from
 * `PlayerStats_OnPlayerSubstituted`.
 *
 * @param substitutionId	Stable substitution snapshot identifier.
 * @param slot				Live round slot to rehydrate.
 * @param client			Incoming survivor client to bind to the slot.
 * @return					True on success, otherwise false.
 */
native bool PlayerStats_ApplySubstitutionSnapshotToSlot(const char[] substitutionId, int slot, int client);

/**
 * Broadcasts the current round summary and round table using the plugin's
 * configured announce/output policy.
 *
 * @noreturn
 */
native void PlayerStats_BroadcastRoundStats();

public SharedPlugin __pl_l4d2_player_stats =
{
	name = LIBRARY_L4D2PLAYERSTATS,
	file = "l4d2_player_stats.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_player_stats_SetNTVOptional()
{
	MarkNativeAsOptional("PlayerStats_IsRoundActive");
	MarkNativeAsOptional("PlayerStats_IsRoundLive");
	MarkNativeAsOptional("PlayerStats_GetRoundId");
	MarkNativeAsOptional("PlayerStats_IsRoundPlayerSlotValid");
	MarkNativeAsOptional("PlayerStats_GetRoundPlayerClient");
	MarkNativeAsOptional("PlayerStats_GetCurrentModeProperty");
	MarkNativeAsOptional("PlayerStats_FillRoundKeyValues");
	MarkNativeAsOptional("PlayerStats_FillRoundPlayerKeyValues");
	MarkNativeAsOptional("PlayerStats_ApplySubstitutionSnapshotToSlot");
	MarkNativeAsOptional("PlayerStats_BroadcastRoundStats");
}
#endif
