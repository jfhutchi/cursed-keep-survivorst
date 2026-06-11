class_name Boss
extends Node2D
## The Cursed Castellan — Heart of the Keep. Final boss.
## Phases:
##   1 (100-70%): radial curse bursts + minion summons
##   2 (70-35%):  + ground sigil explosions + telegraphed charge sweeps
##   3 (<35%):    ENRAGE - faster cooldowns, denser bursts, red glow
## Implements the same combat interface as Enemy (take_damage / apply_*)
## so every weapon works against it.

var world: Node2D
var alive := true
var active := true
var elite := false
var radius := 46.0
var hp := 2600.0
var max_hp := 2600.0
var contact_damage := 25.0
var speed := 62.0

# Status interface (heavily resisted but functional)
var burn_dps := 0.0
var burn_t := 0.0
var poison_dps := 0.0
var poison_t := 0.0
var poison_vuln := 0.0
var bleed_dps := 0.0
var bleed_t := 0.0
var slow_factor := 0.0
var slow_t := 0.0
var marked := false
var mark_vuln := 0.0
var mark_t := 0.0
var mark_explode := false
var mark_explode_damage := 0.0
var mark_spread := 0.0

var phase := 1
var enraged := false

var _state := "spawning" # spawning | fight | charging | dying
var _state_t := 0.0
var _contact_cd := 0.0
var _dot_acc := 0.0
var _flash := 0.0
var _bob := 0.0

var _burst_cd := 4.0
var _summon_cd := 6.0
var _sigil_cd := 8.0
var _charge_cd := 11.0
var _charge_dir := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite


func setup(boss_def: Dictionary, hp_mult: float) -> void:
	max_hp = boss_def["hp"] * hp_mult * world.enemy_mods.get("elite_hp_mult", 1.0)
	hp = max_hp
	contact_damage = boss_def["damage"]
	speed = boss_def["speed"]
	radius = boss_def["radius"]
	_state = "spawning"
	_state_t = 0.0
	AudioManager.play(&"boss_spawn")
	GameEvents.boss_spawned.emit(self)
	GameEvents.boss_health_changed.emit(hp, max_hp)
	GameEvents.screen_shake_requested.emit(10.0)
	world.spawn_fx({"kind": "boss_warning", "pos": global_position, "radius": 110.0, "duration": 1.8})
	modulate.a = 0.0


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_state_t += delta
	_tick_statuses(delta)
	if not alive:
		return
	var player: Node2D = world.player
	match _state:
		"spawning":
			modulate.a = clampf(_state_t / 1.6, 0.0, 1.0)
			if _state_t >= 1.8:
				_state = "fight"
				_state_t = 0.0
		"fight":
			if player != null and player.alive:
				_fight_tick(delta, player)
		"charging":
			_charge_tick(delta, player)
	_animate(delta)


func _fight_tick(delta: float, player: Node2D) -> void:
	var cd_scale := 0.6 if enraged else 1.0
	var slow_mult := 1.0 - slow_factor * 0.4 if slow_t > 0.0 else 1.0 # bosses resist slows
	var dir: Vector2 = (player.global_position - global_position).normalized()
	global_position += dir * speed * (1.5 if enraged else 1.0) * slow_mult * delta
	var half: Vector2 = GameData.ARENA_HALF
	global_position = global_position.clamp(-half + Vector2(60, 60), half - Vector2(60, 60))

	_contact_cd -= delta
	if _contact_cd <= 0.0:
		var rsum := radius + 20.0
		if global_position.distance_squared_to(player.global_position) < rsum * rsum:
			player.take_damage(contact_damage, global_position)
			_contact_cd = 1.0

	_burst_cd -= delta
	if _burst_cd <= 0.0:
		_burst_cd = 5.5 * cd_scale
		_radial_burst()

	_summon_cd -= delta
	if _summon_cd <= 0.0:
		_summon_cd = 8.0 * cd_scale
		_summon_minions()

	if phase >= 2:
		_sigil_cd -= delta
		if _sigil_cd <= 0.0:
			_sigil_cd = 7.0 * cd_scale
			_ground_sigils(player)
		_charge_cd -= delta
		if _charge_cd <= 0.0:
			_charge_cd = 9.0 * cd_scale
			_begin_charge(player)


func _radial_burst() -> void:
	AudioManager.play(&"boss_attack")
	var count := 16 if enraged else 10
	var base_angle := randf() * TAU
	for i in count:
		var a := base_angle + TAU * i / count
		world.spawn_enemy_projectile({"kind": "shard", "pos": global_position,
			"dir": Vector2.from_angle(a), "speed": 240.0 if not enraged else 290.0,
			"damage": 14.0, "color": Color(0.78, 0.45, 1.0), "hostile": true,
			"max_distance": 900.0, "size": 1.3})
	world.spawn_fx({"kind": "nova", "pos": global_position, "color": Color(0.78, 0.45, 1.0), "radius": 90.0})


func _summon_minions() -> void:
	AudioManager.play(&"boss_attack", -4.0)
	var pool := ["bone_crawler", "starved_ghoul", "wraith"]
	var count := 5 if enraged else 4
	for i in count:
		var a := TAU * i / count + randf() * 0.5
		var pos: Vector2 = global_position + Vector2.from_angle(a) * randf_range(90.0, 150.0)
		world.spawn_enemy(pool[randi() % pool.size()], pos, false, 2.2)
	world.spawn_fx({"kind": "ring", "pos": global_position, "color": Color(0.6, 1.0, 0.6), "radius": 150.0})


func _ground_sigils(player: Node2D) -> void:
	var count := 5 if enraged else 3
	for i in count:
		var offset := Vector2(randf_range(-180, 180), randf_range(-180, 180))
		var pos: Vector2 = player.global_position + offset if i > 0 else player.global_position
		world.spawn_zone({"kind": "sigil", "pos": pos, "radius": 85.0, "delay": 1.1,
			"damage": 18.0, "color": Color(0.78, 0.45, 1.0), "source": "boss"})


func _begin_charge(player: Node2D) -> void:
	_state = "charging"
	_state_t = 0.0
	_charge_dir = (player.global_position - global_position).normalized()
	AudioManager.play(&"knight_charge")
	world.spawn_fx({"kind": "warning_line", "pos": global_position, "angle": _charge_dir.angle(),
		"length": 620.0, "width": radius * 2.4, "duration": 0.85})


func _charge_tick(delta: float, player: Node2D) -> void:
	if _state_t < 0.85:
		# wind-up: track the player slightly
		if player != null and player.alive:
			var want: Vector2 = (player.global_position - global_position).normalized()
			_charge_dir = _charge_dir.lerp(want, 1.2 * delta).normalized()
		return
	if _state_t < 1.45:
		global_position += _charge_dir * 640.0 * delta
		var half: Vector2 = GameData.ARENA_HALF
		var clamped := global_position.clamp(-half + Vector2(60, 60), half - Vector2(60, 60))
		if clamped != global_position:
			global_position = clamped
			_end_charge()
			return
		if player != null and player.alive and _contact_cd <= 0.0:
			var rsum := radius + 22.0
			if global_position.distance_squared_to(player.global_position) < rsum * rsum:
				player.take_damage(contact_damage * 1.3, global_position)
				_contact_cd = 1.0
		_contact_cd -= delta
		return
	_end_charge()


func _end_charge() -> void:
	GameEvents.screen_shake_requested.emit(7.0)
	world.spawn_fx({"kind": "shockwave", "pos": global_position, "color": Color(0.8, 0.5, 1.0), "radius": 160.0})
	_state = "fight"
	_state_t = 0.0


func _tick_statuses(delta: float) -> void:
	if burn_t > 0.0: burn_t -= delta
	if poison_t > 0.0: poison_t -= delta
	if bleed_t > 0.0: bleed_t -= delta
	if slow_t > 0.0: slow_t -= delta
	if mark_t > 0.0:
		mark_t -= delta
		if mark_t <= 0.0:
			marked = false
	_dot_acc += delta
	if _dot_acc >= 0.45:
		_dot_acc -= 0.45
		var dot := 0.0
		if burn_t > 0.0: dot += burn_dps * 0.45
		if poison_t > 0.0: dot += poison_dps * 0.45
		if bleed_t > 0.0: dot += bleed_dps * 0.45
		if dot > 0.0:
			take_damage(dot, Vector2.ZERO, "dot", false, false)


func apply_burn(dps: float, dur: float) -> void:
	burn_dps = maxf(burn_dps, dps); burn_t = maxf(burn_t, dur)

func apply_poison(dps: float, dur: float) -> void:
	poison_dps = maxf(poison_dps, dps); poison_t = maxf(poison_t, dur)

func apply_bleed(dps: float, dur: float) -> void:
	bleed_dps = maxf(bleed_dps, dps); bleed_t = maxf(bleed_t, dur)

func apply_slow(factor: float, dur: float) -> void:
	slow_factor = clampf(maxf(slow_factor, factor), 0.0, 0.5); slow_t = maxf(slow_t, dur)

func apply_stun(_dur: float) -> void:
	pass # the Castellan cannot be stunned

func apply_mark(vuln: float, dur: float, explode: bool, explode_damage: float, spread: float) -> void:
	marked = true
	mark_vuln = maxf(mark_vuln, vuln * 0.5) # bosses resist marks
	mark_t = maxf(mark_t, dur)
	mark_explode = explode
	mark_explode_damage = explode_damage
	mark_spread = spread


func take_damage(amount: float, kb: Vector2, _source: String, is_crit: bool, flash := true) -> float:
	if not alive or _state == "spawning":
		return 0.0
	var final := amount
	if marked:
		final *= 1.0 + mark_vuln
	if poison_t > 0.0 and poison_vuln > 0.0:
		final *= 1.0 + poison_vuln
	hp -= final
	knockback_nudge(kb)
	if flash:
		_flash = 1.0
		sprite.self_modulate = Color(3.0, 2.0, 2.0)
		AudioManager.play(&"boss_hurt", -8.0)
	world.show_damage_number(global_position + Vector2(0, -radius), final, is_crit)
	GameEvents.boss_health_changed.emit(maxf(hp, 0.0), max_hp)
	if not enraged and hp <= max_hp * 0.35:
		_enrage()
	if phase == 1 and hp <= max_hp * 0.7:
		phase = 2
	if hp <= 0.0:
		_die()
	return final


func knockback_nudge(kb: Vector2) -> void:
	global_position += kb * 0.02 # nearly immovable


func _enrage() -> void:
	enraged = true
	phase = 3
	AudioManager.play(&"boss_spawn", -3.0, 0.3)
	world.spawn_fx({"kind": "nova", "pos": global_position, "color": Color(1.0, 0.25, 0.3), "radius": 200.0})
	GameEvents.screen_shake_requested.emit(8.0)


func _die() -> void:
	alive = false
	_state = "dying"
	hp = 0.0
	AudioManager.play(&"boss_death")
	GameEvents.hit_stop_requested.emit(0.12)
	GameEvents.screen_shake_requested.emit(14.0)
	for i in 4:
		world.spawn_fx({"kind": "burst", "pos": global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40)),
			"color": Color(0.8, 0.5, 1.0), "size": 2.5, "radius": 120.0})
	world.spawn_fx({"kind": "nova", "pos": global_position, "color": Color(1.0, 0.9, 0.6), "radius": 320.0, "duration": 0.8})
	# slow collapse, then signal victory
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", sprite.scale * Vector2(1.3, 0.1), 1.2).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, "modulate", Color(2.0, 1.5, 2.0, 0.0), 1.2)
	tw.chain().tween_callback(func() -> void: GameEvents.boss_defeated.emit())


func _animate(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 5.0)
	sprite.self_modulate = sprite.self_modulate.lerp(
		Color(1.6, 0.7, 0.7) if enraged else Color.WHITE, 6.0 * delta)
	_bob += delta * 2.0
	if alive:
		sprite.position.y = sin(_bob) * 5.0
		if _state == "charging" and _state_t < 0.85:
			sprite.scale = sprite.scale.lerp(Vector2(0.92, 1.08), 6.0 * delta)
		else:
			sprite.scale = sprite.scale.lerp(Vector2.ONE, 6.0 * delta)
		var player: Node2D = world.player
		if player != null:
			sprite.flip_h = player.global_position.x < global_position.x
	queue_redraw()


func _draw() -> void:
	if not alive:
		return
	# grounding drop shadow
	draw_set_transform(Vector2(0, radius * 0.95), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius * 1.05, Color(0, 0, 0, 0.34))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# heart-of-the-keep aura
	var aura := Color(1.0, 0.25, 0.3, 0.18) if enraged else Color(0.7, 0.4, 1.0, 0.14)
	draw_circle(Vector2.ZERO, radius + 26.0 + sin(_bob * 2.0) * 6.0, aura)
	draw_arc(Vector2.ZERO, radius + 14.0, 0, TAU, 40, Color(aura.r, aura.g, aura.b, 0.5), 2.5)
	if marked:
		var c := Color(1.0, 0.6, 0.87)
		var top := Vector2(0, -radius - 24)
		draw_arc(top, 9.0, 0, TAU, 16, c, 2.5)
	if burn_t > 0.0:
		draw_circle(Vector2(0, -radius * 0.4), 6.0 + sin(_bob * 6.0) * 2.0, Color(1.0, 0.55, 0.2, 0.7))
	if poison_t > 0.0:
		draw_circle(Vector2(radius * 0.4, -radius * 0.5), 5.0, Color(0.5, 1.0, 0.4, 0.6))
