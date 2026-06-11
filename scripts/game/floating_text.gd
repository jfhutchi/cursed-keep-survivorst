class_name FloatingText
extends Node2D
## Pooled floating combat text (damage numbers, healing, pickups).

var world: Node2D
var active := false

var _t := 0.0
var _duration := 0.7
var _vel := Vector2(0, -55)
var _label: Label


func _ready() -> void:
	if _label == null:
		_make_label()


func _make_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-40, -14)
	_label.size = Vector2(80, 20)
	add_child(_label)


func setup(pos: Vector2, text: String, color: Color, font_size := 13) -> void:
	if _label == null:
		_make_label()
	global_position = pos + Vector2(randf_range(-8, 8), -10)
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("outline_size", 3)
	_t = 0.0
	_vel = Vector2(randf_range(-12, 12), -55)
	scale = Vector2.ONE
	modulate.a = 1.0


func _pool_activate() -> void:
	active = true
	visible = true
	set_process(true)


func _pool_deactivate() -> void:
	active = false
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	if not active:
		return
	_t += delta
	global_position += _vel * delta
	_vel.y += 40.0 * delta
	modulate.a = 1.0 - pow(_t / _duration, 2.0)
	if _t >= _duration:
		world.release_text(self)
