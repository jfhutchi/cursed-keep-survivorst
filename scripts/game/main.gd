class_name Main
extends Node
## Game flow controller: menu -> run -> level-up loop -> game over / victory.
## Owns the UI screens and the current GameWorld instance.

enum State { MENU, PLAYING, LEVEL_UP, PAUSED, GAME_OVER, VICTORY }

const WORLD_SCENE := preload("res://scenes/game/GameWorld.tscn")

var state: State = State.MENU
var world: GameWorld

var _pending_level_ups := 0
var _last_records: Dictionary = {}

@onready var main_menu: MainMenu = $MainMenu
@onready var hud: Hud = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var level_up_screen: LevelUpScreen = $LevelUpScreen
@onready var game_over_screen: ResultScreen = $GameOverScreen
@onready var victory_screen: ResultScreen = $VictoryScreen
@onready var debug_overlay: DebugOverlay = $DebugOverlay


var touch_controls: TouchControls


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	debug_overlay.main = self
	hud.visible = false
	touch_controls = TouchControls.new()
	add_child(touch_controls)
	touch_controls.visible = false

	main_menu.start_pressed.connect(start_run)
	pause_menu.resume_pressed.connect(_resume)
	pause_menu.restart_pressed.connect(restart_run)
	pause_menu.menu_pressed.connect(to_menu)
	level_up_screen.chosen.connect(_on_upgrade_chosen)
	game_over_screen.restart_pressed.connect(restart_run)
	game_over_screen.menu_pressed.connect(to_menu)
	victory_screen.restart_pressed.connect(restart_run)
	victory_screen.menu_pressed.connect(to_menu)

	GameEvents.level_up.connect(_on_level_up)
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.boss_defeated.connect(_on_boss_defeated)
	GameEvents.hit_stop_requested.connect(_on_hit_stop)


func state_name() -> String:
	return State.keys()[state]


## Web: browsers keep Godot's audio worklet running when the tab is
## backgrounded, so mute on focus loss (and pause a running fight).
func _notification(what: int) -> void:
	if not OS.has_feature("web"):
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			AudioServer.set_bus_mute(0, true)
			if state == State.PLAYING:
				_pause()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			AudioServer.set_bus_mute(0, false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		match state:
			State.PLAYING:
				_pause()
			State.PAUSED:
				_resume()


# === FLOW ==================================================================

func start_run() -> void:
	if OS.has_feature("web") and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		# Runs inside a button/key press (a user gesture), so the browser
		# honors the fullscreen request; with the project's landscape
		# orientation setting, mobile browsers also lock to landscape.
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	main_menu.visible = false
	game_over_screen.visible = false
	victory_screen.visible = false
	pause_menu.visible = false
	level_up_screen.visible = false
	_pending_level_ups = 0
	if world != null:
		world.queue_free()
	world = WORLD_SCENE.instantiate()
	# HUD must point at the new world BEFORE _ready fires: the starter-weapon
	# unlock signal rebuilds the weapon row from hud.world.weapon_manager.
	hud.world = world
	add_child(world)
	move_child(world, 0)
	hud.visible = true
	touch_controls.visible = DisplayServer.is_touchscreen_available()
	get_tree().paused = false
	state = State.PLAYING


func restart_run() -> void:
	start_run()


func to_menu() -> void:
	if world != null:
		world.queue_free()
		world = null
	hud.world = null
	hud.visible = false
	touch_controls.visible = false
	pause_menu.visible = false
	game_over_screen.visible = false
	victory_screen.visible = false
	level_up_screen.visible = false
	get_tree().paused = false
	state = State.MENU
	main_menu.refresh_records()
	main_menu.visible = true


func _pause() -> void:
	state = State.PAUSED
	get_tree().paused = true
	pause_menu.open()


func _resume() -> void:
	pause_menu.visible = false
	get_tree().paused = false
	state = State.PLAYING


# === LEVEL-UP LOOP =========================================================

func _on_level_up(_new_level: int) -> void:
	_pending_level_ups += 1
	if state == State.PLAYING:
		_open_level_up()


func _open_level_up() -> void:
	if _pending_level_ups <= 0 or world == null:
		return
	state = State.LEVEL_UP
	get_tree().paused = true
	level_up_screen.show_choices(world.upgrade_system.roll_choices(3))


func _on_upgrade_chosen(upgrade: Dictionary) -> void:
	_pending_level_ups -= 1
	if world != null:
		world.upgrade_system.apply(upgrade)
	if _pending_level_ups > 0 and state == State.LEVEL_UP:
		level_up_screen.show_choices(world.upgrade_system.roll_choices(3))
		return
	if state == State.LEVEL_UP:
		get_tree().paused = false
		state = State.PLAYING


# === RUN END ===============================================================

func _on_player_died() -> void:
	if state in [State.GAME_OVER, State.VICTORY]:
		return
	state = State.GAME_OVER
	AudioManager.play(&"game_over")
	var stats := world.run_stats()
	stats["victory"] = false
	_last_records = SaveSystem.record_run(stats)
	# brief beat to let the collapse animation read, then the screen
	var timer := get_tree().create_timer(1.4, true, false, true)
	timer.timeout.connect(func() -> void:
		if state == State.GAME_OVER:
			get_tree().paused = true
			game_over_screen.show_results(stats, _last_records))


func _on_boss_defeated() -> void:
	if state in [State.GAME_OVER, State.VICTORY]:
		return
	state = State.VICTORY
	AudioManager.play(&"victory")
	world.game_active = false
	var stats := world.run_stats()
	stats["victory"] = true
	_last_records = SaveSystem.record_run(stats)
	var timer := get_tree().create_timer(1.6, true, false, true)
	timer.timeout.connect(func() -> void:
		if state == State.VICTORY:
			get_tree().paused = true
			victory_screen.show_results(stats, _last_records))


# === FEEL ==================================================================

func _on_hit_stop(duration: float) -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.05
	var timer := get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func() -> void: Engine.time_scale = 1.0)
