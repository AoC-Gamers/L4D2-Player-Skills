#if defined _l4d2_player_skills_detect_observations_included
#endinput
#endif
#define _l4d2_player_skills_detect_observations_included

// Snapshot of one player_hurt input; weapon retains the original 32-byte buffer.
enum struct SkillsDamageObservation
{
	int victim;
	int attacker;
	int damage;
	int damageType;
	int hitgroup;
	int entityId;
	int weaponId;
	char weapon[32];
}

// Snapshot of one player_death input; death consumers historically read weapon into 64 bytes.
enum struct SkillsDeathObservation
{
	int victim;
	int attacker;
	int damage;
	bool headshot;
	char weapon[64];
}
