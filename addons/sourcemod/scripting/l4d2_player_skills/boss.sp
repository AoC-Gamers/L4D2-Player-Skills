#if defined _l4d2_player_skills_boss_included
	#endinput
#endif
#define _l4d2_player_skills_boss_included

// Boss session coordinator. This file keeps Tank/Witch lifecycle, damage-session
// finalization, and event emission for boss-related skills and summaries.

bool g_bBossTankDamageHooked[MAXPLAYERS + 1];

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
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			SDKUnhook(client, SDKHook_OnTakeDamagePost, Boss_OnTankTakeDamagePost);
		}

		g_bBossTankDamageHooked[client] = false;
	}

	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		L4D2BossSession(index).Reset();
	}
}

void Boss_Shutdown()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		Boss_UnhookTankDamageClient(client);
	}
}

// Client lifecycle and control-transfer flow.
void Boss_OnClientPutInServer(int client)
{
	Boss_HookTankDamageClient(client);

	if (client > 0 && client <= MaxClients)
	{
		for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
		{
			if (g_BossSessions[index].state == L4D2BossState_Active
				&& g_BossSessions[index].type == L4D2Boss_Tank
				&& g_BossSessions[index].userid == GetClientUserId(client))
			{
				L4D2BossSession(index).RefreshOwner(client);
			}
		}
	}
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
	g_bBossTankDamageHooked[client] = true;
}

void Boss_UnhookTankDamageClient(int client)
{
	if (client <= 0 || client > MaxClients || !g_bBossTankDamageHooked[client])
	{
		return;
	}

	SDKUnhook(client, SDKHook_OnTakeDamagePost, Boss_OnTankTakeDamagePost);
	g_bBossTankDamageHooked[client] = false;
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

	L4D2BossSession(sessionIndex).RefreshOwner(newtank);
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

	L4D2BossSession(sessionIndex).RefreshOwner(tank);
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

	L4D2BossSession(sessionIndex).RefreshOwner(tank);
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

	L4D2BossSession(sessionIndex).RefreshOwner(tank);
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

	L4D2BossSession(sessionIndex).RefreshOwner(tank);
	g_BossSessions[sessionIndex].tank.inStasis = false;
	g_BossSessions[sessionIndex].lastHealth = GetClientHealth(tank);
	Skills_Debug(PlayerSkillsDebug_Boss, "Tank left stasis. session=%d tank=%d", g_BossSessions[sessionIndex].id, tank);
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
				? L4D2TankSessionEnd_Wipe
				: L4D2TankSessionEnd_Escaped;
		}

		if (g_BossSessions[index].type == L4D2Boss_Tank)
		{
			int tankClient = GetClientOfUserId(g_BossSessions[index].userid);
			if (IsValidTank(tankClient))
			{
				g_BossSessions[index].lastHealth = GetClientHealth(tankClient);
				L4D2BossSession(index).RefreshOwner(tankClient);
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

	L4D2BossSession(sessionIndex).RefreshOwner(victim);

	Boss_CreateTankDeadEvent(sessionIndex, GetClientOfUserId(event.GetInt("attacker")));

	g_BossSessions[sessionIndex].lastHealth = 0;
	g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
	g_BossSessions[sessionIndex].tank.endReason = L4D2TankSessionEnd_Dead;
	Boss_FinalizeSession(sessionIndex);
}

void Boss_EventPlayerIncapacitatedStart(Event event)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));

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

	int sessionIndex = Boss_FindTankSessionByUserid(userid);
	if (sessionIndex != -1)
	{
		L4D2BossSession(sessionIndex).RefreshOwner(client);
		return sessionIndex;
	}

	sessionIndex = Boss_FindTankSessionByClient(client);
	if (sessionIndex != -1)
	{
		L4D2BossSession(sessionIndex).RefreshOwner(client);
		return sessionIndex;
	}

	int slot = Boss_FindFreeSession();
	if (slot == -1)
	{
		Skills_Debug(PlayerSkillsDebug_Boss, "No free boss session slot for Tank userid=%d", userid);
		return -1;
	}

	int maxHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Tank);
	L4D2BossSession(slot).Start(L4D2Boss_Tank, client, userid, maxHealth);
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
	}

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
		if (result < Plugin_Handled && !g_BossSessions[sessionIndex].printed)
		{
			Announce_BossDamage(sessionIndex);
		}
		else
		{
			if (!g_BossSessions[sessionIndex].printed)
			{
				g_BossSessions[sessionIndex].printed = true;
				g_BossSessions[sessionIndex].state = L4D2BossState_Printed;
			}
		}
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
