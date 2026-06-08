#if defined _l4d2_player_skills_detect_rocks_included
	#endinput
#endif
#define _l4d2_player_skills_detect_rocks_included

void Detect_ClearRockSlot(int slot)
{
	if (slot < 0 || slot >= L4D2_SKILLS_MAX_ROCKS || !g_DetectRocks[slot].active)
	{
		return;
	}

	int entity = EntRefToEntIndex(g_DetectRocks[slot].entityRef);
	if (entity > MaxClients && IsValidEntity(entity))
	{
		SDKUnhook(entity, SDKHook_TraceAttack, Detect_TraceAttack_Rock);
	}

	if (g_iDetectActiveRocks > 0)
	{
		g_iDetectActiveRocks--;
	}

	g_DetectRocks[slot].Reset();
}

void Detect_OnTankRockReleasePost(int tank, int rock)
{
	if (!Skills_IsEnabled() || !IsValidEntity(rock) || rock <= MaxClients)
	{
		return;
	}

	int slot = Detect_FindRockSlotByTank(tank);
	if (slot == -1)
	{
		slot = Detect_FindFreeRockSlot();
	}

	if (slot == -1)
	{
		return;
	}

	Detect_ClearRockSlot(slot);
	g_DetectRocks[slot].active = true;
	g_DetectRocks[slot].entityRef = EntIndexToEntRef(rock);
	g_DetectRocks[slot].tank.Capture(tank);
	g_DetectRocks[slot].releasedAt = GetGameTime();
	g_iDetectActiveRocks++;
	Boss_OnTankRockReleased(tank);
	SDKHook(rock, SDKHook_TraceAttack, Detect_TraceAttack_Rock);
}

void Detect_OnTankRockBounceTouchPost(int tank, int rock, int entity)
{
	if (tank < -1)
	{
		return;
	}

	int slot = Detect_FindRockSlot(rock);
	if (slot == -1)
	{
		return;
	}

	if (IsValidSurvivor(entity))
	{
		if (!g_DetectRocks[slot].hit)
		{
			int tankClient = g_DetectRocks[slot].tank.ResolveClient();
			if (tankClient > 0)
			{
				Boss_OnTankRockConnected(tankClient);
			}
			Detect_EmitTankRockHit(g_DetectRocks[slot].tank, entity);
			g_DetectRocks[slot].hit = true;
		}
	}

	g_DetectRocks[slot].touched = true;
}

void Detect_OnTankRockDetonate(int tank, int rock)
{
	if (tank < -1)
	{
		return;
	}

	Detect_QueueRockFinalize(rock);
}

int Detect_FindRockSlot(int rock)
{
	if (rock <= MaxClients || g_iDetectActiveRocks <= 0)
	{
		return -1;
	}

	int rockRef = rock > 0 ? EntIndexToEntRef(rock) : INVALID_ENT_REFERENCE;
	for (int slot = 0; slot < L4D2_SKILLS_MAX_ROCKS; slot++)
	{
		if (g_DetectRocks[slot].active && g_DetectRocks[slot].entityRef == rockRef)
		{
			return slot;
		}
	}

	return -1;
}

int Detect_FindFreeRockSlot()
{
	for (int slot = 0; slot < L4D2_SKILLS_MAX_ROCKS; slot++)
	{
		if (!g_DetectRocks[slot].active)
		{
			return slot;
		}
	}

	return -1;
}

int Detect_FindRockSlotByTank(int tank)
{
	if (!IsValidTank(tank) || g_iDetectActiveRocks <= 0)
	{
		return -1;
	}

	for (int slot = 0; slot < L4D2_SKILLS_MAX_ROCKS; slot++)
	{
		if (!g_DetectRocks[slot].active)
		{
			continue;
		}

		if (g_DetectRocks[slot].tank.IsSameRuntimePlayer(tank)
			|| g_DetectRocks[slot].tank.IsSamePersistentPlayer(tank))
		{
			return slot;
		}
	}

	return -1;
}

void Detect_FinalizeRock(int rock)
{
	int slot = Detect_FindRockSlot(rock);
	if (slot == -1)
	{
		return;
	}

	if (!g_DetectRocks[slot].touched
		&& !g_DetectRocks[slot].hit
		&& g_DetectRocks[slot].totalDamage > 0
		&& IsValidSurvivor(g_DetectRocks[slot].lastShooter))
	{
		Detect_EmitTankRockSkeet(g_DetectRocks[slot].lastShooter, g_DetectRocks[slot].tank);
	}

	Detect_ClearRockSlot(slot);
}

void Detect_QueueRockFinalize(int rock)
{
	if (rock <= MaxClients || g_iDetectActiveRocks <= 0)
	{
		return;
	}

	int slot = Detect_FindRockSlot(rock);
	if (slot == -1 || g_DetectRocks[slot].finalizeQueued)
	{
		return;
	}

	g_DetectRocks[slot].finalizeQueued = true;
	CreateTimer(L4D2_SKILLS_ROCK_FINALIZE_DELAY, Detect_TimerFinalizeRock, g_DetectRocks[slot].entityRef, TIMER_FLAG_NO_MAPCHANGE);
}

Action Detect_TimerFinalizeRock(Handle timer, any rockRef)
{
	if (g_iDetectActiveRocks <= 0)
	{
		return Plugin_Stop;
	}

	int rock = EntRefToEntIndex(rockRef);
	if (rock == INVALID_ENT_REFERENCE)
	{
		for (int slot = 0; slot < L4D2_SKILLS_MAX_ROCKS; slot++)
		{
			if (g_DetectRocks[slot].active && g_DetectRocks[slot].entityRef == rockRef)
			{
				if (!g_DetectRocks[slot].touched
					&& !g_DetectRocks[slot].hit
					&& g_DetectRocks[slot].totalDamage > 0
					&& IsValidSurvivor(g_DetectRocks[slot].lastShooter))
				{
					Detect_EmitTankRockSkeet(g_DetectRocks[slot].lastShooter, g_DetectRocks[slot].tank);
				}

				Detect_ClearRockSlot(slot);
				break;
			}
		}

		return Plugin_Stop;
	}

	Detect_FinalizeRock(rock);
	return Plugin_Stop;
}

void Detect_MarkTankRockHit(int tank, int survivor)
{
	int slot = Detect_FindRockSlotByTank(tank);
	if (slot == -1)
	{
		return;
	}

	g_DetectRocks[slot].touched = true;
	if (!g_DetectRocks[slot].hit)
	{
		int tankClient = g_DetectRocks[slot].tank.ResolveClient();
		if (tankClient > 0)
		{
			Boss_OnTankRockConnected(tankClient);
		}
		Detect_EmitTankRockHit(g_DetectRocks[slot].tank, survivor);
		g_DetectRocks[slot].hit = true;
	}
}

Action Detect_TraceAttack_Rock(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!IsValidSurvivor(attacker))
	{
		return Plugin_Continue;
	}

	int slot = Detect_FindRockSlot(victim);
	if (slot == -1 || g_DetectRocks[slot].touched || g_DetectRocks[slot].hit)
	{
		return Plugin_Continue;
	}

	int roundedDamage = RoundToFloor(damage);
	if (roundedDamage > 0)
	{
		g_DetectRocks[slot].totalDamage += roundedDamage;
		g_DetectRocks[slot].lastShooter = attacker;
	}

	return Plugin_Continue;
}

void Detect_EmitTankRockSkeet(int shooter, L4D2PlayerRef tank)
{
	int eventId = Skills_CreateEvent(L4D2Skill_TankRockSkeet);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(shooter);
	g_SkillEvents[eventIndex].victim = tank;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_TankRockSkeet);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_EmitTankRockHit(L4D2PlayerRef tank, int survivor)
{
	int eventId = Skills_CreateEvent(L4D2Skill_TankRockHit);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor = tank;
	g_SkillEvents[eventIndex].victim.Capture(survivor);

	Action result = API_FireSkillDetected(eventId, L4D2Skill_TankRockHit);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}
