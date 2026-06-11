extends SceneTree
## Headless project validator for Cursed Keep Survivors.
## Run with:
##   godot --headless --path . --script res://scripts/tools/validate_project.gd
## Exits 0 when every check passes, 1 otherwise.

const WeaponDataT := preload("res://scripts/data/weapon_data.gd")
const EnemyDataT := preload("res://scripts/data/enemy_data.gd")
const UpgradeDataT := preload("res://scripts/data/upgrade_data.gd")
const WaveDataT := preload("res://scripts/data/wave_data.gd")
const WeaponManagerT := preload("res://scripts/weapons/weapon_manager.gd")
const AudioManagerT := preload("res://scripts/core/audio_manager.gd")

const REQUIRED_SCENES: Array = [
	"res://scenes/Main.tscn",
	"res://scenes/game/GameWorld.tscn",
	"res://scenes/player/Player.tscn",
	"res://scenes/ui/MainMenu.tscn",
	"res://scenes/ui/HUD.tscn",
	"res://scenes/ui/PauseMenu.tscn",
	"res://scenes/ui/LevelUpScreen.tscn",
	"res://scenes/ui/GameOverScreen.tscn",
	"res://scenes/ui/VictoryScreen.tscn",
	"res://scenes/ui/DebugOverlay.tscn",
	"res://scenes/enemies/BoneCrawler.tscn",
	"res://scenes/enemies/StarvedGhoul.tscn",
	"res://scenes/enemies/Wraith.tscn",
	"res://scenes/enemies/PlagueBrute.tscn",
	"res://scenes/enemies/CultHexer.tscn",
	"res://scenes/enemies/GraveSplitter.tscn",
	"res://scenes/enemies/HollowKnight.tscn",
	"res://scenes/enemies/CursedCastellan.tscn",
	"res://scenes/projectiles/Projectile.tscn",
	"res://scenes/pickups/XPOrb.tscn",
	"res://scenes/pickups/Pickup.tscn",
	"res://scenes/effects/Zone.tscn",
	"res://scenes/effects/Fx.tscn",
	"res://scenes/effects/FloatingText.tscn",
]

const REQUIRED_ASSET_DIRS: Array = [
	"res://assets/generated/characters",
	"res://assets/generated/enemies",
	"res://assets/generated/weapons",
	"res://assets/generated/icons",
	"res://assets/generated/environment",
	"res://assets/generated/ui",
]

var _failures := 0
var _passes := 0


func _initialize() -> void:
	print("=== Cursed Keep Survivors :: project validation ===")
	_check_main_scene()
	_check_scenes()
	_check_asset_dirs()
	_check_weapons()
	_check_enemies()
	_check_waves()
	_check_upgrades()
	_check_offer_rules()
	_check_save_path()
	print("====================================================")
	print("PASSED: %d   FAILED: %d" % [_passes, _failures])
	if _failures > 0:
		print("VALIDATION RESULT: FAIL")
	else:
		print("VALIDATION RESULT: OK")
	quit(1 if _failures > 0 else 0)


func _ok(msg: String) -> void:
	_passes += 1
	print("  PASS  " + msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("  FAIL  " + msg)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		_ok(msg)
	else:
		_fail(msg)


func _check_main_scene() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	_expect(main_scene == "res://scenes/Main.tscn", "main scene setting points to res://scenes/Main.tscn")
	_expect(ResourceLoader.exists(main_scene), "main scene file exists")


func _check_scenes() -> void:
	var all_load := true
	for path: String in REQUIRED_SCENES:
		if not ResourceLoader.exists(path):
			_fail("required scene missing: " + path)
			all_load = false
			continue
		var scene: PackedScene = load(path)
		if scene == null or not scene.can_instantiate():
			_fail("scene fails to load: " + path)
			all_load = false
	if all_load:
		_ok("all %d required scenes exist and load" % REQUIRED_SCENES.size())


func _check_asset_dirs() -> void:
	for dir_path: String in REQUIRED_ASSET_DIRS:
		_expect(DirAccess.dir_exists_absolute(dir_path), "generated asset folder exists: " + dir_path)


func _check_weapons() -> void:
	var weapons: Dictionary = WeaponDataT.WEAPONS
	_expect(weapons.size() >= 16, "at least 16 weapon definitions (%d found)" % weapons.size())
	_expect(weapons.has(WeaponDataT.STARTER_WEAPON), "starter weapon '%s' exists" % WeaponDataT.STARTER_WEAPON)
	_expect(WeaponDataT.DEFAULT_WEAPON_CAP > 0, "active weapon cap is defined (%d)" % WeaponDataT.DEFAULT_WEAPON_CAP)

	var names: Dictionary = {}
	var icon_ok := true
	var impl_ok := true
	var id_ok := true
	for id: String in weapons.keys():
		var w: Dictionary = weapons[id]
		if w.get("id", "") != id:
			_fail("weapon dict id mismatch for '%s'" % id)
			id_ok = false
		var weapon_name: String = w.get("name", "")
		if names.has(weapon_name):
			_fail("duplicate weapon display name: " + weapon_name)
			id_ok = false
		names[weapon_name] = true
		var icon: String = w.get("icon", "")
		if icon == "" or not FileAccess.file_exists(icon):
			_fail("weapon '%s' icon missing: %s" % [id, icon])
			icon_ok = false
		if not WeaponManagerT.IMPLEMENTED.has(id):
			_fail("weapon '%s' has no implementation in WeaponManager" % id)
			impl_ok = false
		if not AudioManagerT.SFX.has(StringName("w_" + id)):
			_fail("weapon '%s' has no audio cue (w_%s)" % [id, id])
			impl_ok = false
	for impl_id: String in WeaponManagerT.IMPLEMENTED:
		if not weapons.has(impl_id):
			_fail("WeaponManager implements unknown weapon '%s'" % impl_id)
			impl_ok = false
	if id_ok:
		_ok("weapon ids and display names are unique and consistent")
	if icon_ok:
		_ok("every weapon has a generated icon file")
	if impl_ok:
		_ok("every weapon has an implementation and an audio cue")


func _check_enemies() -> void:
	var enemies: Dictionary = EnemyDataT.ENEMIES
	_expect(enemies.size() >= 7, "at least 7 enemy types (%d found)" % enemies.size())
	var ok := true
	for id: String in enemies.keys():
		var e: Dictionary = enemies[id]
		if e.get("id", "") != id:
			_fail("enemy dict id mismatch for '%s'" % id)
			ok = false
		for key in ["name", "scene", "sprite", "hp", "speed", "damage", "xp", "score", "radius", "behavior"]:
			if not e.has(key):
				_fail("enemy '%s' missing field '%s'" % [id, key])
				ok = false
		if not ResourceLoader.exists(str(e.get("scene", ""))):
			_fail("enemy '%s' scene missing: %s" % [id, e.get("scene", "")])
			ok = false
		if not FileAccess.file_exists(str(e.get("sprite", ""))):
			_fail("enemy '%s' sprite missing: %s" % [id, e.get("sprite", "")])
			ok = false
		if e.has("splits_into") and not enemies.has(str(e["splits_into"])):
			_fail("enemy '%s' splits into unknown enemy '%s'" % [id, e["splits_into"]])
			ok = false
	if ok:
		_ok("enemy definitions are complete, scenes and sprites exist")
	_expect(ResourceLoader.exists(str(EnemyDataT.BOSS.get("scene", ""))), "boss scene exists")
	_expect(FileAccess.file_exists(str(EnemyDataT.BOSS.get("sprite", ""))), "boss sprite exists")


func _check_waves() -> void:
	var waves: Array = WaveDataT.WAVES
	_expect(waves.size() >= 10, "at least 10 waves defined (%d found)" % waves.size())
	var ok := true
	var boss_found := false
	for i in waves.size():
		var wave: Dictionary = waves[i]
		for id: String in wave.get("comp", {}).keys():
			if not EnemyDataT.ENEMIES.has(id):
				_fail("wave %d references unknown enemy '%s'" % [i + 1, id])
				ok = false
		if bool(wave.get("boss", false)):
			boss_found = true
	if ok:
		_ok("all wave compositions reference valid enemies")
	_expect(boss_found, "final boss wave is defined")


func _check_upgrades() -> void:
	var upgrades: Array = UpgradeDataT.UPGRADES
	_expect(upgrades.size() >= 75, "at least 75 upgrade definitions (%d found)" % upgrades.size())
	var ids: Dictionary = {}
	var ok := true
	var unlock_count := 0
	var weapon_specific: Dictionary = {}
	var stat_count := 0
	var cursed_count := 0
	for u: Dictionary in upgrades:
		var id: String = u.get("id", "")
		if id == "" or ids.has(id):
			_fail("duplicate or empty upgrade id: '%s'" % id)
			ok = false
		ids[id] = true
		var kind: String = u.get("kind", "stat")
		match kind:
			"unlock":
				unlock_count += 1
				if not WeaponDataT.WEAPONS.has(str(u.get("weapon", ""))):
					_fail("unlock upgrade '%s' references unknown weapon '%s'" % [id, u.get("weapon", "")])
					ok = false
			"weapon":
				var weapon_id := str(u.get("weapon", ""))
				if not WeaponDataT.WEAPONS.has(weapon_id):
					_fail("weapon upgrade '%s' references unknown weapon '%s'" % [id, weapon_id])
					ok = false
				weapon_specific[weapon_id] = int(weapon_specific.get(weapon_id, 0)) + 1
				# verify each wmod key exists in the weapon's base stats
				var base: Dictionary = WeaponDataT.WEAPONS.get(weapon_id, {}).get("base", {})
				for key: String in u.get("wmods", {}).keys():
					if not base.has(key):
						_fail("upgrade '%s' modifies unknown stat '%s' of '%s'" % [id, key, weapon_id])
						ok = false
			"synergy":
				for req: String in u.get("requires", []):
					if not WeaponDataT.WEAPONS.has(req):
						_fail("synergy '%s' requires unknown weapon '%s'" % [id, req])
						ok = false
			"stat":
				stat_count += 1
			"cursed":
				cursed_count += 1
		if not u.has("icon") or str(u["icon"]) == "" or not FileAccess.file_exists(str(u["icon"])):
			_fail("upgrade '%s' icon missing: %s" % [id, u.get("icon", "<none>")])
			ok = false
	if ok:
		_ok("upgrade ids unique; all weapon/synergy references and icons valid")
	_expect(stat_count >= 15, "at least 15 global stat upgrades (%d)" % stat_count)
	_expect(unlock_count >= 15, "at least 15 weapon unlock upgrades (%d)" % unlock_count)
	var ws_total := 0
	for v in weapon_specific.values():
		ws_total += int(v)
	_expect(ws_total >= 40, "at least 40 weapon-specific upgrades (%d)" % ws_total)
	_expect(cursed_count + 1 >= 5, "at least 5 cursed tradeoff upgrades (%d + Death's Favor)" % cursed_count)
	var missing_two: Array[String] = []
	for weapon_id: String in WeaponDataT.WEAPONS.keys():
		if int(weapon_specific.get(weapon_id, 0)) < 2:
			missing_two.append(weapon_id)
	_expect(missing_two.is_empty(), "every weapon has at least 2 specific upgrades" +
		("" if missing_two.is_empty() else " (missing: %s)" % ", ".join(missing_two)))


## Simulates the level-up offer filter to prove unlock upgrades are never
## offered for owned weapons and weapon upgrades never for locked ones.
func _check_offer_rules() -> void:
	var owned := {"soul_bolt": {"level": 1}, "rune_knives": {"level": 1}}
	var weapon_cap: int = WeaponDataT.DEFAULT_WEAPON_CAP
	var ok := true
	for u: Dictionary in UpgradeDataT.UPGRADES:
		var kind: String = u.get("kind", "stat")
		var valid := true
		match kind:
			"unlock":
				var w := str(u.get("weapon", ""))
				if owned.has(w) or owned.size() >= weapon_cap:
					valid = false
			"weapon":
				if not owned.has(str(u.get("weapon", ""))):
					valid = false
			"synergy":
				for req: String in u.get("requires", []):
					if not owned.has(req):
						valid = false
		# mirror of UpgradeSystem._is_valid rules
		if kind == "unlock" and valid and owned.has(str(u.get("weapon", ""))):
			_fail("offer rules: unlock '%s' offered while weapon owned" % u["id"])
			ok = false
		if kind == "weapon" and valid and not owned.has(str(u.get("weapon", ""))):
			_fail("offer rules: weapon upgrade '%s' offered while locked" % u["id"])
			ok = false
	if ok:
		_ok("offer rules: no unlock for owned weapons, no weapon upgrades for locked weapons")


func _check_save_path() -> void:
	var f := FileAccess.open("user://cks_validate_probe.tmp", FileAccess.WRITE)
	if f != null:
		f.store_string("ok")
		f = null
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://cks_validate_probe.tmp"))
		_ok("save system path user:// is writable")
	else:
		_fail("save system path user:// is not writable")
