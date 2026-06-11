class_name UpgradeSystem
extends Node
## Rolls valid level-up choices and applies chosen upgrades.
## Validity rules:
##  - never offer more stacks than max_stacks
##  - unlocks: only for weapons not owned, and only below the weapon cap
##  - weapon-specific: only for owned weapons
##  - synergies: only when both required weapons are owned
##  - cursed: only offered from player level 5 onward
##  - luck increases the weight of non-common rarities

var world: Node2D
var player: Node2D
var weapon_manager: Node

var taken: Dictionary = {} # upgrade id -> stacks taken


func roll_choices(count := 3) -> Array:
	var candidates: Array = []
	var weights: Array = []
	for upgrade: Dictionary in GameData.upgrades:
		if not _is_valid(upgrade):
			continue
		candidates.append(upgrade)
		weights.append(_weight_of(upgrade))
	var choices: Array = []
	while choices.size() < count and not candidates.is_empty():
		var total := 0.0
		for w: float in weights:
			total += w
		var roll := randf() * total
		var idx := 0
		for i in weights.size():
			roll -= weights[i]
			if roll <= 0.0:
				idx = i
				break
		choices.append(candidates[idx])
		candidates.remove_at(idx)
		weights.remove_at(idx)
	# pad with Soul Mend if the pool ran dry (it has effectively infinite stacks)
	while choices.size() < count:
		choices.append(UpgradeData.get_upgrade("soul_mend"))
	return choices


func _is_valid(upgrade: Dictionary) -> bool:
	var stacks := int(taken.get(upgrade["id"], 0))
	if stacks >= int(upgrade.get("max_stacks", 1)):
		return false
	match upgrade.get("kind", "stat"):
		"unlock":
			var weapon_id: String = upgrade["weapon"]
			if weapon_manager.owned.has(weapon_id):
				return false
			if weapon_manager.owned_count() >= weapon_manager.weapon_cap:
				return false
		"weapon":
			if not weapon_manager.owned.has(upgrade["weapon"]):
				return false
		"synergy":
			for required: String in upgrade.get("requires", []):
				if not weapon_manager.owned.has(required):
					return false
		"cursed":
			if player.level < 5:
				return false
		"special":
			if upgrade.get("special", "") == "weapon_cap":
				if weapon_manager.weapon_cap >= WeaponData.ABSOLUTE_WEAPON_CAP:
					return false
	return true


func _weight_of(upgrade: Dictionary) -> float:
	var rarity: String = upgrade.get("rarity", "common")
	var weight: float = UpgradeData.RARITY_WEIGHTS.get(rarity, 50.0)
	if rarity != "common":
		weight *= player.stats["luck"]
	return weight


func apply(upgrade: Dictionary) -> void:
	taken[upgrade["id"]] = int(taken.get(upgrade["id"], 0)) + 1
	if upgrade.has("stats"):
		player.apply_stat_mods(upgrade["stats"])
	if upgrade.has("enemy_mods"):
		for key: String in upgrade["enemy_mods"].keys():
			world.enemy_mods[key] = float(world.enemy_mods.get(key, 1.0)) * float(upgrade["enemy_mods"][key])
	match upgrade.get("kind", "stat"):
		"unlock":
			weapon_manager.unlock_weapon(upgrade["weapon"])
		"weapon":
			for key: String in upgrade.get("wmods", {}).keys():
				weapon_manager.add_mod(upgrade["weapon"], key, upgrade["wmods"][key])
		"synergy":
			world.synergies[upgrade["id"]] = true
		"special":
			match upgrade.get("special", ""):
				"revive":
					player.revive_charges += 1
				"weapon_cap":
					weapon_manager.weapon_cap = mini(weapon_manager.weapon_cap + 1, WeaponData.ABSOLUTE_WEAPON_CAP)
	AudioManager.play(&"upgrade_pick")
	GameEvents.upgrade_chosen.emit(upgrade)
