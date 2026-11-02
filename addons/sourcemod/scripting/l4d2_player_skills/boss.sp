#if defined _l4d2_player_skills_boss_included
	#endinput
#endif
#define _l4d2_player_skills_boss_included

// Boss session coordinator. This file keeps Tank/Witch lifecycle, damage-session
// finalization, and event emission for boss-related skills and summaries.

bool g_bBossTankDamageHooked[MAXPLAYERS + 1];
int g_iBossTankVictimLastHealth[MAXPLAYERS + 1];
int g_iBossTankVictimLastSession[MAXPLAYERS + 1];
int g_iBossTankVictimLastDamage[MAXPLAYERS + 1];
int g_iBossTankVictimLastHitTick[MAXPLAYERS + 1];
bool g_bBossTankVictimLastHitClaw[MAXPLAYERS + 1];
int g_iBossPendingTankTransitionSession = -1;
#define L4D2_SKILLS_TANK_BOT_CONTROL_CONFIRM_TIME 0.10
#define L4D2_SKILLS_TANK_TRIVIAL_BOT_CONTROL_TIME 1.0
#define L4D2_SKILLS_TANK_TRANSITION_FLUSH_TIME 0.50

#include "l4d2_player_skills/boss/queries.sp"
#include "l4d2_player_skills/boss/tank.sp"
#include "l4d2_player_skills/boss/witch.sp"

// Initialization and reset.
void Boss_Init()
{
	Boss_ResetAll();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			Boss_HookTankDamageClient(client);
		}
	}
}

void Boss_ResetAll()
{
	Boss_ClearPendingTankTransition();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			SDKUnhook(client, SDKHook_OnTakeDamage, Boss_OnClientTakeDamage);
			SDKUnhook(client, SDKHook_OnTakeDamagePost, Boss_OnTankTakeDamagePost);
		}

		g_bBossTankDamageHooked[client] = false;
		g_iBossTankVictimLastHealth[client] = 0;
		g_iBossTankVictimLastSession[client] = 0;
		g_iBossTankVictimLastDamage[client] = 0;
		g_iBossTankVictimLastHitTick[client] = 0;
		g_bBossTankVictimLastHitClaw[client] = false;
	}

	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		L4D2BossSession(index).Reset();
	}
}

void Boss_Shutdown()
{
	Boss_ClearPendingTankTransition();

	for (int client = 1; client <= MaxClients; client++)
	{
		Boss_UnhookTankDamageClient(client);
	}
}

// Client lifecycle and control-transfer flow.
void Boss_OnClientPutInServer(int client)
{
	Boss_HookTankDamageClient(client);
}

	void Boss_OnClientDisconnect(int client)
	{
		Boss_UnhookTankDamageClient(client);

	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0 || g_BossSessions[index].state != L4D2BossState_Active)
		{
			continue;
		}

			if (g_BossSessions[index].userid == GetClientUserId(client))
			{
				if (g_BossSessions[index].type == L4D2Boss_Tank)
				{
					L4D2BossSession(index).CloseActiveTankControl(GetGameTime());
					g_BossSessions[index].tank.pendingBotControl = true;
					g_BossSessions[index].tank.pendingBotUserid = 0;
					g_BossSessions[index].tank.pendingBotStartedAt = GetGameTime();
					g_BossSessions[index].entity = -1;
					g_BossSessions[index].entRef = INVALID_ENT_REFERENCE;
				}

				g_BossSessions[index].owner.Capture(client);
				Skills_Debug(PlayerSkillsDebug_Boss, "Boss owner disconnected. session=%d userid=%d", g_BossSessions[index].id, g_BossSessions[index].userid);
			}
		}
	}

// Entity lifecycle and round flow.
void Boss_OnRoundStart()
{
	Boss_ResetAll();
}

void Boss_OnRoundEnd()
{
	int epoch = g_Runtime.lifecycleEpoch;
	if (Boss_IsValidPendingTankTransitionSession(g_iBossPendingTankTransitionSession))
	{
		int targetSessionIndex = Boss_FindSingleActiveTankSession();
		if (targetSessionIndex != -1)
		{
			Boss_MaybeMergePendingTankTransitionIntoSession(targetSessionIndex);
		}
	}
	if (epoch != g_Runtime.lifecycleEpoch)
	{
		return;
	}

	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0 || g_BossSessions[index].state != L4D2BossState_Active)
		{
			continue;
		}

		g_BossSessions[index].state = L4D2BossState_Escaped;
		if (g_BossSessions[index].type == L4D2Boss_Tank)
		{
			g_BossSessions[index].tank.endReason = Boss_DidRoundEndInWipe()
				? L4D2TankSessionEnd_SurvivorsWiped
				: L4D2TankSessionEnd_SurvivorsEscaped;
		}

		if (g_BossSessions[index].type == L4D2Boss_Tank)
		{
			int tankClient = GetClientOfUserId(g_BossSessions[index].userid);
			if (IsValidTank(tankClient))
			{
				g_BossSessions[index].lastHealth = GetClientHealth(tankClient);
				if (IsFakeClient(tankClient))
				{
					if (g_BossSessions[index].tank.pendingBotControl
						&& g_BossSessions[index].tank.pendingBotUserid == GetClientUserId(tankClient))
					{
						Boss_ForcePendingTankBotControlNow(index, tankClient);
					}
					else
					{
						L4D2BossSession(index).UpdateOwnerSnapshot(tankClient);
						int activeControlIndex = g_BossSessions[index].tank.activeControlIndex;
						bool hasMatchingActiveBotControl = activeControlIndex >= 0
							&& activeControlIndex < L4D2_SKILLS_MAX_TANK_CONTROLS
							&& g_BossSessions[index].tank.controls[activeControlIndex].active
							&& g_BossSessions[index].tank.controls[activeControlIndex].player.IsSamePersistentPlayer(tankClient);
						if (!hasMatchingActiveBotControl)
						{
							L4D2BossSession(index).OpenTankControl(tankClient, g_BossSessions[index].closedAt > 0.0 ? g_BossSessions[index].closedAt : GetGameTime());
						}
					}
				}
				else
				{
					L4D2BossSession(index).RefreshOwner(tankClient);
				}
			}
		}

		if (g_BossSessions[index].type == L4D2Boss_Witch)
		{
			int witch = EntRefToEntIndex(g_BossSessions[index].entRef);
			if (IsWitchEntity(witch))
			{
				g_BossSessions[index].lastHealth = GetEntProp(witch, Prop_Data, "m_iHealth");
			}
		}

		Boss_FinalizeSession(index);
		if (epoch != g_Runtime.lifecycleEpoch)
		{
			return;
		}
	}

	Boss_FlushPendingTankTransition();
}

// Event-driven Tank and Witch tracking.
void Boss_EventPlayerIncapacitatedStart(Event event)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (Skills_IsEnabled()
		&& IsValidSurvivor(victim)
		&& IsValidTank(attacker))
	{
		int sessionIndex = Boss_EnsureTankSession(attacker);
		if (sessionIndex != -1)
		{
			Boss_PromotePendingTankBotControlForActivity(sessionIndex, attacker, "incap");

			char weapon[64];
			event.GetString("weapon", weapon, sizeof(weapon));
			bool isClaw = StrEqual(weapon, "tank_claw");
			int committedDamage = g_iBossTankVictimLastHealth[victim];
			if (committedDamage < 0)
			{
				committedDamage = 0;
			}

			if (g_iBossTankVictimLastSession[victim] == g_BossSessions[sessionIndex].id
				&& g_iBossTankVictimLastHitTick[victim] == GetGameTickCount()
				&& g_bBossTankVictimLastHitClaw[victim] == isClaw)
			{
				committedDamage -= g_iBossTankVictimLastDamage[victim];
				if (committedDamage < 0)
				{
					committedDamage = 0;
				}
			}

			if (StrEqual(weapon, "tank_claw"))
			{
				g_BossSessions[sessionIndex].tank.punchDamage += committedDamage;
			}
			else if (StrEqual(weapon, "tank_rock"))
			{
				// Rocks stay represented by tank_control / rock skills only.
			}
			else
			{
				g_BossSessions[sessionIndex].tank.hittableDamage += committedDamage;
			}

			g_BossSessions[sessionIndex].tank.incaps++;
		}
	}

	if (!Skills_IsEnabled() || !g_bWitchPrintOnIncap)
	{
		return;
	}

	int witch = event.GetInt("attackerentid");

	if (!IsValidSurvivor(victim) || !IsWitchEntity(witch))
	{
		return;
	}

	int sessionIndex = Boss_FindWitchSessionByEntity(witch);
	if (sessionIndex == -1)
	{
		sessionIndex = Boss_EnsureWitchSession(witch);
	}

	if (sessionIndex == -1)
	{
		return;
	}

	if (IsWitchEntity(witch))
	{
		g_BossSessions[sessionIndex].lastHealth = GetEntProp(witch, Prop_Data, "m_iHealth");
	}

	g_BossSessions[sessionIndex].witch.incapVictim.Capture(victim);

	// A Witch that already incapped a survivor stops generating follow-up skills.
	// The remaining-health print becomes the terminal announce for that lifecycle.
	g_BossSessions[sessionIndex].printed = true;
	g_BossSessions[sessionIndex].state = L4D2BossState_Printed;

	Boss_CreateWitchIncapEvent(sessionIndex, witch, victim);
	Boss_AnnounceWitchRemainingHealth(witch);
}

// Session lookup and allocation helpers.
int Boss_FindDamageEntryByPersistentRef(int sessionIndex, L4D2PlayerRef player)
{
	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active)
		{
			continue;
		}

		if (g_BossDamage[sessionIndex][entry].player.IsSamePersistentRef(player))
		{
			return entry;
		}
	}

	return -1;
}

int Boss_FindFreeDamageEntrySlot(int sessionIndex)
{
	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active)
		{
			return entry;
		}
	}

	return -1;
}

int Boss_FindOrCreateDamageEntry(int sessionIndex, int attacker)
{
	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active)
		{
			continue;
		}

		if (g_BossDamage[sessionIndex][entry].player.IsSamePersistentPlayer(attacker))
		{
			return entry;
		}
	}

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active)
		{
			return entry;
		}
	}

	return -1;
}

void Boss_ConsolidateDamageEntries(int sessionIndex)
{
	for (int baseEntry = 0; baseEntry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; baseEntry++)
	{
		if (!g_BossDamage[sessionIndex][baseEntry].active || g_BossDamage[sessionIndex][baseEntry].damage <= 0)
		{
			continue;
		}

		for (int mergeEntry = baseEntry + 1; mergeEntry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; mergeEntry++)
		{
			if (!g_BossDamage[sessionIndex][mergeEntry].active || g_BossDamage[sessionIndex][mergeEntry].damage <= 0)
			{
				continue;
			}

			if (!g_BossDamage[sessionIndex][baseEntry].player.IsSamePersistentRef(g_BossDamage[sessionIndex][mergeEntry].player))
			{
				continue;
			}

			g_BossDamage[sessionIndex][baseEntry].damage += g_BossDamage[sessionIndex][mergeEntry].damage;
			g_BossDamage[sessionIndex][baseEntry].shots += g_BossDamage[sessionIndex][mergeEntry].shots;
			g_BossDamage[sessionIndex][mergeEntry].Reset();
		}
	}
}

// Session event creation and counters.
bool Boss_IsFinalizationContextCurrent(int sessionIndex, int sessionId, int epoch)
{
	return epoch == g_Runtime.lifecycleEpoch
		&& sessionIndex >= 0
		&& sessionIndex < L4D2_SKILLS_MAX_BOSSES
		&& g_BossSessions[sessionIndex].id == sessionId;
}

void Boss_FinalizeSessionImmediate(int sessionIndex, bool allowAnnounce = true)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| g_BossSessions[sessionIndex].id == 0 || g_BossSessions[sessionIndex].finalized)
	{
		return;
	}

	int sessionId = g_BossSessions[sessionIndex].id;
	int epoch = g_Runtime.lifecycleEpoch;
	// Fence recursive finalization before either synchronous public forward.
	g_BossSessions[sessionIndex].finalized = true;
	if (g_BossSessions[sessionIndex].type == L4D2Boss_Witch
		&& g_BossSessions[sessionIndex].state == L4D2BossState_Escaped)
	{
		allowAnnounce = false;
	}

	if (g_BossSessions[sessionIndex].type == L4D2Boss_Tank
		&& g_BossSessions[sessionIndex].tank.endReason != L4D2TankSessionEnd_None)
	{
		API_FireTankSessionClosed(g_BossSessions[sessionIndex].id, g_BossSessions[sessionIndex].tank.endReason);
		if (!Boss_IsFinalizationContextCurrent(sessionIndex, sessionId, epoch))
		{
			return;
		}
	}

	Boss_ConsolidateDamageEntries(sessionIndex);

	if (g_BossSessions[sessionIndex].type == L4D2Boss_Tank)
	{
		int activeDamageEntries = 0;
		for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
		{
			if (!g_BossDamage[sessionIndex][entry].active || g_BossDamage[sessionIndex][entry].damage <= 0)
			{
				continue;
			}

			activeDamageEntries++;
			Skills_Debug(PlayerSkillsDebug_Boss,
				"Tank finalize damage entry. session=%d entry=%d userid=%d name=%s damage=%d shots=%d",
				g_BossSessions[sessionIndex].id,
				entry,
				g_BossDamage[sessionIndex][entry].player.userid,
				g_BossDamage[sessionIndex][entry].player.name,
				g_BossDamage[sessionIndex][entry].damage,
				g_BossDamage[sessionIndex][entry].shots);
		}

		Skills_Debug(PlayerSkillsDebug_Boss,
			"Tank finalize summary. session=%d state=%d entity=%d lastHealth=%d total=%d entries=%d other=%d allowAnnounce=%d printed=%d",
			g_BossSessions[sessionIndex].id,
			g_BossSessions[sessionIndex].state,
			g_BossSessions[sessionIndex].entity,
			g_BossSessions[sessionIndex].lastHealth,
			g_BossSessions[sessionIndex].totalDamage,
			activeDamageEntries,
			Boss_GetOtherDamage(sessionIndex),
			allowAnnounce,
			g_BossSessions[sessionIndex].printed);
	}

	if (g_BossSessions[sessionIndex].type == L4D2Boss_Witch)
	{
		Skills_Debug(PlayerSkillsDebug_Boss,
			"Witch finalize pending. session=%d entity=%d state=%d lastHealth=%d total=%d harasser_userid=%d harasser_name=%s incap_userid=%d incap_name=%s startled=%d crown=%d",
			g_BossSessions[sessionIndex].id,
			g_BossSessions[sessionIndex].entity,
			g_BossSessions[sessionIndex].state,
			g_BossSessions[sessionIndex].lastHealth,
			g_BossSessions[sessionIndex].totalDamage,
			g_BossSessions[sessionIndex].witch.harasser.userid,
			g_BossSessions[sessionIndex].witch.harasser.name,
			g_BossSessions[sessionIndex].witch.incapVictim.userid,
			g_BossSessions[sessionIndex].witch.incapVictim.name,
			g_BossSessions[sessionIndex].witch.startled,
			g_BossSessions[sessionIndex].witch.crownDetected);
	}

	Action result = API_FireBossDamageFinalized(g_BossSessions[sessionIndex].id, g_BossSessions[sessionIndex].type);
	if (!Boss_IsFinalizationContextCurrent(sessionIndex, sessionId, epoch))
	{
		return;
	}
	if (allowAnnounce && result < Plugin_Handled && !g_BossSessions[sessionIndex].printed)
	{
		Announce_BossDamage(sessionIndex);
	}
	else if (!g_BossSessions[sessionIndex].printed)
	{
		g_BossSessions[sessionIndex].printed = true;
		g_BossSessions[sessionIndex].state = L4D2BossState_Printed;
	}
}

void Boss_FinalizeSession(int sessionIndex)
	{
		if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
		{
			return;
		}

		if (g_BossSessions[sessionIndex].finalized)
		{
			return;
		}

	if (g_BossSessions[sessionIndex].closedAt <= 0.0)
	{
		g_BossSessions[sessionIndex].closedAt = GetGameTime();
	}

	if (g_BossSessions[sessionIndex].type == L4D2Boss_Tank)
	{
		int pendingTank = GetClientOfUserId(g_BossSessions[sessionIndex].tank.pendingBotUserid);
		if (Boss_TankSessionHasMeaningfulBotActivity(sessionIndex))
		{
			Boss_PromotePendingTankBotControlForActivity(sessionIndex, pendingTank, "finalize");
		}

		L4D2BossSession(sessionIndex).CloseActiveTankControl(g_BossSessions[sessionIndex].closedAt);
		Boss_NormalizeTankControls(sessionIndex);
	}

	if (g_BossSessions[sessionIndex].type == L4D2Boss_Tank)
	{
		int targetSessionIndex = Boss_FindSingleOtherActiveTankSession(sessionIndex);
		if (Skills_HasTankControlEqSubstituteApi()
			&& g_BossSessions[sessionIndex].tank.endReason == L4D2TankSessionEnd_TankDead)
		{
			if (!g_BossSessions[sessionIndex].tank.isSubstitute)
			{
				Boss_QueuePendingTankTransition(sessionIndex);
				if (targetSessionIndex != -1)
				{
					Boss_MaybeMergePendingTankTransitionIntoSession(targetSessionIndex);
				}

				if (g_BossSessions[sessionIndex].finalized)
				{
					return;
				}

				return;
			}

			if (g_iBossPendingTankTransitionSession != -1)
			{
				Boss_MaybeMergePendingTankTransitionIntoSession(sessionIndex);
			}
		}

		if (targetSessionIndex != -1)
		{
			Boss_ClearPendingTankTransition();
			Boss_MergeTankSessionIntoActiveSession(sessionIndex, targetSessionIndex);
			g_BossSessions[sessionIndex].finalized = true;
			g_BossSessions[sessionIndex].printed = true;
			g_BossSessions[sessionIndex].state = L4D2BossState_Printed;
			return;
		}

		if (!Skills_HasTankControlEqSubstituteApi()
			&& Skills_HasTankControlEq()
			&& g_BossSessions[sessionIndex].tank.endReason == L4D2TankSessionEnd_TankDead)
		{
			Boss_QueuePendingTankTransition(sessionIndex);
			return;
		}
	}

	Boss_FinalizeSessionImmediate(sessionIndex);
}

// Witch event helpers.
