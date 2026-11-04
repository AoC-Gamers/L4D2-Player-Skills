/**
 * @brief Lightweight runtime wrapper over a boss session slot.
 * @remarks Exposes helpers to initialize, reset and update tracked Tank/Witch
 *          sessions stored in g_BossSessions.
 */
methodmap L4D2BossSession
{
	/**
	 * @brief Wraps a raw boss session slot index.
	 *
	 * @param index         Zero-based slot in g_BossSessions.
	 */
	public L4D2BossSession(int index)
	{
		return view_as<L4D2BossSession>(index);
	}

	property int Index
	{
		/**
		 * @brief Returns the raw slot index represented by this wrapper.
		 */
		public get()
		{
			return view_as<int>(this);
		}
	}

	/**
	 * @brief Checks whether the wrapped session slot is currently in use.
	 *
	 * @return              True if the slot contains a valid runtime session.
	 */
	public bool IsValid()
	{
		int index = this.Index;
		return index >= 0 && index < L4D2_SKILLS_MAX_BOSSES && g_BossSessions[index].id > 0;
	}

	/**
	 * @brief Clears the session and all captured damage entries for this slot.
	 *
	 * @noreturn
	 */
	public void Reset()
	{
		int index = this.Index;
		g_BossSessions[index].Reset();

		for (int entry = 0; entry < L4D2_SKILLS_MAX_DAMAGE_ENTRIES; entry++)
		{
			g_BossDamage[index][entry].Reset();
		}
	}

	/**
	 * @brief Starts a new boss session in the wrapped slot.
	 *
	 * @param type          Boss type to track.
	 * @param entity        Current entity index for the boss.
	 * @param userid        Userid of the current controller when applicable.
	 * @param maxHealth     Expected maximum health captured for this session.
	 *
	 * @noreturn
	 */
	public void Start(L4D2BossType type, int entity, int userid, int maxHealth)
	{
		int index = this.Index;

		this.Reset();

		g_BossSessions[index].id		 = ++g_iBossSerial;
		g_BossSessions[index].type		 = type;
		g_BossSessions[index].state		 = L4D2BossState_Active;
		g_BossSessions[index].entity	 = entity;
		g_BossSessions[index].entRef	 = entity > 0 ? EntIndexToEntRef(entity) : INVALID_ENT_REFERENCE;
		g_BossSessions[index].userid	 = userid;
		g_BossSessions[index].maxHealth	 = maxHealth;
		// maxHealth is the captured expected maximum; lastHealth is a current observation.
		int observedHealth = maxHealth;
		if (type == L4D2Boss_Tank && IsValidClient(entity))
		{
			observedHealth = GetClientHealth(entity);
		}
		g_BossSessions[index].lastHealth = observedHealth;
		g_BossSessions[index].startedAt	 = GetGameTime();
		g_BossSessions[index].closedAt	 = 0.0;
		g_BossSessions[index].printed	 = false;
		if (type == L4D2Boss_Tank)
		{
			g_BossSessions[index].tank.lifecycleId = ++g_iTankLifecycleSerial;
		}

		int client						 = GetClientOfUserId(userid);
		if (IsValidClient(client))
		{
			this.UpdateOwnerSnapshot(client);
			if (type != L4D2Boss_Tank || !IsFakeClient(client))
			{
				this.RefreshOwner(client);
			}
		}
	}

	public void UpdateOwnerSnapshot(int client)
	{
		if (!this.IsValid() || !IsValidClient(client))
		{
			return;
		}

		g_BossSessions[this.Index].userid = GetClientUserId(client);
		g_BossSessions[this.Index].entity = client;
		g_BossSessions[this.Index].entRef = EntIndexToEntRef(client);
		g_BossSessions[this.Index].owner.Capture(client);
	}

	public void CancelPendingTankBotControl()
	{
		if (!this.IsValid() || g_BossSessions[this.Index].type != L4D2Boss_Tank)
		{
			return;
		}

		g_BossSessions[this.Index].tank.pendingBotControl = false;
		g_BossSessions[this.Index].tank.pendingBotUserid = 0;
		g_BossSessions[this.Index].tank.pendingBotStartedAt = 0.0;
	}

	public void BeginPendingTankBotControl(int client, float startTime = 0.0)
	{
		if (!this.IsValid()
			|| g_BossSessions[this.Index].type != L4D2Boss_Tank
			|| !IsValidClient(client)
			|| !IsFakeClient(client))
		{
			return;
		}

		if (startTime <= 0.0)
		{
			startTime = GetGameTime();
		}

		this.UpdateOwnerSnapshot(client);

		int activeIndex = g_BossSessions[this.Index].tank.activeControlIndex;
		if (activeIndex >= 0
			&& activeIndex < L4D2_SKILLS_MAX_TANK_CONTROLS
			&& g_BossSessions[this.Index].tank.controls[activeIndex].active
			&& !g_BossSessions[this.Index].tank.controls[activeIndex].player.IsSamePersistentPlayer(client))
		{
			this.CloseActiveTankControl(startTime);
		}

		if (g_BossSessions[this.Index].tank.pendingBotControl
			&& g_BossSessions[this.Index].tank.pendingBotUserid == GetClientUserId(client))
		{
			if (g_BossSessions[this.Index].tank.pendingBotStartedAt <= 0.0
				|| startTime < g_BossSessions[this.Index].tank.pendingBotStartedAt)
			{
				g_BossSessions[this.Index].tank.pendingBotStartedAt = startTime;
			}

			return;
		}

		g_BossSessions[this.Index].tank.pendingBotControl = true;
		g_BossSessions[this.Index].tank.pendingBotUserid = GetClientUserId(client);
		g_BossSessions[this.Index].tank.pendingBotStartedAt = startTime;
	}

	public void CloseActiveTankControl(float endTime = 0.0)
	{
		if (!this.IsValid() || g_BossSessions[this.Index].type != L4D2Boss_Tank)
		{
			return;
		}

		int index = this.Index;
		int controlIndex = g_BossSessions[index].tank.activeControlIndex;
		if (controlIndex < 0 || controlIndex >= L4D2_SKILLS_MAX_TANK_CONTROLS)
		{
			return;
		}

		if (!g_BossSessions[index].tank.controls[controlIndex].active
			|| g_BossSessions[index].tank.controls[controlIndex].startedAt <= 0.0)
		{
			g_BossSessions[index].tank.activeControlIndex = -1;
			return;
		}

		if (endTime <= 0.0)
		{
			endTime = GetGameTime();
		}

		if (endTime < g_BossSessions[index].tank.controls[controlIndex].startedAt)
		{
			endTime = g_BossSessions[index].tank.controls[controlIndex].startedAt;
		}

		g_BossSessions[index].tank.controls[controlIndex].endedAt = endTime;
		g_BossSessions[index].tank.controls[controlIndex].controlTime +=
			endTime - g_BossSessions[index].tank.controls[controlIndex].startedAt;
		g_BossSessions[index].tank.controls[controlIndex].remainingHealth = g_BossSessions[index].lastHealth;
		g_BossSessions[index].tank.controls[controlIndex].startedAt = 0.0;
		g_BossSessions[index].tank.activeControlIndex = -1;
	}

		public void OpenTankControl(int client, float startTime = 0.0)
		{
			if (!this.IsValid() || g_BossSessions[this.Index].type != L4D2Boss_Tank || !IsValidClient(client))
			{
				return;
			}

			if (startTime <= 0.0)
			{
				startTime = GetGameTime();
			}

			int index = this.Index;
			int activeIndex = g_BossSessions[index].tank.activeControlIndex;
			if (activeIndex >= 0
				&& activeIndex < L4D2_SKILLS_MAX_TANK_CONTROLS
				&& g_BossSessions[index].tank.controls[activeIndex].active)
			{
				if (g_BossSessions[index].tank.controls[activeIndex].player.IsSamePersistentPlayer(client))
				{
					g_BossSessions[index].tank.controls[activeIndex].player.Capture(client);
					return;
				}

				this.CloseActiveTankControl();
			}

			if (g_BossSessions[index].tank.controlCount >= L4D2_SKILLS_MAX_TANK_CONTROLS)
			{
				int overflowIndex = L4D2_SKILLS_MAX_TANK_CONTROLS - 1;
			g_BossSessions[index].tank.controls[overflowIndex].mergedControls++;
			g_BossSessions[index].tank.controls[overflowIndex].active = true;
			g_BossSessions[index].tank.controls[overflowIndex].overflow = true;
			g_BossSessions[index].tank.controls[overflowIndex].player.Capture(client);
			g_BossSessions[index].tank.controls[overflowIndex].startedAt = startTime;
			g_BossSessions[index].tank.activeControlIndex = overflowIndex;
			return;
		}

		int controlIndex = g_BossSessions[index].tank.controlCount++;
		g_BossSessions[index].tank.controls[controlIndex].Reset();
		g_BossSessions[index].tank.controls[controlIndex].active = true;
		g_BossSessions[index].tank.controls[controlIndex].overflow = false;
		g_BossSessions[index].tank.controls[controlIndex].mergedControls = 1;
		g_BossSessions[index].tank.controls[controlIndex].player.Capture(client);
		g_BossSessions[index].tank.controls[controlIndex].startedAt = startTime;
		g_BossSessions[index].tank.activeControlIndex = controlIndex;
	}

	public void RecordTankRockThrown()
	{
		if (!this.IsValid() || g_BossSessions[this.Index].type != L4D2Boss_Tank)
		{
			return;
		}

		int controlIndex = g_BossSessions[this.Index].tank.activeControlIndex;
		if (controlIndex < 0 || controlIndex >= L4D2_SKILLS_MAX_TANK_CONTROLS)
		{
			return;
		}

		g_BossSessions[this.Index].tank.controls[controlIndex].rocksThrown++;
	}

	public void RecordTankRockHit()
	{
		if (!this.IsValid() || g_BossSessions[this.Index].type != L4D2Boss_Tank)
		{
			return;
		}

		int controlIndex = g_BossSessions[this.Index].tank.activeControlIndex;
		if (controlIndex < 0 || controlIndex >= L4D2_SKILLS_MAX_TANK_CONTROLS)
		{
			return;
		}

		g_BossSessions[this.Index].tank.controls[controlIndex].rocksHit++;
	}

	/**
	 * @brief Refreshes the owner snapshot for a player-controlled boss.
	 *
	 * @param client        Client index of the current controller.
	 *
	 * @noreturn
	 */
	public 	void RefreshOwner(int client)
	{
		if (!this.IsValid() || !IsValidClient(client))
		{
			return;
		}

		this.UpdateOwnerSnapshot(client);

		if (g_BossSessions[this.Index].type == L4D2Boss_Tank)
		{
			if (IsFakeClient(client))
			{
				int activeIndex = g_BossSessions[this.Index].tank.activeControlIndex;
				if (activeIndex >= 0
					&& activeIndex < L4D2_SKILLS_MAX_TANK_CONTROLS
					&& g_BossSessions[this.Index].tank.controls[activeIndex].active
					&& g_BossSessions[this.Index].tank.controls[activeIndex].player.IsSamePersistentPlayer(client))
				{
					g_BossSessions[this.Index].tank.controls[activeIndex].player.Capture(client);
					this.CancelPendingTankBotControl();
					return;
				}

				this.BeginPendingTankBotControl(client);
				return;
			}

			this.CancelPendingTankBotControl();
			this.OpenTankControl(client);
		}
	}

	/**
	 * @brief Adds survivor damage to the current boss session.
	 *
	 * @param attacker      Survivor client index that dealt the damage.
	 * @param damage        Positive damage amount to accumulate.
	 *
	 * @noreturn
	 */
	public 	void AddDamage(int attacker, int damage, bool countShot = false)
	{
		if (!this.IsValid() || !IsValidSurvivor(attacker) || damage <= 0)
		{
			return;
		}

		int index = this.Index;
		int entry = Boss_FindOrCreateDamageEntry(index, attacker);
		if (entry == -1)
		{
			return;
		}

		if (!g_BossDamage[index][entry].active)
		{
			g_BossDamage[index][entry].active = true;
			g_BossDamage[index][entry].player.Capture(attacker);
		}

		g_BossDamage[index][entry].damage += damage;
		if (countShot)
		{
			g_BossDamage[index][entry].shots++;
		}
		g_BossSessions[index].totalDamage += damage;
	}
}
