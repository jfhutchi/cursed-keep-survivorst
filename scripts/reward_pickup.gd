class_name RewardPickup
extends Area2D

signal collected(pickup: RewardPickup, value: int)

var value := 1
var target: Node2D
var magnet_distance := 170.0
var collect_distance := 24.0
var drift_speed := 80.0
var magnet_speed := 340.0

var _visual: Polygon2D
var _collected := false


func _ready() -> void:
	_build_placeholder_body()


func setup(drop_value: int, target_node: Node2D) -> void:
	value = drop_value
	target = target_node


func _physics_process(delta: float) -> void:
	if target == null or _collected:
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= collect_distance:
		_collected = true
		collected.emit(self, value)
		return
	if distance <= magnet_distance:
		var direction := global_position.direction_to(target.global_position)
		global_position += direction * magnet_speed * delta
	else:
		global_position.y += sin(Time.get_ticks_msec() / 120.0 + global_position.x) * drift_speed * 0.03 * delta
	rotation += delta * 5.0


func _build_placeholder_body() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)

	_visual = Polygon2D.new()
	_visual.name = "RewardDiamond"
	_visual.polygon = PackedVector2Array([
		Vector2(0.0, -12.0),
		Vector2(12.0, 0.0),
		Vector2(0.0, 12.0),
		Vector2(-12.0, 0.0),
	])
	_visual.color = Color(1.0, 0.76, 0.2)
	add_child(_visual)
