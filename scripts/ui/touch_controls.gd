class_name TouchControls
extends CanvasLayer
## On-screen controls for touchscreen devices (mobile / web-on-mobile):
## a floating virtual joystick on the left half of the screen and a dash
## button bottom-right. Hidden and inert when no touchscreen is present.
##
## Movement is exposed through `move_vector` (read by Player as a fallback
## when no keyboard/gamepad input is active). Dash presses the existing
## "dash" input action, so gameplay code needs no special casing.

const JOY_RADIUS := 70.0
const DASH_RADIUS := 44.0
const PAUSE_RADIUS := 22.0

var move_vector := Vector2.ZERO

var _enabled := false
var _joy_index := -1
var _joy_origin := Vector2.ZERO
var _joy_current := Vector2.ZERO
var _dash_index := -1
var _canvas: Control


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("touch_controls")
	_enabled = DisplayServer.is_touchscreen_available()
	if not _enabled:
		visible = false
		set_process_input(false)
		return
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)


func _input(event: InputEvent) -> void:
	if not _enabled or not visible:
		return
	if get_tree().paused:
		_release_all()
		return
	var vp: Vector2 = _canvas.get_viewport_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(_pause_center()) <= PAUSE_RADIUS * 1.6:
				# dispatch a real action event so Main's _unhandled_input sees it
				var pause_ev := InputEventAction.new()
				pause_ev.action = "pause"
				pause_ev.pressed = true
				Input.parse_input_event(pause_ev)
				return
			if event.position.distance_to(_dash_center(vp)) <= DASH_RADIUS * 1.5:
				_dash_index = event.index
				Input.action_press("dash")
			elif event.position.x < vp.x * 0.55 and _joy_index < 0:
				_joy_index = event.index
				_joy_origin = event.position
				_joy_current = event.position
				move_vector = Vector2.ZERO
		else:
			if event.index == _joy_index:
				_joy_index = -1
				move_vector = Vector2.ZERO
			if event.index == _dash_index:
				_dash_index = -1
				Input.action_release("dash")
	elif event is InputEventScreenDrag and event.index == _joy_index:
		_joy_current = event.position
		move_vector = ((_joy_current - _joy_origin) / JOY_RADIUS).limit_length(1.0)
	_canvas.queue_redraw()


func _release_all() -> void:
	if _dash_index >= 0:
		Input.action_release("dash")
	_dash_index = -1
	_joy_index = -1
	move_vector = Vector2.ZERO


func _dash_center(vp: Vector2) -> Vector2:
	return Vector2(vp.x - 96.0, vp.y - 110.0)


func _pause_center() -> Vector2:
	return Vector2(332.0, 46.0) # right of the HUD dash arc, clear of the timer


func _draw_controls() -> void:
	var vp: Vector2 = _canvas.get_viewport_rect().size
	# dash button (always faintly visible)
	var dash_pos := _dash_center(vp)
	var pressed := _dash_index >= 0
	_canvas.draw_circle(dash_pos, DASH_RADIUS, Color(0.08, 0.06, 0.14, 0.55 if pressed else 0.35))
	_canvas.draw_arc(dash_pos, DASH_RADIUS, 0, TAU, 32, Color(0.55, 0.83, 1.0, 0.8 if pressed else 0.45), 2.5)
	_canvas.draw_line(dash_pos + Vector2(-14, 6), dash_pos + Vector2(0, -10), Color(0.55, 0.83, 1.0, 0.9), 3.0)
	_canvas.draw_line(dash_pos + Vector2(0, -10), dash_pos + Vector2(14, 6), Color(0.55, 0.83, 1.0, 0.9), 3.0)
	# pause button ("II"), top-left next to the dash cooldown arc
	var pause_pos := _pause_center()
	_canvas.draw_circle(pause_pos, PAUSE_RADIUS, Color(0.08, 0.06, 0.14, 0.4))
	_canvas.draw_arc(pause_pos, PAUSE_RADIUS, 0, TAU, 24, Color(0.85, 0.71, 0.42, 0.55), 2.0)
	_canvas.draw_line(pause_pos + Vector2(-4, -7), pause_pos + Vector2(-4, 7), Color(0.95, 0.88, 0.7, 0.9), 3.5)
	_canvas.draw_line(pause_pos + Vector2(4, -7), pause_pos + Vector2(4, 7), Color(0.95, 0.88, 0.7, 0.9), 3.5)
	# floating joystick (only while touched)
	if _joy_index >= 0:
		_canvas.draw_circle(_joy_origin, JOY_RADIUS, Color(0.08, 0.06, 0.14, 0.3))
		_canvas.draw_arc(_joy_origin, JOY_RADIUS, 0, TAU, 36, Color(0.85, 0.71, 0.42, 0.5), 2.0)
		var knob: Vector2 = _joy_origin + move_vector * JOY_RADIUS
		_canvas.draw_circle(knob, 26.0, Color(0.85, 0.71, 0.42, 0.55))
		_canvas.draw_circle(knob, 18.0, Color(0.95, 0.88, 0.7, 0.7))
