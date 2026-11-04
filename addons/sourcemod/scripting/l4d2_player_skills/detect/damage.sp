void Detect_HandlePlayerHurt(SkillsDamageObservation observation)
{
	int victim = observation.victim;
	int attacker = observation.attacker;
	int damage = observation.damage;
	int damageType = observation.damageType;
	int hitgroup = observation.hitgroup;
	char weapon[32];
	strcopy(weapon, sizeof(weapon), observation.weapon);
	int weaponId = observation.weaponId;

	// Some indirect/projectile damage paths (notably GL splash and throwables)
	// can reach player_hurt without a useful weapon string. Fall back to the
	// attacker's most recent weapon_fire so the damage is still attributed to
	// the correct survivor.
	if (weaponId == WEPID_NONE && IsValidSurvivor(attacker))
	{
		int lastWeaponId = Detect_GetLastWeaponId(attacker);
		float lastWeaponFireTime = Detect_GetLastWeaponFireTime(attacker);
		float delta = GetGameTime() - lastWeaponFireTime;
		if (lastWeaponId != WEPID_NONE
			&& (Skills_IsRangedShotWeaponId(lastWeaponId)
				|| lastWeaponId == WEPID_MOLOTOV
				|| lastWeaponId == WEPID_PIPE_BOMB
				|| lastWeaponId == WEPID_VOMITJAR)
			&& delta >= 0.0
			&& delta <= 0.20)
		{
			weaponId = lastWeaponId;
		}
	}

	if (damage > 0 && IsValidSurvivor(attacker) && Detect_IsTrackableSiLifeKillClass(victim))
	{
		Detect_RecordSiLifeKillDamage(victim, attacker, damage, weaponId, damageType, hitgroup);
	}

	if (damage > 0 && IsValidSurvivor(victim) && IsValidZombieClass(attacker, L4D2ZombieClass_Charger))
	{
		Detect_RecordChargerClawHitFromDamage(victim, attacker, observation.entityId, float(damage), damageType, weaponId);
	}

	if (IsValidSurvivor(victim) && g_DetectChargeVictim[victim].charger > 0 && damage > 0)
	{
		bool byTrigger = false;
		if (StrEqual(weapon, "trigger_hurt"))
		{
			byTrigger = true;
		}

		if (!IsValidInfected(attacker))
		{
			Detect_MarkChargeMapDamage(victim, damage, damageType, byTrigger);
		}
		else if (attacker != g_DetectChargeVictim[victim].charger)
		{
			g_DetectChargeVictim[victim].flags |= DCFLAG_KILLEDBYOTHER;
		}

		if (L4D_IsPlayerHangingFromLedge(victim))
		{
			g_DetectChargeVictim[victim].flags |= DCFLAG_LEDGE;
		}
	}

	if (!IsValidZombieClass(victim, L4D2ZombieClass_Hunter) || !IsValidSurvivor(attacker))
	{
		if (IsValidSurvivor(victim) && IsValidTank(attacker))
		{
			if (StrEqual(weapon, "tank_rock"))
			{
				Detect_MarkTankRockHit(attacker, victim);
			}
		}

		return;
	}
}
