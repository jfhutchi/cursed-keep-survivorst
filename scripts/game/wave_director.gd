class_name WaveDirector
extends Node
## Drives the 10-wave survival run: spawn pacing, composition, elites,
## wave announcements and the final boss.

var world: Node2D
var wave_index := 0
var time_in_wave := 0.0
var boss_spawned := false
var running := false

var _spawn_timer := 1.0


func start() -> void:
	wave_index = 0
	time_in_wave = 0.0
	boss_spawned = false
	running = true
	_announce()


func current_wave() -> Dictionary:
	return WaveData.get_wave(wave_index)


func update(delta: float) -> void:
	if not running:
		return
	var wave := current_wave()
	time_in_wave += delta

	# advance to next wave (boss wave only ends with victory/defeat)
	if time_in_wave >= float(wave["duration"]) and not bool(wave.get("boss", false)):
		wave_index += 1
		time_in_wave = 0.0
		wave = current_wave()
		_announce()

	if bool(wave.get("boss", false)) and not boss_spawned:
		boss_spawned = true
		world.spawn_boss()

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		var progress := clampf(time_in_wave / float(wave["duration"]), 0.0, 1.0)
		var interval: Array = wave["interval"]
		_spawn_timer = lerpf(float(interval[0]), float(interval[1]), progress)
		if world.enemies_alive.size() < int(wave["max_alive"]):
			_spawn_one(wave)


func _spawn_one(wave: Dictionary) -> void:
	var comp: Dictionary = wave["comp"]
	var total := 0.0
	for w in comp.values():
		total += float(w)
	var roll := randf() * total
	var chosen := ""
	for id: String in comp.keys():
		roll -= float(comp[id])
		if roll <= 0.0:
			chosen = id
			break
	if chosen == "":
		return
	var elite := randf() < float(wave.get("elite_chance", 0.0))
	world.spawn_enemy(chosen, _spawn_position(), elite, float(wave.get("hp_mult", 1.0)))


## Spawns on a ring around the player, clamped inside the arena and pushed
## off-screen where possible — never directly on top of the player.
func _spawn_position() -> Vector2:
	var player: Node2D = world.player
	var center: Vector2 = player.global_position if player != null else Vector2.ZERO
	var half: Vector2 = GameData.ARENA_HALF
	for attempt in 8:
		var angle := randf() * TAU
		var dist := randf_range(GameData.SPAWN_RING.x, GameData.SPAWN_RING.y)
		var pos := center + Vector2.from_angle(angle) * dist
		pos = pos.clamp(-half + Vector2(40, 40), half - Vector2(40, 40))
		if pos.distance_squared_to(center) > 360.0 * 360.0:
			return pos
	# fallback: arena edge farthest from player
	return Vector2(-half.x + 60 if center.x > 0 else half.x - 60, clampf(center.y, -half.y + 60, half.y - 60))


func _announce() -> void:
	var wave := current_wave()
	AudioManager.play(&"wave_start")
	GameEvents.wave_started.emit(wave_index + 1, str(wave["name"]))
