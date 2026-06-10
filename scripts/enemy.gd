class_name RewardLoopEnemy
extends CharacterBody2D

signal defeated(enemy, reward_value: int, score_value: int)

const Rules := preload("res://scripts/reward_loop_rules.gd")

var target: Node2D
var enemy_kind := "basic"
var max_health := 2
var health := 2
var move_speed := Rules.BASIC_ENEMY_SPEED
var reward_value := Rules.BASE_REWARD_VALUE
var score_value := 10
var contact_damage := 1

var _is_defeated := false
var _body: Polygon2D


func _ready() -> void:
	_build_placeholder_body()


func setup(kind: String, elapsed_seconds: float) -> void:
	enemy_kind = kind
	var time_bonus: int = int(floor(elapsed_seconds / 45.0))
	if enemy_kind == "elite":
		max_health = 6 + time_bonus * 2
		move_speed = Rules.ELITE_ENEMY_SPEED + float(time_bonus * 4)
		reward_value = Rules.BASE_REWARD_VALUE + 3 + time_bonus
		score_value = 35 + time_bonus * 8
		scale = Vector2(1.25, 1.25)
	else:
		max_health = 2 + time_bonus
		move_speed = Rules.BASIC_ENEMY_SPEED + float(time_bonus * 5)
		reward_value = Rules.BASE_REWARD_VALUE + time_bonus
		score_value = 10 + time_bonus * 3
		scale = Vector2.ONE
	health = max_health


func _physics_process(_delta: float) -> void:
	if target == null or _is_defeated:
		velocity = Vector2.ZERO
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	move_and_slide()


func take_damage(amount: int) -> void:
	if _is_defeated:
		return
	health -= amount
	_flash()
	if health <= 0:
		_is_defeated = true
		defeated.emit(self, reward_value, score_value)


func _build_placeholder_body() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 17.0
	shape.shape = circle
	add_child(shape)

	_body = Polygon2D.new()
	_body.name = "EnemyBlock"
	if enemy_kind == "elite":
		_body.polygon = PackedVector2Array([
			Vector2(0.0, -25.0),
			Vector2(24.0, 0.0),
			Vector2(0.0, 25.0),
			Vector2(-24.0, 0.0),
		])
		_body.color = Color(0.95, 0.46, 0.16)
	else:
		_body.polygon = PackedVector2Array([
			Vector2(-17.0, -17.0),
			Vector2(17.0, -17.0),
			Vector2(17.0, 17.0),
			Vector2(-17.0, 17.0),
		])
		_body.color = Color(0.86, 0.16, 0.20)
	add_child(_body)


func _flash() -> void:
	if _body == null:
		return
	var original := _body.color
	_body.color = Color(1.0, 0.96, 0.72)
	var tween := create_tween()
	tween.tween_property(_body, "color", original, 0.12)
