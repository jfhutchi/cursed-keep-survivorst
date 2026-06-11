class_name MainMenu
extends CanvasLayer
## Title screen: emblem, start, controls, high score, credits.

signal start_pressed

var _controls_panel: PanelContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bg := TextureRect.new()
	bg.texture = load("res://assets/generated/ui/menu_bg.svg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 10)
	add_child(center)

	var emblem := TextureRect.new()
	emblem.texture = load("res://assets/generated/ui/emblem.svg")
	emblem.custom_minimum_size = Vector2(140, 140)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(emblem)

	center.add_child(UiTheme.make_title("CURSED KEEP", 58))
	center.add_child(UiTheme.make_title("SURVIVORS", 34, UiTheme.PARCHMENT))
	var tagline := UiTheme.make_label("The keep is alive. Outlast it.", 15, Color(0.6, 0.55, 0.7))
	center.add_child(tagline)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	center.add_child(spacer)

	var start := UiTheme.make_button("BEGIN THE VIGIL", 22)
	start.pressed.connect(func() -> void: start_pressed.emit())
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(start)
	start.call_deferred("grab_focus")

	var controls := UiTheme.make_button("CONTROLS", 18)
	controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls.pressed.connect(_toggle_controls)
	center.add_child(controls)

	if not OS.has_feature("web"):
		var quit := UiTheme.make_button("ABANDON (QUIT)", 18)
		quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		quit.pressed.connect(func() -> void: get_tree().quit())
		center.add_child(quit)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	center.add_child(spacer2)

	var save: Dictionary = SaveSystem.data
	var record_text := "High Score: %d    Best Wave: %d    Runs: %d" % [
		int(save["high_score"]), int(save["best_wave"]), int(save["total_runs"])]
	if float(save["fastest_victory_time"]) > 0.0:
		record_text += "    Fastest Victory: %s" % _format_time(float(save["fastest_victory_time"]))
	center.add_child(UiTheme.make_label(record_text, 14, UiTheme.GOLD_DIM))

	var credits := UiTheme.make_label(
		"All art, animation and audio are original and generated in-project. No external assets.",
		12, Color(0.45, 0.42, 0.55))
	credits.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	credits.offset_top = -30.0
	credits.offset_bottom = -10.0
	add_child(credits)

	_build_controls_panel()


func _build_controls_panel() -> void:
	_controls_panel = PanelContainer.new()
	_controls_panel.add_theme_stylebox_override("panel", UiTheme.panel_style())
	_controls_panel.set_anchors_preset(Control.PRESET_CENTER)
	_controls_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_controls_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_controls_panel.visible = false
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_controls_panel.add_child(v)
	v.add_child(UiTheme.make_title("CONTROLS", 28))
	for line in [
		"WASD / Arrow Keys — move",
		"SPACE — dash (brief invulnerability)",
		"Weapons fire on their own. Position, dodge, collect.",
		"1 / 2 / 3 or mouse — choose level-up upgrades",
		"ESC — pause        F3 — debug overlay",
	]:
		v.add_child(UiTheme.make_label(line, 16))
	var close := UiTheme.make_button("CLOSE", 16)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void: _controls_panel.visible = false)
	v.add_child(close)
	add_child(_controls_panel)


func _toggle_controls() -> void:
	_controls_panel.visible = not _controls_panel.visible


func refresh_records() -> void:
	# rebuild is cheap: just re-enter the scene tree state
	for child in get_children():
		child.queue_free()
	_ready.call_deferred()


static func _format_time(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]
