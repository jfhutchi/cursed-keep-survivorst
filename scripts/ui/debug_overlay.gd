class_name DebugOverlay
extends CanvasLayer
## F3 debug overlay: FPS, state, entity counts, player and weapon info.

var main: Node # Main
var _label: Label
var _accum := 0.0


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var panel := PanelContainer.new()
	var style := UiTheme.panel_style(Color(0, 0, 0, 0.72), Color(0.3, 0.3, 0.4), 1, 4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 8
	panel.offset_top = 64
	add_child(panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	panel.add_child(_label)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		visible = not visible


func _process(delta: float) -> void:
	if not visible:
		return
	_accum -= delta
	if _accum > 0.0:
		return
	_accum = 0.2
	var lines: Array[String] = []
	lines.append("Cursed Keep Survivors v%s" % str(ProjectSettings.get_setting("application/config/version", "?")))
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	lines.append("State: %s" % main.state_name())
	var world: GameWorld = main.world
	if world != null:
		var counts: Dictionary = world.debug_counts()
		lines.append("Wave: %d / %d" % [int(counts["wave"]), WaveData.wave_count()])
		lines.append("Enemies: %d   Projectiles: %d" % [int(counts["enemies"]), int(counts["projectiles"])])
		lines.append("XP orbs: %d   Zones: %d   FX: %d" % [int(counts["orbs"]), int(counts["zones"]), int(counts["fx"])])
		var p: Player = world.player
		if p != null:
			lines.append("Player: LV %d   HP %.0f/%.0f" % [p.level, p.hp, p.stats["max_health"]])
		var wm: WeaponManager = world.weapon_manager
		var weapon_bits: Array[String] = []
		for id: String in wm.owned.keys():
			weapon_bits.append("%s:%d" % [id, int(wm.owned[id]["level"])])
		lines.append("Weapons (%d/%d): %s" % [wm.owned_count(), wm.weapon_cap, ", ".join(weapon_bits)])
		var wave: Dictionary = world.wave_director.current_wave()
		lines.append("Spawn interval: %.2f-%.2f  max alive: %d" % [
			float(wave["interval"][0]), float(wave["interval"][1]), int(wave["max_alive"])])
	_label.text = "\n".join(lines)
