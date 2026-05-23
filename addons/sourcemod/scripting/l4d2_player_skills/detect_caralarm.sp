#if defined _l4d2_player_skills_detect_caralarm_included
	#endinput
#endif
#define _l4d2_player_skills_detect_caralarm_included

void Detect_FormatEntityKey(int entity, char[] buffer, int maxlen)
{
	FormatEx(buffer, maxlen, "%x", entity);
}

void Detect_RemoveCarAlarmTracking(int entity)
{
	if (g_smDetectCarAlarmTargets == null || g_smDetectCarGlassParents == null || g_smDetectCarPendingSurvivor == null)
	{
		return;
	}

	char key[16];
	Detect_FormatEntityKey(entity, key, sizeof(key));
	g_smDetectCarGlassParents.Remove(key);
	g_smDetectCarPendingSurvivor.Remove(key);
	if (g_smDetectCarPendingReason != null)
	{
		g_smDetectCarPendingReason.Remove(key);
	}
	if (g_smDetectCarPendingInfected != null)
	{
		g_smDetectCarPendingInfected.Remove(key);
	}
	if (g_smDetectCarPendingFlags != null)
	{
		g_smDetectCarPendingFlags.Remove(key);
	}
}

void Detect_OnSpawn_CarAlarm(int entity)
{
	if (!IsValidEntity(entity) || g_smDetectCarAlarmTargets == null)
	{
		return;
	}

	char target[64];
	GetEntPropString(entity, Prop_Data, "m_iName", target, sizeof(target));
	if (target[0] != '\0')
	{
		g_smDetectCarAlarmTargets.SetValue(target, entity);
	}
}

void Detect_OnSpawn_CarGlass(int entity)
{
	if (!IsValidEntity(entity) || g_smDetectCarAlarmTargets == null || g_smDetectCarGlassParents == null)
	{
		return;
	}

	char parentName[64];
	GetEntPropString(entity, Prop_Data, "m_iParent", parentName, sizeof(parentName));
	if (parentName[0] == '\0')
	{
		return;
	}

	int parentEntity = -1;
	if (!g_smDetectCarAlarmTargets.GetValue(parentName, parentEntity) || !IsValidEntity(parentEntity))
	{
		return;
	}

	char glassKey[16];
	Detect_FormatEntityKey(entity, glassKey, sizeof(glassKey));
	g_smDetectCarGlassParents.SetValue(glassKey, parentEntity);
}

Action Detect_OnTakeDamage_CarAlarm(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidSurvivor(attacker))
	{
		return Plugin_Continue;
	}

	Detect_RecordCarAlarmAttempt(victim, attacker, inflictor, damage, damagetype, false, false);
	return Plugin_Continue;
}

Action Detect_OnTakeDamage_CarGlass(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidSurvivor(attacker) || g_smDetectCarGlassParents == null)
	{
		return Plugin_Continue;
	}

	char glassKey[16];
	Detect_FormatEntityKey(victim, glassKey, sizeof(glassKey));

	int parentEntity = -1;
	if (!g_smDetectCarGlassParents.GetValue(glassKey, parentEntity) || !IsValidEntity(parentEntity))
	{
		return Plugin_Continue;
	}

	Detect_RecordCarAlarmAttempt(parentEntity, attacker, inflictor, damage, damagetype, false, true);
	return Plugin_Continue;
}

Action Detect_OnTouch_CarAlarm(int entity, int client)
{
	if (!IsValidSurvivor(client))
	{
		return Plugin_Continue;
	}

	Detect_RecordCarAlarmAttempt(entity, client, 0, 0.0, DMG_CLUB, true, false);
	return Plugin_Continue;
}

Action Detect_OnTouch_CarGlass(int entity, int client)
{
	if (!IsValidSurvivor(client) || g_smDetectCarGlassParents == null)
	{
		return Plugin_Continue;
	}

	char glassKey[16];
	Detect_FormatEntityKey(entity, glassKey, sizeof(glassKey));

	int parentEntity = -1;
	if (!g_smDetectCarGlassParents.GetValue(glassKey, parentEntity) || !IsValidEntity(parentEntity))
	{
		return Plugin_Continue;
	}

	Detect_RecordCarAlarmAttempt(parentEntity, client, 0, 0.0, DMG_CLUB, true, true);
	return Plugin_Continue;
}

void Detect_RecordCarAlarmAttempt(int entity, int survivor, int inflictor, float damage, int damagetype, bool touched, bool throughGlass)
{
	if (!IsValidSurvivor(survivor) || g_smDetectCarPendingSurvivor == null || g_smDetectCarPendingReason == null || g_smDetectCarPendingInfected == null || g_smDetectCarPendingFlags == null)
	{
		return;
	}

	char key[16];
	Detect_FormatEntityKey(entity, key, sizeof(key));
	g_smDetectCarPendingSurvivor.SetValue(key, survivor);
	g_smDetectCarPendingInfected.SetValue(key, 0);

	int flags = throughGlass ? CARFLAG_INDIRECT : 0;
	int dominator = L4D2_GetSpecialInfectedDominatingMe(survivor);
	if (IsValidInfected(dominator))
	{
		flags |= CARFLAG_FORCED;
		g_smDetectCarPendingInfected.SetValue(key, dominator);
	}
	g_smDetectCarPendingFlags.SetValue(key, flags);

	if (touched)
	{
		g_smDetectCarPendingReason.SetValue(key, view_as<int>(L4D2CarAlarm_Touched));
		CreateTimer(0.01, Detect_TimerCheckCarAlarm, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	if (damagetype & DMG_BLAST)
	{
		flags |= CARFLAG_INDIRECT;
		g_smDetectCarPendingFlags.SetValue(key, flags);

		if (IsValidZombieClass(inflictor, L4D2ZombieClass_Boomer))
		{
			g_smDetectCarPendingReason.SetValue(key, view_as<int>(L4D2CarAlarm_Boomer));
			g_smDetectCarPendingInfected.SetValue(key, inflictor);
		}
		else
		{
			g_smDetectCarPendingReason.SetValue(key, view_as<int>(L4D2CarAlarm_Explosion));
		}

		CreateTimer(0.01, Detect_TimerCheckCarAlarm, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	if (damage == 0.0 && (damagetype & DMG_CLUB || damagetype & DMG_SLASH) && !(damagetype & DMG_SLOWBURN))
	{
		g_smDetectCarPendingReason.SetValue(key, view_as<int>(L4D2CarAlarm_Touched));
		CreateTimer(0.01, Detect_TimerCheckCarAlarm, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	g_smDetectCarPendingReason.SetValue(key, view_as<int>(L4D2CarAlarm_Hit));
	CreateTimer(0.01, Detect_TimerCheckCarAlarm, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

Action Detect_TimerCheckCarAlarm(Handle timer, any entityRef)
{
	int entity = EntRefToEntIndex(entityRef);
	if (entity == INVALID_ENT_REFERENCE || g_smDetectCarPendingSurvivor == null || g_smDetectCarPendingReason == null || g_smDetectCarPendingInfected == null || g_smDetectCarPendingFlags == null)
	{
		return Plugin_Stop;
	}

	char key[16];
	Detect_FormatEntityKey(entity, key, sizeof(key));

	int survivor = 0;
	if (!g_smDetectCarPendingSurvivor.GetValue(key, survivor))
	{
		return Plugin_Stop;
	}

	int pendingReason = view_as<int>(L4D2CarAlarm_Unknown);
	g_smDetectCarPendingReason.GetValue(key, pendingReason);

	int pendingInfected = 0;
	g_smDetectCarPendingInfected.GetValue(key, pendingInfected);

	int pendingFlags = 0;
	g_smDetectCarPendingFlags.GetValue(key, pendingFlags);

	g_smDetectCarPendingSurvivor.Remove(key);
	g_smDetectCarPendingReason.Remove(key);
	g_smDetectCarPendingInfected.Remove(key);
	g_smDetectCarPendingFlags.Remove(key);
	if ((GetGameTime() - g_fDetectLastCarAlarm) >= L4D2_SKILLS_CARALARM_WINDOW || !IsValidSurvivor(survivor))
	{
		return Plugin_Stop;
	}

	int infected = 0;
	if (pendingReason == view_as<int>(L4D2CarAlarm_Boomer) && IsValidZombieClass(pendingInfected, L4D2ZombieClass_Boomer))
	{
		infected = pendingInfected;
	}
	else if (IsValidInfected(pendingInfected))
	{
		infected = pendingInfected;
	}
	else
	{
		int dominator = L4D2_GetSpecialInfectedDominatingMe(survivor);
		if (IsValidInfected(dominator))
		{
			infected = dominator;
		}
	}

	int eventId = Skills_CreateEvent(L4D2Skill_CarAlarmTriggered);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return Plugin_Stop;
	}

	g_SkillEvents[eventIndex].actor.Capture(survivor);
	if (IsValidInfected(infected))
	{
		g_SkillEvents[eventIndex].victim.Capture(infected);
		g_SkillEvents[eventIndex].zombieClass = view_as<int>(GetClientZombieClass(infected));
	}
	g_SkillEvents[eventIndex].reason = pendingReason;
	g_SkillEvents[eventIndex].indirect = (pendingFlags & CARFLAG_INDIRECT) != 0;
	g_SkillEvents[eventIndex].forced = (pendingFlags & CARFLAG_FORCED) != 0;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_CarAlarmTriggered);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	return Plugin_Stop;
}
