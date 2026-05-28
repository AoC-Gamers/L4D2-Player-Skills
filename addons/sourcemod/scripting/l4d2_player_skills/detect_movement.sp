#if defined _l4d2_player_skills_detect_movement_included
	#endinput
#endif
#define _l4d2_player_skills_detect_movement_included

Action Detect_TimerBoomerVomitCheck(Handle timer, any userid)
{
	int boomer = GetClientOfUserId(userid);
	if (!IsValidZombieClass(boomer, L4D2ZombieClass_Boomer))
	{
		return Plugin_Stop;
	}

	int amount = g_DetectBoomer[boomer].vomitHits;
	g_DetectBoomer[boomer].vomitHits = 0;
	if (amount <= 0)
	{
		return Plugin_Stop;
	}

	Detect_EmitBoomerVomitLanded(boomer, amount);
	return Plugin_Stop;
}

Action Detect_TimerCheckHop(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidSurvivor(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		g_DetectHop[client].hopCheck = true;
		CreateTimer(L4D2_SKILLS_HOPEND_CHECK_TIME, Detect_TimerCheckHopStreak, userid, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

Action Detect_TimerCheckHopStreak(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidSurvivor(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	if (g_DetectHop[client].hopCheck && g_DetectHop[client].hops > 0)
	{
		Detect_FinishBHopStreak(client);
	}

	return Plugin_Stop;
}

void Detect_EventAbilityUse(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(client, L4D2ZombieClass_Hunter) && !IsValidZombieClass(client, L4D2ZombieClass_Jockey) && !IsValidZombieClass(client, L4D2ZombieClass_Charger))
	{
		return;
	}

	char ability[64];
	event.GetString("ability", ability, sizeof(ability));
	if (StrEqual(ability, "ability_lunge"))
	{
		Detect_ResetHunterPounceState(client);
		Detect_SetHunterPouncing(client, true);
		if (g_DetectHunterDamageSnapshot[client].lastHealth <= 0)
		{
			g_DetectHunterDamageSnapshot[client].lastHealth = GetClientHealth(client);
		}
		GetClientAbsOrigin(client, g_DetectLeap[client].origin);
		g_DetectLeap[client].originSet = true;
		CreateTimer(0.5, Timer_DetectHunterGroundedCheck, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(ability, "ability_charge") && IsValidZombieClass(client, L4D2ZombieClass_Charger))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger charge opened from ability_use. charger=%d ability=%s",
			client,
			ability);
		Detect_SetChargerCharging(client, true);
	}
	else if (StrEqual(ability, "ability_leap") && IsValidZombieClass(client, L4D2ZombieClass_Jockey))
	{
		Detect_ResetJockeyLeapState(client);
		Detect_SetJockeyLeaping(client, true);
		GetClientAbsOrigin(client, g_DetectLeap[client].origin);
		g_DetectLeap[client].originSet = true;
		CreateTimer(0.5, Timer_DetectJockeyGroundedCheck, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Detect_EventPlayerJump(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(client) || !IsPlayerAlive(client))
	{
		return;
	}

	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	velocity[2] = 0.0;

	float newSpeed = GetVectorLength(velocity);
	g_DetectHop[client].hopCheck = false;

	if (!g_DetectHop[client].isHopping)
	{
		float minInitSpeed = g_cvDetectBHopMinInitSpeed != null ? g_cvDetectBHopMinInitSpeed.FloatValue : 150.0;
		if (newSpeed >= minInitSpeed)
		{
			g_DetectHop[client].topVelocity = newSpeed;
			g_DetectHop[client].isHopping = true;
			g_DetectHop[client].hops = 0;
		}
	}
	else
	{
		float oldSpeed = GetVectorLength(g_DetectHop[client].lastHop);
		float keepSpeed = g_cvDetectBHopContSpeed != null ? g_cvDetectBHopContSpeed.FloatValue : 300.0;
		if ((newSpeed - oldSpeed) > L4D2_SKILLS_HOP_ACCEL_THRESH || newSpeed >= keepSpeed)
		{
			g_DetectHop[client].hops++;
			if (newSpeed > g_DetectHop[client].topVelocity)
			{
				g_DetectHop[client].topVelocity = newSpeed;
			}
		}
		else
		{
			Detect_FinishBHopStreak(client);
		}
	}

	g_DetectHop[client].lastHop[0] = velocity[0];
	g_DetectHop[client].lastHop[1] = velocity[1];
	g_DetectHop[client].lastHop[2] = velocity[2];

	if (g_DetectHop[client].hops != 0)
	{
		CreateTimer(L4D2_SKILLS_HOP_CHECK_TIME, Detect_TimerCheckHop, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Detect_EventPlayerJumpApex(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(client, L4D2ZombieClass_Hunter) && !IsValidZombieClass(client, L4D2ZombieClass_Jockey))
	{
		if (IsValidSurvivor(client) && g_DetectHop[client].isHopping)
		{
			float velocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
			velocity[2] = 0.0;
			float length = GetVectorLength(velocity);
			if (length > g_DetectHop[client].topVelocity)
			{
				g_DetectHop[client].topVelocity = length;
			}
		}
		return;
	}

	GetClientAbsOrigin(client, g_DetectLeap[client].origin);
	g_DetectLeap[client].originSet = true;

	if (IsValidZombieClass(client, L4D2ZombieClass_Jockey))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Jockey leap opened from jump_apex. jockey=%d",
			client);
		Detect_SetJockeyLeaping(client, true);
		CreateTimer(0.5, Timer_DetectJockeyGroundedCheck, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Detect_EventJockeyRide(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int jockey = GetClientOfUserId(event.GetInt("userid"));
	int survivor = GetClientOfUserId(event.GetInt("victim"));
	if (!IsValidZombieClass(jockey, L4D2ZombieClass_Jockey) || !IsValidSurvivor(survivor))
	{
		return;
	}

	float height = Detect_GetLeapHeight(jockey, survivor);
	float threshold = g_cvJockeyHighPounceHeight != null ? g_cvJockeyHighPounceHeight.FloatValue : L4D2_SKILLS_DEFAULT_JOCKEY_HIGH_POUNCE_HEIGHT;
	bool reportedHigh = height >= threshold;
	if (!reportedHigh)
	{
		Detect_ResetJockeyLeapState(jockey);
		g_DetectLeap[jockey].Reset();
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_JockeyHighPounce);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		g_SkillEvents[eventIndex].actor.Capture(jockey);
		g_SkillEvents[eventIndex].victim.Capture(survivor);
		g_SkillEvents[eventIndex].height = height;
		g_SkillEvents[eventIndex].reportedHigh = true;

		Action result = API_FireSkillDetected(eventId, L4D2Skill_JockeyHighPounce);
		if (result < Plugin_Handled)
		{
			Announce_Skill(eventId);
		}
	}

	Detect_ResetJockeyLeapState(jockey);
}

void Detect_EventJockeyPunched(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int jockey = GetClientOfUserId(event.GetInt("jockeyuserid"));
	bool isLunging = event.GetBool("islunging");

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Jockey punched event. jockey=%d attacker=%d islunging=%d tracked_leaping=%d",
		jockey,
		attacker,
		isLunging ? 1 : 0,
		(jockey > 0 && jockey <= MaxClients && Detect_IsJockeyEffectivelyLeaping(jockey)) ? 1 : 0);
}

void Detect_EventJockeyKilled(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int jockey = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Jockey killed event. jockey=%d attacker=%d weapon=%s tracked_leaping=%d",
		jockey,
		attacker,
		weapon,
		(jockey > 0 && jockey <= MaxClients && Detect_IsJockeyEffectivelyLeaping(jockey)) ? 1 : 0);
}

Action Timer_DetectHunterGroundedCheck(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		return Plugin_Continue;
	}

	if (client > 0)
	{
		Detect_SetHunterPouncing(client, false);
	}

	return Plugin_Stop;
}

Action Timer_DetectJockeyGroundedCheck(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		return Plugin_Continue;
	}

	if (client > 0)
	{
		Detect_SetJockeyLeaping(client, false);
	}

	return Plugin_Stop;
}

void Detect_ResetBoomer(int boomer)
{
	if (boomer < 1 || boomer > MaxClients)
	{
		return;
	}

	g_DetectBoomer[boomer].Reset();
}

void Detect_ResetBHop(int client)
{
	if (client < 1 || client > MaxClients)
	{
		return;
	}

	g_DetectHop[client].Reset();
}

void Detect_EmitBoomerVomitLanded(int boomer, int amount)
{
	if (!IsValidZombieClass(boomer, L4D2ZombieClass_Boomer) || amount <= 0)
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_BoomerVomitLanded);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(boomer);
	g_SkillEvents[eventIndex].amount = amount;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_BoomerVomitLanded);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_FinishBHopStreak(int client)
{
	if (client < 1 || client > MaxClients)
	{
		return;
	}

	int minStreak = g_cvDetectBHopMinStreak != null ? g_cvDetectBHopMinStreak.IntValue : 3;
	if (g_DetectHop[client].hops >= minStreak)
	{
		int eventId = Skills_CreateEvent(L4D2Skill_BunnyHopStreak);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(client);
			g_SkillEvents[eventIndex].streak = g_DetectHop[client].hops;
			g_SkillEvents[eventIndex].maxVelocity = g_DetectHop[client].topVelocity;

			Action result = API_FireSkillDetected(eventId, L4D2Skill_BunnyHopStreak);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}
	}

	Detect_ResetBHop(client);
}
