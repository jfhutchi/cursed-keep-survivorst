class_name RewardFloatingText
extends Label


func setup(display_text: String, world_position: Vector2, text_color: Color) -> void:
	text = display_text
	position = world_position
	modulate = text_color
	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)


func _ready() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 42.0, 0.65)
	tween.tween_property(self, "modulate:a", 0.0, 0.65)
	tween.finished.connect(queue_free)
