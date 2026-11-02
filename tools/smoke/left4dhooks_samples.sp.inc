// Manual snapshots of Left4DHooks calls used by the Skills core.
// SmokeLH_Sample is called only by the separate admin command while capture is
// active; it performs no automatic polling and mutates no game state.

void SmokeLH_Sample()
{
	if (!g_Runtime.configsReady)
	{
		SmokeLH_Skip("all", "configs_not_ready");
		return;
	}

	int sampled;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		SmokeLH_SampleClient(client);
		sampled++;
	}
	if (sampled == 0) SmokeLH_Skip("client_queries", "no_in_game_clients");

	SmokeLH_SampleModeNative();
	SmokeLH_SampleSafeAreaNative();
	SmokeLH_SamplePendingTankStock();

	int weaponSeq = SmokeLH_Begin("stock:L4D2_GetWeaponIdByWeaponName");
	TraceTextValue(TraceSource_Left4DHooks, weaponSeq, "weaponName", "weapon_pistol");
	TraceIntValue(TraceSource_Left4DHooks, weaponSeq, "result",
		view_as<int>(L4D2_GetWeaponIdByWeaponName("weapon_pistol")));
}

void SmokeLH_SampleClient(int client)
{
	int survivor = GetClientTeam(client) == 2 ? client : 0;
	int infected = GetClientTeam(client) == 3 ? client : 0;

	if (client > 0)
	{
		int teamSeq = SmokeLH_Begin("stock:L4D_GetClientTeam");
		TraceEntityValue(TraceSource_Left4DHooks, teamSeq, "client", client);
		TraceIntValue(TraceSource_Left4DHooks, teamSeq, "result", L4D_GetClientTeam(client));

		if (HasEntProp(client, Prop_Send, "m_isIncapacitated"))
		{
			int seq = SmokeLH_Begin("stock:L4D_IsPlayerIncapacitated");
			TraceEntityValue(TraceSource_Left4DHooks, seq, "client", client);
			TraceIntValue(TraceSource_Left4DHooks, seq, "result", L4D_IsPlayerIncapacitated(client));
		}
		else
		{
			SmokeLH_Skip("stock:L4D_IsPlayerIncapacitated", "missing_sendprop_m_isIncapacitated");
		}

		if (HasEntProp(client, Prop_Send, "m_isHangingFromLedge"))
		{
			int seq = SmokeLH_Begin("stock:L4D_IsPlayerHangingFromLedge");
			TraceEntityValue(TraceSource_Left4DHooks, seq, "client", client);
			TraceIntValue(TraceSource_Left4DHooks, seq, "result", L4D_IsPlayerHangingFromLedge(client));
		}
		else
		{
			SmokeLH_Skip("stock:L4D_IsPlayerHangingFromLedge", "missing_sendprop_m_isHangingFromLedge");
		}

		if (HasEntProp(client, Prop_Send, "m_customAbility"))
		{
			int seq = SmokeLH_Begin("stock:L4D_GetPlayerCustomAbility");
			TraceEntityValue(TraceSource_Left4DHooks, seq, "client", client);
			TraceEntityValue(TraceSource_Left4DHooks, seq, "result", L4D_GetPlayerCustomAbility(client));
		}
		else
		{
			SmokeLH_Skip("stock:L4D_GetPlayerCustomAbility", "missing_sendprop_m_customAbility");
		}

		if (HasEntProp(client, Prop_Send, "m_hActiveWeapon"))
		{
			int seq = SmokeLH_Begin("stock:L4D_GetPlayerCurrentWeapon");
			TraceEntityValue(TraceSource_Left4DHooks, seq, "client", client);
			TraceEntityValue(TraceSource_Left4DHooks, seq, "result", L4D_GetPlayerCurrentWeapon(client));
		}
		else
		{
			SmokeLH_Skip("stock:L4D_GetPlayerCurrentWeapon", "missing_sendprop_m_hActiveWeapon");
		}
	}
	else
	{
		SmokeLH_Skip("stock:L4D_GetClientTeam", "no_in_game_client");
		SmokeLH_Skip("stock:L4D_IsPlayerIncapacitated", "no_in_game_client");
		SmokeLH_Skip("stock:L4D_IsPlayerHangingFromLedge", "no_in_game_client");
		SmokeLH_Skip("stock:L4D_GetPlayerCustomAbility", "no_in_game_client");
		SmokeLH_Skip("stock:L4D_GetPlayerCurrentWeapon", "no_in_game_client");
	}

	if (infected > 0)
	{
		if (SmokeLH_HasSendProps(infected,
			"m_pummelVictim", "m_carryVictim", "m_pounceVictim", "m_tongueVictim", "m_jockeyVictim"))
		{
			int seq = SmokeLH_Begin("stock:L4D2_GetSurvivorVictim");
			TraceEntityValue(TraceSource_Left4DHooks, seq, "infected", infected);
			TraceEntityValue(TraceSource_Left4DHooks, seq, "result", L4D2_GetSurvivorVictim(infected));
		}
		else
		{
			SmokeLH_Skip("stock:L4D2_GetSurvivorVictim", "missing_required_sendprop");
		}

		if (HasEntProp(infected, Prop_Send, "m_zombieClass"))
		{
			int seq = SmokeLH_Begin("stock:L4D2_GetPlayerZombieClass");
			TraceEntityValue(TraceSource_Left4DHooks, seq, "client", infected);
			int zombieClass = view_as<int>(L4D2_GetPlayerZombieClass(infected));
			TraceIntValue(TraceSource_Left4DHooks, seq, "result", zombieClass);

			if (zombieClass >= view_as<int>(L4D2ZombieClass_Smoker)
				&& zombieClass <= view_as<int>(L4D2ZombieClass_NotInfected))
			{
				int nameSeq = SmokeLH_Begin("stock:L4D2_GetZombieClassname:className0based");
				TraceIntValue(TraceSource_Left4DHooks, nameSeq, "className0based", zombieClass - 1);
				TraceTextValue(TraceSource_Left4DHooks, nameSeq, "result",
					L4D2_GetZombieClassname(view_as<L4D2ZombieClassType>(zombieClass - 1)));
			}
			else
			{
				SmokeLH_Skip("stock:L4D2_GetZombieClassname", "zombie_class_out_of_range");
			}

			if (zombieClass == view_as<int>(L4D2ZombieClass_Charger))
			{
				int pummelOffset = FindSendPropInfo("CTerrorPlayer", "m_pummelAttacker");
				if (pummelOffset >= 0)
				{
					int seqPummel = SmokeLH_Begin("stock:L4D2_IsInQueuedPummel");
					TraceEntityValue(TraceSource_Left4DHooks, seqPummel, "charger", infected);
					TraceIntValue(TraceSource_Left4DHooks, seqPummel, "result", L4D2_IsInQueuedPummel(infected));

					int seqVictim = SmokeLH_Begin("stock:L4D2_GetQueuedPummelVictim");
					TraceEntityValue(TraceSource_Left4DHooks, seqVictim, "charger", infected);
					TraceEntityValue(TraceSource_Left4DHooks, seqVictim, "result", L4D2_GetQueuedPummelVictim(infected));
				}
				else
				{
					SmokeLH_Skip("stock:L4D2_IsInQueuedPummel", "missing_sendprop_m_pummelAttacker");
					SmokeLH_Skip("stock:L4D2_GetQueuedPummelVictim", "missing_sendprop_m_pummelAttacker");
				}
			}
			else
			{
				SmokeLH_Skip("stock:L4D2_IsInQueuedPummel", "sample_client_not_charger");
				SmokeLH_Skip("stock:L4D2_GetQueuedPummelVictim", "sample_client_not_charger");
			}
		}
		else
		{
			SmokeLH_Skip("stock:L4D2_GetPlayerZombieClass", "missing_sendprop_m_zombieClass");
			SmokeLH_Skip("stock:L4D2_GetZombieClassname", "missing_sendprop_m_zombieClass");
			SmokeLH_Skip("stock:L4D2_IsInQueuedPummel", "missing_sendprop_m_zombieClass");
			SmokeLH_Skip("stock:L4D2_GetQueuedPummelVictim", "missing_sendprop_m_zombieClass");
		}
	}
	else
	{
		SmokeLH_Skip("stock:L4D2_GetSurvivorVictim", "no_in_game_infected");
		SmokeLH_Skip("stock:L4D2_GetPlayerZombieClass", "no_in_game_infected");
		SmokeLH_Skip("stock:L4D2_GetZombieClassname", "no_in_game_infected");
		SmokeLH_Skip("stock:L4D2_IsInQueuedPummel", "no_in_game_infected");
		SmokeLH_Skip("stock:L4D2_GetQueuedPummelVictim", "no_in_game_infected");
	}

	if (survivor > 0)
	{
		if (SmokeLH_HasSendProps(survivor,
			"m_pummelAttacker", "m_carryAttacker", "m_pounceAttacker", "m_tongueOwner", "m_jockeyAttacker"))
		{
			int seq = SmokeLH_Begin("stock:L4D2_GetInfectedAttacker");
			TraceEntityValue(TraceSource_Left4DHooks, seq, "survivor", survivor);
			TraceEntityValue(TraceSource_Left4DHooks, seq, "result", L4D2_GetInfectedAttacker(survivor));
		}
		else
		{
			SmokeLH_Skip("stock:L4D2_GetInfectedAttacker", "missing_required_sendprop");
		}

		if (HasEntProp(survivor, Prop_Send, "m_tongueOwner"))
		{
			int seq = SmokeLH_Begin("stock:L4D_GetAttackerSmoker");
			TraceEntityValue(TraceSource_Left4DHooks, seq, "survivor", survivor);
			TraceEntityValue(TraceSource_Left4DHooks, seq, "result", L4D_GetAttackerSmoker(survivor));
		}
		else
		{
			SmokeLH_Skip("stock:L4D_GetAttackerSmoker", "missing_sendprop_m_tongueOwner");
		}

		if (HasEntProp(survivor, Prop_Send, "m_reachedTongueOwner"))
		{
			int seq = SmokeLH_Begin("stock:L4D_HasReachedSmoker");
			TraceEntityValue(TraceSource_Left4DHooks, seq, "survivor", survivor);
			TraceIntValue(TraceSource_Left4DHooks, seq, "result", L4D_HasReachedSmoker(survivor));
		}
		else
		{
			SmokeLH_Skip("stock:L4D_HasReachedSmoker", "missing_sendprop_m_reachedTongueOwner");
		}

		SmokeLH_SampleDominatingNative(survivor);
	}
	else
	{
		SmokeLH_Skip("stock:L4D2_GetInfectedAttacker", "no_in_game_survivor");
		SmokeLH_Skip("stock:L4D_GetAttackerSmoker", "no_in_game_survivor");
		SmokeLH_Skip("stock:L4D_HasReachedSmoker", "no_in_game_survivor");
		SmokeLH_Skip("native:L4D2_GetSpecialInfectedDominatingMe", "no_in_game_survivor");
	}

}

void SmokeLH_SampleModeNative()
{
	if (!SmokeLH_NativeAvailable("L4D_GetGameModeType"))
	{
		SmokeLH_SkipNative("L4D_GetGameModeType");
		return;
	}

	int seq = SmokeLH_Begin("native:L4D_GetGameModeType");
	TraceIntValue(TraceSource_Left4DHooks, seq, "result", L4D_GetGameModeType());
}

void SmokeLH_SampleSafeAreaNative()
{
	if (!SmokeLH_NativeAvailable("L4D_HasAnySurvivorLeftSafeArea"))
	{
		SmokeLH_SkipNative("L4D_HasAnySurvivorLeftSafeArea");
		return;
	}

	int seq = SmokeLH_Begin("native:L4D_HasAnySurvivorLeftSafeArea");
	TraceIntValue(TraceSource_Left4DHooks, seq, "result", L4D_HasAnySurvivorLeftSafeArea());
}

void SmokeLH_SampleDominatingNative(int survivor)
{
	if (!SmokeLH_NativeAvailable("L4D2_GetSpecialInfectedDominatingMe"))
	{
		SmokeLH_SkipNative("L4D2_GetSpecialInfectedDominatingMe");
		return;
	}

	int seq = SmokeLH_Begin("native:L4D2_GetSpecialInfectedDominatingMe");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "survivor", survivor);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "result", L4D2_GetSpecialInfectedDominatingMe(survivor));
}

void SmokeLH_SamplePendingTankStock()
{
	int resource = FindEntityByClassname(-1, "terror_player_manager");
	if (resource == -1)
	{
		SmokeLH_Skip("stock:L4D_GetPendingTankPlayer", "resource_entity_unavailable");
		return;
	}

	if (!HasEntProp(resource, Prop_Send, "m_pendingTankPlayerIndex"))
	{
		SmokeLH_Skip("stock:L4D_GetPendingTankPlayer", "missing_sendprop_m_pendingTankPlayerIndex");
		return;
	}

	int seq = SmokeLH_Begin("stock:L4D_GetPendingTankPlayer");
	TraceEntityValue(TraceSource_Left4DHooks, seq, "resource", resource);
	TraceEntityValue(TraceSource_Left4DHooks, seq, "result", L4D_GetPendingTankPlayer());
}

bool SmokeLH_NativeAvailable(const char[] nativeName)
{
	return g_Runtime.hasLeft4DHooks
		&& g_Runtime.configsReady
		&& GetFeatureStatus(FeatureType_Native, nativeName) == FeatureStatus_Available;
}

void SmokeLH_SkipNative(const char[] nativeName)
{
	char reason[96];
	char query[128];
	if (!g_Runtime.hasLeft4DHooks)
	{
		strcopy(reason, sizeof(reason), "left4dhooks_library_unavailable");
	}
	else if (!g_Runtime.configsReady)
	{
		strcopy(reason, sizeof(reason), "configs_not_ready");
	}
	else
	{
		Format(reason, sizeof(reason), "native_unavailable:%s", nativeName);
	}

	Format(query, sizeof(query), "native:%s", nativeName);
	SmokeLH_Skip(query, reason);
}

int SmokeLH_Begin(const char[] query)
{
	int seq = TraceBegin(TraceSource_Left4DHooks, query);
	TraceLine(TraceSource_Left4DHooks,
		"{\"kind\":\"manual_state_sample\",\"query\":\"%s\",\"seq\":%d}", query, seq);
	return seq;
}

void SmokeLH_Skip(const char[] query, const char[] reason)
{
	int sequence = TraceBegin(TraceSource_Left4DHooks, "sample_skipped");
	TraceLine(TraceSource_Left4DHooks,
		"{\"kind\":\"manual_state_sample_skipped\",\"query\":\"%s\",\"reason\":\"%s\",\"seq\":%d}",
		query, reason, sequence);
}

bool SmokeLH_HasSendProps(int client, const char[] prop1, const char[] prop2, const char[] prop3, const char[] prop4, const char[] prop5)
{
	return HasEntProp(client, Prop_Send, prop1)
		&& HasEntProp(client, Prop_Send, prop2)
		&& HasEntProp(client, Prop_Send, prop3)
		&& HasEntProp(client, Prop_Send, prop4)
		&& HasEntProp(client, Prop_Send, prop5);
}
