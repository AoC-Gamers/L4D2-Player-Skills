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

void Boss_HookTankDamageClient(int client)
{
	if (client <= 0 || client > MaxClients || g_bBossTankDamageHooked[client])
	{
		return;
	}

	SDKHook(client, SDKHook_OnTakeDamagePost, Boss_OnTankTakeDamagePost);
	SDKHook(client, SDKHook_OnTakeDamage, Boss_OnClientTakeDamage);
	g_bBossTankDamageHooked[client] = true;
}

void Boss_UnhookTankDamageClient(int client)
{
	if (client <= 0 || client > MaxClients || !g_bBossTankDamageHooked[client])
	{
		return;
	}

	SDKUnhook(client, SDKHook_OnTakeDamagePost, Boss_OnTankTakeDamagePost);
	SDKUnhook(client, SDKHook_OnTakeDamage, Boss_OnClientTakeDamage);
	g_bBossTankDamageHooked[client] = false;
}

Action Boss_OnClientTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!Skills_IsRoundLive()
		|| !IsValidSurvivor(victim)
		|| !IsValidTank(attacker)
		|| RoundToFloor(damage) <= 0)
	{
		return Plugin_Continue;
	}

	if (IsIncapacitated(victim) || L4D_IsPlayerHangingFromLedge(victim))
	{
		return Plugin_Continue;
	}

	int playerHealth = GetSurvivorPermanentHealth(victim) + GetSurvivorTemporaryHealth(victim);
	if (RoundToFloor(damage) >= playerHealth)
	{
		g_iBossTankVictimLastHealth[victim] = playerHealth;
	}

	return Plugin_Continue;
}

static void Boss_QueuePendingTankBotControlConfirmation(int sessionIndex, int tank)
{
	if (sessionIndex < 0
		|| sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| !IsValidTank(tank)
		|| !IsFakeClient(tank))
	{
		return;
	}

	DataPack pack = new DataPack();
	pack.WriteCell(sessionIndex);
	pack.WriteCell(g_BossSessions[sessionIndex].id);
	pack.WriteCell(GetClientUserId(tank));
	CreateTimer(L4D2_SKILLS_TANK_BOT_CONTROL_CONFIRM_TIME, Boss_TimerConfirmPendingTankBotControl, pack, TIMER_FLAG_NO_MAPCHANGE);
}

static void Boss_ForcePendingTankBotControlNow(int sessionIndex, int tank)
{
	if (sessionIndex < 0
		|| sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| !IsValidTank(tank)
		|| !IsFakeClient(tank)
		|| g_BossSessions[sessionIndex].type != L4D2Boss_Tank)
	{
		return;
	}

	float startedAt = g_BossSessions[sessionIndex].tank.pendingBotStartedAt;
	if (startedAt <= 0.0)
	{
		startedAt = GetGameTime();
	}

	L4D2BossSession(sessionIndex).CancelPendingTankBotControl();
	L4D2BossSession(sessionIndex).UpdateOwnerSnapshot(tank);
	L4D2BossSession(sessionIndex).OpenTankControl(tank, startedAt);
}

static bool Boss_IsTrivialBotTankControl(L4D2TankControlEntry control)
{
	return control.active
		&& control.player.bot
		&& control.controlTime <= L4D2_SKILLS_TANK_TRIVIAL_BOT_CONTROL_TIME
		&& control.rocksThrown == 0
		&& control.rocksHit == 0;
}

static bool Boss_HasFutureHumanTankControl(int sessionIndex, int startIndex)
{
	for (int entry = startIndex; entry < g_BossSessions[sessionIndex].tank.controlCount && entry < L4D2_SKILLS_MAX_TANK_CONTROLS; entry++)
	{
		if (!g_BossSessions[sessionIndex].tank.controls[entry].active
			|| g_BossSessions[sessionIndex].tank.controls[entry].player.bot)
		{
			continue;
		}

		return true;
	}

	return false;
}

static bool Boss_HasFutureSameHumanTankControl(int sessionIndex, int startIndex, L4D2PlayerRef player)
{
	for (int entry = startIndex; entry < g_BossSessions[sessionIndex].tank.controlCount && entry < L4D2_SKILLS_MAX_TANK_CONTROLS; entry++)
	{
		if (!g_BossSessions[sessionIndex].tank.controls[entry].active
			|| g_BossSessions[sessionIndex].tank.controls[entry].player.bot)
		{
			continue;
		}

		if (g_BossSessions[sessionIndex].tank.controls[entry].player.IsSamePersistentRef(player))
		{
			return true;
		}
	}

	return false;
}

static void Boss_NormalizeTankControls(int sessionIndex)
{
	if (sessionIndex < 0
		|| sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| g_BossSessions[sessionIndex].type != L4D2Boss_Tank)
	{
		return;
	}

	L4D2TankControlEntry normalized[L4D2_SKILLS_MAX_TANK_CONTROLS];
	int normalizedCount = 0;

	for (int entry = 0; entry < g_BossSessions[sessionIndex].tank.controlCount && entry < L4D2_SKILLS_MAX_TANK_CONTROLS; entry++)
	{
		L4D2TankControlEntry current;
		current = g_BossSessions[sessionIndex].tank.controls[entry];
		if (!current.active)
		{
			continue;
		}

		if (Boss_IsTrivialBotTankControl(current))
		{
			if (normalizedCount == 0)
			{
				if (Boss_HasFutureHumanTankControl(sessionIndex, entry + 1))
				{
					continue;
				}
			}
			else if (!normalized[normalizedCount - 1].player.bot
				&& Boss_HasFutureSameHumanTankControl(sessionIndex, entry + 1, normalized[normalizedCount - 1].player))
			{
				continue;
			}
		}

		if (normalizedCount > 0
			&& !current.player.bot
			&& !normalized[normalizedCount - 1].player.bot
			&& normalized[normalizedCount - 1].player.IsSamePersistentRef(current.player))
		{
			normalized[normalizedCount - 1].controlTime += current.controlTime;
			normalized[normalizedCount - 1].rocksThrown += current.rocksThrown;
			normalized[normalizedCount - 1].rocksHit += current.rocksHit;
			normalized[normalizedCount - 1].remainingHealth = current.remainingHealth;
			normalized[normalizedCount - 1].endedAt = current.endedAt;
			normalized[normalizedCount - 1].synthetic = normalized[normalizedCount - 1].synthetic || current.synthetic;
			normalized[normalizedCount - 1].overflow = normalized[normalizedCount - 1].overflow || current.overflow;
			normalized[normalizedCount - 1].mergedControls += (current.mergedControls > 0 ? current.mergedControls : 1);
			normalized[normalizedCount - 1].player = current.player;
			continue;
		}

		normalized[normalizedCount] = current;
		if (normalized[normalizedCount].mergedControls <= 0)
		{
			normalized[normalizedCount].mergedControls = 1;
		}
		normalizedCount++;
	}

	for (int entry = 0; entry < L4D2_SKILLS_MAX_TANK_CONTROLS; entry++)
	{
		g_BossSessions[sessionIndex].tank.controls[entry].Reset();
		if (entry < normalizedCount)
		{
			g_BossSessions[sessionIndex].tank.controls[entry] = normalized[entry];
		}
	}

	g_BossSessions[sessionIndex].tank.controlCount = normalizedCount;
	g_BossSessions[sessionIndex].tank.activeControlIndex = -1;
}

void Boss_OnReplaceTank(int tank, int newtank)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int sessionIndex = Boss_FindTankSessionByClient(tank);
	if (sessionIndex == -1)
	{
		sessionIndex = Boss_FindTankSessionByUserid(GetClientUserId(tank));
	}

	if (sessionIndex == -1)
	{
		if (!IsValidTank(newtank))
		{
			return;
		}

		sessionIndex = Boss_EnsureTankSession(newtank);
		if (sessionIndex == -1)
		{
			return;
		}
	}

	if (!IsValidTank(newtank))
	{
		return;
	}

	L4D2BossSession(sessionIndex).CancelPendingTankBotControl();
	L4D2BossSession(sessionIndex).RefreshOwner(newtank);
	if (IsFakeClient(newtank))
	{
		Boss_QueuePendingTankBotControlConfirmation(sessionIndex, newtank);
	}
	g_BossSessions[sessionIndex].lastHealth = GetClientHealth(newtank);
	g_BossSessions[sessionIndex].tank.inStasis = false;
	Skills_Debug(PlayerSkillsDebug_Boss, "Tank control transferred. session=%d old=%d new=%d userid=%d", g_BossSessions[sessionIndex].id, tank, newtank, g_BossSessions[sessionIndex].userid);
}

void Boss_OnTryOfferingTankBot(int tank, bool enterStasis)
{
	if (!Skills_IsEnabled() || !IsValidTank(tank))
	{
		return;
	}

	int sessionIndex = Boss_EnsureTankSession(tank);
	if (sessionIndex == -1)
	{
		return;
	}

	L4D2BossSession(sessionIndex).UpdateOwnerSnapshot(tank);
	g_BossSessions[sessionIndex].tank.inStasis = enterStasis;
	g_BossSessions[sessionIndex].lastHealth = GetClientHealth(tank);

	int pendingPlayer = L4D_GetPendingTankPlayer();

	Skills_Debug(PlayerSkillsDebug_Boss, "TryOfferingTankBot pre. session=%d tank=%d stasis=%d pending=%d", g_BossSessions[sessionIndex].id, tank, enterStasis, pendingPlayer);
}

void Boss_OnTryOfferingTankBotPost(int tank, bool enterStasis)
{
	if (!Skills_IsEnabled() || !IsValidTank(tank))
	{
		return;
	}

	int sessionIndex = Boss_EnsureTankSession(tank);
	if (sessionIndex == -1)
	{
		return;
	}

	L4D2BossSession(sessionIndex).UpdateOwnerSnapshot(tank);
	g_BossSessions[sessionIndex].tank.inStasis = enterStasis;
	g_BossSessions[sessionIndex].lastHealth = GetClientHealth(tank);

	int pendingPlayer = L4D_GetPendingTankPlayer();

	Skills_Debug(PlayerSkillsDebug_Boss, "TryOfferingTankBot post. session=%d tank=%d stasis=%d pending=%d", g_BossSessions[sessionIndex].id, tank, enterStasis, pendingPlayer);
}

void Boss_OnTryOfferingTankBotPostHandled(int tank, bool enterStasis)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int sessionIndex = -1;
	if (IsValidTank(tank))
	{
		sessionIndex = Boss_EnsureTankSession(tank);
	}

	if (sessionIndex == -1)
	{
		return;
	}

	g_BossSessions[sessionIndex].tank.inStasis = enterStasis;
	Skills_Debug(PlayerSkillsDebug_Boss, "TryOfferingTankBot handled. session=%d tank=%d stasis=%d", g_BossSessions[sessionIndex].id, tank, enterStasis);
}

void Boss_OnEnterStasis(int tank)
{
	if (!Skills_IsEnabled() || !IsValidTank(tank))
	{
		return;
	}

	int sessionIndex = Boss_EnsureTankSession(tank);
	if (sessionIndex == -1)
	{
		return;
	}

	L4D2BossSession(sessionIndex).UpdateOwnerSnapshot(tank);
	g_BossSessions[sessionIndex].tank.inStasis = true;
	g_BossSessions[sessionIndex].lastHealth = GetClientHealth(tank);
	Skills_Debug(PlayerSkillsDebug_Boss, "Tank entered stasis. session=%d tank=%d", g_BossSessions[sessionIndex].id, tank);
}

void Boss_OnLeaveStasis(int tank)
{
	if (!Skills_IsEnabled() || !IsValidTank(tank))
	{
		return;
	}

	int sessionIndex = Boss_EnsureTankSession(tank);
	if (sessionIndex == -1)
	{
		return;
	}

	L4D2BossSession(sessionIndex).UpdateOwnerSnapshot(tank);
	g_BossSessions[sessionIndex].tank.inStasis = false;
	g_BossSessions[sessionIndex].lastHealth = GetClientHealth(tank);
	if (IsFakeClient(tank))
	{
		L4D2BossSession(sessionIndex).BeginPendingTankBotControl(tank);
		Boss_QueuePendingTankBotControlConfirmation(sessionIndex, tank);
	}
	else
	{
		L4D2BossSession(sessionIndex).RefreshOwner(tank);
	}

	Skills_Debug(PlayerSkillsDebug_Boss, "Tank left stasis. session=%d tank=%d fake=%d", g_BossSessions[sessionIndex].id, tank, IsFakeClient(tank));
}

Action Boss_TimerConfirmPendingTankBotControl(Handle timer, DataPack pack)
{
	pack.Reset();
	int sessionIndex = pack.ReadCell();
	int sessionId = pack.ReadCell();
	int userid = pack.ReadCell();
	delete pack;

	if (sessionIndex < 0
		|| sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| g_BossSessions[sessionIndex].id != sessionId
		|| g_BossSessions[sessionIndex].state != L4D2BossState_Active
		|| g_BossSessions[sessionIndex].type != L4D2Boss_Tank
		|| !g_BossSessions[sessionIndex].tank.pendingBotControl
		|| g_BossSessions[sessionIndex].tank.pendingBotUserid != userid)
	{
		return Plugin_Stop;
	}

	int tank = GetClientOfUserId(userid);
	if (!IsValidTank(tank) || !IsFakeClient(tank))
	{
		L4D2BossSession(sessionIndex).CancelPendingTankBotControl();
		return Plugin_Stop;
	}

	float startedAt = g_BossSessions[sessionIndex].tank.pendingBotStartedAt;
	L4D2BossSession(sessionIndex).CancelPendingTankBotControl();
	L4D2BossSession(sessionIndex).UpdateOwnerSnapshot(tank);
	L4D2BossSession(sessionIndex).OpenTankControl(tank, startedAt);
	Skills_Debug(PlayerSkillsDebug_Boss, "Confirmed persistent Tank bot control. session=%d userid=%d startedAt=%.3f", g_BossSessions[sessionIndex].id, userid, startedAt);
	return Plugin_Stop;
}

void Boss_OnEntityCreated(int entity, const char[] classname)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	if (StrContains(classname, "witch", false) != -1)
	{
		int sessionIndex = Boss_EnsureWitchSession(entity);
		if (sessionIndex != -1)
		{
			Boss_HookWitchDamageEntity(sessionIndex, entity);
		}
	}
}

void Boss_OnSpawnWitchPost(int entity)
{
	if (!Skills_IsEnabled() || !IsWitchEntity(entity))
	{
		return;
	}

	int sessionIndex = Boss_EnsureWitchSession(entity);
	if (sessionIndex == -1)
	{
		return;
	}

	Boss_HookWitchDamageEntity(sessionIndex, entity);
}

// Entity lifecycle and round flow.
void Boss_OnRoundStart()
{
	Boss_ResetAll();
}

void Boss_OnRoundEnd()
{
	if (Boss_IsValidPendingTankTransitionSession(g_iBossPendingTankTransitionSession))
	{
		int targetSessionIndex = Boss_FindSingleActiveTankSession();
		if (targetSessionIndex != -1)
		{
			Boss_MaybeMergePendingTankTransitionIntoSession(targetSessionIndex);
		}
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
	}

	Boss_FlushPendingTankTransition();
}

// Event-driven Tank and Witch tracking.
void Boss_EventTankSpawn(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidTank(client))
	{
		return;
	}

	Boss_EnsureTankSession(client);
}

void Boss_OnTankTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if (!Skills_IsRoundLive() || !IsValidTank(victim) || !IsValidSurvivor(attacker))
	{
		return;
	}

	int roundedDamage = RoundToFloor(damage);
	if (roundedDamage <= 0)
	{
		return;
	}

	int sessionIndex = Boss_EnsureTankSession(victim);
	if (sessionIndex == -1)
	{
		return;
	}

	L4D2BossSession(sessionIndex).RefreshOwner(victim);

	int maxHealth = g_BossSessions[sessionIndex].maxHealth;
	if (maxHealth > 0 && g_BossSessions[sessionIndex].totalDamage + roundedDamage > maxHealth)
	{
		roundedDamage = maxHealth - g_BossSessions[sessionIndex].totalDamage;
	}

	if (roundedDamage > 0)
	{
		L4D2BossSession(sessionIndex).AddDamage(attacker, roundedDamage);
	}

	g_BossSessions[sessionIndex].lastHealth = GetClientHealth(victim);
}

void Boss_EventPlayerHurt(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("dmg_health");
	if (!IsValidSurvivor(victim) || !IsValidTank(attacker) || damage <= 0)
	{
		return;
	}

	if (IsIncapacitated(victim) || L4D_IsPlayerHangingFromLedge(victim))
	{
		return;
	}

	int sessionIndex = Boss_EnsureTankSession(attacker);
	if (sessionIndex == -1)
	{
		return;
	}

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	bool isClaw = StrEqual(weapon, "tank_claw");

	if (isClaw)
	{
		g_BossSessions[sessionIndex].tank.punchesHit++;
		g_BossSessions[sessionIndex].tank.punchDamage += damage;
	}
	else if (!StrEqual(weapon, "tank_rock"))
	{
		g_BossSessions[sessionIndex].tank.hittablesHit++;
		g_BossSessions[sessionIndex].tank.hittableDamage += damage;
	}

	g_iBossTankVictimLastSession[victim] = g_BossSessions[sessionIndex].id;
	g_iBossTankVictimLastDamage[victim] = damage;
	g_iBossTankVictimLastHitTick[victim] = GetGameTickCount();
	g_bBossTankVictimLastHitClaw[victim] = isClaw;
}

void Boss_EventPlayerDeath(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidInfected(victim) || L4D2_GetPlayerZombieClass(victim) != L4D2ZombieClass_Tank)
	{
		return;
	}

	int sessionIndex = Boss_FindTankSessionByUserid(event.GetInt("userid"));
	if (sessionIndex == -1)
	{
		sessionIndex = Boss_FindTankSessionByUserid(GetClientUserId(victim));
	}

	if (sessionIndex == -1)
	{
		sessionIndex = Boss_FindTankSessionByClient(victim);
	}

	if (sessionIndex == -1)
	{
		sessionIndex = Boss_EnsureTankSession(victim);
	}

	if (sessionIndex == -1)
	{
		return;
	}

	Boss_CreateTankDeadEvent(sessionIndex, GetClientOfUserId(event.GetInt("attacker")));

	g_BossSessions[sessionIndex].lastHealth = 0;
	g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
	g_BossSessions[sessionIndex].tank.endReason = L4D2TankSessionEnd_TankDead;
	Boss_FinalizeSession(sessionIndex);
}

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

void Boss_RecordTankLedgeHang(int attacker)
{
	if (!Skills_IsEnabled() || !IsValidTank(attacker))
	{
		return;
	}

	int sessionIndex = Boss_EnsureTankSession(attacker);
	if (sessionIndex == -1)
	{
		return;
	}

	g_BossSessions[sessionIndex].tank.ledgeHangs++;
}

	void Boss_EventWitchKilled(Event event)
	{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int witch = event.GetInt("witchid");
	int killer = GetClientOfUserId(event.GetInt("userid"));
	bool oneShot = event.GetBool("oneshot");
	bool meleeOnly = event.GetBool("melee_only");

	int sessionIndex = Boss_FindWitchSessionByEntity(witch);
	if (sessionIndex == -1)
	{
		sessionIndex = Boss_EnsureWitchSession(witch);
	}

	if (sessionIndex == -1)
	{
		return;
	}

	Boss_HookWitchDamageEntity(sessionIndex, witch);

		// If the Witch session already produced a visible announce path (for example
		// the remaining-health summary triggered on incap), do not emit an additional
		// death-side announce for the same Witch lifecycle.
		if (g_BossSessions[sessionIndex].printed)
		{
			g_BossSessions[sessionIndex].lastHealth = 0;
			g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
			Boss_FinalizeSession(sessionIndex);
			return;
		}

		if (IsValidTank(killer))
		{
			Announce_WitchKilledByTank(sessionIndex, killer);
			g_BossSessions[sessionIndex].printed = true;
			g_BossSessions[sessionIndex].lastHealth = 0;
			g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
			Boss_FinalizeSession(sessionIndex);
			return;
		}

	g_BossSessions[sessionIndex].witch.pendingKillerUserid = GetClientUserId(killer);
	g_BossSessions[sessionIndex].witch.pendingWitchOneShot = oneShot;
	g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly = meleeOnly;
	// Witch kill classification is delayed for the same reason as Hunter death:
	// shotgun pellets and the final kill event do not always arrive in a stable
	// order, so the crown decision must run on the settled session state.
	CreateTimer(0.10, Boss_TimerEvaluateWitchDeath, sessionIndex, TIMER_FLAG_NO_MAPCHANGE);
	Skills_Debug(PlayerSkillsDebug_Boss, "Witch death queued. session=%d killer=%d oneshot=%d melee_only=%d delay=0.10", g_BossSessions[sessionIndex].id, killer, oneShot, meleeOnly);
}

Action Boss_TimerEvaluateWitchDeath(Handle timer, any data)
{
	if (!Skills_IsRoundLive())
	{
		return Plugin_Stop;
	}

	int sessionIndex = data;

	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| g_BossSessions[sessionIndex].id == 0
		|| g_BossSessions[sessionIndex].type != L4D2Boss_Witch)
	{
		return Plugin_Stop;
	}

		if (g_BossSessions[sessionIndex].printed)
		{
			Skills_Debug(PlayerSkillsDebug_Boss, "Witch death timer continuing to finalize. session=%d reason=already_printed", g_BossSessions[sessionIndex].id);
			g_BossSessions[sessionIndex].lastHealth = 0;
			g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
			g_BossSessions[sessionIndex].witch.pendingKillerUserid = 0;
			g_BossSessions[sessionIndex].witch.pendingWitchOneShot = false;
			g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly = false;
			Boss_FinalizeSession(sessionIndex);
			return Plugin_Stop;
		}

	int killer = GetClientOfUserId(g_BossSessions[sessionIndex].witch.pendingKillerUserid);
	if (IsValidSurvivor(killer))
	{
		Boss_CreateWitchDeadEvent(sessionIndex, killer);
	}

		if (g_BossSessions[sessionIndex].printed)
		{
			g_BossSessions[sessionIndex].lastHealth = 0;
			g_BossSessions[sessionIndex].witch.pendingKillerUserid = 0;
			g_BossSessions[sessionIndex].witch.pendingWitchOneShot = false;
			g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly = false;
			g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
			Boss_FinalizeSession(sessionIndex);
			return Plugin_Stop;
		}

		if (g_BossSessions[sessionIndex].witch.crownDetected)
		{
			g_BossSessions[sessionIndex].lastHealth = 0;
			g_BossSessions[sessionIndex].printed = true;
			g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
			g_BossSessions[sessionIndex].witch.pendingKillerUserid = 0;
			g_BossSessions[sessionIndex].witch.pendingWitchOneShot = false;
			g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly = false;
			Boss_FinalizeSession(sessionIndex);
			return Plugin_Stop;
		}

	g_BossSessions[sessionIndex].lastHealth = 0;
	g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
	g_BossSessions[sessionIndex].witch.pendingKillerUserid = 0;
	g_BossSessions[sessionIndex].witch.pendingWitchOneShot = false;
	g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly = false;
	Boss_FinalizeSession(sessionIndex);
	return Plugin_Stop;
}

// Session lookup and allocation helpers.
int Boss_EnsureTankSession(int client)
{
	int userid = GetClientUserId(client);
	bool hasTankControlEq = Skills_HasTankControlEq();
	int tankId = hasTankControlEq ? TankControl_GetClientTankId(client) : 0;

	Skills_Debug(PlayerSkillsDebug_Boss,
		"EnsureTankSession enter. client=%d userid=%d fake=%d tank_id=%d entity=%d tank_control=%d",
		client,
		userid,
		IsValidClient(client) && IsFakeClient(client),
		tankId,
		client,
		hasTankControlEq);

	int sessionIndex = Boss_FindTankSessionByUserid(userid);
	if (sessionIndex != -1)
	{
		if (tankId > 0)
		{
			Boss_UpdateTankSessionTankControlMetadata(sessionIndex, tankId);
		}

		Skills_Debug(PlayerSkillsDebug_Boss, "EnsureTankSession matched by userid. session=%d client=%d userid=%d", g_BossSessions[sessionIndex].id, client, userid);
		L4D2BossSession(sessionIndex).RefreshOwner(client);
		Boss_MaybeMergePendingTankTransitionIntoSession(sessionIndex);
		return sessionIndex;
	}

	sessionIndex = Boss_FindTankSessionByClient(client);
	if (sessionIndex != -1)
	{
		if (tankId > 0)
		{
			Boss_UpdateTankSessionTankControlMetadata(sessionIndex, tankId);
		}

		Skills_Debug(PlayerSkillsDebug_Boss, "EnsureTankSession matched by client. session=%d client=%d userid=%d", g_BossSessions[sessionIndex].id, client, userid);
		L4D2BossSession(sessionIndex).RefreshOwner(client);
		Boss_MaybeMergePendingTankTransitionIntoSession(sessionIndex);
		return sessionIndex;
	}

	if (tankId > 0)
	{
		sessionIndex = Boss_FindTankSessionByLifecycleId(tankId);
		if (sessionIndex != -1)
		{
			Boss_UpdateTankSessionTankControlMetadata(sessionIndex, tankId);
			L4D2BossSession(sessionIndex).RefreshOwner(client);
			Skills_Debug(PlayerSkillsDebug_Boss,
				"Recovered Tank id session. session=%d client=%d userid=%d tank_id=%d olduserid=%d",
				g_BossSessions[sessionIndex].id,
				client,
				userid,
				tankId,
				g_BossSessions[sessionIndex].userid);
			Boss_MaybeMergePendingTankTransitionIntoSession(sessionIndex);
			return sessionIndex;
		}

		Skills_Debug(PlayerSkillsDebug_Boss,
			"EnsureTankSession tank id lookup failed. client=%d userid=%d tank_id=%d",
			client,
			userid,
			tankId);

		if (hasTankControlEq && !Skills_HasTankControlEqSubstituteApi())
		{
			sessionIndex = Boss_FindSingleActiveTankSession();
			if (sessionIndex != -1)
			{
				Boss_UpdateTankSessionTankControlMetadata(sessionIndex, tankId);
				Skills_Debug(PlayerSkillsDebug_Boss,
					"Recovered Tank sole active session after tank id mismatch. session=%d client=%d userid=%d old_tank_id=%d new_tank_id=%d",
					g_BossSessions[sessionIndex].id,
					client,
					userid,
					g_BossSessions[sessionIndex].tank.lifecycleId,
					tankId);
				L4D2BossSession(sessionIndex).RefreshOwner(client);
				Boss_MaybeMergePendingTankTransitionIntoSession(sessionIndex);
				return sessionIndex;
			}
		}
	}

	if (!hasTankControlEq && IsFakeClient(client))
	{
		sessionIndex = Boss_FindTankSessionForBotReclaim(client);
		if (sessionIndex != -1)
		{
			L4D2BossSession(sessionIndex).RefreshOwner(client);
			Skills_Debug(PlayerSkillsDebug_Boss,
				"Recovered Tank bot reclaim session. session=%d client=%d userid=%d olduserid=%d",
				g_BossSessions[sessionIndex].id,
				client,
				userid,
				g_BossSessions[sessionIndex].userid);
			Boss_MaybeMergePendingTankTransitionIntoSession(sessionIndex);
			return sessionIndex;
		}
	}

	if (!hasTankControlEq)
	{
		sessionIndex = Boss_FindTankSessionForHumanTakeover(client);
		if (sessionIndex != -1)
		{
			L4D2BossSession(sessionIndex).RefreshOwner(client);
			Skills_Debug(PlayerSkillsDebug_Boss,
				"Recovered Tank handoff session. session=%d newclient=%d userid=%d olduserid=%d",
				g_BossSessions[sessionIndex].id,
				client,
				userid,
				g_BossSessions[sessionIndex].userid);
			Boss_MaybeMergePendingTankTransitionIntoSession(sessionIndex);
			return sessionIndex;
		}
	}

	Skills_Debug(PlayerSkillsDebug_Boss,
		"EnsureTankSession creating new session. client=%d userid=%d fake=%d tank_id=%d",
		client,
		userid,
		IsValidClient(client) && IsFakeClient(client),
		tankId);

	int slot = Boss_FindFreeSession();
	if (slot == -1)
	{
		Skills_Debug(PlayerSkillsDebug_Boss, "No free boss session slot for Tank userid=%d", userid);
		return -1;
	}

	int maxHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Tank);
	L4D2BossSession(slot).Start(L4D2Boss_Tank, client, userid, maxHealth);
	if (tankId > 0)
	{
		Boss_UpdateTankSessionTankControlMetadata(slot, tankId);
	}
	Boss_MaybeMergePendingTankTransitionIntoSession(slot);
	Skills_Debug(PlayerSkillsDebug_Boss, "Started Tank session. session=%d userid=%d client=%d maxhp=%d", g_BossSessions[slot].id, userid, client, maxHealth);
	return slot;
}

int Boss_EnsureWitchSession(int entity)
{
	if (!IsWitchEntity(entity))
	{
		return -1;
	}

	int health = GetEntProp(entity, Prop_Data, "m_iHealth");
	if (health <= 0)
	{
		return -1;
	}

	int sessionIndex = Boss_FindWitchSessionByEntity(entity);
	if (sessionIndex != -1)
	{
		Boss_HookWitchDamageEntity(sessionIndex, entity);
		return sessionIndex;
	}

	int slot = Boss_FindFreeSession();
	if (slot == -1)
	{
		Skills_Debug(PlayerSkillsDebug_Boss, "No free boss session slot for Witch entity=%d", entity);
		return -1;
	}

	int maxHealth = Skills_GetWitchMaxHealth();
	L4D2BossSession(slot).Start(L4D2Boss_Witch, entity, 0, maxHealth);
	Boss_HookWitchDamageEntity(slot, entity);
	Skills_Debug(PlayerSkillsDebug_Boss, "Started Witch session. session=%d entity=%d maxhp=%d", g_BossSessions[slot].id, entity, maxHealth);
	return slot;
}

void Boss_HookWitchDamageEntity(int sessionIndex, int witch)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || !IsWitchEntity(witch))
	{
		return;
	}

	if (g_BossSessions[sessionIndex].witch.damageHooksAttached)
	{
		return;
	}

	SDKHook(witch, SDKHook_OnTakeDamage, Boss_OnWitchTakeDamage);
	SDKHook(witch, SDKHook_OnTakeDamagePost, Boss_OnWitchTakeDamagePost);
	g_BossSessions[sessionIndex].witch.damageHooksAttached = true;
}

int Boss_FindFreeSession()
{
	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0)
		{
			return index;
		}
	}

	return -1;
}

int Boss_FindTankSessionByLifecycleId(int lifecycleId)
{
	if (lifecycleId <= 0)
	{
		return -1;
	}

	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0
			|| g_BossSessions[index].state != L4D2BossState_Active
			|| g_BossSessions[index].type != L4D2Boss_Tank)
		{
			continue;
		}

		if (g_BossSessions[index].tank.lifecycleId == lifecycleId)
		{
			return index;
		}
	}

	return -1;
}

int Boss_FindSingleActiveTankSession()
{
	int candidate = -1;

	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0
			|| g_BossSessions[index].state != L4D2BossState_Active
			|| g_BossSessions[index].type != L4D2Boss_Tank)
		{
			continue;
		}

		if (candidate != -1)
		{
			return -1;
		}

		candidate = index;
	}

	return candidate;
}

int Boss_FindSingleOtherActiveTankSession(int sessionIndex)
{
	int candidate = -1;

	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (index == sessionIndex
			|| g_BossSessions[index].id == 0
			|| g_BossSessions[index].state != L4D2BossState_Active
			|| g_BossSessions[index].type != L4D2Boss_Tank)
		{
			continue;
		}

		if (candidate != -1)
		{
			return -1;
		}

		candidate = index;
	}

	return candidate;
}

static bool Boss_IsValidPendingTankTransitionSession(int sessionIndex)
{
	return sessionIndex >= 0
		&& sessionIndex < L4D2_SKILLS_MAX_BOSSES
		&& g_BossSessions[sessionIndex].id != 0
		&& !g_BossSessions[sessionIndex].finalized
		&& g_BossSessions[sessionIndex].type == L4D2Boss_Tank
		&& g_BossSessions[sessionIndex].tank.endReason == L4D2TankSessionEnd_TankDead;
}

static void Boss_UpdateTankSessionTankControlMetadata(int sessionIndex, int tankId)
{
	if (sessionIndex < 0
		|| sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| g_BossSessions[sessionIndex].id == 0
		|| g_BossSessions[sessionIndex].type != L4D2Boss_Tank)
	{
		return;
	}

	g_BossSessions[sessionIndex].tank.lifecycleId = tankId;
	g_BossSessions[sessionIndex].tank.startReason = TankControlStart_Unknown;
	g_BossSessions[sessionIndex].tank.parentTankId = 0;
	g_BossSessions[sessionIndex].tank.isSubstitute = false;

	if (!Skills_HasTankControlEqSubstituteApi() || tankId <= 0)
	{
		return;
	}

	g_BossSessions[sessionIndex].tank.startReason = TankControl_GetTankStartReason(tankId);
	g_BossSessions[sessionIndex].tank.parentTankId = TankControl_GetParentTankId(tankId);
	g_BossSessions[sessionIndex].tank.isSubstitute = TankControl_IsSubstituteTank(tankId);
}

void Boss_ClearPendingTankTransition()
{
	g_iBossPendingTankTransitionSession = -1;
}

static void Boss_QueuePendingTankTransition(int sessionIndex)
{
	if (Boss_IsValidPendingTankTransitionSession(g_iBossPendingTankTransitionSession)
		&& g_iBossPendingTankTransitionSession != sessionIndex)
	{
		int pendingSessionIndex = g_iBossPendingTankTransitionSession;
		Boss_ClearPendingTankTransition();
		Boss_FinalizeSessionImmediate(pendingSessionIndex, false);
	}

	g_iBossPendingTankTransitionSession = sessionIndex;

	Skills_Debug(PlayerSkillsDebug_Boss,
		"Queued pending Tank transition session. session=%d reason=%d tank_id=%d",
		g_BossSessions[sessionIndex].id,
		g_BossSessions[sessionIndex].tank.endReason,
		g_BossSessions[sessionIndex].tank.lifecycleId);
}

static void Boss_MaybeMergePendingTankTransitionIntoSession(int targetSessionIndex)
{
	if (!Boss_IsValidPendingTankTransitionSession(g_iBossPendingTankTransitionSession)
		|| targetSessionIndex < 0
		|| targetSessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| g_BossSessions[targetSessionIndex].id == 0
		|| g_BossSessions[targetSessionIndex].state != L4D2BossState_Active
		|| g_BossSessions[targetSessionIndex].type != L4D2Boss_Tank
		|| targetSessionIndex == g_iBossPendingTankTransitionSession)
	{
		return;
	}

	int pendingSessionIndex = g_iBossPendingTankTransitionSession;
	if (Skills_HasTankControlEqSubstituteApi())
	{
		bool isSubstitute = g_BossSessions[targetSessionIndex].tank.isSubstitute;
		int parentTankId = g_BossSessions[targetSessionIndex].tank.parentTankId;
		int pendingTankId = g_BossSessions[pendingSessionIndex].tank.lifecycleId;

		if (!isSubstitute || pendingTankId <= 0 || parentTankId != pendingTankId)
		{
			Boss_ClearPendingTankTransition();
			Skills_Debug(PlayerSkillsDebug_Boss,
				"Skipped pending Tank transition merge. pending_session=%d pending_tank_id=%d target_session=%d target_tank_id=%d substitute=%d parent_tank_id=%d",
				g_BossSessions[pendingSessionIndex].id,
				pendingTankId,
				g_BossSessions[targetSessionIndex].id,
				g_BossSessions[targetSessionIndex].tank.lifecycleId,
				isSubstitute,
				parentTankId);
			Boss_FinalizeSessionImmediate(pendingSessionIndex, false);
			return;
		}
	}

	Boss_ClearPendingTankTransition();
	Boss_MergeTankSessionIntoActiveSession(pendingSessionIndex, targetSessionIndex);
	g_BossSessions[pendingSessionIndex].finalized = true;
	g_BossSessions[pendingSessionIndex].printed = true;
	g_BossSessions[pendingSessionIndex].state = L4D2BossState_Printed;
}

static void Boss_FlushPendingTankTransition()
{
	if (!Boss_IsValidPendingTankTransitionSession(g_iBossPendingTankTransitionSession))
	{
		Boss_ClearPendingTankTransition();
		return;
	}

	int pendingSessionIndex = g_iBossPendingTankTransitionSession;
	Boss_ClearPendingTankTransition();
	Boss_FinalizeSessionImmediate(pendingSessionIndex, false);
}

static int Boss_FindDamageEntryByPersistentRef(int sessionIndex, L4D2PlayerRef player)
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

static int Boss_FindFreeDamageEntrySlot(int sessionIndex)
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

static void Boss_AppendMergedAiTankControl(int targetSessionIndex, int remainingHealth, float controlTime, int rocksThrown, int rocksHit, int mergedControls)
{
	if (targetSessionIndex < 0
		|| targetSessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| g_BossSessions[targetSessionIndex].id == 0
		|| g_BossSessions[targetSessionIndex].type != L4D2Boss_Tank
		|| controlTime <= 0.0)
	{
		return;
	}

	int insertIndex = g_BossSessions[targetSessionIndex].tank.activeControlIndex;
	if (insertIndex < 0 || insertIndex > g_BossSessions[targetSessionIndex].tank.controlCount)
	{
		insertIndex = g_BossSessions[targetSessionIndex].tank.controlCount;
	}

	if (insertIndex > 0
		&& g_BossSessions[targetSessionIndex].tank.controls[insertIndex - 1].active
		&& g_BossSessions[targetSessionIndex].tank.controls[insertIndex - 1].player.bot)
	{
		g_BossSessions[targetSessionIndex].tank.controls[insertIndex - 1].synthetic = true;
		g_BossSessions[targetSessionIndex].tank.controls[insertIndex - 1].controlTime += controlTime;
		g_BossSessions[targetSessionIndex].tank.controls[insertIndex - 1].rocksThrown += rocksThrown;
		g_BossSessions[targetSessionIndex].tank.controls[insertIndex - 1].rocksHit += rocksHit;
		g_BossSessions[targetSessionIndex].tank.controls[insertIndex - 1].remainingHealth = remainingHealth;
		g_BossSessions[targetSessionIndex].tank.controls[insertIndex - 1].mergedControls += (mergedControls > 0 ? mergedControls : 1);
		return;
	}

	if (g_BossSessions[targetSessionIndex].tank.controlCount >= L4D2_SKILLS_MAX_TANK_CONTROLS)
	{
		int overflowIndex = L4D2_SKILLS_MAX_TANK_CONTROLS - 1;
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].active = true;
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].synthetic = true;
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].player.Reset();
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].player.bot = true;
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].player.character = -1;
		strcopy(g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].player.name, MAX_NAME_LENGTH, "IA");
		strcopy(g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].player.auth, sizeof(g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].player.auth), "BOT");
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].controlTime += controlTime;
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].rocksThrown += rocksThrown;
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].rocksHit += rocksHit;
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].remainingHealth = remainingHealth;
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].overflow = true;
		g_BossSessions[targetSessionIndex].tank.controls[overflowIndex].mergedControls += (mergedControls > 0 ? mergedControls : 1);
		return;
	}

	for (int entry = g_BossSessions[targetSessionIndex].tank.controlCount; entry > insertIndex; entry--)
	{
		g_BossSessions[targetSessionIndex].tank.controls[entry] = g_BossSessions[targetSessionIndex].tank.controls[entry - 1];
	}

	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].Reset();
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].active = true;
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].synthetic = true;
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].player.bot = true;
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].player.character = -1;
	strcopy(g_BossSessions[targetSessionIndex].tank.controls[insertIndex].player.name, MAX_NAME_LENGTH, "IA");
	strcopy(g_BossSessions[targetSessionIndex].tank.controls[insertIndex].player.auth, sizeof(g_BossSessions[targetSessionIndex].tank.controls[insertIndex].player.auth), "BOT");
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].controlTime = controlTime;
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].remainingHealth = remainingHealth;
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].rocksThrown = rocksThrown;
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].rocksHit = rocksHit;
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].mergedControls = (mergedControls > 0 ? mergedControls : 1);
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].startedAt = 0.0;
	g_BossSessions[targetSessionIndex].tank.controls[insertIndex].endedAt = 0.0;

	g_BossSessions[targetSessionIndex].tank.controlCount++;
	if (g_BossSessions[targetSessionIndex].tank.activeControlIndex >= insertIndex)
	{
		g_BossSessions[targetSessionIndex].tank.activeControlIndex++;
	}
}

static void Boss_MergeTankSessionIntoActiveSession(int sourceSessionIndex, int targetSessionIndex)
{
	if (sourceSessionIndex < 0 || sourceSessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| targetSessionIndex < 0 || targetSessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| sourceSessionIndex == targetSessionIndex
		|| g_BossSessions[sourceSessionIndex].id == 0
		|| g_BossSessions[targetSessionIndex].id == 0)
	{
		return;
	}

	Boss_ConsolidateDamageEntries(sourceSessionIndex);

	float sourceControlTime = 0.0;
	int sourceRocksThrown = 0;
	int sourceRocksHit = 0;
	int sourceMergedControls = 0;
	for (int entry = 0; entry < g_BossSessions[sourceSessionIndex].tank.controlCount && entry < L4D2_SKILLS_MAX_TANK_CONTROLS; entry++)
	{
		if (!g_BossSessions[sourceSessionIndex].tank.controls[entry].active)
		{
			continue;
		}

		sourceControlTime += g_BossSessions[sourceSessionIndex].tank.controls[entry].controlTime;
		sourceRocksThrown += g_BossSessions[sourceSessionIndex].tank.controls[entry].rocksThrown;
		sourceRocksHit += g_BossSessions[sourceSessionIndex].tank.controls[entry].rocksHit;
		sourceMergedControls += (g_BossSessions[sourceSessionIndex].tank.controls[entry].mergedControls > 0
			? g_BossSessions[sourceSessionIndex].tank.controls[entry].mergedControls
			: 1);
	}

	Boss_AppendMergedAiTankControl(
		targetSessionIndex,
		g_BossSessions[sourceSessionIndex].lastHealth,
		sourceControlTime,
		sourceRocksThrown,
		sourceRocksHit,
		sourceMergedControls);

	int sourceHealthPool = g_BossSessions[sourceSessionIndex].maxHealth;
	int inferredSourceMaxHealth = g_BossSessions[sourceSessionIndex].lastHealth + g_BossSessions[sourceSessionIndex].totalDamage;
	if (inferredSourceMaxHealth > sourceHealthPool)
	{
		sourceHealthPool = inferredSourceMaxHealth;
	}

	g_BossSessions[targetSessionIndex].maxHealth += sourceHealthPool;
	if (g_BossSessions[targetSessionIndex].startedAt <= 0.0
		|| (g_BossSessions[sourceSessionIndex].startedAt > 0.0
			&& g_BossSessions[sourceSessionIndex].startedAt < g_BossSessions[targetSessionIndex].startedAt))
	{
		g_BossSessions[targetSessionIndex].startedAt = g_BossSessions[sourceSessionIndex].startedAt;
	}

	g_BossSessions[targetSessionIndex].totalDamage += g_BossSessions[sourceSessionIndex].totalDamage;
	g_BossSessions[targetSessionIndex].tank.punchesHit += g_BossSessions[sourceSessionIndex].tank.punchesHit;
	g_BossSessions[targetSessionIndex].tank.punchDamage += g_BossSessions[sourceSessionIndex].tank.punchDamage;
	g_BossSessions[targetSessionIndex].tank.hittablesHit += g_BossSessions[sourceSessionIndex].tank.hittablesHit;
	g_BossSessions[targetSessionIndex].tank.hittableDamage += g_BossSessions[sourceSessionIndex].tank.hittableDamage;
	g_BossSessions[targetSessionIndex].tank.incaps += g_BossSessions[sourceSessionIndex].tank.incaps;
	g_BossSessions[targetSessionIndex].tank.ledgeHangs += g_BossSessions[sourceSessionIndex].tank.ledgeHangs;

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sourceSessionIndex][entry].active || g_BossDamage[sourceSessionIndex][entry].damage <= 0)
		{
			continue;
		}

		int targetEntry = Boss_FindDamageEntryByPersistentRef(targetSessionIndex, g_BossDamage[sourceSessionIndex][entry].player);
		if (targetEntry == -1)
		{
			targetEntry = Boss_FindFreeDamageEntrySlot(targetSessionIndex);
			if (targetEntry == -1)
			{
				continue;
			}

			g_BossDamage[targetSessionIndex][targetEntry].active = true;
			g_BossDamage[targetSessionIndex][targetEntry].player = g_BossDamage[sourceSessionIndex][entry].player;
			g_BossDamage[targetSessionIndex][targetEntry].damage = 0;
			g_BossDamage[targetSessionIndex][targetEntry].shots = 0;
		}

		g_BossDamage[targetSessionIndex][targetEntry].damage += g_BossDamage[sourceSessionIndex][entry].damage;
		g_BossDamage[targetSessionIndex][targetEntry].shots += g_BossDamage[sourceSessionIndex][entry].shots;
	}

	Boss_ConsolidateDamageEntries(targetSessionIndex);

	Skills_Debug(PlayerSkillsDebug_Boss,
		"Merged Tank transition session. source_session=%d target_session=%d source_damage=%d target_damage=%d source_pool=%d target_pool=%d",
		g_BossSessions[sourceSessionIndex].id,
		g_BossSessions[targetSessionIndex].id,
		g_BossSessions[sourceSessionIndex].totalDamage,
		g_BossSessions[targetSessionIndex].totalDamage,
		sourceHealthPool,
		g_BossSessions[targetSessionIndex].maxHealth);
}

void Boss_AnnounceWitchRemainingHealth(int witch)
{
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

	Announce_WitchDamage(sessionIndex, true);
	g_BossSessions[sessionIndex].printed = true;
	g_BossSessions[sessionIndex].state = L4D2BossState_Printed;
}

int Boss_FindTankSessionByUserid(int userid)
{
	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0 || g_BossSessions[index].state != L4D2BossState_Active)
		{
			continue;
		}

		if (g_BossSessions[index].type == L4D2Boss_Tank && g_BossSessions[index].userid == userid)
		{
			return index;
		}
	}

	return -1;
}

int Boss_FindTankSessionByClient(int client)
{
	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0 || g_BossSessions[index].state != L4D2BossState_Active)
		{
			continue;
		}

		if (g_BossSessions[index].type == L4D2Boss_Tank && g_BossSessions[index].entity == client)
		{
			return index;
		}
	}

	return -1;
}

int Boss_FindTankSessionForHumanTakeover(int client)
{
	if (!IsValidTank(client) || IsFakeClient(client))
	{
		return -1;
	}

	int candidate = -1;
	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0
			|| g_BossSessions[index].state != L4D2BossState_Active
			|| g_BossSessions[index].type != L4D2Boss_Tank)
		{
			continue;
		}

		int activeControlIndex = g_BossSessions[index].tank.activeControlIndex;
		bool hasHumanControl = activeControlIndex >= 0
			&& activeControlIndex < L4D2_SKILLS_MAX_TANK_CONTROLS
			&& g_BossSessions[index].tank.controls[activeControlIndex].active
			&& !g_BossSessions[index].tank.controls[activeControlIndex].player.bot;

		if (hasHumanControl)
		{
			continue;
		}

		bool hasBotControl = activeControlIndex >= 0
			&& activeControlIndex < L4D2_SKILLS_MAX_TANK_CONTROLS
			&& g_BossSessions[index].tank.controls[activeControlIndex].active
			&& g_BossSessions[index].tank.controls[activeControlIndex].player.bot;

		bool looksLikeSpawnHandoff = g_BossSessions[index].owner.bot
			&& g_BossSessions[index].totalDamage == 0
			&& g_BossSessions[index].lastHealth == g_BossSessions[index].maxHealth;

		if (!g_BossSessions[index].tank.pendingBotControl
			&& !hasBotControl
			&& !looksLikeSpawnHandoff)
		{
			continue;
		}

		if (candidate != -1)
		{
			Skills_Debug(PlayerSkillsDebug_Boss,
				"Tank human takeover ambiguous. client=%d userid=%d existing_candidate=%d conflicting_session=%d",
				client,
				GetClientUserId(client),
				g_BossSessions[candidate].id,
				g_BossSessions[index].id);
			return -1;
		}

		candidate = index;
	}

	return candidate;
}

int Boss_FindTankSessionForBotReclaim(int client)
{
	if (!IsValidTank(client) || !IsFakeClient(client))
	{
		return -1;
	}

	int candidate = -1;
	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0
			|| g_BossSessions[index].state != L4D2BossState_Active
			|| g_BossSessions[index].type != L4D2Boss_Tank)
		{
			continue;
		}

		int activeControlIndex = g_BossSessions[index].tank.activeControlIndex;
		bool hasActiveHumanControl = activeControlIndex >= 0
			&& activeControlIndex < L4D2_SKILLS_MAX_TANK_CONTROLS
			&& g_BossSessions[index].tank.controls[activeControlIndex].active
			&& !g_BossSessions[index].tank.controls[activeControlIndex].player.bot;
		if (hasActiveHumanControl)
		{
			continue;
		}

		bool canReclaim = g_BossSessions[index].tank.pendingBotControl
			|| (!g_BossSessions[index].owner.bot && !IsClientInGame(g_BossSessions[index].entity))
			|| (g_BossSessions[index].owner.bot && g_BossSessions[index].owner.userid == 0);
		if (!canReclaim)
		{
			continue;
		}

		if (candidate != -1)
		{
			Skills_Debug(PlayerSkillsDebug_Boss,
				"Tank bot reclaim ambiguous. client=%d userid=%d existing_candidate=%d conflicting_session=%d",
				client,
				GetClientUserId(client),
				g_BossSessions[candidate].id,
				g_BossSessions[index].id);
			return -1;
		}

		candidate = index;
	}

	return candidate;
}

int Boss_FindWitchSessionByEntity(int entity)
{
	int entRef = entity > 0 ? EntIndexToEntRef(entity) : INVALID_ENT_REFERENCE;

	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0 || g_BossSessions[index].type != L4D2Boss_Witch)
		{
			continue;
		}

		if (g_BossSessions[index].entRef != INVALID_ENT_REFERENCE)
		{
			if (g_BossSessions[index].entRef == entRef)
			{
				return index;
			}

			continue;
		}

		if (g_BossSessions[index].entity == entity)
		{
			return index;
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
void Boss_CreateTankDeadEvent(int sessionIndex, int killer)
{
	if (!IsValidSurvivor(killer))
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_TankDead);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

		g_SkillEvents[eventIndex].actor.Capture(killer);
		g_SkillEvents[eventIndex].actor2 = g_BossSessions[sessionIndex].id;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_TankDead);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Boss_OnTankRockReleased(int tank)
{
	if (!Skills_IsEnabled() || !IsValidTank(tank))
	{
		return;
	}

	int sessionIndex = Boss_EnsureTankSession(tank);
	if (sessionIndex == -1)
	{
		return;
	}

	L4D2BossSession(sessionIndex).RecordTankRockThrown();
}

void Boss_OnTankRockConnected(int tank)
{
	if (!Skills_IsEnabled() || !IsValidTank(tank))
	{
		return;
	}

	int sessionIndex = Boss_EnsureTankSession(tank);
	if (sessionIndex == -1)
	{
		return;
	}

	L4D2BossSession(sessionIndex).RecordTankRockHit();
}

bool Boss_DidRoundEndInWipe()
{
	bool foundAnySurvivor = false;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidSurvivor(client))
		{
			continue;
		}

		foundAnySurvivor = true;

		if (!IsPlayerAlive(client))
		{
			continue;
		}

		if (!L4D_IsPlayerIncapacitated(client) && !L4D_IsPlayerHangingFromLedge(client))
		{
			return false;
		}
	}

	return foundAnySurvivor;
}

static void Boss_FinalizeSessionImmediate(int sessionIndex, bool allowAnnounce = true)
{
	if (g_BossSessions[sessionIndex].type == L4D2Boss_Tank
		&& g_BossSessions[sessionIndex].tank.endReason != L4D2TankSessionEnd_None)
	{
		API_FireTankSessionClosed(g_BossSessions[sessionIndex].id, g_BossSessions[sessionIndex].tank.endReason);
	}

	Boss_ConsolidateDamageEntries(sessionIndex);

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
	g_BossSessions[sessionIndex].finalized = true;
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

void Boss_OnWitchSetHarasser(int witch, int victim)
{
	if (!Skills_IsEnabled() || !IsWitchEntity(witch))
	{
		return;
	}

	int sessionIndex = Boss_EnsureWitchSession(witch);
	if (sessionIndex == -1)
	{
		return;
	}

	Boss_HookWitchDamageEntity(sessionIndex, witch);
	g_BossSessions[sessionIndex].witch.startled = victim > 0;

	if (IsValidClient(victim))
	{
		g_BossSessions[sessionIndex].witch.harasser.Capture(victim);
	}

}

Action Boss_OnWitchTakeDamage(int witch, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!Skills_IsRoundLive() || !IsWitchEntity(witch))
	{
		return Plugin_Continue;
	}

	int sessionIndex = Boss_EnsureWitchSession(witch);
	if (sessionIndex == -1)
	{
		return Plugin_Continue;
	}

	if (g_BossSessions[sessionIndex].printed)
	{
		return Plugin_Continue;
	}

	g_BossSessions[sessionIndex].witch.lastHealthBeforeDamage = GetEntProp(witch, Prop_Data, "m_iHealth");
	g_BossSessions[sessionIndex].witch.lastShotAttacker = attacker;
	g_BossSessions[sessionIndex].witch.lastShotRawDamage = damage;
	g_BossSessions[sessionIndex].witch.lastDamageType = damagetype;
	bool shotgunBlast = (damagetype & DMG_BUCKSHOT) != 0;
	if (!shotgunBlast
		&& IsValidSurvivor(attacker)
		&& Skills_IsShotgunWeaponId(Detect_GetLastWeaponId(attacker))
		&& (GetGameTime() - Detect_GetLastWeaponFireTime(attacker)) <= L4D2_SKILLS_SHOTGUN_BLAST_TIME)
	{
		shotgunBlast = true;
	}

	g_BossSessions[sessionIndex].witch.lastShotIsShotgun = shotgunBlast;

	float now = GetGameTime();
	bool sameBlast = g_BossSessions[sessionIndex].witch.lastShotIsShotgun
		&& g_BossSessions[sessionIndex].witch.lastBlastStartTime > 0.0
		&& (now - g_BossSessions[sessionIndex].witch.lastBlastStartTime) <= L4D2_SKILLS_SHOTGUN_BLAST_TIME
		&& g_BossSessions[sessionIndex].witch.lastShotAttacker == attacker;

	if (!sameBlast)
	{
		g_BossSessions[sessionIndex].witch.lastBlastStartTime = now;
		g_BossSessions[sessionIndex].witch.lastBlastDamage = 0;
		g_BossSessions[sessionIndex].witch.lastBlastRawDamage = 0.0;
	}

	return Plugin_Continue;
}

void Boss_OnWitchTakeDamagePost(int witch, int attacker, int inflictor, float damage, int damagetype)
{
	if (!Skills_IsRoundLive() || !IsWitchEntity(witch))
	{
		return;
	}

	int sessionIndex = Boss_EnsureWitchSession(witch);
	if (sessionIndex == -1)
	{
		return;
	}

	if (g_BossSessions[sessionIndex].printed)
	{
		return;
	}

	int roundedDamage = RoundToFloor(damage);
	if (roundedDamage <= 0)
	{
		return;
	}

	int effectiveDamage = roundedDamage;
	int maxHealth = g_BossSessions[sessionIndex].maxHealth;
	if (maxHealth > 0 && g_BossSessions[sessionIndex].totalDamage + effectiveDamage > maxHealth)
	{
		effectiveDamage = maxHealth - g_BossSessions[sessionIndex].totalDamage;
		if (effectiveDamage < 0)
		{
			effectiveDamage = 0;
		}
	}

	g_BossSessions[sessionIndex].witch.lastShotTime = GetGameTime();
	g_BossSessions[sessionIndex].witch.lastShotAttacker = attacker;
	g_BossSessions[sessionIndex].witch.lastShotDamage = effectiveDamage;
	g_BossSessions[sessionIndex].witch.lastShotRawDamage = damage;
	g_BossSessions[sessionIndex].witch.lastDamageType = damagetype;
	bool shotgunBlast = g_BossSessions[sessionIndex].witch.lastShotIsShotgun;
	if (!shotgunBlast
		&& IsValidSurvivor(attacker)
		&& Skills_IsShotgunWeaponId(Detect_GetLastWeaponId(attacker))
		&& (GetGameTime() - Detect_GetLastWeaponFireTime(attacker)) <= L4D2_SKILLS_SHOTGUN_BLAST_TIME)
	{
		shotgunBlast = true;
	}

	g_BossSessions[sessionIndex].witch.lastShotIsShotgun = shotgunBlast;
	bool countShot = !g_BossSessions[sessionIndex].witch.lastShotIsShotgun || g_BossSessions[sessionIndex].witch.lastBlastDamage <= 0;

	if (g_BossSessions[sessionIndex].witch.lastShotIsShotgun)
	{
		g_BossSessions[sessionIndex].witch.lastBlastDamage += effectiveDamage;
		g_BossSessions[sessionIndex].witch.lastBlastRawDamage += damage;
	}
	else
	{
		g_BossSessions[sessionIndex].witch.lastBlastStartTime = 0.0;
		g_BossSessions[sessionIndex].witch.lastBlastDamage = effectiveDamage;
		g_BossSessions[sessionIndex].witch.lastBlastRawDamage = damage;
	}

	if (!IsValidSurvivor(attacker))
	{
		return;
	}

	if (effectiveDamage <= 0)
	{
		return;
	}

	L4D2BossSession(sessionIndex).AddDamage(attacker, effectiveDamage, countShot);
	int health = GetEntProp(witch, Prop_Data, "m_iHealth");
	g_BossSessions[sessionIndex].lastHealth = health > 0 ? health : 0;
}

void Boss_CreateWitchDeadEvent(int sessionIndex, int killer)
{
	if (!IsValidSurvivor(killer))
	{
		return;
	}

	Boss_ConsolidateDamageEntries(sessionIndex);

	int killerTotalDamage = Boss_GetDamageEntryDamage(sessionIndex, killer);
	int killerShots = Boss_GetDamageEntryShots(sessionIndex, killer);
	int actualDamage = g_BossSessions[sessionIndex].witch.lastShotIsShotgun
		? g_BossSessions[sessionIndex].witch.lastBlastDamage
		: g_BossSessions[sessionIndex].witch.lastShotDamage;
	int missingHealth = g_BossSessions[sessionIndex].maxHealth - g_BossSessions[sessionIndex].totalDamage;
	bool recoveredDamage = false;
	bool recoveredShotgunBlast = false;
	if (g_BossSessions[sessionIndex].witch.lastShotAttacker == killer
		&& missingHealth > 0)
	{
		int damageEntry = Boss_FindOrCreateDamageEntry(sessionIndex, killer);
		if (damageEntry != -1)
		{
			if (!g_BossDamage[sessionIndex][damageEntry].active)
			{
				g_BossDamage[sessionIndex][damageEntry].active = true;
				g_BossDamage[sessionIndex][damageEntry].player.Capture(killer);
			}

			g_BossDamage[sessionIndex][damageEntry].damage += missingHealth;
			g_BossSessions[sessionIndex].totalDamage += missingHealth;
			killerTotalDamage += missingHealth;
			actualDamage += missingHealth;
			recoveredDamage = true;

			if (g_BossSessions[sessionIndex].witch.lastShotIsShotgun)
			{
				if (g_BossSessions[sessionIndex].witch.lastBlastDamage <= 0)
				{
					g_BossDamage[sessionIndex][damageEntry].shots += 1;
					killerShots += 1;
					recoveredShotgunBlast = true;
				}
			}
			else if (g_BossSessions[sessionIndex].witch.lastShotDamage <= 0)
			{
				g_BossDamage[sessionIndex][damageEntry].shots += 1;
				killerShots += 1;
			}
		}
	}
	if (actualDamage <= 0 && killerTotalDamage > 0)
	{
		actualDamage = killerTotalDamage;
	}
	if (killerShots <= 0 && actualDamage > 0)
	{
		killerShots = 1;
	}
	int preBlastDamage = g_BossSessions[sessionIndex].totalDamage - actualDamage;
	if (preBlastDamage < 0)
	{
		preBlastDamage = 0;
	}
	int preBlastHealth = g_BossSessions[sessionIndex].maxHealth - preBlastDamage;
	if (preBlastHealth < 0)
	{
		preBlastHealth = 0;
	}
	bool crown = g_BossSessions[sessionIndex].witch.lastShotAttacker == killer
		&& g_BossSessions[sessionIndex].witch.lastShotIsShotgun
		&& actualDamage >= preBlastHealth;
	int chipDamage = g_BossSessions[sessionIndex].maxHealth - actualDamage;

	L4D2SkillType eventType = crown ? L4D2Skill_WitchCrown : L4D2Skill_WitchDead;
	int eventId = Skills_CreateEvent(eventType);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

		g_SkillEvents[eventIndex].actor.Capture(killer);
		g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	g_SkillEvents[eventIndex].actorDamage = actualDamage;
	g_SkillEvents[eventIndex].damage = actualDamage;
	g_SkillEvents[eventIndex].chipDamage = chipDamage < 0 ? 0 : chipDamage;
	g_SkillEvents[eventIndex].shots = killerShots;
	g_SkillEvents[eventIndex].crown = crown;
	g_SkillEvents[eventIndex].startled = g_BossSessions[sessionIndex].witch.startled;
	g_SkillEvents[eventIndex].actor2 = g_BossSessions[sessionIndex].id;
	Boss_FillWitchAssistData(sessionIndex, killer, eventIndex);
	if (g_SkillEvents[eventIndex].crown)
	{
		int totalAssistDamage = 0;
		for (int assistIndex = 0; assistIndex < g_SkillEvents[eventIndex].assistsCount; assistIndex++)
		{
			totalAssistDamage += g_SkillEvents[eventIndex].assistDamage[assistIndex];
		}

		int normalizedActorDamage = g_BossSessions[sessionIndex].maxHealth - totalAssistDamage;
		if (normalizedActorDamage < 0)
		{
			normalizedActorDamage = 0;
		}
		else if (normalizedActorDamage > g_BossSessions[sessionIndex].maxHealth)
		{
			normalizedActorDamage = g_BossSessions[sessionIndex].maxHealth;
		}

		g_SkillEvents[eventIndex].actorDamage = normalizedActorDamage;
		g_SkillEvents[eventIndex].damage = normalizedActorDamage;
		g_SkillEvents[eventIndex].chipDamage = normalizedActorDamage - actualDamage;
		if (g_SkillEvents[eventIndex].chipDamage < 0)
		{
			g_SkillEvents[eventIndex].chipDamage = 0;
		}
	}
	g_SkillEvents[eventIndex].perfect = g_BossSessions[sessionIndex].witch.pendingWitchOneShot
		&& !g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly
		&& g_SkillEvents[eventIndex].assistsCount == 0;
	if (g_SkillEvents[eventIndex].crown
		&& !g_BossSessions[sessionIndex].witch.pendingWitchOneShot
		&& g_SkillEvents[eventIndex].shots < 2)
	{
		g_SkillEvents[eventIndex].shots = 2;
	}

	if (g_SkillEvents[eventIndex].crown)
	{
		g_BossSessions[sessionIndex].witch.crownDetected = true;
		g_BossSessions[sessionIndex].witch.crowner.Capture(killer);
	}

	Skills_Debug(PlayerSkillsDebug_Boss,
		"Witch dead event built. session=%d killer=%d damage=%d actor_damage=%d chip=%d shots=%d killer_total=%d killer_shots=%d crown=%d perfect=%d assists=%d oneshot=%d melee_only=%d recovered=%d recovered_blast=%d shotgun=%d blast=%d shot=%d",
		g_BossSessions[sessionIndex].id,
		killer,
		g_SkillEvents[eventIndex].damage,
		g_SkillEvents[eventIndex].actorDamage,
		g_SkillEvents[eventIndex].chipDamage,
		g_SkillEvents[eventIndex].shots,
		killerTotalDamage,
		killerShots,
		g_SkillEvents[eventIndex].crown,
		g_SkillEvents[eventIndex].perfect,
		g_SkillEvents[eventIndex].assistsCount,
		g_BossSessions[sessionIndex].witch.pendingWitchOneShot,
		g_BossSessions[sessionIndex].witch.pendingWitchMeleeOnly,
		recoveredDamage,
		recoveredShotgunBlast,
		g_BossSessions[sessionIndex].witch.lastShotIsShotgun,
		g_BossSessions[sessionIndex].witch.lastBlastDamage,
		g_BossSessions[sessionIndex].witch.lastShotDamage);

	Action result = API_FireSkillDetected(eventId, eventType);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

int Boss_GetDamageEntryDamage(int sessionIndex, int client)
{
	if (!IsValidSurvivor(client))
	{
		return 0;
	}

	int totalDamage = 0;

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active || !g_BossDamage[sessionIndex][entry].player.IsSamePersistentPlayer(client))
		{
			continue;
		}

		totalDamage += g_BossDamage[sessionIndex][entry].damage;
	}

	return totalDamage;
}

int Boss_GetDamageEntryShots(int sessionIndex, int client)
{
	if (!IsValidSurvivor(client))
	{
		return 0;
	}

	int totalShots = 0;

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active || !g_BossDamage[sessionIndex][entry].player.IsSamePersistentPlayer(client))
		{
			continue;
		}

		totalShots += g_BossDamage[sessionIndex][entry].shots;
	}

	return totalShots;
}

int Boss_GetDamageEntriesTotalDamage(int sessionIndex)
{
	int totalDamage = 0;

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active || g_BossDamage[sessionIndex][entry].damage <= 0)
		{
			continue;
		}

		totalDamage += g_BossDamage[sessionIndex][entry].damage;
	}

	return totalDamage;
}

int Boss_GetOtherDamage(int sessionIndex)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return 0;
	}

	int otherDamage = g_BossSessions[sessionIndex].totalDamage - Boss_GetDamageEntriesTotalDamage(sessionIndex);
	return otherDamage > 0 ? otherDamage : 0;
}

void Boss_FillWitchAssistData(int sessionIndex, int killer, int eventIndex)
{
	Boss_ConsolidateDamageEntries(sessionIndex);

	for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
	{
		if (!g_BossDamage[sessionIndex][entry].active
			|| g_BossDamage[sessionIndex][entry].damage <= 0
			|| g_BossDamage[sessionIndex][entry].player.IsSamePersistentPlayer(killer))
		{
			continue;
		}

		if (g_SkillEvents[eventIndex].assistsCount < L4D2_SKILLS_MAX_EVENT_ASSISTS)
		{
			int assistIndex = g_SkillEvents[eventIndex].assistsCount;
			g_SkillEvents[eventIndex].assists[assistIndex] = g_BossDamage[sessionIndex][entry].player;
			g_SkillEvents[eventIndex].assistDamage[assistIndex] = g_BossDamage[sessionIndex][entry].damage;
			g_SkillEvents[eventIndex].assistShots[assistIndex] = g_BossDamage[sessionIndex][entry].shots > 0 ? g_BossDamage[sessionIndex][entry].shots : 1;
			g_SkillEvents[eventIndex].assistsCount++;
		}
	}

	for (int pass = 0; pass < g_SkillEvents[eventIndex].assistsCount - 1; pass++)
	{
		for (int i = 0; i < g_SkillEvents[eventIndex].assistsCount - 1 - pass; i++)
		{
			if (g_SkillEvents[eventIndex].assistDamage[i] >= g_SkillEvents[eventIndex].assistDamage[i + 1])
			{
				continue;
			}

			L4D2PlayerRef refTemp;
			refTemp = g_SkillEvents[eventIndex].assists[i];
			int damageTemp = g_SkillEvents[eventIndex].assistDamage[i];
			int shotsTemp = g_SkillEvents[eventIndex].assistShots[i];

			g_SkillEvents[eventIndex].assists[i] = g_SkillEvents[eventIndex].assists[i + 1];
			g_SkillEvents[eventIndex].assistDamage[i] = g_SkillEvents[eventIndex].assistDamage[i + 1];
			g_SkillEvents[eventIndex].assistShots[i] = g_SkillEvents[eventIndex].assistShots[i + 1];

			g_SkillEvents[eventIndex].assists[i + 1] = refTemp;
			g_SkillEvents[eventIndex].assistDamage[i + 1] = damageTemp;
			g_SkillEvents[eventIndex].assistShots[i + 1] = shotsTemp;
		}
	}

	if (g_SkillEvents[eventIndex].assistsCount > 0)
	{
		g_SkillEvents[eventIndex].assister = g_SkillEvents[eventIndex].assists[0];
		g_SkillEvents[eventIndex].assisterDamage = g_SkillEvents[eventIndex].assistDamage[0];
		g_SkillEvents[eventIndex].assisterShots = g_SkillEvents[eventIndex].assistShots[0];
	}
}

// Witch event helpers.
void Boss_CreateWitchIncapEvent(int sessionIndex, int witch, int victim)
{
	if (!IsValidSurvivor(victim))
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_WitchIncap);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.client = witch;
	g_SkillEvents[eventIndex].actor.userid = 0;
	g_SkillEvents[eventIndex].actor.accountId = 0;
	g_SkillEvents[eventIndex].actor.bot = true;
	strcopy(g_SkillEvents[eventIndex].actor.name, sizeof(g_SkillEvents[eventIndex].actor.name), "Witch");
	strcopy(g_SkillEvents[eventIndex].actor.auth, sizeof(g_SkillEvents[eventIndex].actor.auth), "WITCH");

	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].startled = g_BossSessions[sessionIndex].witch.startled;
	g_SkillEvents[eventIndex].actor2 = g_BossSessions[sessionIndex].id;

	if (g_BossSessions[sessionIndex].lastHealth > 0)
	{
		g_SkillEvents[eventIndex].amount = g_BossSessions[sessionIndex].lastHealth;
	}

	Action result = API_FireSkillDetected(eventId, L4D2Skill_WitchIncap);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}
