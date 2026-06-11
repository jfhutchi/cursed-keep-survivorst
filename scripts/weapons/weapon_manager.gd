class_name WeaponManager
extends Node
## Owns every weapon the player has: cooldowns, effective stats, firing,
## unlocks, weapon mods from upgrades, synergy triggers and safety caps.
##
## Targeting modes used across weapons:
##   nearest_enemy, highest_health_enemy, random_enemy, densest_cluster,
##   radial_from_player, forward_or_movement_direction, around_player,
##   ground_near_enemy, defensive_reactive, companion_autonomous
## Expensive scans only happen when a weapon actually fires.

## Every weapon id with a working behavior. The validator cross-checks this
## against WeaponData.WEAPONS so a weapon can't exist as data only.
const IMPLEMENTED: Array = [
	"soul_bolt", "rune_knives", "orbiting_relics", "cursed_flame", "bone_spikes",
	"chain_hex", "sanctified_nova", "blood_scythe", "grave_bell", "thorn_sigil",
	"phantom_bow", "plague_lantern", "iron_maiden", "astral_tome", "moon_chakram",
	"death_mark", "storm_censer", "saints_hammer",
]

var world: Node2D
var player: Node2D

var owned: Dictionary = {}     # id -> {level, cd, mods: {key: {add, mult}}}
var weapon_cap: int = WeaponData.DEFAULT_WEAPON_CAP
var relic_harden_t := 0.0      # Iron Reliquary synergy window

var _pending: Array = []       # [{t: float, fn: Callable}]
var _orbiters: Dictionary = {} # weapon id -> Array[Orbiter]
var _knife_angle := 0.0
var _retal_cd := 0.0
var _maiden_active := false
var _maiden_dr := 0.0

const ORBITER_SCRIPT := preload("res://scripts/game/orbiter.gd")


func _ready() -> void:
	GameEvents.player_hurt.connect(_on_player_hurt)
	GameEvents.player_dashed.connect(_on_player_dashed)
	GameEvents.enemy_killed.connect(_on_enemy_killed)


func start_run() -> void:
	unlock_weapon(WeaponData.STARTER_WEAPON)


func owned_count() -> int:
	return owned.size()


func unlock_weapon(id: String) -> void:
	if owned.has(id):
		return
	owned[id] = {"level": 1, "cd": 0.6, "mods": {}}
	GameEvents.weapon_unlocked.emit(id)
	match id:
		"orbiting_relics", "astral_tome":
			_ensure_orbiters(id)


func add_mod(id: String, key: String, op: Dictionary) -> void:
	if not owned.has(id):
		return
	var mods: Dictionary = owned[id]["mods"]
	if not mods.has(key):
		mods[key] = {"add": 0.0, "mult": 1.0}
	if op.has("add"):
		mods[key]["add"] += float(op["add"])
	if op.has("mult"):
		mods[key]["mult"] *= float(op["mult"])
	owned[id]["level"] = int(owned[id]["level"]) + 1
	GameEvents.weapon_leveled.emit(id, owned[id]["level"])
	if id == "astral_tome" and key == "count":
		_ensure_orbiters(id)


## Effective stat: (base + adds) * mults, then routed player multipliers.
func wstat(id: String, key: String) -> float:
	var def: Dictionary = GameData.weapon(id)
	if def.is_empty():
		return 0.0
	var base: Dictionary = def["base"]
	var v := float(base.get(key, 0.0))
	if owned.has(id):
		var mods: Dictionary = owned[id]["mods"]
		if mods.has(key):
			v = (v + float(mods[key]["add"])) * float(mods[key]["mult"])
	var stats: Dictionary = player.stats
	match key:
		"damage", "burn_dps", "dps", "explode_damage":
			v *= stats["damage_mult"]
		"cooldown", "cast_cd":
			v = maxf(v * stats["cooldown_mult"], 0.18)
		"radius", "cone_deg", "length", "arc_deg", "chain_range":
			v *= stats["area_mult"]
		"speed":
			v *= stats["projectile_speed_mult"]
		"duration", "slow_dur", "burn_dur":
			v *= stats["duration_mult"]
		"count":
			if id in ["soul_bolt", "rune_knives", "phantom_bow", "moon_chakram"]:
				v += stats["projectile_bonus"]
	return v


func update(delta: float) -> void:
	if player == null or not player.alive:
		return
	relic_harden_t = maxf(0.0, relic_harden_t - delta)
	_retal_cd = maxf(0.0, _retal_cd - delta)

	# scheduled follow-up actions (double pulses, second sweeps, ring trains)
	var i := _pending.size() - 1
	while i >= 0:
		_pending[i]["t"] -= delta
		if _pending[i]["t"] <= 0.0:
			var fn: Callable = _pending[i]["fn"]
			_pending.remove_at(i)
			fn.call()
		i -= 1

	for id: String in owned.keys():
		var def: Dictionary = GameData.weapon(id)
		if def["category"] in ["orbit", "summon"]:
			continue # persistent weapons live as orbiters
		owned[id]["cd"] = float(owned[id]["cd"]) - delta
		if float(owned[id]["cd"]) <= 0.0:
			if _fire(id):
				owned[id]["cd"] = wstat(id, "cooldown")
			else:
				owned[id]["cd"] = 0.3 # no valid target; retry shortly


func _schedule(t: float, fn: Callable) -> void:
	_pending.append({"t": t, "fn": fn})


func _ensure_orbiters(id: String) -> void:
	if not _orbiters.has(id):
		_orbiters[id] = []
	var list: Array = _orbiters[id]
	var want := 1
	if id == "astral_tome":
		want = int(wstat("astral_tome", "count"))
	while list.size() < want:
		var orb := Node2D.new()
		orb.set_script(ORBITER_SCRIPT)
		orb.world = world
		orb.weapon_manager = self
		orb.kind = "relics" if id == "orbiting_relics" else "tome"
		if orb.kind == "tome":
			orb.setup_tome(list.size())
		world.entity_layer.add_child(orb)
		list.append(orb)


func clear_run() -> void:
	for id: String in _orbiters.keys():
		for orb: Node2D in _orbiters[id]:
			orb.queue_free()
	_orbiters.clear()
	owned.clear()
	_pending.clear()
	weapon_cap = WeaponData.DEFAULT_WEAPON_CAP
	_maiden_active = false


# === FIRE DISPATCH =========================================================

func _fire(id: String) -> bool:
	match id:
		"soul_bolt": return _fire_soul_bolt()
		"rune_knives": return _fire_rune_knives()
		"cursed_flame": return _fire_cursed_flame()
		"bone_spikes": return _fire_bone_spikes()
		"chain_hex": return _fire_chain_hex()
		"sanctified_nova": return _fire_sanctified_nova()
		"blood_scythe": return _fire_blood_scythe()
		"grave_bell": return _fire_grave_bell()
		"thorn_sigil": return _fire_thorn_sigil()
		"phantom_bow": return _fire_phantom_bow()
		"plague_lantern": return _fire_plague_lantern()
		"iron_maiden": return _fire_iron_maiden()
		"moon_chakram": return _fire_moon_chakram()
		"death_mark": return _fire_death_mark()
		"storm_censer": return _fire_storm_censer()
		"saints_hammer": return _fire_saints_hammer()
	return false


func _fire_soul_bolt() -> bool:
	var target: Node2D = world.nearest_enemy(player.global_position, wstat("soul_bolt", "range"))
	if target == null:
		return false
	var count := int(wstat("soul_bolt", "count"))
	var dir: Vector2 = (target.global_position - player.global_position).normalized()
	var soulburst := wstat("soul_bolt", "soulburst") > 0.0
	var params := {"kind": "bolt", "color": GameData.weapon_color("soul_bolt"),
		"speed": wstat("soul_bolt", "speed"), "damage": wstat("soul_bolt", "damage"),
		"pierce": int(wstat("soul_bolt", "pierce")), "source": "soul_bolt",
		"size": wstat("soul_bolt", "size"), "max_distance": wstat("soul_bolt", "range") * 1.3,
		"soulburst": soulburst}
	if world.synergies.has("soulfire_covenant"):
		params["burn_dps"] = wstat("soul_bolt", "damage") * 0.5
		params["burn_dur"] = 2.0
	for i in count:
		var spread := (i - (count - 1) * 0.5) * 0.15
		var p := params.duplicate()
		p["pos"] = player.global_position + dir.rotated(spread) * 14.0
		p["dir"] = dir.rotated(spread)
		world.spawn_projectile(p)
	AudioManager.play_weapon("soul_bolt")
	return true


func _fire_rune_knives() -> bool:
	var count := int(wstat("rune_knives", "count"))
	_knife_angle += 0.7
	var returning := wstat("rune_knives", "returning") > 0.0
	for i in count:
		var a := _knife_angle + TAU * i / count
		world.spawn_projectile({"kind": "knife", "color": GameData.weapon_color("rune_knives"),
			"pos": player.global_position, "dir": Vector2.from_angle(a),
			"speed": wstat("rune_knives", "speed"), "damage": wstat("rune_knives", "damage"),
			"source": "rune_knives", "max_distance": wstat("rune_knives", "range"),
			"bleed": wstat("rune_knives", "bleed"),
			"behavior": "chakram" if returning else "straight"})
	AudioManager.play_weapon("rune_knives")
	return true


func spawn_moonlit_knives(pos: Vector2) -> void:
	# Moonlit Blades synergy: chakram apex releases rune knives
	for i in 2:
		var a := randf() * TAU
		world.spawn_projectile({"kind": "knife", "color": GameData.weapon_color("rune_knives"),
			"pos": pos, "dir": Vector2.from_angle(a), "speed": 460.0,
			"damage": wstat("rune_knives", "damage") * 0.6, "source": "rune_knives",
			"max_distance": 220.0})


func _fire_cursed_flame() -> bool:
	var aim: Vector2 = world.densest_cluster_pos(player.global_position, 420.0)
	if aim == Vector2.INF:
		return false
	var dir: Vector2 = (aim - player.global_position).normalized()
	var length := wstat("cursed_flame", "length")
	var half_angle := deg_to_rad(wstat("cursed_flame", "cone_deg")) * 0.5
	var damage := wstat("cursed_flame", "damage")
	var burn_dps := wstat("cursed_flame", "burn_dps")
	var burn_dur := wstat("cursed_flame", "burn_dur")
	var enemies: Array = world.query_enemies(player.global_position, length)
	var hit_any := false
	for enemy in enemies:
		var to_e: Vector2 = enemy.global_position - player.global_position
		if absf(dir.angle_to(to_e)) <= half_angle:
			world.deal_damage(enemy, damage, "cursed_flame", {})
			if enemy.alive:
				enemy.apply_burn(burn_dps, burn_dur)
			hit_any = true
	world.spawn_fx({"kind": "flame_cone", "pos": player.global_position, "angle": dir.angle(),
		"arc_deg": wstat("cursed_flame", "cone_deg"), "length": length,
		"color": GameData.weapon_color("cursed_flame")})
	if wstat("cursed_flame", "linger") > 0.0:
		world.spawn_zone({"kind": "cloud", "pos": player.global_position + dir * length * 0.55,
			"radius": 70.0 * player.stats["area_mult"], "duration": 2.5, "tick": 0.5,
			"source": "cursed_flame", "color": GameData.weapon_color("cursed_flame"),
			"opts": {"burn_dps": burn_dps, "burn_dur": 1.5}})
	AudioManager.play_weapon("cursed_flame")
	return hit_any or true


func _fire_bone_spikes() -> bool:
	var targets: Array = world.random_enemies(int(wstat("bone_spikes", "count")), player.global_position, 430.0)
	if targets.is_empty():
		return false
	for target in targets:
		world.spawn_zone({"kind": "erupt", "pos": target.global_position,
			"radius": wstat("bone_spikes", "radius"), "delay": wstat("bone_spikes", "delay"),
			"damage": wstat("bone_spikes", "damage"), "source": "bone_spikes",
			"color": GameData.weapon_color("bone_spikes"),
			"slow": wstat("bone_spikes", "slow"), "slow_dur": 1.2,
			"opts": {"second": wstat("bone_spikes", "second") > 0.0}})
	return true


func _fire_chain_hex() -> bool:
	var first: Node2D = world.nearest_enemy(player.global_position, wstat("chain_hex", "range"))
	if first == null:
		return false
	var chains := int(wstat("chain_hex", "chains"))
	var chain_range := wstat("chain_hex", "chain_range")
	var damage := wstat("chain_hex", "damage")
	var fork := wstat("chain_hex", "fork")
	var slow := wstat("chain_hex", "slow")
	var slow_dur := wstat("chain_hex", "slow_dur")
	var points := PackedVector2Array([player.global_position])
	var visited := {}
	var current: Node2D = first
	var jump := 0
	while current != null and jump <= chains:
		visited[current.get_instance_id()] = true
		points.append(current.global_position)
		world.deal_damage(current, damage * pow(0.85, jump), "chain_hex", {})
		if current.alive and slow > 0.0:
			current.apply_slow(slow, slow_dur)
		# Hexfire Lattice synergy: the hex ignites everything it jumps through
		if current.alive and world.synergies.has("hexfire_lattice"):
			current.apply_burn(damage * 0.35, 2.0)
		if fork > 0.0 and randf() < fork:
			var fork_target: Node2D = world.nearest_enemy_excluding(current.global_position, chain_range, visited)
			if fork_target != null:
				visited[fork_target.get_instance_id()] = true
				world.deal_damage(fork_target, damage * 0.6, "chain_hex", {})
				world.spawn_fx({"kind": "lightning", "pos": current.global_position,
					"color": GameData.weapon_color("chain_hex"),
					"points": PackedVector2Array([current.global_position, fork_target.global_position])})
		current = world.nearest_enemy_excluding(current.global_position, chain_range, visited)
		jump += 1
	world.spawn_fx({"kind": "lightning", "pos": player.global_position,
		"color": GameData.weapon_color("chain_hex"), "points": points})
	AudioManager.play_weapon("chain_hex")
	return true


func _fire_sanctified_nova() -> bool:
	_nova_pulse(1.0)
	if wstat("sanctified_nova", "double") > 0.0:
		_schedule(0.35, _nova_pulse.bind(0.7))
	if world.synergies.has("bell_of_judgment") and owned.has("grave_bell"):
		_schedule(0.2, _bell_ring.bind(0.6))
	return true


func _nova_pulse(mult: float) -> void:
	var radius := wstat("sanctified_nova", "radius")
	var damage := wstat("sanctified_nova", "damage") * mult
	var kb: float = wstat("sanctified_nova", "knockback") * player.stats["knockback_mult"]
	var heal_chance := wstat("sanctified_nova", "heal_chance")
	var enemies: Array = world.query_enemies(player.global_position, radius)
	for enemy in enemies:
		world.deal_damage(enemy, damage, "sanctified_nova",
			{"kb": (enemy.global_position - player.global_position).normalized() * kb})
		if heal_chance > 0.0 and randf() < heal_chance:
			player.heal(3.0, false)
	world.spawn_fx({"kind": "nova", "pos": player.global_position, "radius": radius,
		"color": GameData.weapon_color("sanctified_nova")})
	AudioManager.play_weapon("sanctified_nova")


func _fire_blood_scythe() -> bool:
	var dir: Vector2 = player.facing
	_scythe_sweep(dir, 1.0)
	if int(wstat("blood_scythe", "sweeps")) > 1:
		_schedule(0.25, _scythe_sweep.bind(-dir, 0.8))
	return true


func _scythe_sweep(dir: Vector2, mult: float) -> void:
	var radius := wstat("blood_scythe", "radius")
	var half_arc := deg_to_rad(wstat("blood_scythe", "arc_deg")) * 0.5
	var damage := wstat("blood_scythe", "damage") * mult
	var lifesteal := wstat("blood_scythe", "lifesteal")
	var bleed := wstat("blood_scythe", "bleed")
	var total := 0.0
	var enemies: Array = world.query_enemies(player.global_position, radius)
	for enemy in enemies:
		var to_e: Vector2 = enemy.global_position - player.global_position
		if absf(dir.angle_to(to_e)) <= half_arc:
			total += world.deal_damage(enemy, damage, "blood_scythe",
				{"kb": to_e.normalized() * 110.0})["dealt"]
			if bleed > 0.0 and enemy.alive:
				enemy.apply_bleed(damage * bleed * 0.5, 2.0)
			# Grave Harvest synergy handled on kill signal
	if lifesteal > 0.0 and total > 0.0:
		player.heal(total * lifesteal, false)
	world.spawn_fx({"kind": "sweep", "pos": player.global_position, "angle": dir.angle(),
		"arc_deg": wstat("blood_scythe", "arc_deg"), "radius": radius,
		"color": GameData.weapon_color("blood_scythe")})
	AudioManager.play_weapon("blood_scythe")


func _fire_grave_bell() -> bool:
	var rings := int(wstat("grave_bell", "rings"))
	_bell_ring(1.0)
	for i in range(1, rings):
		_schedule(0.3 * i, _bell_ring.bind(0.85))
	return true


func _bell_ring(mult: float) -> void:
	var radius := wstat("grave_bell", "radius")
	var damage := wstat("grave_bell", "damage") * mult
	var slow := wstat("grave_bell", "slow")
	var slow_dur := wstat("grave_bell", "slow_dur")
	var stun_chance := wstat("grave_bell", "stun_chance")
	var enemies: Array = world.query_enemies(player.global_position, radius)
	for enemy in enemies:
		world.deal_damage(enemy, damage, "grave_bell", {})
		if enemy.alive:
			enemy.apply_slow(slow, slow_dur)
			if stun_chance > 0.0 and randf() < stun_chance:
				enemy.apply_stun(0.8)
	# Stormcaller's Toll synergy: rings can call lightning onto a rung enemy
	if world.synergies.has("stormcallers_toll") and owned.has("storm_censer") and not enemies.is_empty() and randf() < 0.25:
		_spawn_strike(enemies.pick_random().global_position)
	world.spawn_fx({"kind": "ring", "pos": player.global_position, "radius": radius,
		"color": GameData.weapon_color("grave_bell")})
	AudioManager.play_weapon("grave_bell")


func _fire_thorn_sigil() -> bool:
	var count := int(wstat("thorn_sigil", "count"))
	for i in count:
		var pos: Vector2
		var anchor: Array = world.random_enemies(1, player.global_position, 380.0)
		if not anchor.is_empty() and randf() < 0.6:
			pos = anchor[0].global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		else:
			pos = player.global_position + Vector2(randf_range(-240, 240), randf_range(-240, 240))
		_spawn_trap(pos, 1.0)
	AudioManager.play_weapon("thorn_sigil")
	return true


func _spawn_trap(pos: Vector2, scale_mult: float) -> void:
	world.spawn_zone({"kind": "trap", "pos": pos,
		"radius": wstat("thorn_sigil", "radius") * scale_mult,
		"damage": wstat("thorn_sigil", "damage"), "tick": wstat("thorn_sigil", "tick"),
		"duration": wstat("thorn_sigil", "duration"), "slow": wstat("thorn_sigil", "slow"),
		"slow_dur": 0.8, "source": "thorn_sigil", "color": GameData.weapon_color("thorn_sigil"),
		"opts": {"spread": wstat("thorn_sigil", "spread") > 0.0,
			"poison": world.synergies.has("plague_thorns")}})


func spawn_spread_trap(pos: Vector2) -> void:
	world.spawn_zone({"kind": "trap", "pos": pos,
		"radius": wstat("thorn_sigil", "radius") * 0.8,
		"damage": wstat("thorn_sigil", "damage"), "tick": wstat("thorn_sigil", "tick"),
		"duration": wstat("thorn_sigil", "duration") * 0.6, "slow": wstat("thorn_sigil", "slow"),
		"slow_dur": 0.8, "source": "thorn_sigil", "color": GameData.weapon_color("thorn_sigil"),
		"opts": {}})


## Grave Tithe synergy: an expiring Thorn Sigil erupts into bone spikes.
func spawn_tithe_spike(pos: Vector2) -> void:
	if not owned.has("bone_spikes"):
		return
	world.spawn_zone({"kind": "erupt", "pos": pos,
		"radius": wstat("bone_spikes", "radius") * 0.7,
		"delay": wstat("bone_spikes", "delay") * 0.8,
		"damage": wstat("bone_spikes", "damage") * 0.6, "source": "bone_spikes",
		"color": GameData.weapon_color("bone_spikes"), "opts": {}})


func _fire_phantom_bow() -> bool:
	var target: Node2D = world.highest_health_enemy(player.global_position, wstat("phantom_bow", "range"))
	if target == null:
		return false
	var count := int(wstat("phantom_bow", "count"))
	var dir: Vector2 = (target.global_position - player.global_position).normalized()
	for i in count:
		var spread := (i - (count - 1) * 0.5) * 0.12
		world.spawn_projectile({"kind": "arrow", "color": GameData.weapon_color("phantom_bow"),
			"pos": player.global_position, "dir": dir.rotated(spread),
			"speed": wstat("phantom_bow", "speed"), "damage": wstat("phantom_bow", "damage"),
			"pierce": int(wstat("phantom_bow", "pierce")), "source": "phantom_bow",
			"crit_bonus": wstat("phantom_bow", "crit_bonus"),
			"split": wstat("phantom_bow", "split") > 0.0,
			"max_distance": wstat("phantom_bow", "range") * 1.25})
	AudioManager.play_weapon("phantom_bow")
	return true


func _fire_plague_lantern() -> bool:
	var aim: Vector2 = world.densest_cluster_pos(player.global_position, 430.0)
	if aim == Vector2.INF:
		return false
	var count := int(wstat("plague_lantern", "count"))
	for i in count:
		var offset := Vector2.ZERO if i == 0 else Vector2(randf_range(-90, 90), randf_range(-90, 90))
		world.spawn_zone({"kind": "cloud", "pos": aim + offset,
			"radius": wstat("plague_lantern", "radius"),
			"duration": wstat("plague_lantern", "duration"), "tick": 0.5,
			"source": "plague_lantern", "color": GameData.weapon_color("plague_lantern"),
			"opts": {"poison_dps": wstat("plague_lantern", "dps"), "poison_dur": 2.0,
				"vuln": wstat("plague_lantern", "vuln")}})
	AudioManager.play_weapon("plague_lantern")
	return true


func _fire_iron_maiden() -> bool:
	if _maiden_active:
		return false
	_activate_maiden()
	return true


func _activate_maiden() -> void:
	_maiden_active = true
	var duration := wstat("iron_maiden", "duration")
	var cage := Node2D.new()
	cage.set_script(ORBITER_SCRIPT)
	cage.world = world
	cage.weapon_manager = self
	cage.kind = "maiden"
	world.entity_layer.add_child(cage)
	cage.start_maiden(duration)
	_maiden_dr = wstat("iron_maiden", "dr")
	player.dr_extra += _maiden_dr
	# immediate retaliation burst
	world.area_damage(player.global_position, wstat("iron_maiden", "radius"),
		wstat("iron_maiden", "damage") * wstat("iron_maiden", "retaliation"),
		"iron_maiden", Color(1.0, 0.55, 0.42))
	AudioManager.play_weapon("iron_maiden")


func maiden_finished(cage: Node2D) -> void:
	_maiden_active = false
	player.dr_extra = maxf(0.0, player.dr_extra - _maiden_dr)
	cage.queue_free()
	# Iron Reliquary visual tie-in: cage cracks into a brief shockwave
	world.spawn_fx({"kind": "shockwave", "pos": player.global_position,
		"radius": wstat("iron_maiden", "radius"), "color": Color(1.0, 0.55, 0.42)})


func _fire_moon_chakram() -> bool:
	var count := int(wstat("moon_chakram", "count"))
	var dir: Vector2 = player.facing
	for i in count:
		var spread := (i - (count - 1) * 0.5) * 0.35
		world.spawn_projectile({"kind": "chakram", "color": GameData.weapon_color("moon_chakram"),
			"pos": player.global_position, "dir": dir.rotated(spread),
			"speed": wstat("moon_chakram", "speed"), "damage": wstat("moon_chakram", "damage"),
			"pierce": 999, "source": "moon_chakram", "behavior": "chakram",
			"size": wstat("moon_chakram", "size"),
			"max_distance": wstat("moon_chakram", "distance"),
			"on_return_knives": world.synergies.has("moonlit_blades") and owned.has("rune_knives"),
			"lifetime": 6.0})
	AudioManager.play_weapon("moon_chakram")
	return true


func _fire_death_mark() -> bool:
	var marks := int(wstat("death_mark", "marks"))
	var targets: Array = world.random_enemies(marks, player.global_position, 540.0)
	if targets.is_empty():
		return false
	for target in targets:
		target.apply_mark(wstat("death_mark", "vuln"), wstat("death_mark", "duration"),
			wstat("death_mark", "explode") > 0.0, wstat("death_mark", "explode_damage"),
			wstat("death_mark", "spread"))
	AudioManager.play_weapon("death_mark")
	return true


func _fire_storm_censer() -> bool:
	var strikes := int(wstat("storm_censer", "strikes"))
	var targets: Array = world.random_enemies(strikes, player.global_position, 600.0)
	if targets.is_empty():
		return false
	var double_chance := wstat("storm_censer", "double")
	for target in targets:
		_spawn_strike(target.global_position)
		if double_chance > 0.0 and randf() < double_chance:
			_spawn_strike(target.global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60)))
	return true


func _spawn_strike(pos: Vector2) -> void:
	world.spawn_zone({"kind": "strike", "pos": pos, "radius": wstat("storm_censer", "radius"),
		"delay": wstat("storm_censer", "delay"), "damage": wstat("storm_censer", "damage"),
		"source": "storm_censer", "color": GameData.weapon_color("storm_censer")})


func _fire_saints_hammer() -> bool:
	var aim: Vector2 = world.densest_cluster_pos(player.global_position, 480.0)
	if aim == Vector2.INF:
		return false
	world.spawn_zone({"kind": "hammer", "pos": aim, "radius": wstat("saints_hammer", "radius"),
		"delay": wstat("saints_hammer", "delay"), "damage": wstat("saints_hammer", "damage"),
		"knockback": wstat("saints_hammer", "knockback") * player.stats["knockback_mult"],
		"stun": wstat("saints_hammer", "stun"), "source": "saints_hammer",
		"color": GameData.weapon_color("saints_hammer"),
		"opts": {"crack": wstat("saints_hammer", "crack") > 0.0}})
	return true


# === REACTIVE / SYNERGY HOOKS ==============================================

func _on_player_hurt(_amount: float, hp: float, max_hp: float) -> void:
	if not owned.has("iron_maiden"):
		return
	# retaliation burst on being hit (internal 2s cooldown)
	if _retal_cd <= 0.0:
		_retal_cd = 2.0
		world.area_damage(player.global_position, wstat("iron_maiden", "radius") * 0.8,
			wstat("iron_maiden", "damage") * 0.7, "iron_maiden", Color(1.0, 0.55, 0.42))
		# Maiden's Verdict synergy: retaliation also drops a small hammer
		if world.synergies.has("maidens_verdict") and owned.has("saints_hammer"):
			var aim: Vector2 = world.densest_cluster_pos(player.global_position, 320.0)
			if aim == Vector2.INF:
				aim = player.global_position
			world.spawn_zone({"kind": "hammer", "pos": aim,
				"radius": wstat("saints_hammer", "radius") * 0.7,
				"delay": wstat("saints_hammer", "delay") * 0.7,
				"damage": wstat("saints_hammer", "damage") * 0.5,
				"knockback": wstat("saints_hammer", "knockback") * 0.7,
				"source": "saints_hammer",
				"color": GameData.weapon_color("saints_hammer"), "opts": {}})
	# Last Rites upgrade: emergency cage at low health
	if wstat("iron_maiden", "emergency") > 0.0 and hp <= max_hp * 0.3 and not _maiden_active:
		_activate_maiden()
		owned["iron_maiden"]["cd"] = wstat("iron_maiden", "cooldown")


func _on_player_dashed() -> void:
	if world != null and world.synergies.has("iron_reliquary"):
		relic_harden_t = 2.0


func _on_enemy_killed(enemy: Node2D, _source: String) -> void:
	if world != null and world.synergies.has("grave_harvest") and enemy.marked:
		player.heal(2.0, false)
