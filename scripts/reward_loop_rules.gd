@tool
class_name RewardLoopRules
extends RefCounted

const BASE_REWARD_VALUE := 2
const BASE_ENEMY_SPAWN_INTERVAL := 1.15
const MIN_ENEMY_SPAWN_INTERVAL := 0.42
const BASIC_ENEMY_SPEED := 88.0
const ELITE_ENEMY_SPEED := 58.0
const BASE_UPGRADE_THRESHOLD := 45
const UPGRADE_THRESHOLD_STEP := 18
const SESSION_LENGTH := 180.0
const CHEST_EARN_TIME := 95.0
const CHEST_SCORE_REQUIREMENT := 1500
const PLAYER_SPEED := 220.0
const PLAYER_HEALTH := 6
const ATTACK_INTERVAL := 0.62
const ATTACK_RANGE := 190.0
const FEEDBACK_INTENSITY := 1.0


static func xp_required_for_level(level: int) -> int:
	return BASE_UPGRADE_THRESHOLD + max(level - 1, 0) * UPGRADE_THRESHOLD_STEP


static func should_offer_upgrade(xp: int, level: int) -> bool:
	return xp >= xp_required_for_level(level)


static func spawn_interval_for_time(elapsed_seconds: float) -> float:
	var reduction: float = floor(elapsed_seconds / 30.0) * 0.12
	return max(BASE_ENEMY_SPAWN_INTERVAL - reduction, MIN_ENEMY_SPAWN_INTERVAL)


static func should_spawn_elite(spawn_count: int) -> bool:
	return spawn_count > 0 and spawn_count % 6 == 0


static func should_earn_chest(elapsed_seconds: float, score: int, chest_already_earned: bool) -> bool:
	if chest_already_earned:
		return false
	return elapsed_seconds >= CHEST_EARN_TIME or score >= CHEST_SCORE_REQUIREMENT


static func upgrade_pool() -> Array[Dictionary]:
	return [
		{
			"id": "attack_rate",
			"title": "Quicker Hex",
			"description": "Auto-blast fires faster.",
			"effect_type": "attack_interval",
			"amount": -0.12,
			"repeatable": true,
		},
		{
			"id": "attack_range",
			"title": "Longer Reach",
			"description": "Auto-blast finds farther targets.",
			"effect_type": "attack_range",
			"amount": 42.0,
			"repeatable": true,
		},
		{
			"id": "reward_value",
			"title": "Bigger Sparks",
			"description": "Pickups fill more progress.",
			"effect_type": "reward_bonus",
			"amount": 1,
			"repeatable": true,
		},
		{
			"id": "move_speed",
			"title": "Quick Boots",
			"description": "Move faster for the rest of the run.",
			"effect_type": "move_speed",
			"amount": 34.0,
			"repeatable": false,
		},
		{
			"id": "max_health",
			"title": "Bone Ward",
			"description": "Gain two health and refill one.",
			"effect_type": "max_health",
			"amount": 2,
			"repeatable": true,
		},
		{
			"id": "spark_chain",
			"title": "Chain Spark",
			"description": "Blasts jump to one nearby target.",
			"effect_type": "chain_attack",
			"amount": 1,
			"repeatable": false,
		},
	]


static func upgrade_choices(level: int, already_chosen: Array, count: int = 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = upgrade_pool()
	var choices: Array[Dictionary] = []
	var used_ids := {}
	var offset: int = max(level - 1, 0) % pool.size()

	for step in range(pool.size()):
		var source_upgrade: Dictionary = pool[(offset + step) % pool.size()]
		var upgrade: Dictionary = source_upgrade.duplicate(true)
		var id := String(upgrade.get("id", ""))
		var repeatable := bool(upgrade.get("repeatable", true))
		if not repeatable and already_chosen.has(id):
			continue
		if used_ids.has(id):
			continue

		used_ids[id] = true
		choices.append(upgrade)
		if choices.size() == count:
			return choices

	for source_upgrade: Dictionary in pool:
		var id := String(source_upgrade.get("id", ""))
		if used_ids.has(id):
			continue
		used_ids[id] = true
		choices.append(source_upgrade.duplicate(true))
		if choices.size() == count:
			return choices

	return choices


static func chest_reward_pool() -> Array[Dictionary]:
	return [
		{
			"id": "score_cache",
			"title": "Copper Cache",
			"description": "Earned coins boost this run score.",
			"effect_type": "score_bonus",
			"amount": 50,
		},
		{
			"id": "spark_bundle",
			"title": "Spark Bundle",
			"description": "Pickups fill more progress this run.",
			"effect_type": "reward_multiplier",
			"amount": 1,
		},
		{
			"id": "wide_blast",
			"title": "Wide Blast",
			"description": "Auto-blast reaches farther targets.",
			"effect_type": "attack_range",
			"amount": 55.0,
		},
		{
			"id": "green_cloak",
			"title": "Green Cloak Tint",
			"description": "Earned cosmetic color for this run.",
			"effect_type": "cosmetic_tint",
			"amount": 1,
		},
	]


static func chest_reward_for(session_id: String, reward_count: int, upgrade_count: int) -> Dictionary:
	var pool: Array[Dictionary] = chest_reward_pool()
	var key := "%s:%d:%d" % [session_id, reward_count, upgrade_count]
	var index: int = abs(key.hash()) % pool.size()
	return pool[index].duplicate(true)
