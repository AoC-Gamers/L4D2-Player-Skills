// Private detector ownership: movement dispatch

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
		Detect_OpenSkeetQualityWindow(client);
		if (g_DetectHunterDamageSnapshot[client].lastHealth <= 0)
		{
			g_DetectHunterDamageSnapshot[client].lastHealth = GetClientHealth(client);
		}
		GetClientAbsOrigin(client, g_DetectLeap[client].origin);
		g_DetectLeap[client].originSet = true;
		Detect_QueueClientTimer(0.5, Timer_DetectHunterGroundedCheck, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrEqual(ability, "ability_charge") && IsValidZombieClass(client, L4D2ZombieClass_Charger))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger charge opened from ability_use. charger=%d ability=%s",
			client,
			ability);
		Detect_StartChargerCharge(client);
	}
	else if (StrEqual(ability, "ability_leap") && IsValidZombieClass(client, L4D2ZombieClass_Jockey))
	{
		Detect_ResetJockeyLeapState(client);
		Detect_SetJockeyLeaping(client, true);
		Detect_OpenSkeetQualityWindow(client);
		GetClientAbsOrigin(client, g_DetectLeap[client].origin);
		g_DetectLeap[client].originSet = true;
		Detect_QueueClientTimer(0.5, Timer_DetectJockeyGroundedCheck, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
		if (!g_DetectSkeetQualityWindow[client].active)
		{
			Detect_OpenSkeetQualityWindow(client);
		}
		Detect_SetJockeyLeaping(client, true);
		Detect_LogJockeyLeapState(client, "jump_apex_open");
		Detect_QueueClientTimer(0.5, Timer_DetectJockeyGroundedCheck, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}
