// Private detector ownership: shared

void Detect_EmitGenericLedgeHang(L4D2SkillType type, int attacker, int victim, int zombieClass)
{
	if (!IsValidSurvivor(victim) || !IsValidInfected(attacker))
	{
		return;
	}

	int eventId = Skills_CreateEvent(type);
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex == -1)
	{
		return;
	}

	g_SkillEvents[eventIndex].actor.Capture(attacker);
	g_SkillEvents[eventIndex].victim.Capture(victim);
	g_SkillEvents[eventIndex].zombieClass = zombieClass;
	g_SkillEvents[eventIndex].ledgeHang = true;

	Action result = API_FireSkillDetected(eventId, type);
	if (result < Plugin_Handled)
	{
		Announce_Skill(eventId);
	}
}
