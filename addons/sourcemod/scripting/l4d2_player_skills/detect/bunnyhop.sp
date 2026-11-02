// Private detector ownership: bunnyhop

Action Detect_TimerCheckHop(Handle timer, any context)
{
	int userid = Detect_ReadDeferredClientUserId(view_as<DataPack>(context));
	if (userid <= 0)
	{
		return Plugin_Stop;
	}

	if (!Skills_IsRoundLive())
	{
		return Plugin_Stop;
	}

	int client = GetClientOfUserId(userid);
	if (!IsValidSurvivor(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		g_DetectHop[client].hopCheck = true;
		Detect_QueueClientTimer(L4D2_SKILLS_HOPEND_CHECK_TIME, Detect_TimerCheckHopStreak, userid, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

Action Detect_TimerCheckHopStreak(Handle timer, any context)
{
	int userid = Detect_ReadDeferredClientUserId(view_as<DataPack>(context));
	if (userid <= 0)
	{
		return Plugin_Stop;
	}

	if (!Skills_IsRoundLive())
	{
		return Plugin_Stop;
	}

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
		Detect_QueueClientTimer(L4D2_SKILLS_HOP_CHECK_TIME, Detect_TimerCheckHop, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Detect_ResetBHop(int client)
{
	if (client < 1 || client > MaxClients)
	{
		return;
	}

	g_DetectHop[client].Reset();
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
