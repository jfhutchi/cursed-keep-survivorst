@tool
extends McpTestSuite

const WeaponDataT := preload("res://scripts/data/weapon_data.gd")
const EnemyDataT := preload("res://scripts/data/enemy_data.gd")
const UpgradeDataT := preload("res://scripts/data/upgrade_data.gd")
const WaveDataT := preload("res://scripts/data/wave_data.gd")
const WeaponManagerT := preload("res://scripts/weapons/weapon_manager.gd")
const UpgradeSystemT := preload("res://scripts/upgrades/upgrade_system.gd")
const AudioManagerT := preload("res://scripts/core/audio_manager.gd")
const FakeWeaponManagerT := preload("res://tests/fakes/fake_weapon_manager.gd")
const FakePlayerT := preload("res://tests/fakes/fake_player.gd")


func suite_name() -> String:
	return "game_data_integrity"


func test_weapon_data_is_implemented_and_asset_backed() -> void:
	var weapons: Dictionary = WeaponDataT.WEAPONS
	assert_eq(weapons.size(), 18, "game should define the full 18-weapon pool")
	assert_true(weapons.has(WeaponDataT.STARTER_WEAPON), "starter weapon should exist in weapon data")
	assert_true(WeaponDataT.DEFAULT_WEAPON_CAP > 0, "default weapon cap should be positive")
	assert_true(WeaponDataT.ABSOLUTE_WEAPON_CAP >= WeaponDataT.DEFAULT_WEAPON_CAP, "absolute weapon cap should not be below default")

	var names: Dictionary = {}
	for id: String in weapons.keys():
		var weapon: Dictionary = weapons[id]
		assert_eq(str(weapon.get("id", "")), id, "weapon dictionary id should match key: " + id)
		var weapon_name := str(weapon.get("name", ""))
		assert_true(weapon_name != "", "weapon should have a display name: " + id)
		assert_true(not names.has(weapon_name), "weapon display names should be unique: " + weapon_name)
		names[weapon_name] = true
		assert_true(FileAccess.file_exists(str(weapon.get("icon", ""))), "weapon icon should exist: " + id)
		assert_true(weapon.has("base") and weapon["base"] is Dictionary and not weapon["base"].is_empty(), "weapon should define base stats: " + id)
		assert_true(WeaponManagerT.IMPLEMENTED.has(id), "weapon should have a WeaponManager implementation: " + id)
		assert_true(AudioManagerT.SFX.has(StringName("w_" + id)), "weapon should have an audio cue: " + id)

	for impl_id: String in WeaponManagerT.IMPLEMENTED:
		assert_true(weapons.has(impl_id), "WeaponManager should not implement an unknown weapon: " + impl_id)


func test_upgrade_pool_references_known_weapons_and_assets() -> void:
	var upgrades: Array = UpgradeDataT.UPGRADES
	assert_true(upgrades.size() >= 100, "upgrade pool should remain broad enough for a full run")

	var ids: Dictionary = {}
	var unlock_count := 0
	var weapon_upgrade_count := 0
	var synergy_count := 0
	var cursed_count := 0

	for upgrade: Dictionary in upgrades:
		var id := str(upgrade.get("id", ""))
		assert_true(id != "", "upgrade id should not be empty")
		assert_true(not ids.has(id), "upgrade ids should be unique: " + id)
		ids[id] = true
		assert_true(FileAccess.file_exists(str(upgrade.get("icon", ""))), "upgrade icon should exist: " + id)

		var kind := str(upgrade.get("kind", "stat"))
		match kind:
			"unlock":
				unlock_count += 1
				assert_true(WeaponDataT.WEAPONS.has(str(upgrade.get("weapon", ""))), "unlock should reference a known weapon: " + id)
			"weapon":
				weapon_upgrade_count += 1
				var weapon_id := str(upgrade.get("weapon", ""))
				assert_true(WeaponDataT.WEAPONS.has(weapon_id), "weapon upgrade should reference a known weapon: " + id)
				var base: Dictionary = WeaponDataT.WEAPONS.get(weapon_id, {}).get("base", {})
				var wmods: Dictionary = upgrade.get("wmods", {})
				assert_true(not wmods.is_empty(), "weapon upgrade should define at least one weapon mod: " + id)
				for key: String in wmods.keys():
					assert_true(base.has(key), "weapon upgrade should modify an existing base stat: %s.%s" % [id, key])
					var op: Dictionary = wmods[key]
					assert_true(op.has("add") or op.has("mult"), "weapon mod should use add or mult: %s.%s" % [id, key])
			"synergy":
				synergy_count += 1
				var requires: Array = upgrade.get("requires", [])
				assert_true(requires.size() >= 2, "synergy should require at least two weapons: " + id)
				for required: String in requires:
					assert_true(WeaponDataT.WEAPONS.has(required), "synergy should require known weapons: %s -> %s" % [id, required])
			"cursed":
				cursed_count += 1
			"stat", "special":
				pass
			_:
				assert_true(false, "upgrade should use a known kind: %s (%s)" % [id, kind])

	assert_true(unlock_count >= 17, "upgrade pool should include unlocks for non-starter weapons")
	assert_true(weapon_upgrade_count >= 50, "upgrade pool should include weapon-specific upgrades")
	assert_true(synergy_count >= 8, "upgrade pool should include synergy upgrades")
	assert_true(cursed_count >= 6, "upgrade pool should include cursed tradeoffs")


func test_enemies_and_waves_reference_existing_game_content() -> void:
	var enemies: Dictionary = EnemyDataT.ENEMIES
	assert_true(enemies.size() >= 8, "enemy pool should include the main enemy roster")

	for id: String in enemies.keys():
		var enemy: Dictionary = enemies[id]
		assert_eq(str(enemy.get("id", "")), id, "enemy dictionary id should match key: " + id)
		assert_true(ResourceLoader.exists(str(enemy.get("scene", ""))), "enemy scene should exist: " + id)
		assert_true(FileAccess.file_exists(str(enemy.get("sprite", ""))), "enemy sprite should exist: " + id)
		assert_true(float(enemy.get("hp", 0.0)) > 0.0, "enemy hp should be positive: " + id)
		assert_true(float(enemy.get("speed", 0.0)) > 0.0, "enemy speed should be positive: " + id)
		if enemy.has("splits_into"):
			assert_true(enemies.has(str(enemy["splits_into"])), "split enemy target should exist: " + id)

	var boss: Dictionary = EnemyDataT.BOSS
	assert_true(ResourceLoader.exists(str(boss.get("scene", ""))), "boss scene should exist")
	assert_true(FileAccess.file_exists(str(boss.get("sprite", ""))), "boss sprite should exist")
	assert_true(float(boss.get("hp", 0.0)) > 0.0, "boss hp should be positive")

	var boss_waves := 0
	var waves: Array = WaveDataT.WAVES
	assert_true(waves.size() >= 10, "wave director should define a full run")
	for i in waves.size():
		var wave: Dictionary = waves[i]
		var comp: Dictionary = wave.get("comp", {})
		assert_true(not comp.is_empty(), "wave should have an enemy composition: %d" % [i + 1])
		for enemy_id: String in comp.keys():
			assert_true(enemies.has(enemy_id), "wave should reference known enemies: wave %d -> %s" % [i + 1, enemy_id])
			assert_true(float(comp[enemy_id]) > 0.0, "wave enemy weights should be positive: wave %d -> %s" % [i + 1, enemy_id])
		var interval: Array = wave.get("interval", [])
		assert_eq(interval.size(), 2, "wave interval should have start and end values: %d" % [i + 1])
		if interval.size() == 2:
			assert_true(float(interval[0]) > 0.0 and float(interval[1]) > 0.0, "wave intervals should be positive: %d" % [i + 1])
		if bool(wave.get("boss", false)):
			boss_waves += 1
	assert_eq(boss_waves, 1, "wave director should define exactly one boss wave")


func test_upgrade_offer_filter_rejects_invalid_choices() -> void:
	var system := UpgradeSystemT.new()
	var weapon_manager := FakeWeaponManagerT.new()
	var player := FakePlayerT.new()
	weapon_manager.weapon_cap = WeaponDataT.DEFAULT_WEAPON_CAP
	weapon_manager.owned = {
		"soul_bolt": {"level": 1},
		"rune_knives": {"level": 1},
	}
	system.weapon_manager = weapon_manager
	system.player = player

	var unlock_owned: Dictionary = UpgradeDataT.get_upgrade("unlock_rune_knives")
	var locked_weapon_mod: Dictionary = UpgradeDataT.get_upgrade("or_count")
	var owned_weapon_mod: Dictionary = UpgradeDataT.get_upgrade("sb_damage")
	var synergy: Dictionary = UpgradeDataT.get_upgrade("moonlit_blades")
	var cursed: Dictionary = UpgradeDataT.get_upgrade("blood_pact")

	assert_true(not system._is_valid(unlock_owned), "owned weapons should not be offered as unlocks")
	assert_true(not system._is_valid(locked_weapon_mod), "locked weapons should not receive weapon-specific upgrades")
	assert_true(not system._is_valid(synergy), "synergies should not be offered until all required weapons are owned")
	assert_true(not system._is_valid(cursed), "cursed upgrades should not be offered before level 5")
	assert_true(system._is_valid(owned_weapon_mod), "owned weapons should receive valid weapon-specific upgrades")

	weapon_manager.owned["moon_chakram"] = {"level": 1}
	player.level = 5
	assert_true(system._is_valid(synergy), "synergies should become valid when all required weapons are owned")
	assert_true(system._is_valid(cursed), "cursed upgrades should become valid at level 5")

	system.taken["sb_damage"] = int(owned_weapon_mod.get("max_stacks", 1))
	assert_true(not system._is_valid(owned_weapon_mod), "maxed upgrades should not be offered again")

	system.free()
	weapon_manager.free()
	player.free()
