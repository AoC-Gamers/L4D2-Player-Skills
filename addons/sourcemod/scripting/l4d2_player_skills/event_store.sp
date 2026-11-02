// Internal event store responsibility; public contracts remain in the include.

/**
 * @brief Clears round-local events without reusing public event IDs.
 *
 * @noreturn
 */
stock void Skills_ResetEvents()
{
	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		g_SkillEvents[index].Reset();
	}

	g_iNextEventSlot = 0;
}

/**
 * @brief Allocates a new runtime skill event in the circular buffer.
 *
 * @param type           Skill type to assign to the new event.
 *
 * @return               Runtime event identifier for the new slot.
 */
stock int Skills_CreateEvent(L4D2SkillType type)
{
	int slot		 = g_iNextEventSlot;
	g_iNextEventSlot = (g_iNextEventSlot + 1) % L4D2_SKILLS_MAX_EVENTS;

	g_SkillEvents[slot].Reset();
	g_SkillEvents[slot].id		  = ++g_iEventSerial;
	g_SkillEvents[slot].type	  = type;
	g_SkillEvents[slot].createdAt = GetGameTime();

	return g_SkillEvents[slot].id;
}

/**
 * @brief Resolves a runtime event id to its current storage slot.
 *
 * @param eventId        Runtime skill event identifier.
 *
 * @return               Zero-based slot index, or -1 if not found.
 */
stock int Skills_GetEventIndex(int eventId)
{
	if (eventId <= 0)
	{
		return -1;
	}

	for (int index = 0; index < L4D2_SKILLS_MAX_EVENTS; index++)
	{
		if (g_SkillEvents[index].id == eventId)
		{
			return index;
		}
	}

	return -1;
}

/**
 * @brief Checks whether a runtime skill event id is still valid.
 *
 * @param eventId        Runtime skill event identifier.
 *
 * @return               True if the event still exists in the circular buffer.
 */
stock bool Skills_IsEventValid(int eventId)
{
	return Skills_GetEventIndex(eventId) != -1;
}

/**
 * @brief Copies one captured player role from a stored skill event.
 *
 * @param eventIndex     Zero-based slot index inside g_SkillEvents.
 * @param slot           Player role slot from L4D2SkillPlayerSlot.
 * @param player         Output player snapshot buffer.
 *
 * @noreturn
 */
stock void Skills_GetEventPlayerRefBySlot(int eventIndex, int slot, L4D2PlayerRef player)
{
	player.Reset();

	switch (slot)
	{
		case 0:
		{
			player = g_SkillEvents[eventIndex].actor;
			return;
		}
		case 1:
		{
			player = g_SkillEvents[eventIndex].victim;
			return;
		}
		case 2:
		{
			player = g_SkillEvents[eventIndex].assister;
			return;
		}
		case 3:
		{
			player = g_SkillEvents[eventIndex].pinVictim;
			return;
		}
	}
}

// Provisional events are internal until the owning detector resolves its priority.
stock void Skills_SetEventPendingPublication(int eventId, bool pending)
{
	int index = Skills_GetEventIndex(eventId);
	if (index != -1)
	{
		g_SkillEvents[index].pendingPublication = pending;
	}
}

stock void Skills_DiscardPendingEvent(int eventId)
{
	int index = Skills_GetEventIndex(eventId);
	if (index != -1 && g_SkillEvents[index].pendingPublication)
	{
		g_SkillEvents[index].Reset();
	}
}
