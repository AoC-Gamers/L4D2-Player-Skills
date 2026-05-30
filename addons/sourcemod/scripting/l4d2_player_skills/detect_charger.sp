#if defined _l4d2_player_skills_detect_charger_included
	#endinput
#endif
#define _l4d2_player_skills_detect_charger_included

void Detect_ResetCharger(int charger)
{
	if (charger < 1 || charger > MaxClients)
	{
		return;
	}

	g_DetectChargerDamageSnapshot[charger].Reset();
	g_bDetectChargerCharging[charger] = false;
	g_fDetectChargerChargeSeenAt[charger] = 0.0;
	g_bDetectChargerKilledMelee[charger] = false;
	g_bDetectChargerKilledCharging[charger] = false;
	g_DetectChargerBowl[charger].Reset();
	g_DetectChargerClaw[charger].Reset();
}

void Detect_SetChargerCharging(int charger, bool state)
{
	if (charger < 1 || charger > MaxClients)
	{
		return;
	}

	g_bDetectChargerCharging[charger] = state;
	if (state)
	{
		g_fDetectChargerChargeSeenAt[charger] = GetGameTime();
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger charge state. charger=%d state=%d seen_at=%.3f",
			charger,
			state ? 1 : 0,
			g_fDetectChargerChargeSeenAt[charger]);
	}
}

bool Detect_IsChargerEffectivelyCharging(int charger)
{
	if (charger < 1 || charger > MaxClients)
	{
		return false;
	}

	if (g_bDetectChargerCharging[charger])
	{
		g_fDetectChargerChargeSeenAt[charger] = GetGameTime();
		return true;
	}

	return g_fDetectChargerChargeSeenAt[charger] > 0.0
		&& (GetGameTime() - g_fDetectChargerChargeSeenAt[charger]) <= L4D2_SKILLS_CHARGER_LEVEL_GRACE_TIME;
}

void Detect_EventChargerChargeStart(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int charger = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		return;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger charge start event. charger=%d",
			charger);
	}

	g_DetectChargerBowl[charger].Reset();
	Detect_SetChargerCharging(charger, true);
}

void Detect_EventChargerChargeEnd(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int charger = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		return;
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger charge end event. charger=%d",
			charger);
	}

	Detect_SetChargerCharging(charger, false);
}

void Detect_EventChargerKilled(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int charger = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	bool melee = event.GetBool("melee");
	bool charging = event.GetBool("charging");
	g_bDetectChargerKilledMelee[charger] = melee;
	g_bDetectChargerKilledCharging[charger] = charging;
	if (charging)
	{
		g_fDetectChargerChargeSeenAt[charger] = GetGameTime();
	}

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger killed event. charger=%d attacker=%d melee=%d charging=%d state_charging=%d effective_charging=%d",
			charger,
			attacker,
			melee ? 1 : 0,
			charging ? 1 : 0,
			(charger > 0 && charger <= MaxClients && Detect_IsChargerCharging(charger)) ? 1 : 0,
			(charger > 0 && charger <= MaxClients && Detect_IsChargerEffectivelyCharging(charger)) ? 1 : 0);
	}
}

void Detect_EventChargerCarryStart(Event event)
{
	if (!Skills_IsEnabled())
	{
		return;
	}

	int charger = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger carry start event. charger=%d victim=%d state_charging=%d effective_charging=%d",
			charger,
			victim,
			(charger > 0 && charger <= MaxClients && Detect_IsChargerCharging(charger)) ? 1 : 0,
			(charger > 0 && charger <= MaxClients && Detect_IsChargerEffectivelyCharging(charger)) ? 1 : 0);
	}

	if (IsValidZombieClass(charger, L4D2ZombieClass_Charger) && IsValidSurvivor(victim))
	{
		g_DetectChargerBowl[charger].active = true;
		g_DetectChargerBowl[charger].emitted = false;
		g_DetectChargerBowl[charger].carriedVictim = victim;
		g_DetectChargerBowl[charger].impactedCount = 0;
	}
}

bool Detect_RecordChargerBowlImpact(int charger, int victim)
{
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger)
		|| !IsValidSurvivor(victim)
		|| !g_DetectChargerBowl[charger].active
		|| g_DetectChargerBowl[charger].carriedVictim == victim)
	{
		return false;
	}

	for (int i = 0; i < g_DetectChargerBowl[charger].impactedCount && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		if (g_DetectChargerBowl[charger].impactedVictims[i] == victim)
		{
			return false;
		}
	}

	if (g_DetectChargerBowl[charger].impactedCount >= L4D2_SKILLS_MAX_EVENT_ASSISTS)
	{
		return false;
	}

	g_DetectChargerBowl[charger].impactedVictims[g_DetectChargerBowl[charger].impactedCount] = victim;
	g_DetectChargerBowl[charger].impactedCount++;
	return true;
}

void Detect_RecordChargerClawHit(int charger, int victim, int damage)
{
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger)
		|| !IsValidSurvivor(victim)
		|| damage <= 0)
	{
		return;
	}

	g_DetectChargerClaw[charger].totalHits++;
	g_DetectChargerClaw[charger].totalDamage += damage;
	g_DetectChargerClaw[charger].victimHits[victim]++;
	g_DetectChargerClaw[charger].victimDamage[victim] += damage;

	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger claw hit recorded. charger=%d victim=%d damage=%d total_hits=%d total_damage=%d",
			charger,
			victim,
			damage,
			g_DetectChargerClaw[charger].totalHits,
			g_DetectChargerClaw[charger].totalDamage);
	}
}

void Detect_RecordChargerClawHitFromDamage(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if (!Skills_IsEnabled()
		|| !IsValidSurvivor(victim)
		|| !IsValidZombieClass(attacker, L4D2ZombieClass_Charger))
	{
		return;
	}

	int minHits = g_cvChargerClawPrintMinHits != null ? g_cvChargerClawPrintMinHits.IntValue : 0;
	if (minHits <= 0)
	{
		return;
	}

	if (Detect_IsChargerEffectivelyCharging(attacker)
		|| g_DetectPinRegistry.pinnedClassByAttacker[attacker] == view_as<int>(L4D2ZombieClass_Charger)
		|| g_DetectPinRegistry.pinnedVictimByAttacker[attacker] > 0)
	{
		return;
	}

	if (inflictor > 0 && inflictor != attacker)
	{
		return;
	}

	bool meleeLikeDamage = (damagetype & DMG_CLUB) != 0 || (damagetype & DMG_SLASH) != 0;
	if (!meleeLikeDamage && inflictor != attacker)
	{
		return;
	}

	int appliedDamage = RoundToFloor(damage);
	if (appliedDamage <= 0)
	{
		return;
	}

	Detect_RecordChargerClawHit(attacker, victim, appliedDamage);
}

bool Detect_ShouldAnnounceChargerClawSummary(int charger)
{
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		return false;
	}

	int minHits = g_cvChargerClawPrintMinHits != null ? g_cvChargerClawPrintMinHits.IntValue : 0;
	return minHits > 0 && g_DetectChargerClaw[charger].totalHits >= minHits;
}

int Detect_GetChargerClawTotalHits(int charger)
{
	return (charger >= 1 && charger <= MaxClients) ? g_DetectChargerClaw[charger].totalHits : 0;
}

int Detect_GetChargerClawTotalDamage(int charger)
{
	return (charger >= 1 && charger <= MaxClients) ? g_DetectChargerClaw[charger].totalDamage : 0;
}

int Detect_GetChargerClawVictimHits(int charger, int victim)
{
	if (charger < 1 || charger > MaxClients || victim < 1 || victim > MaxClients)
	{
		return 0;
	}

	return g_DetectChargerClaw[charger].victimHits[victim];
}

int Detect_GetChargerClawVictimDamage(int charger, int victim)
{
	if (charger < 1 || charger > MaxClients || victim < 1 || victim > MaxClients)
	{
		return 0;
	}

	return g_DetectChargerClaw[charger].victimDamage[victim];
}

int Detect_GetChargerBowlImpactCount(int charger)
{
	if (charger < 1 || charger > MaxClients)
	{
		return 0;
	}

	return g_DetectChargerBowl[charger].impactedCount;
}

int Detect_GetChargerBowlImpactVictim(int charger, int index)
{
	if (charger < 1 || charger > MaxClients
		|| index < 0
		|| index >= g_DetectChargerBowl[charger].impactedCount
		|| index >= L4D2_SKILLS_MAX_EVENT_ASSISTS)
	{
		return 0;
	}

	return g_DetectChargerBowl[charger].impactedVictims[index];
}

void Detect_CheckChargerBowl(int charger)
{
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger)
		|| !g_DetectChargerBowl[charger].active
		|| g_DetectChargerBowl[charger].emitted
		|| g_DetectChargerBowl[charger].impactedCount < 2)
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_ChargerBowl);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(charger);
	g_SkillEvents[eventIndex].zombieClass = view_as<int>(L4D2ZombieClass_Charger);
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	g_SkillEvents[eventIndex].amount = g_DetectChargerBowl[charger].impactedCount;
	if (IsValidSurvivor(g_DetectChargerBowl[charger].carriedVictim))
	{
		g_SkillEvents[eventIndex].victim.Capture(g_DetectChargerBowl[charger].carriedVictim);
		g_SkillEvents[eventIndex].pinVictim.Capture(g_DetectChargerBowl[charger].carriedVictim);
	}

	g_DetectChargerBowl[charger].emitted = true;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_ChargerBowl);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_ResetChargeTrack(int survivor)
{
	if (survivor < 1 || survivor > MaxClients)
	{
		return;
	}

	g_DetectChargeVictim[survivor].Reset();
}

void Detect_MarkChargeMapDamage(int victim, int damage, int damageType, bool byTrigger)
{
	if (victim < 1 || victim > MaxClients || damage <= 0)
	{
		return;
	}

	g_DetectChargeVictim[victim].mapDamage += damage;
	g_DetectChargeVictim[victim].lastMapDamageTime = GetGameTime();

	if (damageType & DMG_FALL)
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_FALL;
	}

	if (damageType & DMG_DROWN)
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_DROWN;
	}

	if (byTrigger)
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_TRIGGER;
	}

	if (damage >= L4D2_SKILLS_CHARGE_MIN_MAP_DAMAGE)
	{
		g_DetectChargeVictim[victim].flags |= DCFLAG_HURTLOTS;
	}
}

bool Detect_HasRecentChargeMapDamage(int victim)
{
	return victim >= 1
		&& victim <= MaxClients
		&& g_DetectChargeVictim[victim].mapDamage >= L4D2_SKILLS_CHARGE_MIN_MAP_DAMAGE
		&& g_DetectChargeVictim[victim].lastMapDamageTime > 0.0
		&& (GetGameTime() - g_DetectChargeVictim[victim].lastMapDamageTime) <= L4D2_SKILLS_CHARGE_MAP_RECHECK_WINDOW;
}

void Detect_RecordChargeVictim(int charger, int victim, bool wasCarried)
{
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger) || !IsValidSurvivor(victim))
	{
		return;
	}

	int assister = g_DetectPinRegistry.pinnerByVictim[victim];
	if (!IsValidInfected(assister) || assister == charger)
	{
		assister = L4D2_GetSpecialInfectedDominatingMe(victim);
		if (!IsValidInfected(assister) || assister == charger)
		{
			assister = 0;
		}
	}

	g_DetectChargeVictim[victim].charger = charger;
	g_DetectChargeVictim[victim].assister = assister;
	g_DetectChargeVictim[victim].wasCarried = wasCarried;
	g_DetectChargeVictim[victim].setupEmitted = false;
	g_DetectChargeVictim[victim].startTime = GetGameTime();
	GetClientAbsOrigin(victim, g_DetectChargeVictim[victim].startOrigin);
	g_DetectChargeVictim[victim].flags = 0;
	g_DetectChargeVictim[victim].mapDamage = 0;
	g_DetectChargeVictim[victim].lastMapDamageTime = 0.0;
	g_DetectChargeVictim[victim].incapTime = 0.0;
}

float Detect_GetChargeVerticalDrop(int victim)
{
	if (!IsValidSurvivor(victim))
	{
		return 0.0;
	}

	float currentOrigin[3];
	GetClientAbsOrigin(victim, currentOrigin);
	return g_DetectChargeVictim[victim].startOrigin[2] - currentOrigin[2];
}

bool Detect_IsChargerDeathSetupEligible(int victim, bool incapped, bool ledgeHang)
{
	if (!IsValidSurvivor(victim))
	{
		return false;
	}

	if (ledgeHang)
	{
		return false;
	}

	if (!incapped)
	{
		return false;
	}

	if ((g_DetectChargeVictim[victim].flags & DCFLAG_DEADLY) != 0)
	{
		return false;
	}

	float height = Detect_GetChargeVerticalDrop(victim);
	float threshold = g_cvDetectDeathSetupHeight != null ? g_cvDetectDeathSetupHeight.FloatValue : 100.0;
	return height >= threshold;
}

void Detect_EmitChargerLedgeHang(int victim)
{
	if (!IsValidSurvivor(victim) || g_DetectChargeVictim[victim].setupEmitted)
	{
		return;
	}

	int charger = g_DetectChargeVictim[victim].charger;
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		return;
	}

	float startTime = g_DetectChargeVictim[victim].startTime;
	if (startTime <= 0.0 || (GetGameTime() - startTime) > L4D2_SKILLS_CHARGE_TRACK_WINDOW)
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_ChargerLedgeHang);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(charger);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = view_as<int>(L4D2ZombieClass_Charger);
	g_SkillEvents[eventIndex].wasCarried = g_DetectChargeVictim[victim].wasCarried;
	g_SkillEvents[eventIndex].ledgeHang = true;
	g_SkillEvents[eventIndex].height = Detect_GetChargeVerticalDrop(victim);

	g_DetectChargeVictim[victim].setupEmitted = true;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_ChargerLedgeHang);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

void Detect_EmitChargerDeathSetup(int victim, bool incapped, bool ledgeHang)
{
	if (!IsValidSurvivor(victim) || g_DetectChargeVictim[victim].setupEmitted)
	{
		return;
	}

	int charger = g_DetectChargeVictim[victim].charger;
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		return;
	}

	float startTime = g_DetectChargeVictim[victim].startTime;
	if (startTime <= 0.0 || (GetGameTime() - startTime) > L4D2_SKILLS_CHARGE_TRACK_WINDOW)
	{
		return;
	}

	if (!Detect_IsChargerDeathSetupEligible(victim, incapped, ledgeHang))
	{
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_ChargerDeathSetup);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(charger);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = view_as<int>(L4D2ZombieClass_Charger);
	g_SkillEvents[eventIndex].wasCarried = g_DetectChargeVictim[victim].wasCarried;
	g_SkillEvents[eventIndex].incapped = incapped;
	g_SkillEvents[eventIndex].ledgeHang = ledgeHang;
	g_SkillEvents[eventIndex].height = Detect_GetChargeVerticalDrop(victim);

	g_DetectChargeVictim[victim].setupEmitted = true;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_ChargerDeathSetup);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}

Action Detect_TimerEmitChargerDeathSetup(Handle timer, any userid)
{
	int victim = GetClientOfUserId(userid);
	if (!IsValidSurvivor(victim))
	{
		return Plugin_Stop;
	}

	g_DetectChargeVictim[victim].setupQueued = false;
	if (g_DetectChargeVictim[victim].setupEmitted || !IsPlayerAlive(victim))
	{
		return Plugin_Stop;
	}

	bool ledgeHang = (g_DetectChargeVictim[victim].flags & DCFLAG_LEDGE) != 0;
	bool incapped = (g_DetectChargeVictim[victim].flags & DCFLAG_INCAP) != 0;
	Detect_EmitChargerDeathSetup(victim, incapped, ledgeHang);
	return Plugin_Stop;
}

void Detect_CheckChargerInstaKill(Event event, int victim)
{
	int charger = g_DetectChargeVictim[victim].charger;
	if (!IsValidZombieClass(charger, L4D2ZombieClass_Charger))
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	float startTime = g_DetectChargeVictim[victim].startTime;
	bool extendedChargeWindow = g_DetectChargeVictim[victim].incapTime > 0.0
		|| (g_DetectChargeVictim[victim].flags & (DCFLAG_INCAP | DCFLAG_LEDGE)) != 0;
	float maxTrackWindow = extendedChargeWindow ? L4D2_SKILLS_CHARGE_INCAP_WINDOW : L4D2_SKILLS_CHARGE_TRACK_WINDOW;
	if (startTime <= 0.0 || (GetGameTime() - startTime) > maxTrackWindow)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsValidInfected(attacker) && attacker != charger)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	if (attacker == charger
		&& (StrEqual(weapon, "charger_claw")
			|| StrEqual(weapon, "charger_pummel")
			|| StrEqual(weapon, "charger_impact")))
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	if ((g_DetectChargeVictim[victim].flags & DCFLAG_KILLEDBYOTHER) != 0)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	float deathPos[3];
	GetClientAbsOrigin(victim, deathPos);

	float height = g_DetectChargeVictim[victim].startOrigin[2] - deathPos[2];
	float threshold = g_cvDetectInstaKillHeight != null ? g_cvDetectInstaKillHeight.FloatValue : 400.0;
	bool recentMapDamage = Detect_HasRecentChargeMapDamage(victim);
	bool mapDeathSignal = (g_DetectChargeVictim[victim].flags & (DCFLAG_FALL | DCFLAG_DROWN | DCFLAG_TRIGGER | DCFLAG_DEADLY | DCFLAG_LEDGE)) != 0;
	bool chargeIncapContext = (g_DetectChargeVictim[victim].flags & DCFLAG_INCAP) != 0;
	if ((g_DetectChargeVictim[victim].flags & DCFLAG_LEDGE) != 0)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	if (height < threshold && !recentMapDamage && !chargeIncapContext)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	if (!recentMapDamage
		&& attacker <= 0
		&& !mapDeathSignal
		&& !StrEqual(weapon, "world")
		&& !StrEqual(weapon, "trigger_hurt")
		&& !StrEqual(weapon, "worldspawn"))
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	int eventId = Skills_CreateEvent(L4D2Skill_ChargerInstaKill);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		Detect_ResetChargeTrack(victim);
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(charger);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = view_as<int>(L4D2ZombieClass_Charger);
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	g_SkillEvents[eventIndex].height = height;
	g_SkillEvents[eventIndex].distance = GetVectorDistance(g_DetectChargeVictim[victim].startOrigin, deathPos);
	g_SkillEvents[eventIndex].wasCarried = g_DetectChargeVictim[victim].wasCarried;
	g_SkillEvents[eventIndex].damage = g_DetectChargeVictim[victim].mapDamage;
	g_SkillEvents[eventIndex].incapped = chargeIncapContext;
	g_SkillEvents[eventIndex].ledgeHang = (g_DetectChargeVictim[victim].flags & DCFLAG_LEDGE) != 0;
	g_SkillEvents[eventIndex].fatalFall = (g_DetectChargeVictim[victim].flags & DCFLAG_FALL) != 0;
	g_SkillEvents[eventIndex].deadlySlam = (g_DetectChargeVictim[victim].flags & DCFLAG_DEADLY) != 0;
	if (IsValidInfected(g_DetectChargeVictim[victim].assister) && g_DetectChargeVictim[victim].assister != charger)
	{
		g_SkillEvents[eventIndex].assistScope = L4D2SkillAssistScope_SkillWindow;
		g_SkillEvents[eventIndex].assists[0].Capture(g_DetectChargeVictim[victim].assister);
		g_SkillEvents[eventIndex].assistsCount = 1;
		g_SkillEvents[eventIndex].assister = g_SkillEvents[eventIndex].assists[0];
	}

	Action result = API_FireSkillDetected(eventId, L4D2Skill_ChargerInstaKill);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	Detect_ResetChargeTrack(victim);
}

bool Detect_IsChargerCharging(int charger)
{
	int abilityEnt = GetEntPropEnt(charger, Prop_Send, "m_customAbility");
	return IsValidEntity(abilityEnt) && GetEntProp(abilityEnt, Prop_Send, "m_isCharging") != 0;
}

void Detect_FillChargerLevelPriorDamage(int eventIndex, int victim, int attacker, int chipDamage)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS)
	{
		return;
	}

	int assistDamageTotal = 0;
	for (int i = 0; i < g_SkillEvents[eventIndex].assistsCount && i < L4D2_SKILLS_MAX_EVENT_ASSISTS; i++)
	{
		assistDamageTotal += g_SkillEvents[eventIndex].assistDamage[i];
	}

	int actorChipDamage = Detect_GetSiLifePreviousDamageByAttacker(victim, attacker);
	int actorChipShots = Detect_GetSiLifePreviousShotsByAttacker(victim, attacker);
	int inferredChipDamage = actorChipDamage + assistDamageTotal;
	if (chipDamage > inferredChipDamage)
	{
		inferredChipDamage = chipDamage;
	}

	g_SkillEvents[eventIndex].actorChipDamage = actorChipDamage;
	g_SkillEvents[eventIndex].actorChipShots = actorChipShots;
	g_SkillEvents[eventIndex].chipDamage = inferredChipDamage;
}

void Detect_HandleChargerHurt(int victim, int attacker, int damageType, int appliedDamage, int postHealth)
{
	if (appliedDamage <= 0)
	{
		return;
	}

	bool meleeDamage = (damageType & DMG_CLUB) != 0 || (damageType & DMG_SLASH) != 0 || g_bDetectChargerKilledMelee[victim];
	bool chargingRaw = Detect_IsChargerCharging(victim);
	bool chargingEffective = Detect_IsChargerEffectivelyCharging(victim) || g_bDetectChargerKilledCharging[victim];
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger level check. charger=%d attacker=%d applied=%d post=%d damagetype=%d melee=%d charging_raw=%d charging_effective=%d health_before=%d raw=%.1f",
			victim,
			attacker,
			appliedDamage,
			postHealth,
			damageType,
			meleeDamage ? 1 : 0,
			chargingRaw ? 1 : 0,
			chargingEffective ? 1 : 0,
			g_DetectChargerDamageSnapshot[victim].lastHealthBeforeDamage,
			g_DetectChargerDamageSnapshot[victim].lastRawDamage);
	}

	bool deadNow = !IsPlayerAlive(victim) || postHealth <= 1;
	if (postHealth <= 1)
	{
		postHealth = 0;
	}

	if (deadNow
		&& meleeDamage
		&& (chargingRaw || chargingEffective))
	{
		int chargerHealthBeforeDamage = g_DetectChargerDamageSnapshot[victim].lastHealthBeforeDamage > 0
			? g_DetectChargerDamageSnapshot[victim].lastHealthBeforeDamage
			: g_DetectChargerDamageSnapshot[victim].lastHealth;
		int chargerBaselineHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Charger);
		int chipDamage = chargerBaselineHealth - chargerHealthBeforeDamage;
		if (chipDamage < 0)
		{
			chipDamage = 0;
		}

		float rawDamage = g_DetectChargerDamageSnapshot[victim].lastRawDamage;
		if (g_DetectChargerDamageSnapshot[victim].lastAttacker != attacker || !(g_DetectChargerDamageSnapshot[victim].lastDamageType & (DMG_CLUB | DMG_SLASH)))
		{
			rawDamage = float(chargerHealthBeforeDamage);
		}

		int chargerHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Charger);
		bool qualifiesAtBaseline = rawDamage >= float(chargerHealth);

		int eventId = Skills_CreateEvent(L4D2Skill_ChargerLevel);
		int eventIndex = Skills_GetEventIndex(eventId);
		if (eventIndex != -1)
		{
			g_SkillEvents[eventIndex].actor.Capture(attacker);
			g_SkillEvents[eventIndex].victim.Capture(victim);
			g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
			g_SkillEvents[eventIndex].damage = chargerHealthBeforeDamage;
			g_SkillEvents[eventIndex].actorDamage = chargerHealthBeforeDamage;
			g_SkillEvents[eventIndex].chipDamage = chipDamage;
			g_SkillEvents[eventIndex].shots = 1;
			int assistsFound = Detect_WriteSiTrackAssistsToEventAsSkillWindow(eventIndex, victim, attacker);
			Detect_FillChargerLevelPriorDamage(eventIndex, victim, attacker, chipDamage);
			g_SkillEvents[eventIndex].perfect = (g_SkillEvents[eventIndex].chipDamage == 0) && assistsFound == 0;

			Action result = API_FireSkillDetected(eventId, L4D2Skill_ChargerLevel);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}

		Detect_MarkSiLifeKillSuppressed(victim);
		if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
		{
			Skills_Debug(PlayerSkillsDebug_Detect,
				"Charger level classified. charger=%d attacker=%d pre=%d chip=%d qualifies_at_baseline=%d perfect=%d",
				victim,
				attacker,
				chargerHealthBeforeDamage,
				g_SkillEvents[eventIndex].chipDamage,
				qualifiesAtBaseline ? 1 : 0,
				g_SkillEvents[eventIndex].perfect ? 1 : 0);
		}
	}

	if (postHealth > 0)
	{
		g_DetectChargerDamageSnapshot[victim].lastHealth = postHealth;
	}
	else
	{
		g_DetectChargerDamageSnapshot[victim].lastHealth = 0;
		Detect_SetChargerCharging(victim, false);
		g_bDetectChargerKilledMelee[victim] = false;
		g_bDetectChargerKilledCharging[victim] = false;
	}
}

bool Detect_TryEmitChargerLevelFromDeath(int victim, int attacker)
{
	if (!IsValidZombieClass(victim, L4D2ZombieClass_Charger) || !IsValidSurvivor(attacker))
	{
		return false;
	}

	if (!g_bDetectChargerKilledMelee[victim] || !g_bDetectChargerKilledCharging[victim])
	{
		return false;
	}

	int chargerHealth = Skills_GetSpecialMaxHealth(L4D2ZombieClass_Charger);
	int chargerHealthBeforeDamage = g_DetectChargerDamageSnapshot[victim].lastHealthBeforeDamage > 0
		? g_DetectChargerDamageSnapshot[victim].lastHealthBeforeDamage
		: (g_DetectChargerDamageSnapshot[victim].lastHealth > 0 ? g_DetectChargerDamageSnapshot[victim].lastHealth : chargerHealth);
	int chipDamage = chargerHealth - chargerHealthBeforeDamage;
	if (chipDamage < 0)
	{
		chipDamage = 0;
	}

	float rawDamage = g_DetectChargerDamageSnapshot[victim].lastRawDamage;
	if (rawDamage <= 0.0)
	{
		rawDamage = float(Detect_GetSiLifeDamageByAttacker(victim, attacker));
	}

	bool qualifiesAtBaseline = rawDamage >= float(chargerHealth);

	int eventId = Skills_CreateEvent(L4D2Skill_ChargerLevel);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return false;
	}

	g_SkillEvents[eventIndex].actor.Capture(attacker);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].damageScope = L4D2SkillDamageScope_SkillWindow;
	g_SkillEvents[eventIndex].damage = chargerHealthBeforeDamage;
	g_SkillEvents[eventIndex].actorDamage = chargerHealthBeforeDamage;
	g_SkillEvents[eventIndex].chipDamage = chipDamage;
	g_SkillEvents[eventIndex].shots = 1;
	int assistsFound = Detect_WriteSiTrackAssistsToEventAsSkillWindow(eventIndex, victim, attacker);
	Detect_FillChargerLevelPriorDamage(eventIndex, victim, attacker, chipDamage);
	g_SkillEvents[eventIndex].perfect = (g_SkillEvents[eventIndex].chipDamage == 0) && assistsFound == 0;

	Action result = API_FireSkillDetected(eventId, L4D2Skill_ChargerLevel);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}

	Detect_MarkSiLifeKillSuppressed(victim);
	if (Skills_IsDebugEnabled(PlayerSkillsDebug_Detect))
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Charger level fallback classified. charger=%d attacker=%d pre=%d chip=%d qualifies_at_baseline=%d perfect=%d raw=%.1f",
			victim,
			attacker,
			chargerHealthBeforeDamage,
			g_SkillEvents[eventIndex].chipDamage,
			qualifiesAtBaseline ? 1 : 0,
			g_SkillEvents[eventIndex].perfect ? 1 : 0,
			rawDamage);
	}

	return true;
}
