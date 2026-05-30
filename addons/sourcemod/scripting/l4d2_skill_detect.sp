#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <l4d2_player_skills>

#define PLAYER_SKILLS_LIBRARY "l4d2_player_skills"

Handle g_hForwardSkeet					= INVALID_HANDLE;
Handle g_hForwardPounceKill				= INVALID_HANDLE;
Handle g_hForwardSkeetMelee				= INVALID_HANDLE;
Handle g_hForwardHunterPounceMeleeKill	= INVALID_HANDLE;
Handle g_hForwardSkeetSniper			= INVALID_HANDLE;
Handle g_hForwardHunterPounceSniperKill = INVALID_HANDLE;
Handle g_hForwardSkeetGL				= INVALID_HANDLE;
Handle g_hForwardHunterDeadstop			= INVALID_HANDLE;
Handle g_hForwardBoomerPop				= INVALID_HANDLE;
Handle g_hForwardLevel					= INVALID_HANDLE;
Handle g_hForwardChargerMeleeKill		= INVALID_HANDLE;
Handle g_hForwardCrown					= INVALID_HANDLE;
Handle g_hForwardStartledCrown			= INVALID_HANDLE;
Handle g_hForwardSmokerTongueCut		= INVALID_HANDLE;
Handle g_hForwardSmokerSelfClear		= INVALID_HANDLE;
Handle g_hForwardRockSkeet				= INVALID_HANDLE;
Handle g_hForwardRockHit				= INVALID_HANDLE;
Handle g_hForwardHunterDP				= INVALID_HANDLE;
Handle g_hForwardJockeyDP				= INVALID_HANDLE;
Handle g_hForwardDeathCharge			= INVALID_HANDLE;
Handle g_hForwardClear					= INVALID_HANDLE;
Handle g_hForwardVomitLanded			= INVALID_HANDLE;
Handle g_hForwardBHopStreak				= INVALID_HANDLE;
Handle g_hForwardAlarmTriggered			= INVALID_HANDLE;
bool   g_bSkillsAvailable				= false;

public Plugin myinfo =
{
	name		= "L4D2 Skill Detect Wrapper",
	author		= "lechuga",
	description = "Legacy skill_detect wrapper over l4d2_player_skills",
	version		= "0.1.0",
	url			= "https://github.com/AoC-Gamers/L4D2-Player-Skills"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("skill_detect");

	g_hForwardSkeet					 = CreateGlobalForward("OnSkeet", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardPounceKill			 = CreateGlobalForward("OnPounceKill", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardSkeetMelee			 = CreateGlobalForward("OnSkeetMelee", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardHunterPounceMeleeKill	 = CreateGlobalForward("OnHunterPounceMeleeKill", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardSkeetSniper			 = CreateGlobalForward("OnSkeetSniper", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardHunterPounceSniperKill = CreateGlobalForward("OnHunterPounceSniperKill", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardSkeetGL				 = CreateGlobalForward("OnSkeetGL", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardHunterDeadstop		 = CreateGlobalForward("OnHunterDeadstop", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardBoomerPop				 = CreateGlobalForward("OnBoomerPop", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float);
	g_hForwardLevel					 = CreateGlobalForward("OnChargerLevel", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardChargerMeleeKill		 = CreateGlobalForward("OnChargerMeleeKill", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardCrown					 = CreateGlobalForward("OnWitchCrown", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardStartledCrown			 = CreateGlobalForward("OnWitchCrownStartled", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardSmokerTongueCut		 = CreateGlobalForward("OnSmokerTongueCut", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardSmokerSelfClear		 = CreateGlobalForward("OnSmokerSelfClear", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardRockSkeet				 = CreateGlobalForward("OnTankRockSkeet", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardRockHit				 = CreateGlobalForward("OnTankRockHit", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardHunterDP				 = CreateGlobalForward("OnHunterHighPounce", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
	g_hForwardJockeyDP				 = CreateGlobalForward("OnJockeyHighPounce", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	g_hForwardDeathCharge			 = CreateGlobalForward("OnChargerDeathCharge", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
	g_hForwardClear					 = CreateGlobalForward("OnSpecialPinClear", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
	g_hForwardVomitLanded			 = CreateGlobalForward("OnBoomerVomitLanded", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardBHopStreak			 = CreateGlobalForward("OnBunnyHopStreak", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
	g_hForwardAlarmTriggered		 = CreateGlobalForward("OnCarAlarmTriggered", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	return APLRes_Success;
}

public void OnPluginStart()
{
	Legacy_KeepUnusedForwardsAlive();
	g_bSkillsAvailable = LibraryExists(PLAYER_SKILLS_LIBRARY);
}

public void OnPluginEnd()
{
	g_bSkillsAvailable = false;
	Legacy_CloseForwards();
}

public void OnAllPluginsLoaded()
{
	g_bSkillsAvailable = LibraryExists(PLAYER_SKILLS_LIBRARY);
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, PLAYER_SKILLS_LIBRARY))
	{
		g_bSkillsAvailable = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, PLAYER_SKILLS_LIBRARY))
	{
		g_bSkillsAvailable = false;
	}
}

void Legacy_KeepUnusedForwardsAlive()
{
	if (g_hForwardPounceKill == INVALID_HANDLE
		|| g_hForwardHunterPounceMeleeKill == INVALID_HANDLE
		|| g_hForwardHunterPounceSniperKill == INVALID_HANDLE
		|| g_hForwardChargerMeleeKill == INVALID_HANDLE)
	{
	}
}

void Legacy_CloseForward(Handle &forwardHandle)
{
	if (forwardHandle != INVALID_HANDLE)
	{
		delete forwardHandle;
		forwardHandle = INVALID_HANDLE;
	}
}

void Legacy_CloseForwards()
{
	Legacy_CloseForward(g_hForwardSkeet);
	Legacy_CloseForward(g_hForwardPounceKill);
	Legacy_CloseForward(g_hForwardSkeetMelee);
	Legacy_CloseForward(g_hForwardHunterPounceMeleeKill);
	Legacy_CloseForward(g_hForwardSkeetSniper);
	Legacy_CloseForward(g_hForwardHunterPounceSniperKill);
	Legacy_CloseForward(g_hForwardSkeetGL);
	Legacy_CloseForward(g_hForwardHunterDeadstop);
	Legacy_CloseForward(g_hForwardBoomerPop);
	Legacy_CloseForward(g_hForwardLevel);
	Legacy_CloseForward(g_hForwardChargerMeleeKill);
	Legacy_CloseForward(g_hForwardCrown);
	Legacy_CloseForward(g_hForwardStartledCrown);
	Legacy_CloseForward(g_hForwardSmokerTongueCut);
	Legacy_CloseForward(g_hForwardSmokerSelfClear);
	Legacy_CloseForward(g_hForwardRockSkeet);
	Legacy_CloseForward(g_hForwardRockHit);
	Legacy_CloseForward(g_hForwardHunterDP);
	Legacy_CloseForward(g_hForwardJockeyDP);
	Legacy_CloseForward(g_hForwardDeathCharge);
	Legacy_CloseForward(g_hForwardClear);
	Legacy_CloseForward(g_hForwardVomitLanded);
	Legacy_CloseForward(g_hForwardBHopStreak);
	Legacy_CloseForward(g_hForwardAlarmTriggered);
}

bool Legacy_IsEventValid(int eventId)
{
	return PlayerSkills_IsEventValid(eventId);
}

int Legacy_GetEventClient(int eventId, L4D2SkillPlayerSlot slot)
{
	return PlayerSkills_GetEventClient(eventId, slot);
}

int Legacy_GetEventInt(int eventId, L4D2SkillIntField field)
{
	return PlayerSkills_GetEventInt(eventId, field);
}

float Legacy_GetEventFloat(int eventId, L4D2SkillFloatField field)
{
	return PlayerSkills_GetEventFloat(eventId, field);
}

bool Legacy_GetEventBool(int eventId, L4D2SkillBoolField field)
{
	return PlayerSkills_GetEventBool(eventId, field);
}

void Legacy_FireSkeetLike(Handle forwardHandle, int survivor, int hunter)
{
	Call_StartForward(forwardHandle);
	Call_PushCell(survivor);
	Call_PushCell(hunter);
	Call_Finish();
}

public Action PlayerSkills_OnSkillDetected(int eventId, L4D2SkillType type)
{
	if (!g_bSkillsAvailable || !Legacy_IsEventValid(eventId))
	{
		return Plugin_Continue;
	}

	int actor  = Legacy_GetEventClient(eventId, L4D2SkillPlayer_Actor);
	int victim = Legacy_GetEventClient(eventId, L4D2SkillPlayer_Victim);

	switch (type)
	{
		case L4D2Skill_HunterSkeet:
		{
			if (Legacy_GetEventBool(eventId, L4D2SkillBool_GrenadeLauncher))
			{
				Legacy_FireSkeetLike(g_hForwardSkeetGL, actor, victim);
			}
			else if (Legacy_GetEventBool(eventId, L4D2SkillBool_Sniper))
			{
				Legacy_FireSkeetLike(g_hForwardSkeetSniper, actor, victim);

				Call_StartForward(g_hForwardHunterPounceSniperKill);
				Call_PushCell(actor);
				Call_PushCell(victim);
				Call_PushCell(Legacy_GetEventInt(eventId, L4D2SkillInt_Damage));
				Call_PushCell(Legacy_GetEventBool(eventId, L4D2SkillBool_WouldQualifyAtBaseline));
				Call_Finish();
			}
			else
			{
				Legacy_FireSkeetLike(g_hForwardSkeet, actor, victim);

				Call_StartForward(g_hForwardPounceKill);
				Call_PushCell(actor);
				Call_PushCell(victim);
				Call_PushCell(Legacy_GetEventInt(eventId, L4D2SkillInt_Damage));
				Call_PushCell(Legacy_GetEventBool(eventId, L4D2SkillBool_WouldQualifyAtBaseline));
				Call_Finish();
			}
		}

		case L4D2Skill_HunterSkeetMelee:
		{
			Legacy_FireSkeetLike(g_hForwardSkeetMelee, actor, victim);

			Call_StartForward(g_hForwardHunterPounceMeleeKill);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_PushCell(Legacy_GetEventInt(eventId, L4D2SkillInt_Damage));
			Call_PushCell(Legacy_GetEventBool(eventId, L4D2SkillBool_WouldQualifyAtBaseline));
			Call_Finish();
		}

		case L4D2Skill_HunterDeadstop:
		{
			Legacy_FireSkeetLike(g_hForwardHunterDeadstop, actor, victim);
		}

		case L4D2Skill_BoomerPop:
		{
			Call_StartForward(g_hForwardBoomerPop);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_PushCell(Legacy_GetEventInt(eventId, L4D2SkillInt_ShoveCount));
			Call_PushFloat(Legacy_GetEventFloat(eventId, L4D2SkillFloat_TimeA));
			Call_Finish();
		}

		case L4D2Skill_ChargerLevel:
		{
			Call_StartForward(g_hForwardLevel);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_Finish();

			Call_StartForward(g_hForwardChargerMeleeKill);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_PushCell(Legacy_GetEventInt(eventId, L4D2SkillInt_Damage));
			Call_Finish();
		}

		case L4D2Skill_WitchCrown:
		{
			int	 damage		= Legacy_GetEventInt(eventId, L4D2SkillInt_Damage);
			int	 chipDamage = Legacy_GetEventInt(eventId, L4D2SkillInt_ChipDamage);
			bool startled	= Legacy_GetEventBool(eventId, L4D2SkillBool_Startled);

			if (startled || chipDamage > 0)
			{
				Call_StartForward(g_hForwardStartledCrown);
				Call_PushCell(actor);
				Call_PushCell(damage);
				Call_PushCell(chipDamage);
				Call_Finish();
			}
			else
			{
				Call_StartForward(g_hForwardCrown);
				Call_PushCell(actor);
				Call_PushCell(damage);
				Call_Finish();
			}
		}

		case L4D2Skill_SmokerTongueCut:
		{
			Call_StartForward(g_hForwardSmokerTongueCut);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_Finish();
		}

		case L4D2Skill_SmokerSelfClear:
		{
			Call_StartForward(g_hForwardSmokerSelfClear);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_PushCell(Legacy_GetEventBool(eventId, L4D2SkillBool_WithShove));
			Call_Finish();
		}

		case L4D2Skill_TankRockSkeet:
		{
			Call_StartForward(g_hForwardRockSkeet);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_Finish();
		}

		case L4D2Skill_TankRockHit:
		{
			Call_StartForward(g_hForwardRockHit);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_Finish();
		}

		case L4D2Skill_HunterHighPounce:
		{
			Call_StartForward(g_hForwardHunterDP);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_PushCell(Legacy_GetEventInt(eventId, L4D2SkillInt_Damage));
			Call_PushFloat(Legacy_GetEventFloat(eventId, L4D2SkillFloat_CalculatedDamage));
			Call_PushFloat(Legacy_GetEventFloat(eventId, L4D2SkillFloat_Height));
			Call_PushCell(Legacy_GetEventBool(eventId, L4D2SkillBool_ReportedHigh));
			Call_Finish();
		}

		case L4D2Skill_JockeyHighPounce:
		{
			Call_StartForward(g_hForwardJockeyDP);
			Call_PushCell(victim);
			Call_PushCell(actor);
			Call_PushFloat(Legacy_GetEventFloat(eventId, L4D2SkillFloat_Height));
			Call_PushCell(Legacy_GetEventBool(eventId, L4D2SkillBool_ReportedHigh));
			Call_Finish();
		}

		case L4D2Skill_ChargerInstaKill:
		{
			Call_StartForward(g_hForwardDeathCharge);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_PushFloat(Legacy_GetEventFloat(eventId, L4D2SkillFloat_Height));
			Call_PushFloat(Legacy_GetEventFloat(eventId, L4D2SkillFloat_Distance));
			Call_PushCell(Legacy_GetEventBool(eventId, L4D2SkillBool_WasCarried));
			Call_Finish();
		}

		case L4D2Skill_SpecialPinClear:
		{
			Call_StartForward(g_hForwardClear);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_PushCell(Legacy_GetEventClient(eventId, L4D2SkillPlayer_PinVictim));
			Call_PushCell(Legacy_GetEventInt(eventId, L4D2SkillInt_ZombieClass));
			Call_PushFloat(Legacy_GetEventFloat(eventId, L4D2SkillFloat_TimeA));
			Call_PushFloat(Legacy_GetEventFloat(eventId, L4D2SkillFloat_TimeB));
			Call_PushCell(Legacy_GetEventBool(eventId, L4D2SkillBool_WithShove));
			Call_Finish();
		}

		case L4D2Skill_BoomerVomitLanded:
		{
			Call_StartForward(g_hForwardVomitLanded);
			Call_PushCell(actor);
			Call_PushCell(Legacy_GetEventInt(eventId, L4D2SkillInt_Amount));
			Call_Finish();
		}

		case L4D2Skill_BunnyHopStreak:
		{
			Call_StartForward(g_hForwardBHopStreak);
			Call_PushCell(actor);
			Call_PushCell(Legacy_GetEventInt(eventId, L4D2SkillInt_Streak));
			Call_PushFloat(Legacy_GetEventFloat(eventId, L4D2SkillFloat_MaxVelocity));
			Call_Finish();
		}

		case L4D2Skill_CarAlarmTriggered:
		{
			Call_StartForward(g_hForwardAlarmTriggered);
			Call_PushCell(actor);
			Call_PushCell(victim);
			Call_PushCell(Legacy_GetEventInt(eventId, L4D2SkillInt_Reason));
			Call_Finish();
		}
	}

	return Plugin_Continue;
}
