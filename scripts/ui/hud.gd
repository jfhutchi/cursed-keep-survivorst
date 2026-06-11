class_name Hud
extends CanvasLayer
## In-run HUD: HP/XP bars, level, wave, timer, score, weapon loadout with
## levels, dash cooldown indicator, wave banner and boss health bar.

var world: GameWorld

var _hp_bar: ProgressBar
var _hp_label: Label
var _xp_bar: ProgressBar
var _level_label: Label
var _timer_label: Label
var _score_label: Label
var _wave_label: Label
var _weapon_row: HBoxContainer
var _dash_arc: Control
var _banner: Label
var _banner_t := 0.0
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _weapon_widgets: Dictionary = {}


func _ready() -> void:
	layer = 10

	# --- mood vignette behind all HUD elements (gameplay only; HUD is
	# hidden in menus). Transparent center, dark corners.
	var vignette := TextureRect.new()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	gradient.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.38)])
	var vignette_tex := GradientTexture2D.new()
	vignette_tex.gradient = gradient
	vignette_tex.fill = GradientTexture2D.FILL_RADIAL
	vignette_tex.fill_from = Vector2(0.5, 0.5)
	vignette_tex.fill_to = Vector2(1.02, 0.5)
	vignette_tex.width = 256
	vignette_tex.height = 144
	vignette.texture = vignette_tex
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	# --- XP strip across the top
	_xp_bar = UiTheme.make_bar(UiTheme.SOUL)
	_xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_left = 8
	_xp_bar.offset_right = -8
	_xp_bar.offset_top = 6
	_xp_bar.offset_bottom = 18
	add_child(_xp_bar)

	_level_label = UiTheme.make_label("LV 1", 14, UiTheme.SOUL)
	_level_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_level_label.offset_left = -86
	_level_label.offset_right = -12
	_level_label.offset_top = 22
	add_child(_level_label)

	# --- HP block, top-left
	var hp_box := VBoxContainer.new()
	hp_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hp_box.offset_left = 12
	hp_box.offset_top = 26
	hp_box.add_theme_constant_override("separation", 2)
	add_child(hp_box)
	_hp_bar = UiTheme.make_bar(UiTheme.BLOOD)
	_hp_bar.custom_minimum_size = Vector2(230, 18)
	hp_box.add_child(_hp_bar)
	_hp_label = UiTheme.make_label("100 / 100", 12)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hp_box.add_child(_hp_label)

	# --- dash indicator next to HP
	_dash_arc = Control.new()
	_dash_arc.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_dash_arc.offset_left = 254
	_dash_arc.offset_top = 28
	_dash_arc.custom_minimum_size = Vector2(36, 36)
	_dash_arc.draw.connect(_draw_dash_arc)
	add_child(_dash_arc)

	# --- timer / wave / score, top-right
	var right_box := VBoxContainer.new()
	right_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_box.offset_left = -260
	right_box.offset_right = -12
	right_box.offset_top = 40
	right_box.add_theme_constant_override("separation", 2)
	add_child(right_box)
	_timer_label = UiTheme.make_label("0:00", 26, UiTheme.PARCHMENT)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_box.add_child(_timer_label)
	_wave_label = UiTheme.make_label("Wave 1", 15, UiTheme.GOLD)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_box.add_child(_wave_label)
	_score_label = UiTheme.make_label("Score 0", 15, Color(0.75, 0.72, 0.85))
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_box.add_child(_score_label)

	# --- weapon loadout, bottom-left
	_weapon_row = HBoxContainer.new()
	_weapon_row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_weapon_row.offset_left = 12
	_weapon_row.offset_top = -64
	_weapon_row.offset_bottom = -10
	_weapon_row.add_theme_constant_override("separation", 6)
	add_child(_weapon_row)

	# --- wave banner, centered
	_banner = UiTheme.make_title("", 38)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.offset_top = 110
	_banner.modulate.a = 0.0
	add_child(_banner)

	# --- boss bar, bottom-center
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_box.offset_top = -86
	_boss_box.offset_bottom = -54
	_boss_box.visible = false
	add_child(_boss_box)
	var boss_name := UiTheme.make_label("THE CURSED CASTELLAN — HEART OF THE KEEP", 14, Color(0.85, 0.55, 1.0))
	_boss_box.add_child(boss_name)
	_boss_bar = UiTheme.make_bar(Color(0.7, 0.3, 1.0))
	_boss_bar.custom_minimum_size = Vector2(520, 16)
	_boss_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_boss_box.add_child(_boss_bar)

	GameEvents.wave_started.connect(_on_wave_started)
	GameEvents.weapon_unlocked.connect(func(_id: String) -> void: _refresh_weapons())
	GameEvents.weapon_leveled.connect(func(_id: String, _lv: int) -> void: _refresh_weapons())
	GameEvents.boss_spawned.connect(func(_b: Node2D) -> void: _boss_box.visible = true)
	GameEvents.boss_health_changed.connect(_on_boss_health)
	GameEvents.boss_defeated.connect(func() -> void: _boss_box.visible = false)
	GameEvents.score_changed.connect(func(s: int) -> void: _score_label.text = "Score %d" % s)


func _process(delta: float) -> void:
	if world == null or not is_instance_valid(world) or world.player == null:
		return
	var p: Player = world.player
	_hp_bar.max_value = p.stats["max_health"]
	_hp_bar.value = p.hp
	_hp_label.text = "%d / %d" % [int(maxf(p.hp, 0)), int(p.stats["max_health"])]
	_xp_bar.max_value = p.xp_needed
	_xp_bar.value = p.xp
	_level_label.text = "LV %d" % p.level
	_timer_label.text = _format_time(world.run_time)
	_dash_arc.queue_redraw()
	if _banner_t > 0.0:
		_banner_t -= delta
		_banner.modulate.a = clampf(minf(_banner_t, 1.0), 0.0, 1.0)


func _draw_dash_arc() -> void:
	if world == null or world.player == null:
		return
	var p: Player = world.player
	var center := Vector2(18, 18)
	var ready_in: float = p.dash_ready_in()
	var cooldown: float = p.stats["dash_cooldown"]
	var fraction := 1.0 - clampf(ready_in / maxf(cooldown, 0.01), 0.0, 1.0)
	_dash_arc.draw_circle(center, 16.0, Color(0.05, 0.04, 0.1, 0.7))
	var color := UiTheme.SOUL if fraction >= 1.0 else Color(0.4, 0.45, 0.6)
	_dash_arc.draw_arc(center, 13.0, -PI * 0.5, -PI * 0.5 + TAU * fraction, 24, color, 4.0)
	# little wing glyph
	_dash_arc.draw_line(center + Vector2(-6, 2), center + Vector2(0, -5), color, 2.0)
	_dash_arc.draw_line(center + Vector2(0, -5), center + Vector2(6, 2), color, 2.0)


func _refresh_weapons() -> void:
	if world == null or not is_instance_valid(world):
		return
	for child in _weapon_row.get_children():
		child.queue_free()
	_weapon_widgets.clear()
	var wm: WeaponManager = world.weapon_manager
	for id: String in wm.owned.keys():
		var def: Dictionary = GameData.weapon(id)
		var slot := PanelContainer.new()
		var style := UiTheme.panel_style(UiTheme.PANEL_BG, GameData.weapon_color(id) * Color(1, 1, 1, 0.7), 1, 6)
		style.set_content_margin_all(4)
		slot.add_theme_stylebox_override("panel", style)
		slot.tooltip_text = "%s (Lv %d)\n%s" % [def["name"], wm.owned[id]["level"], def["desc"]]
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		slot.add_child(v)
		var icon := TextureRect.new()
		icon.texture = load(def["icon"])
		icon.custom_minimum_size = Vector2(34, 34)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(icon)
		var lv := UiTheme.make_label(str(wm.owned[id]["level"]), 10, UiTheme.GOLD)
		v.add_child(lv)
		_weapon_row.add_child(slot)


func _on_wave_started(index: int, wave_name: String) -> void:
	_wave_label.text = "Wave %d — %s" % [index, wave_name]
	_banner.text = "WAVE %d\n%s" % [index, wave_name]
	_banner_t = 2.6
	_banner.modulate.a = 1.0


func _on_boss_health(hp: float, max_hp: float) -> void:
	_boss_bar.max_value = max_hp
	_boss_bar.value = hp


static func _format_time(t: float) -> String:
	return "%d:%02d" % [floori(t / 60.0), int(t) % 60]
