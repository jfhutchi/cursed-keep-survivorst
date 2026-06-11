class_name ResultScreen
extends CanvasLayer
## Shared implementation for the Game Over and Victory screens.
## Configured by `victory_mode` (set in the scene or by Main).

signal restart_pressed
signal menu_pressed

@export var victory_mode := false

var _stats_box: VBoxContainer
var _records_label: Label
var _title: Label
var _subtitle: Label
var _restart_btn: Button


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var dim := UiTheme.dim_layer()
	dim.color = Color(0.02, 0.05, 0.03, 0.78) if victory_mode else Color(0.06, 0.01, 0.02, 0.78)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		UiTheme.panel_style(UiTheme.PANEL_BG, UiTheme.GOLD if victory_mode else UiTheme.BLOOD, 2, 14))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	_title = UiTheme.make_title("THE CURSE IS BROKEN" if victory_mode else "THE KEEP CLAIMS YOU",
		36, UiTheme.GOLD if victory_mode else UiTheme.BLOOD)
	v.add_child(_title)

	_subtitle = UiTheme.make_label(
		"The Castellan falls. Dawn touches the walls for the first time in a century."
		if victory_mode else "Another soul for the walls. The keep remembers.",
		14, Color(0.65, 0.62, 0.72))
	v.add_child(_subtitle)

	_stats_box = VBoxContainer.new()
	_stats_box.add_theme_constant_override("separation", 3)
	v.add_child(_stats_box)

	_records_label = UiTheme.make_label("", 15, UiTheme.GOLD)
	v.add_child(_records_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	v.add_child(spacer)

	var restart := UiTheme.make_button("RESTART RUN", 20)
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	v.add_child(restart)
	_restart_btn = restart

	var menu := UiTheme.make_button("MAIN MENU", 18)
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	v.add_child(menu)


func show_results(stats: Dictionary, records: Dictionary) -> void:
	for child in _stats_box.get_children():
		child.queue_free()
	var lines := [
		"Score: %d" % int(stats.get("score", 0)),
		"Time Survived: %s" % _format_time(float(stats.get("time", 0.0))),
		"Waves Reached: %d / %d" % [int(stats.get("wave", 1)), WaveData.wave_count()],
		"Level Reached: %d" % int(stats.get("level", 1)),
		"Enemies Destroyed: %d" % int(stats.get("kills", 0)),
	]
	if victory_mode:
		lines.insert(0, "BOSS DEFEATED — The Cursed Castellan")
	for line: String in lines:
		_stats_box.add_child(UiTheme.make_label(line, 17))
	var record_bits: Array[String] = []
	if bool(records.get("new_high_score", false)):
		record_bits.append("NEW HIGH SCORE!")
	if bool(records.get("new_best_wave", false)):
		record_bits.append("NEW BEST WAVE!")
	if bool(records.get("new_fastest_victory", false)):
		record_bits.append("FASTEST VICTORY!")
	_records_label.text = "  ".join(record_bits)
	visible = true
	_restart_btn.call_deferred("grab_focus")


static func _format_time(t: float) -> String:
	return "%d:%02d" % [floori(t / 60.0), int(t) % 60]
