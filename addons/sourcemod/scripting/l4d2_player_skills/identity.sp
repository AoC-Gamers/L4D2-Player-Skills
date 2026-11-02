// Internal identity responsibility; public contracts remain in the include.

/**
 * @brief Resolves a userid back to a live client index when possible.
 *
 * @param userid         Runtime Source client userid.
 *
 * @return               Client index, or 0 if the userid is no longer online.
 */
stock int ResolveClientFromUserId(int userid)
{
	int client = GetClientOfUserId(userid);
	return IsValidClient(client) ? client : 0;
}

stock int Skills_GetClientSurvivorCharacter(int client)
{
	if (!IsValidSurvivor(client))
	{
		return L4D2Util_SurvivorCharacter_Invalid;
	}

	int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	return (character >= 0 && character < L4D2Util_SurvivorCharacter_Size)
		? character
		: L4D2Util_SurvivorCharacter_Invalid;
}

stock void Skills_ResetIdentityCache()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		g_IdentityCache[i].Reset();
	}
}

stock int Skills_FindIdentityCacheSlotByAccountId(int accountId)
{
	if (accountId <= 0)
	{
		return -1;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_IdentityCache[i].active && !g_IdentityCache[i].ref.bot && g_IdentityCache[i].ref.accountId == accountId)
		{
			return i;
		}
	}

	return -1;
}

stock int Skills_FindIdentityCacheSlotByBotCharacter(int survivorCharacter)
{
	if (survivorCharacter < 0)
	{
		return -1;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_IdentityCache[i].active && g_IdentityCache[i].ref.bot && g_IdentityCache[i].ref.character == survivorCharacter)
		{
			return i;
		}
	}

	return -1;
}

stock int Skills_FindIdentityCacheSlotByUserId(int userid)
{
	if (userid <= 0)
	{
		return -1;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_IdentityCache[i].active && g_IdentityCache[i].ref.userid == userid)
		{
			return i;
		}
	}

	return -1;
}

stock int Skills_FindIdentityCacheSlotForClient(int client)
{
	if (!IsValidClient(client))
	{
		return -1;
	}

	if (!IsFakeClient(client))
	{
		return Skills_FindIdentityCacheSlotByAccountId(GetSteamAccountID(client));
	}

	int survivorCharacter = Skills_GetClientSurvivorCharacter(client);
	if (survivorCharacter != L4D2Util_SurvivorCharacter_Invalid)
	{
		return Skills_FindIdentityCacheSlotByBotCharacter(survivorCharacter);
	}

	return Skills_FindIdentityCacheSlotByUserId(GetClientUserId(client));
}

stock int Skills_FindOrCreateIdentityCacheSlotForClient(int client)
{
	if (!IsValidClient(client))
	{
		return -1;
	}

	int slot = Skills_FindIdentityCacheSlotForClient(client);
	if (slot != -1)
	{
		return slot;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_IdentityCache[i].active)
		{
			return i;
		}
	}

	return -1;
}

stock void Skills_CaptureIdentityForClient(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}

	int slot = Skills_FindOrCreateIdentityCacheSlotForClient(client);
	if (slot == -1)
	{
		return;
	}

	g_IdentityCache[slot].active = true;
	g_IdentityCache[slot].ref.Capture(client);
}

stock void Skills_DetachIdentityClient(int client)
{
	if (client < 1 || client > MaxClients)
	{
		return;
	}

	int userid = GetClientUserId(client);
	if (userid <= 0)
	{
		return;
	}

	int slot = Skills_FindIdentityCacheSlotByUserId(userid);
	if (slot == -1)
	{
		return;
	}

	g_IdentityCache[slot].ref.DetachClient();
}

stock bool Skills_TryResolveIdentityName(int accountId, bool bot, int survivorCharacter, int userid, char[] buffer, int maxlen)
{
	buffer[0] = '\0';

	int slot = -1;
	if (!bot && accountId > 0)
	{
		slot = Skills_FindIdentityCacheSlotByAccountId(accountId);
	}
	else if (bot && survivorCharacter != L4D2Util_SurvivorCharacter_Invalid)
	{
		slot = Skills_FindIdentityCacheSlotByBotCharacter(survivorCharacter);
	}

	if (slot == -1 && userid > 0)
	{
		slot = Skills_FindIdentityCacheSlotByUserId(userid);
	}

	if (slot == -1 || !g_IdentityCache[slot].active || g_IdentityCache[slot].ref.name[0] == '\0')
	{
		return false;
	}

	strcopy(buffer, maxlen, g_IdentityCache[slot].ref.name);
	return true;
}

stock bool Skills_TryResolveIdentityClient(int accountId, bool bot, int survivorCharacter, int userid, int &client)
{
	client = 0;

	if (!bot && accountId > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i) || IsFakeClient(i))
			{
				continue;
			}

			if (GetSteamAccountID(i) == accountId)
			{
				client = i;
				return true;
			}
		}
	}
	else if (bot && survivorCharacter != L4D2Util_SurvivorCharacter_Invalid)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i) || !IsFakeClient(i) || !IsValidSurvivor(i))
			{
				continue;
			}

			if (GetEntProp(i, Prop_Send, "m_survivorCharacter") == survivorCharacter)
			{
				client = i;
				return true;
			}
		}
	}

	if (userid > 0)
	{
		client = ResolveClientFromUserId(userid);
		return client > 0;
	}

	return false;
}

stock bool Skills_IsClientMatchingIdentity(int client, int accountId, bool bot, int survivorCharacter, int userid)
{
	if (!IsValidClient(client))
	{
		return false;
	}

	if (!bot && accountId > 0 && !IsFakeClient(client) && GetSteamAccountID(client) == accountId)
	{
		return true;
	}

	if (bot && IsFakeClient(client))
	{
		if (survivorCharacter != L4D2Util_SurvivorCharacter_Invalid
			&& IsValidSurvivor(client)
			&& GetEntProp(client, Prop_Send, "m_survivorCharacter") == survivorCharacter)
		{
			return true;
		}

		if (userid > 0 && GetClientUserId(client) == userid)
		{
			return true;
		}
	}

	return userid > 0 && GetClientUserId(client) == userid;
}

stock bool Skills_TryBuildPlayerRefFromIdentity(int accountId, bool bot, int survivorCharacter, int userid, L4D2PlayerRef player)
{
	player.Reset();

	int client = 0;
	if (Skills_TryResolveIdentityClient(accountId, bot, survivorCharacter, userid, client))
	{
		player.Capture(client);
		return true;
	}

	player.userid = userid;
	player.accountId = accountId;
	player.bot = bot;
	player.team = L4DTeam_Unassigned;
	player.character = survivorCharacter;
	player.zombieClass = L4D2ZombieClass_NotInfected;

	if (Skills_TryResolveIdentityName(accountId, bot, survivorCharacter, userid, player.name, sizeof(player.name)))
	{
		int slot = -1;
		if (!bot && accountId > 0)
		{
			slot = Skills_FindIdentityCacheSlotByAccountId(accountId);
		}
		else if (bot && survivorCharacter != L4D2Util_SurvivorCharacter_Invalid)
		{
			slot = Skills_FindIdentityCacheSlotByBotCharacter(survivorCharacter);
		}

		if (slot == -1 && userid > 0)
		{
			slot = Skills_FindIdentityCacheSlotByUserId(userid);
		}

		if (slot != -1 && g_IdentityCache[slot].active)
		{
			player.team = g_IdentityCache[slot].ref.team;
			player.zombieClass = g_IdentityCache[slot].ref.zombieClass;
		}

		return true;
	}

	if (bot && survivorCharacter != L4D2Util_SurvivorCharacter_Invalid)
	{
		GetSurvivorNameByIndex(survivorCharacter, player.name, sizeof(player.name));
		return true;
	}

	return player.userid > 0 || player.accountId > 0;
}

/**
 * @brief Returns the typed L4D team for a client.
 *
 * @param client         Client index to inspect.
 *
 * @return               Team enum, or L4DTeam_Unassigned if invalid.
 */
stock L4DTeam GetClientL4DTeam(int client)
{
	return IsValidClient(client) ? L4D_GetClientTeam(client) : L4DTeam_Unassigned;
}
