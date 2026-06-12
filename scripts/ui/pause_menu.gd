class_name PauseMenu
extends CanvasLayer
## Pause overlay: resume, restart, main menu, controls reminder.

signal resume_pressed
signal restart_pressed
signal menu_pressed

var _resume_btn: Button


## Shows the menu and moves focus to Resume for controller/keyboard play.
func open() -> void:
	visible = true
	_resume_btn.call_deferred("grab_focus")


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	add_child(UiTheme.dim_layer())

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style())
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	v.add_child(UiTheme.make_title("THE VIGIL PAUSES", 32))

	var resume := UiTheme.make_button("RESUME")
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	v.add_child(resume)
	_resume_btn = resume

	var restart := UiTheme.make_button("RESTART RUN")
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	v.add_child(restart)

	var menu := UiTheme.make_button("MAIN MENU")
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	v.add_child(menu)

	var music := UiTheme.make_button(_music_label(), 16)
	music.pressed.connect(func() -> void:
		AudioManager.set_music_enabled(not AudioManager.is_music_enabled())
		music.text = _music_label())
	v.add_child(music)

	v.add_child(UiTheme.make_label("WASD move · SPACE dash · ESC resume · F3 debug", 12, Color(0.55, 0.52, 0.65)))


static func _music_label() -> String:
	return "MUSIC: ON" if AudioManager.is_music_enabled() else "MUSIC: OFF"
