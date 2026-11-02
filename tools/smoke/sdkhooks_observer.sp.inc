// Standalone SDKHooks observer for the Skills smoke. Excluded from product builds.
// The root observer supplies TraceBegin/Trace*Value and dispatches the lifecycle
// functions below. This module never changes hook by-reference arguments.

#define SMOKE_SDK_CLASS_WITCH "witch"
#define SMOKE_SDK_CLASS_WITCH_BRIDE "witch_bride"
#define SMOKE_SDK_CLASS_TANK_ROCK "tank_rock"
#define SMOKE_SDK_CLASS_CAR_ALARM "prop_car_alarm"
#define SMOKE_SDK_CLASS_CAR_GLASS "prop_car_glass"

enum SmokeSDKHookFlags
{
	SmokeSDKHook_Damage = (1 << 0),
	SmokeSDKHook_DamagePost = (1 << 1),
	SmokeSDKHook_TraceAttack = (1 << 2),
	SmokeSDKHook_Touch = (1 << 3),
	SmokeSDKHook_Spawn = (1 << 4)
};

enum struct SmokeSDKTrackedEntity
{
	int entRef;
	int entityIndex;
	int flags;
	int userid;
}

ArrayList g_SmokeSDKTrackedEntities;
int g_SmokeSDKGeneration;

void SmokeSDK_Reconcile()
{
	if (!g_Runtime.sdkHooksNeedsSync) return;
	bool reset = g_Runtime.sdkHooksResetPending;
	g_Runtime.sdkHooksNeedsSync = false;
	g_Runtime.sdkHooksResetPending = false;
	if (reset)
	{
		// The old extension already removed its hooks. Do not unhook through a
		// new provider using the old ledger, even if remove/add shared one tick.
		g_SmokeSDKGeneration++;
		delete g_SmokeSDKTrackedEntities;
		g_Runtime.hasSDKHooks = false;
		TraceBegin(TraceSource_SDKHooks, "inventory_invalidated_after_library_removal");
	}
	SmokeSDK_Start();
}

void SmokeSDK_Start()
{
	if (g_SmokeSDKTrackedEntities != null)
	{
		return;
	}
	g_SmokeSDKGeneration++;

	g_Runtime.hasSDKHooks = GetFeatureStatus(FeatureType_Native, "SDKHookEx") == FeatureStatus_Available
		&& GetFeatureStatus(FeatureType_Native, "SDKUnhook") == FeatureStatus_Available;
	int sequence = TraceBegin(TraceSource_SDKHooks, "coverage");
	TraceIntValue(TraceSource_SDKHooks, sequence, "sdkhookex_available", GetFeatureStatus(FeatureType_Native, "SDKHookEx") == FeatureStatus_Available);
	TraceIntValue(TraceSource_SDKHooks, sequence, "sdkunhook_available", GetFeatureStatus(FeatureType_Native, "SDKUnhook") == FeatureStatus_Available);
	if (!g_Runtime.hasSDKHooks) return;

	g_SmokeSDKTrackedEntities = new ArrayList(sizeof(SmokeSDKTrackedEntity));

	// Reconstruct the live side of the inventory for late observer loads.
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			SmokeSDK_HookEntity(client);
		}
	}

	SmokeSDK_ScanClass(SMOKE_SDK_CLASS_WITCH);
	SmokeSDK_ScanClass(SMOKE_SDK_CLASS_WITCH_BRIDE);
	SmokeSDK_ScanClass(SMOKE_SDK_CLASS_TANK_ROCK);
	SmokeSDK_ScanClass(SMOKE_SDK_CLASS_CAR_ALARM);
	SmokeSDK_ScanClass(SMOKE_SDK_CLASS_CAR_GLASS);
}

void SmokeSDK_OnEntityCreated(int entity, const char[] classname)
{
	if (g_Runtime.sdkHooksResetPending || g_SmokeSDKTrackedEntities == null || !SmokeSDK_IsObservedClass(entity, classname))
	{
		return;
	}

	if (entity > 0 && entity < GetMaxEntities())
	{
		// Attach immediately when valid, including Spawn before it fires.
		// The entref pass retries incomplete registrations without duplicating hooks.
		if (IsValidEntity(entity))
		{
			SmokeSDK_HookEntity(entity);
		}
		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteCell(g_SmokeSDKGeneration);
		RequestFrame(SmokeSDK_HookDeferred, pack);
	}
}

void SmokeSDK_Stop()
{
	g_SmokeSDKGeneration++;
	if (g_SmokeSDKTrackedEntities == null)
	{
		return;
	}
	g_Runtime.hasSDKHooks = GetFeatureStatus(FeatureType_Native, "SDKHookEx") == FeatureStatus_Available
		&& GetFeatureStatus(FeatureType_Native, "SDKUnhook") == FeatureStatus_Available;

	SmokeSDKTrackedEntity tracked;
	for (int i = 0; i < g_SmokeSDKTrackedEntities.Length; i++)
	{
		g_SmokeSDKTrackedEntities.GetArray(i, tracked, sizeof(tracked));
		int entity = EntRefToEntIndex(tracked.entRef);
		if (entity == INVALID_ENT_REFERENCE)
		{
			continue;
		}
		if (tracked.userid > 0 && (!IsClientInGame(entity) || GetClientUserId(entity) != tracked.userid))
		{
			continue;
		}

		if (g_Runtime.hasSDKHooks && !g_Runtime.sdkHooksResetPending)
		{
			SmokeSDK_UnhookFlags(entity, tracked.flags);
		}
	}

	delete g_SmokeSDKTrackedEntities;
	g_SmokeSDKTrackedEntities = null;
	g_Runtime.hasSDKHooks = false;
}

void SmokeSDK_OnEntityDestroyed(int entity)
{
	if (g_SmokeSDKTrackedEntities == null) return;
	SmokeSDKTrackedEntity tracked;
	for (int i = g_SmokeSDKTrackedEntities.Length - 1; i >= 0; i--)
	{
		g_SmokeSDKTrackedEntities.GetArray(i, tracked, sizeof(tracked));
		if (tracked.entityIndex == entity || tracked.entRef == entity) g_SmokeSDKTrackedEntities.Erase(i);
	}
	// SDKHooks owns removal from a destroyed entity; never unhook a reused index here.
}

void SmokeSDK_ScanClass(const char[] classname)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, classname)) != -1)
	{
		SmokeSDK_HookEntity(entity);
	}
}

void SmokeSDK_HookDeferred(any data)
{
	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	int entRef = pack.ReadCell();
	int generation = pack.ReadCell();
	delete pack;
	if (generation != g_SmokeSDKGeneration || g_SmokeSDKTrackedEntities == null)
	{
		return;
	}

	int entity = EntRefToEntIndex(entRef);
	if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity))
	{
		return;
	}

	SmokeSDK_HookEntity(entity);
}

bool SmokeSDK_IsObservedClass(int entity, const char[] classname)
{
	if (entity > 0 && entity <= MaxClients)
	{
		return StrEqual(classname, "player");
	}

	return StrEqual(classname, SMOKE_SDK_CLASS_WITCH)
		|| StrEqual(classname, SMOKE_SDK_CLASS_WITCH_BRIDE)
		|| StrEqual(classname, SMOKE_SDK_CLASS_TANK_ROCK)
		|| StrEqual(classname, SMOKE_SDK_CLASS_CAR_ALARM)
		|| StrEqual(classname, SMOKE_SDK_CLASS_CAR_GLASS);
}

void SmokeSDK_HookEntity(int entity)
{
	if (g_Runtime.sdkHooksResetPending || GetFeatureStatus(FeatureType_Native, "SDKHookEx") != FeatureStatus_Available) return;
	if (g_SmokeSDKTrackedEntities == null || entity <= 0 || entity >= GetMaxEntities() || !IsValidEntity(entity))
	{
		return;
	}

	int userid;
	if (entity <= MaxClients)
	{
		if (!IsClientInGame(entity))
		{
			return;
		}
		userid = GetClientUserId(entity);
	}

	int entRef = EntIndexToEntRef(entity);
	SmokeSDKTrackedEntity tracked;
	int existing = SmokeSDK_FindTracked(entRef);
	int flags;
	if (existing != -1)
	{
		g_SmokeSDKTrackedEntities.GetArray(existing, tracked, sizeof(tracked));
		if (tracked.userid == userid)
		{
			flags = tracked.flags;
		}
		else
		{
			// A client slot may still name the same edict after reconnect. Remove only
			// callbacks on this currently resolved edict before recording its new userid.
			SmokeSDK_UnhookFlags(entity, tracked.flags);
			g_SmokeSDKTrackedEntities.Erase(existing);
			existing = -1;
		}
	}

	if (entity <= MaxClients || SmokeSDK_IsWitch(entity))
	{
		SmokeSDK_RecordDamageHooks(entity, flags);
	}

	if (entity > MaxClients)
	{
		char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, SMOKE_SDK_CLASS_TANK_ROCK))
		{
			SmokeSDK_RecordHook(entity, SDKHook_TraceAttack, SmokeSDK_OnTraceAttack, "TraceAttack", SmokeSDKHook_TraceAttack, flags);
		}
		else if (StrEqual(classname, SMOKE_SDK_CLASS_CAR_ALARM) || StrEqual(classname, SMOKE_SDK_CLASS_CAR_GLASS))
		{
			SmokeSDK_RecordDamageHooks(entity, flags);
			SmokeSDK_RecordHook(entity, SDKHook_Touch, SmokeSDK_OnTouch, "Touch", SmokeSDKHook_Touch, flags);
			SmokeSDK_RecordHook(entity, SDKHook_Spawn, SmokeSDK_OnSpawn, "Spawn", SmokeSDKHook_Spawn, flags);
		}
	}

	tracked.entRef = entRef;
	tracked.entityIndex = entity;
	tracked.flags = flags;
	tracked.userid = userid;
	if (existing == -1)
	{
		g_SmokeSDKTrackedEntities.PushArray(tracked, sizeof(tracked));
	}
	else
	{
		g_SmokeSDKTrackedEntities.SetArray(existing, tracked, sizeof(tracked));
	}
}

void SmokeSDK_RecordDamageHooks(int entity, int &flags)
{
	SmokeSDK_RecordHook(entity, SDKHook_OnTakeDamage, SmokeSDK_OnTakeDamage, "OnTakeDamage", SmokeSDKHook_Damage, flags);
	SmokeSDK_RecordHook(entity, SDKHook_OnTakeDamagePost, SmokeSDK_OnTakeDamagePost, "OnTakeDamagePost", SmokeSDKHook_DamagePost, flags);
}

bool SmokeSDK_IsWitch(int entity)
{
	char classname[64];
	if (!GetEntityClassname(entity, classname, sizeof(classname)))
	{
		return false;
	}

	return StrEqual(classname, SMOKE_SDK_CLASS_WITCH) || StrEqual(classname, SMOKE_SDK_CLASS_WITCH_BRIDE);
}

int SmokeSDK_FindTracked(int entRef)
{
	SmokeSDKTrackedEntity tracked;
	for (int i = 0; i < g_SmokeSDKTrackedEntities.Length; i++)
	{
		g_SmokeSDKTrackedEntities.GetArray(i, tracked, sizeof(tracked));
		if (tracked.entRef == entRef)
		{
			return i;
		}
	}

	return -1;
}

void SmokeSDK_RecordHook(int entity, SDKHookType hookType, SDKHookCB callback, const char[] callbackName, SmokeSDKHookFlags flag, int &flags)
{
	if (flags & view_as<int>(flag))
	{
		return;
	}

	int sequence = TraceBegin(TraceSource_SDKHooks, "coverage");
	bool hooked = SDKHookEx(entity, hookType, callback);
	TraceEntityValue(TraceSource_SDKHooks, sequence, "entity", entity);
	TraceIntValue(TraceSource_SDKHooks, sequence, "entref", EntIndexToEntRef(entity));
	TraceIntValue(TraceSource_SDKHooks, sequence, "userid", entity <= MaxClients ? GetClientUserId(entity) : 0);
	TraceLine(TraceSource_SDKHooks, "{\"kind\":\"coverage\",\"seq\":%d,\"callback\":\"%s\",\"hooked\":%d}", sequence, callbackName, hooked);
	if (hooked)
	{
		flags |= view_as<int>(flag);
	}
}

void SmokeSDK_UnhookFlags(int entity, int flags)
{
	if (flags & view_as<int>(SmokeSDKHook_Damage))
	{
		SDKUnhook(entity, SDKHook_OnTakeDamage, SmokeSDK_OnTakeDamage);
	}
	if (flags & view_as<int>(SmokeSDKHook_DamagePost))
	{
		SDKUnhook(entity, SDKHook_OnTakeDamagePost, SmokeSDK_OnTakeDamagePost);
	}
	if (flags & view_as<int>(SmokeSDKHook_TraceAttack))
	{
		SDKUnhook(entity, SDKHook_TraceAttack, SmokeSDK_OnTraceAttack);
	}
	if (flags & view_as<int>(SmokeSDKHook_Touch))
	{
		SDKUnhook(entity, SDKHook_Touch, SmokeSDK_OnTouch);
	}
	if (flags & view_as<int>(SmokeSDKHook_Spawn))
	{
		SDKUnhook(entity, SDKHook_Spawn, SmokeSDK_OnSpawn);
	}
}

Action SmokeSDK_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	int sequence = SmokeSDK_BeginCallback("OnTakeDamage", victim);
	SmokeSDK_RecordDamage(sequence, victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition);
	TraceIntValue(TraceSource_SDKHooks, sequence, "listener_action", view_as<int>(Plugin_Continue));
	return Plugin_Continue;
}

void SmokeSDK_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3])
{
	int sequence = SmokeSDK_BeginCallback("OnTakeDamagePost", victim);
	SmokeSDK_RecordDamage(sequence, victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition);
}

void SmokeSDK_RecordDamage(int sequence, int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3])
{
	SmokeSDK_RecordEntity(sequence, "victim", victim);
	SmokeSDK_RecordEntity(sequence, "attacker", attacker);
	SmokeSDK_RecordEntity(sequence, "inflictor", inflictor);
	SmokeSDK_RecordEntity(sequence, "weapon", weapon);
	TraceFloatValue(TraceSource_SDKHooks, sequence, "damage", damage);
	TraceIntValue(TraceSource_SDKHooks, sequence, "damagetype", damagetype);
	TraceVectorValue(TraceSource_SDKHooks, sequence, "damage_force", damageForce);
	TraceVectorValue(TraceSource_SDKHooks, sequence, "damage_position", damagePosition);
}

Action SmokeSDK_OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	int sequence = SmokeSDK_BeginCallback("TraceAttack", victim);
	SmokeSDK_RecordEntity(sequence, "victim", victim);
	SmokeSDK_RecordEntity(sequence, "attacker", attacker);
	SmokeSDK_RecordEntity(sequence, "inflictor", inflictor);
	TraceFloatValue(TraceSource_SDKHooks, sequence, "damage", damage);
	TraceIntValue(TraceSource_SDKHooks, sequence, "damagetype", damagetype);
	TraceIntValue(TraceSource_SDKHooks, sequence, "ammotype", ammotype);
	TraceIntValue(TraceSource_SDKHooks, sequence, "hitbox", hitbox);
	TraceIntValue(TraceSource_SDKHooks, sequence, "hitgroup", hitgroup);
	TraceIntValue(TraceSource_SDKHooks, sequence, "listener_action", view_as<int>(Plugin_Continue));
	return Plugin_Continue;
}

Action SmokeSDK_OnTouch(int entity, int other)
{
	int sequence = SmokeSDK_BeginCallback("Touch", entity);
	SmokeSDK_RecordEntity(sequence, "entity", entity);
	SmokeSDK_RecordEntity(sequence, "other", other);
	TraceIntValue(TraceSource_SDKHooks, sequence, "listener_action", view_as<int>(Plugin_Continue));
	return Plugin_Continue;
}

Action SmokeSDK_OnSpawn(int entity)
{
	int sequence = SmokeSDK_BeginCallback("Spawn", entity);
	SmokeSDK_RecordEntity(sequence, "entity", entity);
	TraceIntValue(TraceSource_SDKHooks, sequence, "listener_action", view_as<int>(Plugin_Continue));
	return Plugin_Continue;
}

int SmokeSDK_BeginCallback(const char[] callbackName, int entity)
{
	int sequence = TraceBegin(TraceSource_SDKHooks, callbackName);
	SmokeSDK_RecordEntity(sequence, "hooked_entity", entity);
	TraceIntValue(TraceSource_SDKHooks, sequence, "userid", entity > 0 && entity <= MaxClients && IsClientInGame(entity) ? GetClientUserId(entity) : 0);
	return sequence;
}

void SmokeSDK_RecordEntity(int sequence, const char[] key, int entity)
{
	TraceEntityValue(TraceSource_SDKHooks, sequence, key, entity);
	if (entity > 0 && entity <= MaxClients && IsClientInGame(entity))
	{
		char useridKey[64];
		Format(useridKey, sizeof(useridKey), "%s_userid", key);
		TraceIntValue(TraceSource_SDKHooks, sequence, useridKey, GetClientUserId(entity));
	}
}
