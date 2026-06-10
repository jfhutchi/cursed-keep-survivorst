class_name RewardLoopPlayer
extends CharacterBody2D

signal died
signal health_changed(current: int, maximum: int)

const Rules := preload("res://scripts/reward_loop_rules.gd")

var move_speed := Rules.PLAYER_SPEED
var max_health := Rules.PLAYER_HEALTH
var health := Rules.PLAYER_HEALTH
var attack_interval := Rules.ATTACK_INTERVAL
var attack_range := Rules.ATTACK_RANGE
var attack_damage := 1
var reward_bonus := 0
var chain_attack_enabled := false

var arena_bounds := Rect2(Vector2(-900.0, -500.0), Vector2(1800.0, 1000.0))
var _hurt_cooldown := 0.0
var _body: Polygon2D


func _ready() -> void:
	_build_placeholder_body()
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	_hurt_cooldown = max(_hurt_cooldown - delta, 0.0)
	var input_vector := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y += 1.0

	velocity = input_vector.normalized() * move_speed
	move_and_slide()
	global_position.x = clampf(global_position.x, arena_bounds.position.x, arena_bounds.end.x)
	global_position.y = clampf(global_position.y, arena_bounds.position.y, arena_bounds.end.y)


func take_damage(amount: int) -> void:
	if _hurt_cooldown > 0.0 or health <= 0:
		return
	health = max(health - amount, 0)
	_hurt_cooldown = 0.75
	health_changed.emit(health, max_health)
	_flash(Color(1.0, 0.2, 0.16))
	if health == 0:
		died.emit()


func apply_upgrade(upgrade: Dictionary) -> String:
	var id := String(upgrade.get("id", ""))
	var effect_type := String(upgrade.get("effect_type", ""))
	match effect_type:
		"attack_interval":
			var amount := float(upgrade.get("amount", 0.0))
			attack_interval = max(0.25, attack_interval + amount)
		"attack_range":
			var amount := float(upgrade.get("amount", 0.0))
			attack_range += amount
		"reward_bonus":
			var amount := int(upgrade.get("amount", 0))
			reward_bonus += amount
		"move_speed":
			var amount := float(upgrade.get("amount", 0.0))
			move_speed += amount
		"max_health":
			var amount := int(upgrade.get("amount", 0))
			max_health += amount
			health = min(health + 1, max_health)
			health_changed.emit(health, max_health)
		"chain_attack":
			chain_attack_enabled = true
	_flash(Color(0.25, 0.95, 0.55))
	return id


func apply_chest_reward(reward: Dictionary) -> void:
	var effect_type := String(reward.get("effect_type", ""))
	match effect_type:
		"reward_multiplier":
			reward_bonus += int(reward.get("amount", 0))
		"attack_range":
			attack_range += float(reward.get("amount", 0.0))
		"cosmetic_tint":
			set_cosmetic_tint(Color(0.15, 0.9, 0.45))
	_flash(Color(1.0, 0.82, 0.24))


func reward_value(base_value: int) -> int:
	return base_value + reward_bonus


func set_cosmetic_tint(color: Color) -> void:
	if _body != null:
		_body.color = color


func _build_placeholder_body() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	add_child(shape)

	_body = Polygon2D.new()
	_body.name = "UglyPlayerTriangle"
	_body.polygon = PackedVector2Array([
		Vector2(0.0, -24.0),
		Vector2(20.0, 18.0),
		Vector2(-20.0, 18.0),
	])
	_body.color = Color(0.22, 0.86, 0.58)
	add_child(_body)

	var ring := Line2D.new()
	ring.name = "HitRing"
	ring.width = 3.0
	ring.default_color = Color(0.93, 0.95, 0.62)
	ring.closed = true
	var points := PackedVector2Array()
	for i in range(18):
		var angle := TAU * float(i) / 18.0
		points.append(Vector2(cos(angle), sin(angle)) * 24.0)
	ring.points = points
	add_child(ring)


func _flash(color: Color) -> void:
	if _body == null:
		return
	var original := _body.color
	_body.color = color
	var tween := create_tween()
	tween.tween_property(_body, "color", original, 0.18)
