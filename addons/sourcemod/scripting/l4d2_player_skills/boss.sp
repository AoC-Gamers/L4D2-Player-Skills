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
	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		L4D2BossSession(index).Reset();
	}

	for (int client = 1; client <= MaxClients; client++)
	{
		g_bBossTankDamageHooked[client] = false;
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
	g_BossSessions[sessionIndex].inStasis = false;
	g_BossSessions[sessionIndex].pendingOwner.Reset();
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
	g_BossSessions[sessionIndex].inStasis = enterStasis;
	g_BossSessions[sessionIndex].lastHealth = GetClientHealth(tank);

	int pendingPlayer = L4D_GetPendingTankPlayer();
	if (IsValidClient(pendingPlayer))
	{
		g_BossSessions[sessionIndex].pendingOwner.Capture(pendingPlayer);
	}
	else
	{
		g_BossSessions[sessionIndex].pendingOwner.Reset();
	}

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
	g_BossSessions[sessionIndex].inStasis = enterStasis;
	g_BossSessions[sessionIndex].lastHealth = GetClientHealth(tank);

	int pendingPlayer = L4D_GetPendingTankPlayer();
	if (IsValidClient(pendingPlayer))
	{
		g_BossSessions[sessionIndex].pendingOwner.Capture(pendingPlayer);
	}

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

	g_BossSessions[sessionIndex].inStasis = enterStasis;
	g_BossSessions[sessionIndex].pendingOwner.Reset();
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
	g_BossSessions[sessionIndex].inStasis = true;
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
	g_BossSessions[sessionIndex].inStasis = false;
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
			SDKHook(entity, SDKHook_OnTakeDamage, Boss_OnWitchTakeDamage);
			SDKHook(entity, SDKHook_OnTakeDamagePost, Boss_OnWitchTakeDamagePost);
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
	for (int index = 0; index < L4D2_SKILLS_MAX_BOSSES; index++)
	{
		if (g_BossSessions[index].id == 0 || g_BossSessions[index].state != L4D2BossState_Active)
		{
			continue;
		}

		g_BossSessions[index].state = L4D2BossState_Escaped;

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
	int survivorVictim = GetClientOfUserId(event.GetInt("userid"));
	if (Skills_IsEnabled() && g_bWitchPrintOnIncap && IsValidSurvivor(survivorVictim))
	{
		int witch = event.GetInt("attackerentid");
		if (IsWitchEntity(witch))
		{
			Boss_AnnounceWitchRemainingHealth(witch);
		}
	}

	if (Skills_IsEnabled() && IsValidSurvivor(survivorVictim))
	{
		int killer = GetClientOfUserId(event.GetInt("attacker"));
		if (IsValidTank(killer))
		{
			Boss_RecordTankKill(killer);
		}
	}

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

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	Boss_CreateTankDeadEvent(sessionIndex, attacker);

	g_BossSessions[sessionIndex].lastHealth = 0;
	g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
	Boss_FinalizeSession(sessionIndex);
}

void Boss_EventPlayerIncapacitatedStart(Event event)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (IsValidSurvivor(victim) && IsValidTank(attacker))
	{
		Boss_RecordTankIncap(attacker);
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

	int sessionIndex = Boss_FindWitchSessionByEntity(witch);
	if (sessionIndex == -1)
	{
		sessionIndex = Boss_EnsureWitchSession(witch);
	}

	if (sessionIndex == -1)
	{
		return;
	}

	// If the Witch session already produced a visible announce path (for example
	// the remaining-health summary triggered on incap), do not emit an additional
	// death-side announce for the same Witch lifecycle.
	if (g_BossSessions[sessionIndex].printed)
	{
		g_BossSessions[sessionIndex].lastHealth = 0;
		g_BossSessions[sessionIndex].state = L4D2BossState_Printed;
		return;
	}

	if (IsValidTank(killer))
	{
		Announce_WitchKilledByTank(sessionIndex, killer);
		g_BossSessions[sessionIndex].printed = true;
		g_BossSessions[sessionIndex].state = L4D2BossState_Printed;
		g_BossSessions[sessionIndex].lastHealth = 0;
		return;
	}

	if (IsValidSurvivor(killer) && g_BossSessions[sessionIndex].maxHealth > 0 && g_BossSessions[sessionIndex].totalDamage < g_BossSessions[sessionIndex].maxHealth)
	{
		L4D2BossSession(sessionIndex).AddDamage(killer, g_BossSessions[sessionIndex].maxHealth - g_BossSessions[sessionIndex].totalDamage);
	}

	Boss_CreateWitchDeadEvent(sessionIndex, killer);

	if (g_BossSessions[sessionIndex].crownDetected)
	{
		g_BossSessions[sessionIndex].lastHealth = 0;
		g_BossSessions[sessionIndex].printed = true;
		g_BossSessions[sessionIndex].state = L4D2BossState_Printed;
		return;
	}

	g_BossSessions[sessionIndex].lastHealth = 0;
	g_BossSessions[sessionIndex].state = L4D2BossState_Dead;
	Boss_FinalizeSession(sessionIndex);
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
	Skills_Debug(PlayerSkillsDebug_Boss, "Started Witch session. session=%d entity=%d maxhp=%d", g_BossSessions[slot].id, entity, maxHealth);
	return slot;
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

	if (sessionIndex == -1 || g_BossSessions[sessionIndex].printed)
	{
		return;
	}

	if (IsWitchEntity(witch))
	{
		g_BossSessions[sessionIndex].lastHealth = GetEntProp(witch, Prop_Data, "m_iHealth");
	}

	Announce_WitchDamage(sessionIndex, true);
	g_BossSessions[sessionIndex].printed = true;
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
		if (g_BossSessions[index].id == 0 || g_BossSessions[index].state != L4D2BossState_Active)
		{
			continue;
		}

		if (g_BossSessions[index].type == L4D2Boss_Witch
			&& (g_BossSessions[index].entity == entity || g_BossSessions[index].entRef == entRef))
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

		if (g_BossDamage[sessionIndex][entry].player.userid == GetClientUserId(attacker))
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
	g_SkillEvents[eventIndex].victim = g_BossSessions[sessionIndex].owner;
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

	g_BossSessions[sessionIndex].rocksThrown++;
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

	g_BossSessions[sessionIndex].rocksHit++;
}

void Boss_RecordTankIncap(int tank)
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

	g_BossSessions[sessionIndex].incaps++;
}

void Boss_RecordTankKill(int tank)
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

	g_BossSessions[sessionIndex].kills++;
}

bool Boss_DidTankWipe(int sessionIndex)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES)
	{
		return false;
	}

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidSurvivor(client))
		{
			continue;
		}

		if (IsPlayerAlive(client))
		{
			return false;
		}
	}

	return true;
}

void Boss_FinalizeSession(int sessionIndex)
{
	if (sessionIndex < 0 || sessionIndex >= L4D2_SKILLS_MAX_BOSSES || g_BossSessions[sessionIndex].id == 0)
	{
		return;
	}

	if (g_BossSessions[sessionIndex].printed)
	{
		return;
	}

	Action result = API_FireBossDamageFinalized(g_BossSessions[sessionIndex].id, g_BossSessions[sessionIndex].type);
	if (result < Plugin_Handled)
	{
		Announce_BossDamage(sessionIndex);
	}
	else
	{
		g_BossSessions[sessionIndex].printed = true;
		g_BossSessions[sessionIndex].state = L4D2BossState_Printed;
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

	g_BossSessions[sessionIndex].startled = victim > 0;

	if (IsValidClient(victim))
	{
		g_BossSessions[sessionIndex].harasser.Capture(victim);
	}

	Skills_Debug(PlayerSkillsDebug_Boss, "Witch harasser set. session=%d witch=%d victim=%d", g_BossSessions[sessionIndex].id, witch, victim);
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

	g_BossSessions[sessionIndex].lastHealthBeforeDamage = GetEntProp(witch, Prop_Data, "m_iHealth");
	g_BossSessions[sessionIndex].lastShotAttacker = attacker;
	g_BossSessions[sessionIndex].lastShotRawDamage = damage;
	g_BossSessions[sessionIndex].lastDamageType = damagetype;
	g_BossSessions[sessionIndex].lastShotIsShotgun = (damagetype & DMG_BUCKSHOT) != 0;

	float now = GetGameTime();
	bool sameBlast = g_BossSessions[sessionIndex].lastShotIsShotgun
		&& g_BossSessions[sessionIndex].lastBlastStartTime > 0.0
		&& (now - g_BossSessions[sessionIndex].lastBlastStartTime) <= L4D2_SKILLS_SHOTGUN_BLAST_TIME
		&& g_BossSessions[sessionIndex].lastShotAttacker == attacker;

	if (!sameBlast)
	{
		g_BossSessions[sessionIndex].lastBlastStartTime = now;
		g_BossSessions[sessionIndex].lastBlastDamage = 0;
		g_BossSessions[sessionIndex].lastBlastRawDamage = 0.0;
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

	g_BossSessions[sessionIndex].lastShotTime = GetGameTime();
	g_BossSessions[sessionIndex].lastShotAttacker = attacker;
	g_BossSessions[sessionIndex].lastShotDamage = effectiveDamage;
	g_BossSessions[sessionIndex].lastShotRawDamage = damage;
	g_BossSessions[sessionIndex].lastDamageType = damagetype;
	g_BossSessions[sessionIndex].lastShotIsShotgun = (damagetype & DMG_BUCKSHOT) != 0;

	if (g_BossSessions[sessionIndex].lastShotIsShotgun)
	{
		g_BossSessions[sessionIndex].lastBlastDamage += effectiveDamage;
		g_BossSessions[sessionIndex].lastBlastRawDamage += damage;
	}
	else
	{
		g_BossSessions[sessionIndex].lastBlastStartTime = 0.0;
		g_BossSessions[sessionIndex].lastBlastDamage = effectiveDamage;
		g_BossSessions[sessionIndex].lastBlastRawDamage = damage;
	}

	if (!IsValidSurvivor(attacker))
	{
		return;
	}

	if (effectiveDamage <= 0)
	{
		return;
	}

	L4D2BossSession(sessionIndex).AddDamage(attacker, effectiveDamage);

	int health = GetEntProp(witch, Prop_Data, "m_iHealth");
	g_BossSessions[sessionIndex].lastHealth = health > 0 ? health : 0;
}

void Boss_CreateWitchDeadEvent(int sessionIndex, int killer)
{
	if (!IsValidSurvivor(killer))
	{
		return;
	}

	float rawDamage = g_BossSessions[sessionIndex].lastBlastRawDamage;
	bool crown = g_BossSessions[sessionIndex].lastShotAttacker == killer
		&& g_BossSessions[sessionIndex].lastShotIsShotgun
		&& rawDamage >= float(g_BossSessions[sessionIndex].maxHealth);

	int actualDamage = crown ? g_BossSessions[sessionIndex].lastBlastDamage : g_BossSessions[sessionIndex].lastShotDamage;
	int chipDamage = g_BossSessions[sessionIndex].maxHealth - actualDamage;

	int eventId = Skills_CreateEvent(L4D2Skill_WitchDead);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(killer);
	g_SkillEvents[eventIndex].victim.client = g_BossSessions[sessionIndex].entity;
	g_SkillEvents[eventIndex].victim.userid = 0;
	g_SkillEvents[eventIndex].victim.accountId = 0;
	g_SkillEvents[eventIndex].victim.bot = true;
	strcopy(g_SkillEvents[eventIndex].victim.name, sizeof(g_SkillEvents[eventIndex].victim.name), "Witch");
	strcopy(g_SkillEvents[eventIndex].victim.auth, sizeof(g_SkillEvents[eventIndex].victim.auth), "WITCH");
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	g_SkillEvents[eventIndex].actorDamage = actualDamage;
	g_SkillEvents[eventIndex].damage = actualDamage;
	g_SkillEvents[eventIndex].chipDamage = chipDamage < 0 ? 0 : chipDamage;
	g_SkillEvents[eventIndex].shots = crown ? 1 : 0;
	g_SkillEvents[eventIndex].crown = crown;
	g_SkillEvents[eventIndex].startled = g_BossSessions[sessionIndex].startled;
	g_SkillEvents[eventIndex].actor2 = g_BossSessions[sessionIndex].id;

	if (crown)
	{
		g_BossSessions[sessionIndex].crownDetected = true;
		g_BossSessions[sessionIndex].crowner.Capture(killer);
	}

	if (g_BossSessions[sessionIndex].harasser.userid > 0)
	{
		g_SkillEvents[eventIndex].assister = g_BossSessions[sessionIndex].harasser;
	}

	Action result = API_FireSkillDetected(eventId, L4D2Skill_WitchDead);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
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
	g_SkillEvents[eventIndex].startled = g_BossSessions[sessionIndex].startled;
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
