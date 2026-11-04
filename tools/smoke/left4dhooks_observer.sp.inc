// Passive Left4DHooks observer callbacks used by the standalone smoke plugin.
// Keep signatures aligned with the repository's left4dhooks.inc.

public void L4D_OnGameModeChange(int gamemode)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnGameModeChange");
	TraceIntValue(TraceSource_Left4DHooks, seq, "gamemode", gamemode);
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnFirstSurvivorLeftSafeArea_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "client", client);
}

public void L4D_OnWitchSetHarasser(int witch, int victim)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnWitchSetHarasser");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "witch", witch);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "victim", victim);
}

public void L4D_OnSpawnWitch_Post(int entity, const float vecPos[3], const float vecAng[3])
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnSpawnWitch_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "entity", entity);
	TraceVectorValue(TraceSource_Left4DHooks, seq, "vecPos", vecPos);
	TraceVectorValue(TraceSource_Left4DHooks, seq, "vecAng", vecAng);
}

public void L4D2_OnSpawnWitchBride_Post(int entity, const float vecPos[3], const float vecAng[3])
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D2_OnSpawnWitchBride_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "entity", entity);
	TraceVectorValue(TraceSource_Left4DHooks, seq, "vecPos", vecPos);
	TraceVectorValue(TraceSource_Left4DHooks, seq, "vecAng", vecAng);
}

public void L4D_OnGrabWithTongue_Post(int victim, int attacker)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnGrabWithTongue_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "victim", victim);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "attacker", attacker);
}

public void L4D_OnPouncedOnSurvivor_Post(int victim, int attacker)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnPouncedOnSurvivor_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "victim", victim);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "attacker", attacker);
}

public void L4D2_OnJockeyRide_Post(int victim, int attacker)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D2_OnJockeyRide_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "victim", victim);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "attacker", attacker);
}

public void L4D2_OnStartCarryingVictim_Post(int victim, int attacker)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D2_OnStartCarryingVictim_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "victim", victim);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "attacker", attacker);
}

public void L4D2_OnSlammedSurvivor_Post(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D2_OnSlammedSurvivor_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "victim", victim);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "attacker", attacker);
	TraceIntValue(TraceSource_Left4DHooks, seq, "bWallSlam", bWallSlam);
	TraceIntValue(TraceSource_Left4DHooks, seq, "bDeadlyCharge", bDeadlyCharge);
}

public Action L4D_OnFatalFalling(int client, int camera)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnFatalFalling");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "client", client);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "camera", camera);
	TraceIntValue(TraceSource_Left4DHooks, seq, "listener_action", Plugin_Continue);
	return Plugin_Continue;
}

public void L4D_OnFalling(int client)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnFalling");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "client", client);
}

public void L4D_OnLedgeGrabbed_Post(int client)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnLedgeGrabbed_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "client", client);
}

public void L4D_OnIncapacitated_Post(int client, int inflictor, int attacker, float damage, int damagetype, int weapon)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnIncapacitated_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "client", client);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "inflictor", inflictor);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "attacker", attacker);
	TraceFloatValue(TraceSource_Left4DHooks, seq, "damage", damage);
	TraceIntValue(TraceSource_Left4DHooks, seq, "damagetype", damagetype);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "weapon", weapon);
}

public void L4D2_OnPummelVictim_Post(int attacker, int victim)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D2_OnPummelVictim_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "attacker", attacker);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "victim", victim);
}

public void L4D_OnReplaceTank(int tank, int newtank)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnReplaceTank");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "tank", tank);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "newtank", newtank);
}

public Action L4D_OnTryOfferingTankBot(int tank, bool &enterStasis)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnTryOfferingTankBot");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "tank", tank);
	TraceIntValue(TraceSource_Left4DHooks, seq, "enterStasis", enterStasis);
	TraceIntValue(TraceSource_Left4DHooks, seq, "listener_action", Plugin_Continue);
	return Plugin_Continue;
}

public void L4D_OnTryOfferingTankBot_Post(int tank, bool enterStasis)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnTryOfferingTankBot_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "tank", tank);
	TraceIntValue(TraceSource_Left4DHooks, seq, "enterStasis", enterStasis);
}

public void L4D_OnTryOfferingTankBot_PostHandled(int tank, bool enterStasis)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnTryOfferingTankBot_PostHandled");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "tank", tank);
	TraceIntValue(TraceSource_Left4DHooks, seq, "enterStasis", enterStasis);
}

public void L4D_OnEnterStasis(int tank)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnEnterStasis");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "tank", tank);
}

public void L4D_OnLeaveStasis(int tank)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_OnLeaveStasis");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "tank", tank);
}

public void L4D2_OnEntityShoved_Post(int client, int entity, int weapon, const float vecDir[3], bool bIsHighPounce)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D2_OnEntityShoved_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "client", client);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "entity", entity);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "weapon", weapon);
	TraceVectorValue(TraceSource_Left4DHooks, seq, "vecDir", vecDir);
	TraceIntValue(TraceSource_Left4DHooks, seq, "bIsHighPounce", bIsHighPounce);
}

public void L4D_TankRock_OnRelease_Post(int tank, int rock, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_TankRock_OnRelease_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "tank", tank);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "rock", rock);
	TraceVectorValue(TraceSource_Left4DHooks, seq, "vecPos", vecPos);
	TraceVectorValue(TraceSource_Left4DHooks, seq, "vecAng", vecAng);
	TraceVectorValue(TraceSource_Left4DHooks, seq, "vecVel", vecVel);
	TraceVectorValue(TraceSource_Left4DHooks, seq, "vecRot", vecRot);
}

public void L4D_TankRock_BounceTouch_Post(int tank, int rock, int entity)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_TankRock_BounceTouch_Post");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "tank", tank);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "rock", rock);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "entity", entity);
}

public void L4D_TankRock_OnDetonate(int tank, int rock)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, "L4D_TankRock_OnDetonate");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "tank", tank);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "rock", rock);
}

public void L4D2_OnEndVersusModeRound_Post()
{
	TraceBegin(TraceSource_Left4DHooks, "L4D2_OnEndVersusModeRound_Post");
}
