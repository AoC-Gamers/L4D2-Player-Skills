// Timers retain connection identity, life and round generation, never a naked client slot.
// TIMER_DATA_HNDL_CLOSE owns the pack even for repeating timers or map cancellation.
void Detect_QueueClientTimer(float interval, Timer callback, int userid, int flags, int eventId = 0)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
	{
		return;
	}

	DataPack pack = new DataPack();
	pack.WriteCell(g_iDetectRoundGeneration);
	pack.WriteCell(userid);
	pack.WriteCell(g_iDetectClientLifeGeneration[client]);
	pack.WriteCell(eventId);
	CreateTimer(interval, callback, pack, flags | TIMER_DATA_HNDL_CLOSE);
}

int Detect_ReadDeferredClientUserId(DataPack pack)
{
	pack.Reset();
	int roundGeneration = pack.ReadCell();
	int userid = pack.ReadCell();
	int lifeGeneration = pack.ReadCell();
	int client = GetClientOfUserId(userid);
	if (g_Runtime.roundClosed)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Deferred client work discarded. userid=%d reason=round_closed", userid);
		return 0;
	}
	if (roundGeneration != g_iDetectRoundGeneration
		|| !IsValidClient(client)
		|| lifeGeneration != g_iDetectClientLifeGeneration[client])
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Deferred client work discarded. userid=%d reason=stale_round_or_life", userid);
		return 0;
	}

	return userid;
}

void Detect_QueueEntityTimer(float interval, Timer callback, int entityRef, int flags)
{
	DataPack pack = new DataPack();
	pack.WriteCell(g_iDetectRoundGeneration);
	pack.WriteCell(entityRef);
	CreateTimer(interval, callback, pack, flags | TIMER_DATA_HNDL_CLOSE);
}

bool Detect_ReadDeferredEntityRef(DataPack pack, int &entityRef)
{
	pack.Reset();
	int roundGeneration = pack.ReadCell();
	entityRef = pack.ReadCell();
	if (g_Runtime.roundClosed || roundGeneration != g_iDetectRoundGeneration)
	{
		Skills_Debug(PlayerSkillsDebug_Detect,
			"Deferred entity work discarded. entref=%d reason=stale_round", entityRef);
		return false;
	}

	return true;
}
