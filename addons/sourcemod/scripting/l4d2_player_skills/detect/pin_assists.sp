// Private detector ownership: pin assists

int Detect_GetCurrentPinnedVictim(int infected)
{
	if (!IsValidInfected(infected))
	{
		return 0;
	}

	int victim = L4D2_GetSurvivorVictim(infected);
	if (IsValidSurvivor(victim))
	{
		return victim;
	}

	if (IsValidZombieClass(infected, L4D2ZombieClass_Charger) && L4D2_IsInQueuedPummel(infected))
	{
		victim = L4D2_GetQueuedPummelVictim(infected);
		if (IsValidSurvivor(victim))
		{
			return victim;
		}
	}

	victim = g_DetectPinRegistry.pinnedVictimByAttacker[infected];
	return IsValidSurvivor(victim) ? victim : 0;
}

int Detect_GetCurrentPinnedAttacker(int survivor)
{
	if (!IsValidSurvivor(survivor))
	{
		return 0;
	}

	int attacker = L4D2_GetInfectedAttacker(survivor);
	if (IsValidInfected(attacker))
	{
		return attacker;
	}

	attacker = g_DetectPinRegistry.pinnerByVictim[survivor];
	return IsValidInfected(attacker) ? attacker : 0;
}

void Detect_AttachPinnedInfectedAssistToEvent(int eventIndex, int actor, int survivor)
{
	if (eventIndex < 0 || eventIndex >= L4D2_SKILLS_MAX_EVENTS || !IsValidSurvivor(survivor))
	{
		return;
	}

	int assister = Detect_GetCurrentPinnedAttacker(survivor);
	if (!IsValidInfected(assister) || assister == actor || g_SkillEvents[eventIndex].assistsCount > 0)
	{
		return;
	}

	g_SkillEvents[eventIndex].assistScope = L4D2SkillAssistScope_SkillWindow;
	g_SkillEvents[eventIndex].assists[0].Capture(assister);
	g_SkillEvents[eventIndex].assistsCount = 1;
	g_SkillEvents[eventIndex].assister = g_SkillEvents[eventIndex].assists[0];
}
