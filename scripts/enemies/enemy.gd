class_name Enemy
extends Node2D
## Pooled enemy driven by EnemyData definitions.
## Behaviors: chase | wraith (erratic drift) | ranged (Cult Hexer) |
## charger (Hollow Knight). Elites are bigger, tougher, glow gold.
## Ticked by GameWorld (manager loop), not by per-node _process.

@export var enemy_id := "bone_crawler"

var world: Node2D
var active := false
var alive := false

var def: Dictionary = {}
var hp := 10.0
var max_hp := 10.0
var elite := false
var speed := 100.0
var contact_damage := 5.0
var radius := 14.0
var xp_value := 1
var score_value := 10

# statuses
var burn_dps := 0.0
var burn_t := 0.0
var poison_dps := 0.0
var poison_t := 0.0
var poison_vuln := 0.0
var bleed_dps := 0.0
var bleed_t := 0.0
var slow_factor := 0.0
var slow_t := 0.0
var stun_t := 0.0
var marked := false
var mark_vuln := 0.0
var mark_t := 0.0
var mark_explode := false
var mark_explode_damage := 0.0
var mark_spread := 0.0

var knockback := Vector2.ZERO
var _kb_resist := 0.0
var _contact_cd := 0.0
var _dot_acc := 0.0
var _flash := 0.0
var _phase := 0.0
var _separation := Vector2.ZERO
var _sep_timer := 0.0
var _wraith_seed := 0.0

# ranged (hexer)
var _fire_cd := 0.0
# charger (hollow knight)
var _charge_state := 0 # 0 approach, 1 windup, 2 charging, 3 recover
var _charge_t := 0.0
var _charge_dir := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite


func setup(enemy_def: Dictionary, is_elite: bool, hp_mult: float) -> void:
	def = enemy_def
	enemy_id = def["id"]
	elite = is_elite and not def.get("no_elite", false)
	var elite_mods: Dictionary = EnemyData.ELITE
	var ehp := 1.0
	var espeed := 1.0
	var escale := 1.0
	var edmg := 1.0
	if elite:
		var extra: float = world.enemy_mods.get("elite_hp_mult", 1.0)
		ehp = elite_mods["hp_mult"] * extra
		espeed = elite_mods["speed_mult"]
		escale = elite_mods["scale_mult"]
		edmg = elite_mods["damage_mult"]
	max_hp = def["hp"] * hp_mult * ehp
	hp = max_hp
	speed = def["speed"] * espeed
	contact_damage = def["damage"] * edmg
	radius = def["radius"] * escale
	xp_value = int(ceilf(def["xp"] * (elite_mods["xp_mult"] if elite else 1.0)))
	score_value = int(def["score"] * (elite_mods["score_mult"] if elite else 1.0))
	_kb_resist = clampf((def["hp"] - 50.0) / 300.0, 0.0, 0.85)
	alive = true
	burn_dps = 0.0; burn_t = 0.0; poison_dps = 0.0; poison_t = 0.0; poison_vuln = 0.0
	bleed_dps = 0.0; bleed_t = 0.0; slow_factor = 0.0; slow_t = 0.0; stun_t = 0.0
	marked = false; mark_vuln = 0.0; mark_t = 0.0; mark_explode = false; mark_spread = 0.0
	knockback = Vector2.ZERO
	_contact_cd = randf_range(0.0, 0.4)
	_dot_acc = 0.0
	_flash = 0.0
	_phase = randf() * TAU
	_wraith_seed = randf() * 100.0
	_fire_cd = def.get("fire_cooldown", 2.0) * randf_range(0.6, 1.2)
	_charge_state = 0
	_charge_t = 0.0
	sprite.scale = Vector2.ONE * def.get("scale", 1.0) * escale
	sprite.self_modulate = Color.WHITE
	var alpha: float = def.get("alpha", 1.0)
	modulate = Color(1, 1, 1, alpha)
	queue_redraw()


func _pool_activate() -> void:
	active = true
	visible = true


func _pool_deactivate() -> void:
	active = false
	visible = false


## Called by GameWorld every physics frame.
func tick(delta: float, player: Node2D) -> void:
	if not alive:
		return
	_tick_statuses(delta)
	if not alive: # a DoT may have killed us
		return

	var move := Vector2.ZERO
	if stun_t > 0.0:
		stun_t -= delta
	else:
		move = _behavior_move(delta, player)

	var slow_mult := 1.0 - slow_factor if slow_t > 0.0 else 1.0
	var world_speed_mult: float = world.enemy_mods.get("speed_mult", 1.0)
	velocity_apply(delta, move * speed * slow_mult * world_speed_mult)

	_contact_cd -= delta
	if _contact_cd <= 0.0 and player.alive:
		var rsum := radius + 17.0
		if global_position.distance_squared_to(player.global_position) < rsum * rsum:
			player.take_damage(contact_damage, global_position)
			_contact_cd = 0.9

	_animate(delta)


func velocity_apply(delta: float, vel: Vector2) -> void:
	# separation from neighbors, recomputed at 6-7 Hz
	_sep_timer -= delta
	if _sep_timer <= 0.0:
		_sep_timer = 0.15
		_separation = world.compute_separation(self)
	global_position += (vel + _separation * 40.0 + knockback) * delta
	knockback = knockback.lerp(Vector2.ZERO, 8.0 * delta)
	var half: Vector2 = GameData.ARENA_HALF
	global_position = global_position.clamp(-half + Vector2(20, 20), half - Vector2(20, 20))


func _behavior_move(delta: float, player: Node2D) -> Vector2:
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player / maxf(dist, 0.001)
	match def.get("behavior", "chase"):
		"wraith":
			var wobble := sin(Time.get_ticks_msec() * 0.001 * 2.2 + _wraith_seed) * 0.85
			return dir.rotated(wobble)
		"ranged":
			_fire_cd -= delta
			var preferred: float = def.get("preferred_range", 300.0)
			if _fire_cd <= 0.0 and dist < preferred * 1.7:
				_fire_cd = def.get("fire_cooldown", 2.8)
				_fire_at_player(player)
			if dist > preferred * 1.15:
				return dir
			elif dist < preferred * 0.8:
				return -dir * 0.8
			return dir.orthogonal() * 0.45 * (1.0 if int(_wraith_seed) % 2 == 0 else -1.0)
		"charger":
			match _charge_state:
				0:
					if dist < 330.0:
						_charge_state = 1
						_charge_t = def.get("windup", 0.8)
						_charge_dir = dir
						AudioManager.play(&"knight_charge", -6.0)
						world.spawn_fx({"kind": "warning_line", "pos": global_position, "angle": dir.angle(),
							"length": 380.0, "width": radius * 2.2, "duration": _charge_t})
						return Vector2.ZERO
					return dir
				1:
					_charge_t -= delta
					_charge_dir = (player.global_position - global_position).normalized().lerp(_charge_dir, 0.4)
					if _charge_t <= 0.0:
						_charge_state = 2
						_charge_t = def.get("charge_time", 0.6)
					return Vector2.ZERO
				2:
					_charge_t -= delta
					if _charge_t <= 0.0:
						_charge_state = 3
						_charge_t = def.get("charge_cooldown", 3.5)
						return Vector2.ZERO
					return _charge_dir * (def.get("charge_speed", 430.0) / maxf(speed, 1.0))
				3:
					_charge_t -= delta
					if _charge_t <= 0.0:
						_charge_state = 0
					return dir * 0.5
			return dir
		_:
			return dir


func _fire_at_player(player: Node2D) -> void:
	AudioManager.play(&"hexer_cast", -8.0)
	var dir: Vector2 = (player.global_position - global_position).normalized()
	world.spawn_enemy_projectile({"kind": "orb", "pos": global_position + dir * 18.0, "dir": dir,
		"speed": def.get("proj_speed", 230.0), "damage": def.get("proj_damage", 11.0),
		"color": Color(0.8, 0.55, 1.0), "hostile": true, "max_distance": 700.0})


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
		var dot := 0.0
		if burn_t > 0.0: dot += burn_dps * 0.45
		if poison_t > 0.0: dot += poison_dps * 0.45
		if bleed_t > 0.0: dot += bleed_dps * 0.45
		_dot_acc -= 0.45
		if dot > 0.0:
			take_damage(dot, Vector2.ZERO, "dot", false, false)


func apply_burn(dps: float, dur: float) -> void:
	burn_dps = maxf(burn_dps, dps)
	burn_t = maxf(burn_t, dur)


func apply_poison(dps: float, dur: float) -> void:
	poison_dps = minf(poison_dps + dps * 0.5, dps * 3.0) if poison_t > 0.0 else dps
	poison_t = maxf(poison_t, dur)


func apply_bleed(dps: float, dur: float) -> void:
	bleed_dps = maxf(bleed_dps, dps)
	bleed_t = maxf(bleed_t, dur)


func apply_slow(factor: float, dur: float) -> void:
	slow_factor = clampf(maxf(slow_factor, factor), 0.0, 0.8)
	slow_t = maxf(slow_t, dur)


func apply_stun(dur: float) -> void:
	stun_t = maxf(stun_t, dur)


func apply_mark(vuln: float, dur: float, explode: bool, explode_damage: float, spread: float) -> void:
	marked = true
	mark_vuln = maxf(mark_vuln, vuln)
	mark_t = maxf(mark_t, dur)
	mark_explode = mark_explode or explode
	mark_explode_damage = maxf(mark_explode_damage, explode_damage)
	mark_spread = maxf(mark_spread, spread)
	world.spawn_fx({"kind": "mark_pop", "pos": global_position + Vector2(0, -radius - 12), "color": Color(1.0, 0.6, 0.87)})


## Returns the damage actually dealt.
func take_damage(amount: float, kb: Vector2, source: String, is_crit: bool, flash := true) -> float:
	if not alive:
		return 0.0
	var final := amount
	if marked:
		final *= 1.0 + mark_vuln
	if poison_t > 0.0 and poison_vuln > 0.0:
		final *= 1.0 + poison_vuln
	hp -= final
	if flash:
		_flash = 1.0
		sprite.self_modulate = Color(4.0, 4.0, 4.0)
		AudioManager.play(&"enemy_hit", -10.0, 0.15)
	knockback += kb * (1.0 - _kb_resist) * world.player.stats["knockback_mult"]
	world.show_damage_number(global_position + Vector2(0, -radius), final, is_crit)
	if hp <= 0.0:
		_die(source)
	return final


func _die(source: String) -> void:
	alive = false
	if marked and mark_explode:
		world.area_damage(global_position, 90.0, mark_explode_damage, "death_mark", Color(1.0, 0.6, 0.87))
	if marked and mark_spread > 0.0 and randf() < mark_spread:
		var near: Array = world.query_enemies(global_position, 160.0)
		for other in near:
			if other != self and other.alive and not other.marked:
				other.apply_mark(mark_vuln, 4.0, mark_explode, mark_explode_damage, 0.0)
				break
	world.on_enemy_died(self, source)


func _animate(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 5.0)
	sprite.self_modulate = sprite.self_modulate.lerp(Color.WHITE, 10.0 * delta)
	_phase += delta * (8.0 if def.get("behavior", "chase") == "chase" else 4.0)
	match def.get("behavior", "chase"):
		"wraith":
			sprite.position.y = sin(_phase * 0.6) * 4.0
			modulate.a = def.get("alpha", 0.72) + sin(_phase * 0.9) * 0.12
		"charger":
			if _charge_state == 1:
				sprite.scale = sprite.scale.lerp(Vector2.ONE * def.get("scale", 1.0) * (1.35 if elite else 1.0) * Vector2(0.88, 1.1), 6.0 * delta)
				sprite.self_modulate = sprite.self_modulate.lerp(Color(2.0, 0.8, 0.8), 4.0 * delta)
			else:
				sprite.scale = sprite.scale.lerp(Vector2.ONE * def.get("scale", 1.0) * (1.35 if elite else 1.0), 6.0 * delta)
		_:
			sprite.position.y = -absf(sin(_phase)) * 2.5
			sprite.rotation = sin(_phase * 0.5) * 0.06
	if knockback.length_squared() > 1.0 or speed > 1.0:
		var moving_left: bool = world.player.global_position.x < global_position.x
		sprite.flip_h = moving_left
	queue_redraw()


func _draw() -> void:
	if not active or not alive:
		return
	# grounding drop shadow (drawn beneath the sprite child)
	draw_set_transform(Vector2(0, radius * 0.8), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, radius * 0.95, Color(0, 0, 0, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if elite:
		draw_arc(Vector2(0, radius * 0.4), radius + 7.0, 0, TAU, 24, Color(1.0, 0.85, 0.4, 0.55), 2.5)
	if marked:
		var c := Color(1.0, 0.6, 0.87)
		var top := Vector2(0, -radius - 16)
		draw_arc(top, 7.0, 0, TAU, 14, c, 2.0)
		draw_line(top + Vector2(-3, -1), top + Vector2(0, 3), c, 2.0)
		draw_line(top + Vector2(0, 3), top + Vector2(4, -3), c, 2.0)
	if burn_t > 0.0:
		draw_circle(Vector2(0, -radius * 0.5), 4.0 + sin(_phase * 3.0) * 1.5, Color(1.0, 0.55, 0.2, 0.7))
	if poison_t > 0.0:
		draw_circle(Vector2(radius * 0.4, -radius * 0.6), 3.0, Color(0.5, 1.0, 0.4, 0.6))
	if slow_t > 0.0:
		draw_arc(Vector2.ZERO, radius + 3.0, 0, TAU, 18, Color(0.5, 0.7, 1.0, 0.35), 1.5)
	if stun_t > 0.0:
		for i in 3:
			var a := _phase * 2.0 + TAU * i / 3.0
			draw_circle(Vector2(0, -radius - 8) + Vector2.from_angle(a) * 8.0, 2.0, Color(1.0, 1.0, 0.6, 0.8))
