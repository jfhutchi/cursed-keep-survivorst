class_name GameWorld
extends Node2D
## The running game: arena, player, enemies, pools, damage pipeline,
## spatial grid, wave director, weapon manager and run statistics.
## Created fresh by Main for each run; freed on restart.

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/CursedCastellan.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectiles/Projectile.tscn")
const ZONE_SCENE := preload("res://scenes/effects/Zone.tscn")
const FX_SCENE := preload("res://scenes/effects/Fx.tscn")
const XP_ORB_SCENE := preload("res://scenes/pickups/XPOrb.tscn")
const PICKUP_SCENE := preload("res://scenes/pickups/Pickup.tscn")
const TEXT_SCENE := preload("res://scenes/effects/FloatingText.tscn")

const GRID_CELL := 96.0

var player: Player
var camera: CameraRig
var weapon_manager: WeaponManager
var upgrade_system: UpgradeSystem
var wave_director: WaveDirector
var boss: Node2D

var enemies_alive: Array = []
var enemy_mods: Dictionary = {"speed_mult": 1.0, "elite_hp_mult": 1.0}
var synergies: Dictionary = {}

var game_active := false
var run_time := 0.0
var score := 0
var kills := 0

var entity_layer: Node2D
var zone_layer: Node2D
var orb_layer: Node2D
var proj_layer: Node2D
var fx_layer: Node2D
var text_layer: Node2D

var _grid: Dictionary = {}
var _pool_proj: ObjectPool
var _pool_zone: ObjectPool
var _pool_fx: ObjectPool
var _pool_orb: ObjectPool
var _pool_pickup: ObjectPool
var _pool_text: ObjectPool
var _enemy_pools: Dictionary = {}
var _source_counts: Dictionary = {}    # weapon source -> live projectile/zone count
var _hostile_proj_count := 0
var _enemy_scenes: Dictionary = {}


func _ready() -> void:
	var arena := Arena.new()
	arena.z_index = -20
	add_child(arena)

	zone_layer = _make_layer(-5)
	orb_layer = _make_layer(-3)
	entity_layer = _make_layer(0)
	entity_layer.y_sort_enabled = true
	proj_layer = _make_layer(5)
	fx_layer = _make_layer(8)
	text_layer = _make_layer(10)

	player = PLAYER_SCENE.instantiate()
	player.world = self
	entity_layer.add_child(player)
	player.global_position = Vector2.ZERO

	camera = CameraRig.new()
	camera.target = player
	add_child(camera)

	weapon_manager = WeaponManager.new()
	weapon_manager.world = self
	weapon_manager.player = player
	add_child(weapon_manager)

	upgrade_system = UpgradeSystem.new()
	upgrade_system.world = self
	upgrade_system.player = player
	upgrade_system.weapon_manager = weapon_manager
	add_child(upgrade_system)

	wave_director = WaveDirector.new()
	wave_director.world = self
	add_child(wave_director)

	_pool_proj = ObjectPool.new(proj_layer, PROJECTILE_SCENE)
	_pool_zone = ObjectPool.new(zone_layer, ZONE_SCENE)
	_pool_fx = ObjectPool.new(fx_layer, FX_SCENE)
	_pool_orb = ObjectPool.new(orb_layer, XP_ORB_SCENE)
	_pool_pickup = ObjectPool.new(orb_layer, PICKUP_SCENE)
	_pool_text = ObjectPool.new(text_layer, TEXT_SCENE)

	for id: String in GameData.enemies.keys():
		_enemy_scenes[id] = load(GameData.enemies[id]["scene"])

	GameEvents.player_died.connect(_on_player_died)

	weapon_manager.start_run()
	wave_director.start()
	game_active = true
	AudioManager.play(&"run_start")
	GameEvents.run_started.emit()
	GameEvents.score_changed.emit(0)


func _make_layer(z: int) -> Node2D:
	var layer := Node2D.new()
	layer.z_index = z
	add_child(layer)
	return layer


func _physics_process(delta: float) -> void:
	if not game_active:
		return
	run_time += delta
	_rebuild_grid()
	for enemy: Node2D in enemies_alive.duplicate():
		if enemy != boss and enemy.alive:
			enemy.tick(delta, player)
	wave_director.update(delta)
	weapon_manager.update(delta)


# === SPATIAL GRID ==========================================================

func _rebuild_grid() -> void:
	_grid.clear()
	for enemy: Node2D in enemies_alive:
		if not enemy.alive:
			continue
		var key := Vector2i(int(floorf(enemy.global_position.x / GRID_CELL)), int(floorf(enemy.global_position.y / GRID_CELL)))
		if _grid.has(key):
			_grid[key].append(enemy)
		else:
			_grid[key] = [enemy]


func query_enemies(pos: Vector2, radius: float) -> Array:
	var result: Array = []
	var r_sq := radius * radius
	var min_c := Vector2i(int(floorf((pos.x - radius) / GRID_CELL)), int(floorf((pos.y - radius) / GRID_CELL)))
	var max_c := Vector2i(int(floorf((pos.x + radius) / GRID_CELL)), int(floorf((pos.y + radius) / GRID_CELL)))
	for cx in range(min_c.x, max_c.x + 1):
		for cy in range(min_c.y, max_c.y + 1):
			var key := Vector2i(cx, cy)
			if not _grid.has(key):
				continue
			for enemy: Node2D in _grid[key]:
				if enemy.alive and enemy.global_position.distance_squared_to(pos) <= r_sq:
					result.append(enemy)
	return result


func nearest_enemy(pos: Vector2, max_range: float) -> Node2D:
	var best: Node2D = null
	var best_sq := max_range * max_range
	for enemy: Node2D in query_enemies(pos, max_range):
		var d := enemy.global_position.distance_squared_to(pos)
		if d < best_sq:
			best_sq = d
			best = enemy
	return best


func nearest_enemy_excluding(pos: Vector2, max_range: float, excluded: Dictionary) -> Node2D:
	var best: Node2D = null
	var best_sq := max_range * max_range
	for enemy: Node2D in query_enemies(pos, max_range):
		if excluded.has(enemy.get_instance_id()):
			continue
		var d := enemy.global_position.distance_squared_to(pos)
		if d < best_sq:
			best_sq = d
			best = enemy
	return best


func highest_health_enemy(pos: Vector2, max_range: float) -> Node2D:
	var best: Node2D = null
	var best_hp := -1.0
	for enemy: Node2D in query_enemies(pos, max_range):
		if enemy.hp > best_hp:
			best_hp = enemy.hp
			best = enemy
	return best


func random_enemies(count: int, pos: Vector2, max_range: float) -> Array:
	var all := query_enemies(pos, max_range)
	all.shuffle()
	return all.slice(0, count)


func find_marked_enemy(pos: Vector2, max_range: float) -> Node2D:
	var best: Node2D = null
	var best_sq := max_range * max_range
	for enemy: Node2D in query_enemies(pos, max_range):
		if not enemy.marked:
			continue
		var d := enemy.global_position.distance_squared_to(pos)
		if d < best_sq:
			best_sq = d
			best = enemy
	return best


## Returns the center of the densest nearby enemy cluster, or Vector2.INF.
func densest_cluster_pos(pos: Vector2, max_range: float) -> Vector2:
	var candidates := random_enemies(14, pos, max_range)
	if candidates.is_empty():
		return Vector2.INF
	var best_pos: Vector2 = candidates[0].global_position
	var best_count := -1
	for enemy: Node2D in candidates:
		var neighbors := query_enemies(enemy.global_position, 110.0).size()
		if neighbors > best_count:
			best_count = neighbors
			best_pos = enemy.global_position
	return best_pos


func compute_separation(enemy: Node2D) -> Vector2:
	var push := Vector2.ZERO
	var neighbors := query_enemies(enemy.global_position, enemy.radius * 2.2)
	var checked := 0
	for other: Node2D in neighbors:
		if other == enemy:
			continue
		var away: Vector2 = enemy.global_position - other.global_position
		var dist := away.length()
		var min_dist: float = enemy.radius + other.radius
		if dist < min_dist and dist > 0.01:
			push += away / dist * (1.0 - dist / min_dist)
		checked += 1
		if checked >= 6:
			break
	return push.limit_length(1.6)


# === DAMAGE PIPELINE =======================================================

## Central damage entry point: rolls crits, delegates to the enemy.
## opts: kb (Vector2), crit_bonus (float), no_crit (bool)
func deal_damage(enemy: Node2D, base_damage: float, source: String, opts: Dictionary = {}) -> Dictionary:
	if enemy == null or not enemy.alive:
		return {"dealt": 0.0, "crit": false}
	var is_crit := false
	if not bool(opts.get("no_crit", false)):
		var chance: float = player.stats["crit_chance"] + float(opts.get("crit_bonus", 0.0))
		is_crit = randf() < chance
	var dmg: float = base_damage * (player.stats["crit_mult"] if is_crit else 1.0)
	var dealt: float = enemy.take_damage(dmg, opts.get("kb", Vector2.ZERO), source, is_crit)
	return {"dealt": dealt, "crit": is_crit}


func area_damage(pos: Vector2, radius: float, damage: float, source: String, color: Color) -> void:
	for enemy: Node2D in query_enemies(pos, radius):
		deal_damage(enemy, damage, source, {"kb": (enemy.global_position - pos).normalized() * 80.0})
	spawn_fx({"kind": "nova", "pos": pos, "radius": radius, "color": color, "duration": 0.3})


func show_damage_number(pos: Vector2, amount: float, is_crit: bool) -> void:
	if _pool_text.active_count() >= GameData.MAX_FLOATING_TEXT:
		return
	var text: FloatingText = _pool_text.acquire()
	text.world = self
	var color := Color(1.0, 0.85, 0.3) if is_crit else Color(0.95, 0.95, 1.0)
	text.setup(pos, str(int(maxf(roundf(amount), 1.0))), color, 17 if is_crit else 13)


# === SPAWNERS ==============================================================

func spawn_enemy(id: String, pos: Vector2, elite: bool, hp_mult: float) -> Node2D:
	var def: Dictionary = GameData.enemy(id)
	if def.is_empty():
		return null
	if not _enemy_pools.has(id):
		_enemy_pools[id] = ObjectPool.new(entity_layer, _enemy_scenes[id])
	var enemy: Node2D = _enemy_pools[id].acquire()
	enemy.world = self
	enemy.global_position = pos
	enemy.setup(def, elite, hp_mult)
	enemies_alive.append(enemy)
	return enemy


func spawn_boss() -> void:
	boss = BOSS_SCENE.instantiate()
	boss.world = self
	entity_layer.add_child(boss)
	var dir_to_center: Vector2 = (Vector2.ZERO - player.global_position).normalized()
	if dir_to_center.length_squared() < 0.01:
		dir_to_center = Vector2.UP
	boss.global_position = (player.global_position + dir_to_center * 480.0).clamp(
		-GameData.ARENA_HALF + Vector2(120, 120), GameData.ARENA_HALF - Vector2(120, 120))
	boss.setup(GameData.boss, 1.0)
	enemies_alive.append(boss)


func on_enemy_died(enemy: Node2D, source: String) -> void:
	kills += 1
	add_score(enemy.score_value)
	var def: Dictionary = enemy.def
	# death dissolve + burst
	var tint := Color(str(def.get("tint", "ffffff")))
	spawn_fx({"kind": "burst", "pos": enemy.global_position, "color": tint,
		"size": 1.6 if enemy.elite else 1.0, "radius": 50.0})
	var sprite_node: Sprite2D = enemy.get_node("Sprite")
	spawn_fx({"kind": "ghost", "pos": enemy.global_position, "color": tint,
		"texture": sprite_node.texture, "flip": sprite_node.flip_h, "duration": 0.35})
	AudioManager.play(&"elite_death" if enemy.elite else &"enemy_death", -6.0, 0.2)
	# XP soul shards
	var total_xp: int = enemy.xp_value
	var orb_count := 1 if total_xp <= 2 else 2
	for i in orb_count:
		spawn_xp_orb(enemy.global_position, float(total_xp) / orb_count)
	# elite pickups
	if enemy.elite:
		var roll := randf()
		if roll < 0.3:
			spawn_pickup(enemy.global_position + Vector2(20, 0), "health")
		elif roll < 0.42:
			spawn_pickup(enemy.global_position + Vector2(20, 0), "magnet")
	# Grave Splitter: split into fragments
	if def.has("splits_into"):
		for i in int(def.get("split_count", 3)):
			var a := TAU * i / int(def.get("split_count", 3))
			spawn_enemy(str(def["splits_into"]), enemy.global_position + Vector2.from_angle(a) * 26.0, false, 1.0)
	GameEvents.enemy_killed.emit(enemy, source)
	enemies_alive.erase(enemy)
	if enemy == boss:
		boss = null
		enemies_alive.erase(enemy)
	elif _enemy_pools.has(enemy.enemy_id):
		_enemy_pools[enemy.enemy_id].release(enemy)
	else:
		# pooled under its base id (e.g. fragments use the crawler scene)
		for pool_id: String in _enemy_pools.keys():
			var pool: ObjectPool = _enemy_pools[pool_id]
			if pool.active.has(enemy):
				pool.release(enemy)
				break


func add_score(points: int) -> void:
	score += int(points * player.stats["score_mult"])
	GameEvents.score_changed.emit(score)


func spawn_projectile(params: Dictionary) -> void:
	var source: String = params.get("source", "")
	if source != "":
		var def: Dictionary = GameData.weapon(source)
		var cap: int = def.get("max_active", 60) if not def.is_empty() else 60
		if int(_source_counts.get(source, 0)) >= cap:
			return
	if _pool_proj.active_count() >= GameData.MAX_PROJECTILES:
		return
	var proj: Projectile = _pool_proj.acquire()
	proj.world = self
	proj.setup(params)
	if source != "":
		_source_counts[source] = int(_source_counts.get(source, 0)) + 1


func spawn_enemy_projectile(params: Dictionary) -> void:
	if _hostile_proj_count >= GameData.MAX_ENEMY_PROJECTILES:
		return
	params["hostile"] = true
	var proj: Projectile = _pool_proj.acquire()
	proj.world = self
	proj.setup(params)
	_hostile_proj_count += 1


func release_projectile(proj: Projectile) -> void:
	if proj.hostile:
		_hostile_proj_count = maxi(0, _hostile_proj_count - 1)
	elif proj.source != "":
		_source_counts[proj.source] = maxi(0, int(_source_counts.get(proj.source, 0)) - 1)
	_pool_proj.release(proj)


func spawn_zone(params: Dictionary) -> void:
	var source: String = params.get("source", "")
	if source != "" and source != "boss":
		var def: Dictionary = GameData.weapon(source)
		var cap: int = def.get("max_active", 12) if not def.is_empty() else 12
		if int(_source_counts.get("zone_" + source, 0)) >= cap:
			return
	if _pool_zone.active_count() >= GameData.MAX_ZONES:
		return
	var zone: Zone = _pool_zone.acquire()
	zone.world = self
	zone.setup(params)
	if source != "" and source != "boss":
		_source_counts["zone_" + source] = int(_source_counts.get("zone_" + source, 0)) + 1


func release_zone(zone: Zone) -> void:
	if zone.source != "" and zone.source != "boss":
		var key := "zone_" + zone.source
		_source_counts[key] = maxi(0, int(_source_counts.get(key, 0)) - 1)
	_pool_zone.release(zone)


func spawn_fx(params: Dictionary) -> void:
	if _pool_fx.active_count() >= GameData.MAX_FX:
		return
	var fx: Fx = _pool_fx.acquire()
	fx.world = self
	fx.setup(params)


func release_fx(fx: Fx) -> void:
	_pool_fx.release(fx)


func spawn_xp_orb(pos: Vector2, value: float) -> void:
	if _pool_orb.active_count() >= GameData.MAX_XP_ORBS:
		# merge into the nearest live orb instead of dropping XP on the floor
		var nearest: XpOrb = null
		var best := INF
		for orb: XpOrb in _pool_orb.active:
			var d := orb.global_position.distance_squared_to(pos)
			if d < best:
				best = d
				nearest = orb
		if nearest != null:
			nearest.value += value
		return
	var orb2: XpOrb = _pool_orb.acquire()
	orb2.world = self
	orb2.setup(pos, value)


func release_orb(orb: XpOrb) -> void:
	_pool_orb.release(orb)


func magnetize_all_orbs() -> void:
	for orb: XpOrb in _pool_orb.active:
		orb.force_magnet()


func spawn_pickup(pos: Vector2, kind: String) -> void:
	var pickup: Pickup = _pool_pickup.acquire()
	pickup.world = self
	pickup.setup(pos, kind)


func release_pickup(pickup: Pickup) -> void:
	_pool_pickup.release(pickup)


func spawn_text(pos: Vector2, text_str: String, color: Color, size := 13) -> void:
	if _pool_text.active_count() >= GameData.MAX_FLOATING_TEXT:
		return
	var text: FloatingText = _pool_text.acquire()
	text.world = self
	text.setup(pos, text_str, color, size)


func release_text(text: FloatingText) -> void:
	_pool_text.release(text)


# === RUN STATE =============================================================

func _on_player_died() -> void:
	game_active = false


func run_stats() -> Dictionary:
	return {
		"score": score,
		"kills": kills,
		"time": run_time,
		"wave": wave_director.wave_index + 1,
		"level": player.level,
	}


func debug_counts() -> Dictionary:
	return {
		"enemies": enemies_alive.size(),
		"projectiles": _pool_proj.active_count(),
		"orbs": _pool_orb.active_count(),
		"zones": _pool_zone.active_count(),
		"fx": _pool_fx.active_count(),
		"wave": wave_director.wave_index + 1,
	}
