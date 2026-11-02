// Immediate public family/session dispatch. No KeyValues shaping or detection policy.

Handle g_hForwardSkillDetected = INVALID_HANDLE;
Handle g_hForwardKillDetected = INVALID_HANDLE;
Handle g_hForwardBossEventDetected = INVALID_HANDLE;
Handle g_hForwardBossSessionFinalized = INVALID_HANDLE;
Handle g_hForwardTankSessionClosed = INVALID_HANDLE;
Handle g_hForwardSkillSummaryFinalized = INVALID_HANDLE;
Handle g_hForwardKillSummaryFinalized = INVALID_HANDLE;

void API_CreateForwards()
{
	g_hForwardSkillDetected = CreateGlobalForward("PlayerSkills_OnSkillDetected", ET_Event, Param_Cell, Param_Cell);
	g_hForwardKillDetected = CreateGlobalForward("PlayerSkills_OnKillDetected", ET_Event, Param_Cell, Param_Cell);
	g_hForwardBossEventDetected = CreateGlobalForward("PlayerSkills_OnBossEventDetected", ET_Event, Param_Cell, Param_Cell);
	g_hForwardBossSessionFinalized = CreateGlobalForward("PlayerSkills_OnBossSessionFinalized", ET_Event, Param_Cell, Param_Cell);
	g_hForwardTankSessionClosed = CreateGlobalForward("PlayerSkills_OnTankSessionClosed", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardSkillSummaryFinalized = CreateGlobalForward("PlayerSkills_OnSkillSummaryFinalized", ET_Ignore, Param_Cell);
	g_hForwardKillSummaryFinalized = CreateGlobalForward("PlayerSkills_OnKillSummaryFinalized", ET_Ignore, Param_Cell);
}

Action API_FireFamilyDetected(Handle forwardHandle, int eventId, int publicTypeId, const char[] typeName, const char[] debugLabel)
{
	int eventIndex = Skills_GetEventIndex(eventId);
	if (eventIndex != -1)
	{
		char actorName[64];
		char victimName[64];
		char assisterName[64];
		char pinVictimName[64];
		Skills_FormatEventPlayerRoleName(eventIndex, 0, actorName, sizeof(actorName));
		Skills_FormatEventPlayerRoleName(eventIndex, 1, victimName, sizeof(victimName));
		Skills_FormatEventPlayerRoleName(eventIndex, 2, assisterName, sizeof(assisterName));
		Skills_FormatEventPlayerRoleName(eventIndex, 3, pinVictimName, sizeof(pinVictimName));

		Skills_Debug(PlayerSkillsDebug_Core,
			"%s detected. id=%d type=%s actor=%s victim=%s assister=%s pin=%s damage=%d shots=%d headshot=%d amount=%d reason=%d",
			debugLabel,
			eventId,
			typeName,
			actorName,
			victimName,
			assisterName,
			pinVictimName,
			g_SkillEvents[eventIndex].damage,
			g_SkillEvents[eventIndex].shots,
			g_SkillEvents[eventIndex].headshot ? 1 : 0,
			g_SkillEvents[eventIndex].amount,
			g_SkillEvents[eventIndex].reason);
	}

	if (forwardHandle == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}

	Action result = Plugin_Continue;
	Call_StartForward(forwardHandle);
	Call_PushCell(eventId);
	Call_PushCell(publicTypeId);
	Call_Finish(result);

	Skills_Debug(PlayerSkillsDebug_Api, "%s forward finished. id=%d type=%s result=%d", debugLabel, eventId, typeName, result);
	return result;
}

Action API_FireSkillDetected(int eventId, L4D2SkillType type)
{
	switch (API_GetEventFamily(type))
	{
		case L4D2ApiEventFamily_Skill:
		{
			L4D2ApiSkillType publicType = API_MapSkillType(type);
			char typeName[48];
			API_GetSkillTypeName(publicType, typeName, sizeof(typeName));
			return API_FireFamilyDetected(g_hForwardSkillDetected, eventId, view_as<int>(publicType), typeName, "Skill");
		}

		case L4D2ApiEventFamily_Kill:
		{
			L4D2ApiKillType publicType = API_MapKillType(type);
			char typeName[48];
			API_GetKillTypeName(publicType, typeName, sizeof(typeName));
			return API_FireFamilyDetected(g_hForwardKillDetected, eventId, view_as<int>(publicType), typeName, "Kill");
		}

		case L4D2ApiEventFamily_BossEvent:
		{
			L4D2ApiBossEventType publicType = API_MapBossEventType(type);
			char typeName[48];
			API_GetBossEventTypeName(publicType, typeName, sizeof(typeName));
			return API_FireFamilyDetected(g_hForwardBossEventDetected, eventId, view_as<int>(publicType), typeName, "Boss event");
		}
	}

	return Plugin_Continue;
}

Action API_FireBossDamageFinalized(int sessionId, L4D2BossType type)
{
	if (g_hForwardBossSessionFinalized == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}

	Action result = Plugin_Continue;
	Call_StartForward(g_hForwardBossSessionFinalized);
	Call_PushCell(sessionId);
	Call_PushCell(type);
	Call_Finish(result);
	return result;
}

void API_FireTankSessionClosed(int sessionId, L4D2TankSessionEndReason reason)
{
	if (g_hForwardTankSessionClosed == INVALID_HANDLE)
	{
		return;
	}

	Call_StartForward(g_hForwardTankSessionClosed);
	Call_PushCell(sessionId);
	Call_PushCell(reason);
	Call_Finish();
}
