#if defined _l4d2_player_skills_boss_tank_sp_included
	#endinput
#endif
#define _l4d2_player_skills_boss_tank_sp_included

void Boss_HookTankDamageClient(int client)
{
	if (client <= 0 || client > MaxClients || g_bBossTankDamageHooked[client])
	{
		return;
	}

	SDKHook(client, SDKHook_OnTakeDamagePost, Boss_OnTankTakeDamagePost);
	SDKHook(client, SDKHook_OnTakeDamage, Boss_OnClientTakeDamage);
	g_bBossTankDamageHooked[client] = true;
	Skills_Debug(PlayerSkillsDebug_Boss,
		"Hooked boss damage callbacks. client=%d userid=%d",
		client,
		IsClientInGame(client) ? GetClientUserId(client) : 0);
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
	CreateTimer(L4D2_SKILLS_TANK_BOT_CONTROL_CONFIRM_TIME, Boss_TimerConfirmPendingTankBotControl, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
}

static void Boss_QueuePendingTankTransitionFlush(int sessionIndex)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return;
	}

	DataPack pack = new DataPack();
	pack.WriteCell(sessionIndex);
	pack.WriteCell(g_BossSessions[sessionIndex].id);
	CreateTimer(L4D2_SKILLS_TANK_TRANSITION_FLUSH_TIME, Boss_TimerFlushPendingTankTransition, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
}

void Boss_ForcePendingTankBotControlNow(int sessionIndex, int tank)
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

bool Boss_TankSessionHasMeaningfulBotActivity(int sessionIndex)
{
	if (sessionIndex < 0
		|| sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| g_BossSessions[sessionIndex].id == 0
		|| g_BossSessions[sessionIndex].type != L4D2Boss_Tank)
	{
		return false;
	}

	return g_BossSessions[sessionIndex].totalDamage > 0
		|| g_BossSessions[sessionIndex].tank.punchesHit > 0
		|| g_BossSessions[sessionIndex].tank.punchDamage > 0
		|| g_BossSessions[sessionIndex].tank.hittablesHit > 0
		|| g_BossSessions[sessionIndex].tank.hittableDamage > 0
		|| g_BossSessions[sessionIndex].tank.incaps > 0
		|| g_BossSessions[sessionIndex].tank.ledgeHangs > 0;
}

bool Boss_PromotePendingTankBotControlForActivity(int sessionIndex, int tank, const char[] reason)
{
	if (sessionIndex < 0
		|| sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| !IsValidTank(tank)
		|| !IsFakeClient(tank)
		|| g_BossSessions[sessionIndex].id == 0
		|| g_BossSessions[sessionIndex].type != L4D2Boss_Tank
		|| !g_BossSessions[sessionIndex].tank.pendingBotControl
		|| g_BossSessions[sessionIndex].tank.pendingBotUserid != GetClientUserId(tank))
	{
		return false;
	}

	float startedAt = g_BossSessions[sessionIndex].tank.pendingBotStartedAt;
	if (startedAt <= 0.0)
	{
		startedAt = GetGameTime();
	}

	L4D2BossSession(sessionIndex).CancelPendingTankBotControl();
	L4D2BossSession(sessionIndex).UpdateOwnerSnapshot(tank);
	L4D2BossSession(sessionIndex).OpenTankControl(tank, startedAt);
	Skills_Debug(PlayerSkillsDebug_Boss,
		"Promoted pending Tank bot control from activity. session=%d userid=%d startedAt=%.3f reason=%s",
		g_BossSessions[sessionIndex].id,
		GetClientUserId(tank),
		startedAt,
		reason);
	return true;
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

void Boss_NormalizeTankControls(int sessionIndex)
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

Action Boss_TimerFlushPendingTankTransition(Handle timer, DataPack pack)
{
	pack.Reset();
	int sessionIndex = pack.ReadCell();
	int sessionId = pack.ReadCell();

	if (!Boss_IsValidPendingTankTransitionSession(g_iBossPendingTankTransitionSession)
		|| g_iBossPendingTankTransitionSession != sessionIndex
		|| sessionIndex < 0
		|| sessionIndex >= L4D2_SKILLS_MAX_BOSSES
		|| g_BossSessions[sessionIndex].id != sessionId)
	{
		return Plugin_Stop;
	}

	Boss_ClearPendingTankTransition();
	Skills_Debug(PlayerSkillsDebug_Boss,
		"Flushed pending Tank transition by timeout. session=%d tank_id=%d",
		g_BossSessions[sessionIndex].id,
		g_BossSessions[sessionIndex].tank.lifecycleId);
	Boss_FinalizeSessionImmediate(sessionIndex);
	return Plugin_Stop;
}

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

	int sessionIndex = Boss_EnsureTankSession(victim);
	if (sessionIndex == -1)
	{
		return;
	}

	L4D2BossSession(sessionIndex).RefreshOwner(victim);
	Boss_PromotePendingTankBotControlForActivity(sessionIndex, victim, "damage_taken");

	int previousHealth = g_BossSessions[sessionIndex].lastHealth;
	int currentHealth = GetClientHealth(victim);
	int healthDelta = previousHealth > 0 && currentHealth >= 0 ? previousHealth - currentHealth : 0;
	int roundedDamage = RoundToFloor(damage);
	if (roundedDamage <= 0)
	{
		if (healthDelta > 0)
		{
			Skills_Debug(PlayerSkillsDebug_Boss,
				"Tank damage post mismatch. session=%d tank=%d attacker=%d inflictor=%d raw=%.1f rounded=%d prev_hp=%d current_hp=%d delta=%d total=%d",
				g_BossSessions[sessionIndex].id,
				victim,
				attacker,
				inflictor,
				damage,
				roundedDamage,
				previousHealth,
				currentHealth,
				healthDelta,
				g_BossSessions[sessionIndex].totalDamage);
		}

		return;
	}

	int maxHealth = g_BossSessions[sessionIndex].maxHealth;
	if (maxHealth <= 0)
	{
		return;
	}

	if (g_BossSessions[sessionIndex].totalDamage + roundedDamage > maxHealth)
	{
		roundedDamage = maxHealth - g_BossSessions[sessionIndex].totalDamage;
	}

	if (roundedDamage > 0)
	{
		L4D2BossSession(sessionIndex).AddDamage(attacker, roundedDamage);
		Skills_Debug(PlayerSkillsDebug_Boss,
			"Tank damage recorded. session=%d tank=%d attacker=%d inflictor=%d raw=%.1f added=%d prev_hp=%d current_hp=%d delta=%d total=%d",
			g_BossSessions[sessionIndex].id,
			victim,
			attacker,
			inflictor,
			damage,
			roundedDamage,
			previousHealth,
			currentHealth,
			healthDelta,
			g_BossSessions[sessionIndex].totalDamage);
	}

	g_BossSessions[sessionIndex].lastHealth = currentHealth;
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

	Boss_PromotePendingTankBotControlForActivity(sessionIndex, attacker, "player_hurt");

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

	Boss_PromotePendingTankBotControlForActivity(sessionIndex, attacker, "ledge_hang");
	g_BossSessions[sessionIndex].tank.ledgeHangs++;
}

int Boss_EnsureTankSession(int client)
{
	if (IsValidClient(client))
	{
		Boss_HookTankDamageClient(client);
	}

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
	if (maxHealth <= 0)
	{
		return -1;
	}

	L4D2BossSession(slot).Start(L4D2Boss_Tank, client, userid, maxHealth);
	if (tankId > 0)
	{
		Boss_UpdateTankSessionTankControlMetadata(slot, tankId);
	}
	Boss_MaybeMergePendingTankTransitionIntoSession(slot);
	Skills_Debug(PlayerSkillsDebug_Boss, "Started Tank session. session=%d userid=%d client=%d maxhp=%d", g_BossSessions[slot].id, userid, client, maxHealth);
	return slot;
}

bool Boss_IsValidPendingTankTransitionSession(int sessionIndex)
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

void Boss_QueuePendingTankTransition(int sessionIndex)
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
	Boss_QueuePendingTankTransitionFlush(sessionIndex);
}

void Boss_MaybeMergePendingTankTransitionIntoSession(int targetSessionIndex)
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

void Boss_FlushPendingTankTransition()
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

void Boss_MergeTankSessionIntoActiveSession(int sourceSessionIndex, int targetSessionIndex)
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

	Boss_PromotePendingTankBotControlForActivity(sessionIndex, tank, "rock_throw");
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

	Boss_PromotePendingTankBotControlForActivity(sessionIndex, tank, "rock_hit");
	L4D2BossSession(sessionIndex).RecordTankRockHit();
}
