class_name CameraRig
extends Camera2D
## Smoothed follow camera with trauma-based screenshake.

var target: Node2D
var _trauma := 0.0
var _noise_t := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	var half: Vector2 = GameData.ARENA_HALF
	limit_left = int(-half.x - 220)
	limit_right = int(half.x + 220)
	limit_top = int(-half.y - 220)
	limit_bottom = int(half.y + 220)
	GameEvents.screen_shake_requested.connect(add_shake)
	make_current()


func add_shake(strength: float) -> void:
	_trauma = clampf(_trauma + strength / 14.0, 0.0, 1.0)


func _process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		global_position = target.global_position
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * 1.8)
		_noise_t += delta * 40.0
		var amount := _trauma * _trauma * 14.0
		offset = Vector2(
			sin(_noise_t * 1.1) * amount + sin(_noise_t * 3.7) * amount * 0.4,
			cos(_noise_t * 0.9) * amount + cos(_noise_t * 4.1) * amount * 0.4)
	else:
		offset = Vector2.ZERO
