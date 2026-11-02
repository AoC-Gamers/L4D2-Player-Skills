#if defined _l4d2_player_skills_boss_queries_sp_included
	#endinput
#endif
#define _l4d2_player_skills_boss_queries_sp_included

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

int Boss_GetSkillEventAssistDamageTotal(int eventIndex)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return 0;
	}

	int totalAssistDamage = 0;
	for (int assistIndex = 0; assistIndex < g_SkillEvents[eventIndex].assistsCount; assistIndex++)
	{
		totalAssistDamage += g_SkillEvents[eventIndex].assistDamage[assistIndex];
	}

	return totalAssistDamage;
}
