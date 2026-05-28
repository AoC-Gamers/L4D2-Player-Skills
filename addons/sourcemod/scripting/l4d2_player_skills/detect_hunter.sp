#if defined _l4d2_player_skills_detect_hunter_included
	#endinput
#endif
#define _l4d2_player_skills_detect_hunter_included

void Detect_SetHunterPouncing(int hunter, bool state)
{
	g_bDetectHunterPouncing[hunter] = state;
	if (state)
	{
		g_fDetectHunterPounceSeenAt[hunter] = GetGameTime();
	}
}

bool Detect_IsHunterEffectivelyPouncing(int hunter)
{
	if (g_bDetectHunterPouncing[hunter])
	{
		g_fDetectHunterPounceSeenAt[hunter] = GetGameTime();
		return true;
	}

	return g_fDetectHunterPounceSeenAt[hunter] > 0.0
		&& (GetGameTime() - g_fDetectHunterPounceSeenAt[hunter]) <= L4D2_SKILLS_HUNTER_POUNCE_GRACE_TIME;
}

void Detect_ResetHunterPounceState(int hunter)
{
	g_bDetectHunterPouncing[hunter] = false;
	g_fDetectHunterPounceSeenAt[hunter] = 0.0;
	g_iDetectHunterShotDmgTeam[hunter] = 0;
	g_iDetectHunterOverkill[hunter] = 0;
	g_bDetectHunterKilledPouncing[hunter] = false;

	for (int attacker = 1; attacker <= MaxClients; attacker++)
	{
		g_bDetectShotCounted[hunter][attacker] = false;
		g_bDetectHunterShotCounted[hunter][attacker] = false;
		g_fDetectHunterLastShove[hunter][attacker] = 0.0;
		g_iDetectHunterDamage[hunter][attacker] = 0;
		g_iDetectHunterShots[hunter][attacker] = 0;
		g_iDetectHunterShotDmg[hunter][attacker] = 0;
		g_fDetectHunterShotStart[hunter][attacker] = 0.0;
	}
}

void Detect_ResetHunter(int hunter)
{
	Detect_ResetHunterPounceState(hunter);
	g_DetectLeap[hunter].Reset();
	g_bDetectPendingHunterDeathEval[hunter] = false;
	g_bDetectPendingHunterDeathHeadshot[hunter] = false;
	g_iDetectPendingHunterDeathAttackerUserId[hunter] = 0;
	g_sDetectPendingHunterDeathWeapon[hunter][0] = '\0';
	g_iDetectHunterSpawnHealth[hunter] = 0;
	g_DetectHunterDamageSnapshot[hunter].Reset();
}

float Detect_GetLeapHeight(int attacker, int victim)
{
	float attackerOrigin[3];
	float victimOrigin[3];

	if (g_DetectLeap[attacker].originSet)
	{
		attackerOrigin[0] = g_DetectLeap[attacker].origin[0];
		attackerOrigin[1] = g_DetectLeap[attacker].origin[1];
		attackerOrigin[2] = g_DetectLeap[attacker].origin[2];
	}
	else
	{
		GetClientAbsOrigin(attacker, attackerOrigin);
	}

	GetClientAbsOrigin(victim, victimOrigin);

	float height = attackerOrigin[2] - victimOrigin[2];
	return height > 0.0 ? height : 0.0;
}

float Detect_GetLeapDistance(int attacker, int victim)
{
	float attackerOrigin[3];
	float victimOrigin[3];

	if (g_DetectLeap[attacker].originSet)
	{
		attackerOrigin[0] = g_DetectLeap[attacker].origin[0];
		attackerOrigin[1] = g_DetectLeap[attacker].origin[1];
		attackerOrigin[2] = g_DetectLeap[attacker].origin[2];
	}
	else
	{
		GetClientAbsOrigin(attacker, attackerOrigin);
	}

	GetClientAbsOrigin(victim, victimOrigin);
	return GetVectorDistance(attackerOrigin, victimOrigin);
}

float Detect_CalculateHunterPounceDamage(float distance)
{
	float minDistance = g_cvDetectMinPounceDistance != null ? g_cvDetectMinPounceDistance.FloatValue : 300.0;
	float maxDistance = g_cvDetectMaxPounceDistance != null ? g_cvDetectMaxPounceDistance.FloatValue : 1000.0;
	float maxBonusDamage = Skills_GetHunterMaxPounceBonusDamage();

	if (distance <= minDistance)
	{
		return 1.0;
	}

	if (distance >= maxDistance || maxDistance <= minDistance)
	{
		return 1.0 + maxBonusDamage;
	}

	float ratio = (distance - minDistance) / (maxDistance - minDistance);
	return 1.0 + (ratio * maxBonusDamage);
}

bool Detect_IsSkeetWeaponMelee(const char[] weapon)
{
	L4D2WeaponId weaponId = Detect_GetWeaponIdFromEventName(weapon);
	return weaponId == L4D2WeaponId_Melee || weaponId == L4D2WeaponId_Chainsaw || StrEqual(weapon, "melee");
}

bool Detect_IsSkeetWeaponSniper(const char[] weapon)
{
	L4D2WeaponId weaponId = Detect_GetWeaponIdFromEventName(weapon);
	return weaponId == L4D2WeaponId_HuntingRifle
		|| weaponId == L4D2WeaponId_SniperMilitary
		|| weaponId == L4D2WeaponId_SniperAWP
		|| weaponId == L4D2WeaponId_SniperScout
		|| weaponId == L4D2WeaponId_PistolMagnum;
}

bool Detect_IsSkeetWeaponGL(const char[] weapon)
{
	L4D2WeaponId weaponId = Detect_GetWeaponIdFromEventName(weapon);
	return weaponId == L4D2WeaponId_GrenadeLauncher || StrEqual(weapon, "grenade_launcher_projectile");
}

L4D2WeaponId Detect_GetWeaponIdFromEventName(const char[] weapon)
{
	L4D2WeaponId weaponId = L4D2_GetWeaponIdByWeaponName(weapon);
	if (weaponId != L4D2WeaponId_None)
	{
		return weaponId;
	}

	char prefixed[64];
	FormatEx(prefixed, sizeof(prefixed), "weapon_%s", weapon);
	return L4D2_GetWeaponIdByWeaponName(prefixed);
}
