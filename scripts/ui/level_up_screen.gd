class_name LevelUpScreen
extends CanvasLayer
## Level-up choice: three upgrade cards, mouse or 1/2/3 selection.

signal chosen(upgrade: Dictionary)

var _cards_box: HBoxContainer
var _choices: Array = []
var _card_panels: Array = []


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	add_child(UiTheme.dim_layer())

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 18)
	add_child(center)

	center.add_child(UiTheme.make_title("THE KEEP OFFERS", 36))
	center.add_child(UiTheme.make_label("Choose with mouse or press 1 / 2 / 3", 14, Color(0.6, 0.56, 0.7)))

	_cards_box = HBoxContainer.new()
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_box.add_theme_constant_override("separation", 22)
	_cards_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(_cards_box)


func show_choices(choices: Array) -> void:
	_choices = choices
	_card_panels.clear()
	for child in _cards_box.get_children():
		child.queue_free()
	for i in choices.size():
		var card := _build_card(choices[i], i)
		_cards_box.add_child(card)
		_card_panels.append(card)
	visible = true
	if not _card_panels.is_empty():
		_card_panels[0].call_deferred("grab_focus")


func close() -> void:
	visible = false


func _build_card(upgrade: Dictionary, index: int) -> PanelContainer:
	var rarity: String = upgrade.get("rarity", "common")
	var rarity_color: Color = GameData.rarity_color(rarity)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 300)
	var style := UiTheme.panel_style(UiTheme.PANEL_BG, rarity_color, 2, 12)
	card.add_theme_stylebox_override("panel", style)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.focus_mode = Control.FOCUS_ALL

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)

	var key_hint := UiTheme.make_label("[ %d ]" % (index + 1), 13, rarity_color)
	v.add_child(key_hint)

	var icon := TextureRect.new()
	var icon_path: String = upgrade.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)

	v.add_child(UiTheme.make_label(str(upgrade["name"]), 19, UiTheme.PARCHMENT))

	var kind_text := str(upgrade.get("kind", "stat")).to_upper()
	v.add_child(UiTheme.make_label("%s · %s" % [rarity.to_upper(), kind_text], 11, rarity_color))

	var desc := UiTheme.make_label(str(upgrade["desc"]), 14, Color(0.78, 0.75, 0.85))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(200, 0)
	v.add_child(desc)

	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_pick(index))
	card.mouse_entered.connect(func() -> void:
		card.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL_BG_LIGHT, rarity_color, 3, 12))
		AudioManager.play(&"ui_hover", -8.0))
	card.mouse_exited.connect(func() -> void:
		card.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL_BG, rarity_color, 2, 12)))
	# keyboard / controller focus mirrors the mouse-hover highlight
	card.focus_entered.connect(func() -> void:
		card.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL_BG_LIGHT, rarity_color, 3, 12))
		AudioManager.play(&"ui_hover", -8.0))
	card.focus_exited.connect(func() -> void:
		card.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL_BG, rarity_color, 2, 12)))
	return card


func _pick(index: int) -> void:
	if not visible or index >= _choices.size():
		return
	var choice: Dictionary = _choices[index]
	visible = false
	chosen.emit(choice)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("upgrade_1"):
		_pick(0)
	elif event.is_action_pressed("upgrade_2"):
		_pick(1)
	elif event.is_action_pressed("upgrade_3"):
		_pick(2)
	elif event.is_action_pressed("ui_accept"):
		# controller/keyboard: confirm whichever card holds focus
		for i in _card_panels.size():
			if is_instance_valid(_card_panels[i]) and _card_panels[i].has_focus():
				_pick(i)
				break
