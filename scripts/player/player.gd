class_name Player
extends CharacterBody2D
## The Wardkeeper. Smooth 8-direction movement, dash with i-frames,
## stat sheet, XP/leveling, damage/death/revive, procedural animation.

signal dash_state_changed(ready_in: float, cooldown: float)

const BASE_STATS := {
	"max_health": 100.0,
	"move_speed": 230.0,
	"dash_speed": 760.0,
	"dash_duration": 0.18,
	"dash_cooldown": 2.2,
	"armor": 0.0,                  # % damage reduction (can go negative)
	"pickup_radius": 130.0,
	"xp_mult": 1.0,
	"damage_mult": 1.0,
	"cooldown_mult": 1.0,
	"projectile_speed_mult": 1.0,
	"area_mult": 1.0,
	"duration_mult": 1.0,
	"crit_chance": 0.05,
	"crit_mult": 1.5,
	"luck": 1.0,
	"score_mult": 1.0,
	"knockback_mult": 1.0,
	"projectile_bonus": 0.0,
	"regen": 0.0,
}

var stats: Dictionary = BASE_STATS.duplicate()
var hp: float = 100.0
var level := 1
var xp := 0.0
var xp_needed := 14.0
var revive_charges := 0
var dr_extra := 0.0            # extra damage reduction granted by Iron Maiden
var facing := Vector2.RIGHT
var alive := true

var _dashing := false
var _dash_t := 0.0
var _dash_cd := 0.0
var _dash_dir := Vector2.RIGHT
var _hurt_invuln := 0.0
var _regen_acc := 0.0
var _run_phase := 0.0
var _ghost_timer := 0.0

var world: Node2D # GameWorld, set by world on spawn
var _touch: Node # TouchControls overlay, if a touchscreen exists

@onready var sprite: Sprite2D = $Sprite
@onready var glow: Sprite2D = $Glow


func _ready() -> void:
	hp = stats["max_health"]
	xp_needed = GameData.xp_to_next(level)
	_touch = get_tree().get_first_node_in_group("touch_controls")
	queue_redraw()


func _draw() -> void:
	# grounding drop shadow under the Wardkeeper (drawn beneath child sprites)
	draw_set_transform(Vector2(0, 12), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 15.0, Color(0, 0, 0, 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir == Vector2.ZERO and _touch != null:
		input_dir = _touch.move_vector

	_dash_cd = maxf(0.0, _dash_cd - delta)
	dash_state_changed.emit(_dash_cd, stats["dash_cooldown"])

	if _dashing:
		_dash_t -= delta
		velocity = _dash_dir * stats["dash_speed"]
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.035
			_spawn_dash_ghost()
		if _dash_t <= 0.0:
			_dashing = false
	else:
		velocity = input_dir * stats["move_speed"]
		if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
			_start_dash(input_dir)

	move_and_slide()

	# Stay inside the arena.
	var half: Vector2 = GameData.ARENA_HALF
	position = position.clamp(-half + Vector2(24, 24), half - Vector2(24, 24))

	if velocity.length_squared() > 4.0:
		facing = velocity.normalized()

	_hurt_invuln = maxf(0.0, _hurt_invuln - delta)
	_apply_regen(delta)
	_animate(delta)


func _start_dash(input_dir: Vector2) -> void:
	_dashing = true
	_dash_t = stats["dash_duration"]
	_dash_cd = stats["dash_cooldown"]
	_dash_dir = input_dir.normalized() if input_dir.length_squared() > 0.01 else facing
	AudioManager.play(&"dash")
	GameEvents.player_dashed.emit()


func _spawn_dash_ghost() -> void:
	if world != null and world.has_method("spawn_fx"):
		world.spawn_fx({"kind": "ghost", "pos": global_position, "color": Color(0.55, 0.75, 1.0, 0.5),
			"texture": sprite.texture, "flip": sprite.flip_h, "duration": 0.3})


func _apply_regen(delta: float) -> void:
	var regen: float = stats["regen"]
	if regen > 0.0 and hp < stats["max_health"]:
		_regen_acc += regen * delta
		if _regen_acc >= 1.0:
			var amount := floorf(_regen_acc)
			_regen_acc -= amount
			heal(amount, false)


## Procedural animation: idle breathing, run bobbing/tilt, dash stretch.
func _animate(delta: float) -> void:
	var moving := velocity.length_squared() > 4.0
	if moving:
		_run_phase += delta * 11.0
		sprite.position.y = -absf(sin(_run_phase)) * 5.0
		sprite.rotation = signf(velocity.x) * 0.07 if absf(velocity.x) > 1.0 else 0.0
		sprite.scale = sprite.scale.lerp(Vector2(1.04, 0.96) if _dashing else Vector2.ONE, 12.0 * delta)
	else:
		_run_phase += delta * 2.2
		sprite.position.y = sin(_run_phase) * 1.6
		sprite.rotation = lerpf(sprite.rotation, 0.0, 10.0 * delta)
		sprite.scale = sprite.scale.lerp(Vector2(1.0 + sin(_run_phase) * 0.02, 1.0 - sin(_run_phase) * 0.02), 6.0 * delta)
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	if _dashing:
		sprite.scale = Vector2(1.25, 0.8)
	# hurt flash decay
	sprite.modulate = sprite.modulate.lerp(Color.WHITE, 8.0 * delta)
	glow.modulate.a = 0.35 + sin(_run_phase * 0.7) * 0.08
	if _hurt_invuln > 0.0 and not _dashing:
		sprite.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.04)
	else:
		sprite.modulate.a = 1.0


func is_invulnerable() -> bool:
	return _dashing or _hurt_invuln > 0.0


func dash_ready_in() -> float:
	return _dash_cd


func take_damage(amount: float, _source_pos: Vector2 = Vector2.ZERO) -> void:
	if not alive or is_invulnerable():
		return
	var reduction := clampf(stats["armor"], -60.0, 60.0) / 100.0 + dr_extra
	var final := amount * (1.0 - clampf(reduction, -0.6, 0.85))
	if final <= 0.0:
		return
	hp -= final
	_hurt_invuln = 0.45
	sprite.modulate = Color(3.0, 0.6, 0.6)
	AudioManager.play(&"player_hurt")
	GameEvents.player_hurt.emit(final, hp, stats["max_health"])
	GameEvents.screen_shake_requested.emit(clampf(final * 0.35, 2.0, 9.0))
	if hp <= 0.0:
		if revive_charges > 0:
			_revive()
		else:
			_die()


func _revive() -> void:
	revive_charges -= 1
	stats["max_health"] = maxf(20.0, stats["max_health"] - 15.0)
	hp = stats["max_health"] * 0.4
	_hurt_invuln = 1.6
	AudioManager.play(&"level_up")
	GameEvents.player_healed.emit(hp)
	GameEvents.player_stats_changed.emit()
	if world != null:
		world.spawn_fx({"kind": "levelup", "pos": global_position, "color": Color(1.0, 0.5, 0.6)})


func _die() -> void:
	alive = false
	hp = 0.0
	AudioManager.play(&"player_death")
	# Collapse animation: tilt, shrink, fade.
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "rotation", 1.4, 0.7).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, "scale", Vector2(0.7, 0.4), 0.7)
	tw.tween_property(sprite, "modulate", Color(0.4, 0.3, 0.5, 0.0), 0.8)
	tw.tween_property(glow, "modulate:a", 0.0, 0.5)
	if world != null:
		world.spawn_fx({"kind": "burst", "pos": global_position, "color": Color(0.6, 0.7, 1.0), "size": 2.0})
	GameEvents.player_died.emit()


func heal(amount: float, sound := true) -> void:
	if not alive:
		return
	hp = minf(stats["max_health"], hp + amount)
	if sound:
		AudioManager.play(&"heal")
	GameEvents.player_healed.emit(amount)


func gain_xp(amount: float) -> void:
	if not alive:
		return
	xp += amount * stats["xp_mult"]
	GameEvents.xp_gained.emit(amount, xp, xp_needed)
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = GameData.xp_to_next(level)
		AudioManager.play(&"level_up")
		if world != null:
			world.spawn_fx({"kind": "levelup", "pos": global_position, "color": Color(0.7, 0.9, 1.0)})
		GameEvents.level_up.emit(level)


## Applies a stat block from an upgrade: {stat: {"add": x} or {"mult": x}}.
func apply_stat_mods(mods: Dictionary) -> void:
	for key: String in mods.keys():
		var op: Dictionary = mods[key]
		if key == "heal":
			heal(float(op.get("add", 0.0)))
			continue
		if not stats.has(key):
			push_warning("Player: unknown stat '%s'" % key)
			continue
		var before: float = stats[key]
		var value := before
		if op.has("add"):
			value += float(op["add"])
		if op.has("mult"):
			value *= float(op["mult"])
		stats[key] = value
		if key == "max_health":
			stats[key] = maxf(20.0, value)
			if value > before:
				hp += value - before # raising max HP also grants the difference
			hp = clampf(hp, 1.0, stats[key])
	GameEvents.player_stats_changed.emit()
