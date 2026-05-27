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

	g_DetectChargeVictim[victim].charger = charger;
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
		return true;
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
	g_SkillEvents[eventIndex].height = height;
	g_SkillEvents[eventIndex].distance = GetVectorDistance(g_DetectChargeVictim[victim].startOrigin, deathPos);
	g_SkillEvents[eventIndex].wasCarried = g_DetectChargeVictim[victim].wasCarried;
	g_SkillEvents[eventIndex].damage = g_DetectChargeVictim[victim].mapDamage;
	g_SkillEvents[eventIndex].incapped = chargeIncapContext;
	g_SkillEvents[eventIndex].ledgeHang = (g_DetectChargeVictim[victim].flags & DCFLAG_LEDGE) != 0;
	g_SkillEvents[eventIndex].fatalFall = (g_DetectChargeVictim[victim].flags & DCFLAG_FALL) != 0;
	g_SkillEvents[eventIndex].deadlySlam = (g_DetectChargeVictim[victim].flags & DCFLAG_DEADLY) != 0;

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

void Detect_HandleChargerHurt(int victim, int attacker, int damageType, int appliedDamage, int postHealth)
{
	if (appliedDamage <= 0)
	{
		return;
	}

	if (postHealth == 0
		&& (damageType & DMG_CLUB || damageType & DMG_SLASH)
		&& Detect_IsChargerCharging(victim))
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
			g_SkillEvents[eventIndex].damage = chargerHealthBeforeDamage;
			g_SkillEvents[eventIndex].chipDamage = chipDamage;
			g_SkillEvents[eventIndex].wouldQualifyAtBaseline = qualifiesAtBaseline;
			g_SkillEvents[eventIndex].perfect = (g_SkillEvents[eventIndex].chipDamage == 0);

			Action result = API_FireSkillDetected(eventId, L4D2Skill_ChargerLevel);
			if (result < Plugin_Handled)
			{
				Announce_Skill(eventId);
			}
		}

		Detect_MarkSimpleKillSuppressed(victim);
	}

	if (postHealth > 0)
	{
		g_DetectChargerDamageSnapshot[victim].lastHealth = postHealth;
	}
	else
	{
		g_DetectChargerDamageSnapshot[victim].lastHealth = 0;
	}
}
