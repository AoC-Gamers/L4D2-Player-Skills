// Private detector ownership: jockey

bool Detect_IsClientGrounded(int client)
{
	return client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& (GetEntityFlags(client) & FL_ONGROUND) != 0;
}

int Detect_GetClientGroundEntity(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return -1;
	}

	return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
}

float Detect_GetClientVerticalVelocity(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return 0.0;
	}

	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	return velocity[2];
}

float Detect_GetClientHorizontalVelocity(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return 0.0;
	}

	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	velocity[2] = 0.0;
	return GetVectorLength(velocity);
}

void Detect_LogJockeyLeapState(int jockey, const char[] stage)
{
	if (!Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		return;
	}

	float now = GetGameTime();
	float seenAt = (jockey > 0 && jockey <= MaxClients) ? g_fDetectJockeyLeapSeenAt[jockey] : 0.0;
	float age = seenAt > 0.0 ? now - seenAt : -1.0;
	bool validClient = jockey > 0 && jockey <= MaxClients && IsClientInGame(jockey);
	bool alive = validClient && IsPlayerAlive(jockey);
	int flags = validClient ? GetEntityFlags(jockey) : 0;
	bool onGround = Detect_IsClientGrounded(jockey);
	int groundEntity = Detect_GetClientGroundEntity(jockey);
	float velZ = Detect_GetClientVerticalVelocity(jockey);
	float velXY = Detect_GetClientHorizontalVelocity(jockey);
	bool effective = (jockey > 0 && jockey <= MaxClients) ? Detect_IsJockeyEffectivelyLeaping(jockey) : false;
	bool airborne = (jockey > 0 && jockey <= MaxClients) ? Detect_IsJockeyAirborneForSkeet(jockey) : false;
	bool active = (jockey > 0 && jockey <= MaxClients) ? Detect_IsJockeySkeetWindowActive(jockey) : false;
	bool qualityWindow = (jockey > 0 && jockey <= MaxClients) ? g_DetectSkeetQualityWindow[jockey].active : false;
	bool lethalAirborne = (jockey > 0 && jockey <= MaxClients) ? g_bDetectJockeyKilledAirborneLeaping[jockey] : false;

	Skills_Debug(PlayerSkillsDebug_Detect,
		"Jockey leap state. stage=%s jockey=%d valid=%d alive=%d state=%d effective=%d airborne=%d active=%d quality_window=%d lethal_airborne=%d onground=%d ground_ent=%d flags=%d vel_z=%.2f vel_xy=%.2f seen_at=%.3f age=%.3f",
		stage,
		jockey,
		validClient ? 1 : 0,
		alive ? 1 : 0,
		(jockey > 0 && jockey <= MaxClients && g_bDetectJockeyLeaping[jockey]) ? 1 : 0,
		effective ? 1 : 0,
		airborne ? 1 : 0,
		active ? 1 : 0,
		qualityWindow ? 1 : 0,
		lethalAirborne ? 1 : 0,
		onGround ? 1 : 0,
		groundEntity,
		flags,
		velZ,
		velXY,
		seenAt,
		age);
}

void Detect_SetJockeyLeaping(int jockey, bool state)
{
	g_bDetectJockeyLeaping[jockey] = state;
	if (state)
	{
		g_fDetectJockeyLeapSeenAt[jockey] = GetGameTime();
	}

	Detect_LogJockeyLeapState(jockey, state ? "set_true" : "set_false");
}

bool Detect_IsJockeyEffectivelyLeaping(int jockey)
{
	if (g_bDetectJockeyLeaping[jockey])
	{
		g_fDetectJockeyLeapSeenAt[jockey] = GetGameTime();
		return true;
	}

	return g_fDetectJockeyLeapSeenAt[jockey] > 0.0
		&& (GetGameTime() - g_fDetectJockeyLeapSeenAt[jockey]) <= L4D2_SKILLS_HUNTER_POUNCE_GRACE_TIME;
}

bool Detect_IsJockeyAirborneForSkeet(int jockey)
{
	return jockey > 0
		&& jockey <= MaxClients
		&& IsClientInGame(jockey)
		&& IsPlayerAlive(jockey)
		&& !Detect_IsClientGrounded(jockey);
}

bool Detect_IsJockeySkeetWindowActive(int jockey)
{
	return Detect_IsJockeyEffectivelyLeaping(jockey)
		&& Detect_IsJockeyAirborneForSkeet(jockey);
}

bool Detect_DidJockeyDieAirborneForSkeet(int jockey)
{
	return jockey > 0
		&& jockey <= MaxClients
		&& g_bDetectJockeyKilledAirborneLeaping[jockey];
}

void Detect_ResetJockeyLeapState(int jockey)
{
	Detect_LogJockeyLeapState(jockey, "reset_before");
	g_bDetectJockeyLeaping[jockey] = false;
	g_fDetectJockeyLeapSeenAt[jockey] = 0.0;
	g_bDetectJockeyKilledAirborneLeaping[jockey] = false;
	g_DetectLeap[jockey].Reset();
	g_DetectJockeyLastShove[jockey].Reset();
	Detect_CloseSkeetQualityWindow(jockey);
	Detect_LogJockeyLeapState(jockey, "reset_after");
}

void Detect_EventJockeyRideEnd(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int jockey = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	int rescuer = GetClientOfUserId(event.GetInt("rescuer"));
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"SpecialClear jockey_ride_end event. jockey=%d victim=%d rescuer=%d pin_victim=%d",
			jockey,
			victim,
			rescuer,
			jockey >= 1 && jockey <= MaxClients ? g_DetectPinRegistry.pinnedVictimByAttacker[jockey] : 0);
	}
}

void Detect_TryEmitJockeyMeleeSkeet(SkillsDeathObservation observation, int victim, int attacker, bool shouldEmitSiLifeKill)
{
	if (!IsValidZombieClass(victim, L4D2ZombieClass_Jockey) || !shouldEmitSiLifeKill || !IsValidSurvivor(attacker))
	{
		return;
	}

	char weapon[64];
	strcopy(weapon, sizeof(weapon), observation.weapon);
	Skills_Debug(PlayerSkillsDebug_Detect,
		"Jockey melee-skeet check. jockey=%d attacker=%d weapon=%s leaping=%d airborne=%d active=%d quality_window=%d damage=%d",
		victim,
		attacker,
		weapon,
		Detect_IsJockeyEffectivelyLeaping(victim) ? 1 : 0,
		Detect_IsJockeyAirborneForSkeet(victim) ? 1 : 0,
		Detect_IsJockeySkeetWindowActive(victim) ? 1 : 0,
		g_DetectSkeetQualityWindow[victim].active ? 1 : 0,
		observation.damage);
	Detect_LogJockeyLeapState(victim, "melee_check");
	if ((Detect_IsJockeySkeetWindowActive(victim) || Detect_DidJockeyDieAirborneForSkeet(victim)) && Detect_IsSkeetWeaponMelee(weapon))
	{
		int eventId = Skills_CreateEvent(L4D2Skill_JockeySkeetMelee);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(attacker);
			g_SkillEvents[eventIndex].victim.Capture(victim);
			g_SkillEvents[eventIndex].zombieClass = L4D2ZombieClass_Jockey;
			g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
			g_SkillEvents[eventIndex].damage = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Jockey);
			g_SkillEvents[eventIndex].actorDamage = g_SkillEvents[eventIndex].damage;
			g_SkillEvents[eventIndex].shots = 1;
			int assistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, victim, attacker);
			g_SkillEvents[eventIndex].perfect = g_SkillEvents[eventIndex].chipDamage == 0
				&& assistsFound == 0;
			Detect_LogSkeetQuality(victim, attacker, "JockeySkeetMelee", "melee_emit", eventIndex);

			Action result = API_FireSkillDetected(eventId, L4D2Skill_JockeySkeetMelee);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}

		Detect_MarkSiLifeKillSuppressed(victim);
	}
}

void Detect_TryEmitJockeyRangedSkeet(SkillsDeathObservation observation, int victim, int attacker, bool shouldEmitSiLifeKill)
{
	if (!IsValidZombieClass(victim, L4D2ZombieClass_Jockey) || !shouldEmitSiLifeKill || !IsValidSurvivor(attacker))
	{
		return;
	}

	Detect_LogJockeyLeapState(victim, "ranged_check");
	if (!Detect_IsJockeySkeetWindowActive(victim) && !Detect_DidJockeyDieAirborneForSkeet(victim))
	{
		return;
	}

	char weapon[64];
	strcopy(weapon, sizeof(weapon), observation.weapon);
	L4D2WeaponId weaponId = view_as<L4D2WeaponId>(Skills_GetWeaponIdFromEventName(weapon));
	bool headshot = Detect_ResolveHeadshot(victim, attacker, observation.headshot);
	bool grenadeLauncher = weaponId == L4D2WeaponId_GrenadeLauncher;
	bool shotgun = Skills_IsShotgunWeaponId(view_as<int>(weaponId));
	bool sniperHeadshot = headshot && (
		weaponId == L4D2WeaponId_HuntingRifle
		|| weaponId == L4D2WeaponId_SniperMilitary
		|| weaponId == L4D2WeaponId_SniperAWP
		|| weaponId == L4D2WeaponId_SniperScout
		|| weaponId == L4D2WeaponId_PistolMagnum);
	if (!grenadeLauncher && !sniperHeadshot && !shotgun)
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_JockeySkeet);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	int maxHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Jockey);
	g_SkillEvents[eventIndex].actor.Capture(attacker);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = L4D2ZombieClass_Jockey;
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	g_SkillEvents[eventIndex].damage = maxHealth;
	g_SkillEvents[eventIndex].actorDamage = Detect_GetSkeetQualityWindowDamageByAttacker(victim, attacker);
	g_SkillEvents[eventIndex].shots = Detect_GetSkeetQualityWindowShotsByAttacker(victim, attacker);
	g_SkillEvents[eventIndex].headshot = headshot;
	g_SkillEvents[eventIndex].sniper = sniperHeadshot;
	g_SkillEvents[eventIndex].grenadeLauncher = grenadeLauncher;
	g_SkillEvents[eventIndex].actorWeaponId = view_as<int>(weaponId);
	int assistsFound = Detect_FillSkeetQualityFromLifeSnapshot(eventIndex, victim, attacker);
	g_SkillEvents[eventIndex].perfect = g_SkillEvents[eventIndex].shots == 1
		&& g_SkillEvents[eventIndex].chipDamage == 0
		&& assistsFound == 0;
	Detect_LogSkeetQuality(victim, attacker, "JockeySkeet", "ranged_emit", eventIndex);

	Action result = API_FireSkillDetected(eventId, L4D2Skill_JockeySkeet);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	Detect_MarkSiLifeKillSuppressed(victim);
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
	float threshold = g_cvJockeyHighLeapHeight != null ? g_cvJockeyHighLeapHeight.FloatValue : L4D2_SKILLS_DEFAULT_JOCKEY_HIGH_LEAP_HEIGHT;
	bool reportedHigh = height >= threshold;
	if (!reportedHigh)
	{
		Detect_ResetJockeyLeapState(jockey);
		g_DetectLeap[jockey].Reset();
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_JockeyHighLeap);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		g_SkillEvents[eventIndex].actor.Capture(jockey);
		g_SkillEvents[eventIndex].victim.Capture(survivor);
		g_SkillEvents[eventIndex].height = height;
		g_SkillEvents[eventIndex].reportedHigh = true;
		Detect_AttachPinnedInfectedAssistToEvent(eventIndex, jockey, survivor);

		Action result = API_FireSkillDetected(eventId, L4D2Skill_JockeyHighLeap);
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
		"Jockey punched event. jockey=%d attacker=%d islunging=%d effective_leaping=%d",
		jockey,
		attacker,
		isLunging ? 1 : 0,
		(jockey > 0 && jockey <= MaxClients && Detect_IsJockeyEffectivelyLeaping(jockey)) ? 1 : 0);
	Detect_LogJockeyLeapState(jockey, "punched_event");
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
		"Jockey killed event. jockey=%d attacker=%d weapon=%s effective_leaping=%d",
		jockey,
		attacker,
		weapon,
		(jockey > 0 && jockey <= MaxClients && Detect_IsJockeyEffectivelyLeaping(jockey)) ? 1 : 0);
	Detect_LogJockeyLeapState(jockey, "killed_event");
}

Action Timer_DetectJockeyGroundedCheck(Handle timer, any context)
{
	int userid = Detect_ReadDeferredClientUserId(view_as<DataPack>(context));
	if (userid <= 0)
	{
		return Plugin_Stop;
	}

	int client = GetClientOfUserId(userid);
	if (!IsValidZombieClass(client, L4D2ZombieClass_Jockey) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	if (client > 0)
	{
		Detect_LogJockeyLeapState(client, "grounded_timer_tick");
	}
	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		return Plugin_Continue;
	}

	Detect_SetJockeyLeaping(client, false);
	Detect_LogJockeyLeapState(client, "grounded_timer_stop");

	return Plugin_Stop;
}
