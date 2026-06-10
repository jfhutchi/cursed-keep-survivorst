class_name RewardLoopSeed
extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const PickupScript := preload("res://scripts/reward_pickup.gd")
const FloatingTextScript := preload("res://scripts/floating_text.gd")
const Rules := preload("res://scripts/reward_loop_rules.gd")
const EventLoggerScript := preload("res://scripts/reward_event_logger.gd")

var rng := RandomNumberGenerator.new()
var logger: Variant
var player: Variant
var arena_root: Node2D
var pickup_root: Node2D
var feedback_root: Node2D
var ui_layer: CanvasLayer
var time_label: Label
var health_label: Label
var score_label: Label
var progress_bar: ProgressBar
var progress_label: Label
var message_label: Label
var upgrade_overlay: PanelContainer
var upgrade_list: VBoxContainer
var chest_overlay: PanelContainer
var chest_title_label: Label
var chest_body_label: Label
var chest_button: Button
var result_overlay: PanelContainer
var result_label: Label

var enemies: Array[Variant] = []
var pickups: Array[Variant] = []
var selected_upgrade_ids: Array[String] = []
var selected_upgrade_titles: Array[String] = []
var chest_reward_titles: Array[String] = []

var elapsed_time := 0.0
var spawn_timer := 0.0
var attack_timer := 0.0
var contact_timer := 0.0
var spawn_count := 0
var score := 0
var reward_count := 0
var xp := 0
var player_level := 1
var chest_earned := false
var chest_opened := false
var first_reward_logged := false
var first_upgrade_logged := false
var session_ended := false
var pending_chest_reward: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	rng.randomize()
	_build_arena()
	_build_ui()
	_start_session()


func _process(delta: float) -> void:
	if session_ended or get_tree().paused:
		return

	elapsed_time += delta
	spawn_timer -= delta
	attack_timer -= delta
	contact_timer -= delta

	if spawn_timer <= 0.0:
		_spawn_enemy(Rules.should_spawn_elite(spawn_count))
		spawn_count += 1
		spawn_timer = Rules.spawn_interval_for_time(elapsed_time)

	if attack_timer <= 0.0:
		_fire_player_attack()
		attack_timer = player.attack_interval

	if contact_timer <= 0.0:
		_check_enemy_contact()
		contact_timer = 0.22

	if Rules.should_earn_chest(elapsed_time, score, chest_earned):
		_earn_free_chest()

	if elapsed_time >= Rules.SESSION_LENGTH:
		_end_session("win")
		return

	_update_ui()


func _build_arena() -> void:
	arena_root = Node2D.new()
	arena_root.name = "Arena"
	add_child(arena_root)

	var background := ColorRect.new()
	background.name = "CrudeArenaBackdrop"
	background.position = Vector2(-960.0, -540.0)
	background.size = Vector2(1920.0, 1080.0)
	background.color = Color(0.11, 0.13, 0.10)
	background.z_index = -100
	arena_root.add_child(background)

	var boundary := Line2D.new()
	boundary.name = "ArenaBoundary"
	boundary.width = 5.0
	boundary.default_color = Color(0.72, 0.78, 0.56)
	boundary.closed = true
	boundary.points = PackedVector2Array([
		Vector2(-900.0, -500.0),
		Vector2(900.0, -500.0),
		Vector2(900.0, 500.0),
		Vector2(-900.0, 500.0),
	])
	arena_root.add_child(boundary)

	player = PlayerScript.new()
	player.name = "Player"
	player.global_position = Vector2.ZERO
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	arena_root.add_child(player)

	var camera := Camera2D.new()
	camera.name = "PlayerCamera"
	camera.enabled = true
	camera.zoom = Vector2(0.82, 0.82)
	camera.position_smoothing_enabled = true
	player.add_child(camera)

	pickup_root = Node2D.new()
	pickup_root.name = "RewardPickups"
	arena_root.add_child(pickup_root)

	feedback_root = Node2D.new()
	feedback_root.name = "Feedback"
	arena_root.add_child(feedback_root)


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "HUD"
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)

	var ui_root := Control.new()
	ui_root.name = "HUDRoot"
	ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(ui_root)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(16.0, 14.0)
	top_panel.custom_minimum_size = Vector2(410.0, 110.0)
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.09, 0.07, 0.82), Color(0.65, 0.72, 0.46)))
	ui_root.add_child(top_panel)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 4)
	top_panel.add_child(top_box)

	time_label = _make_label("Time 0:00", 18, Color.WHITE)
	health_label = _make_label("Health 6/6", 18, Color(0.9, 0.95, 0.72))
	score_label = _make_label("Score 0 | Sparks 0", 18, Color(1.0, 0.8, 0.35))
	progress_label = _make_label("Level 1 progress", 16, Color(0.76, 0.92, 1.0))
	top_box.add_child(time_label)
	top_box.add_child(health_label)
	top_box.add_child(score_label)
	top_box.add_child(progress_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(380.0, 18.0)
	progress_bar.max_value = Rules.xp_required_for_level(player_level)
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	top_box.add_child(progress_bar)

	message_label = _make_label("Move with WASD or arrows. Attacks are automatic.", 22, Color(0.95, 0.95, 0.78))
	message_label.position = Vector2(32.0, 628.0)
	message_label.size = Vector2(850.0, 42.0)
	ui_root.add_child(message_label)

	upgrade_overlay = _make_overlay(Vector2(580.0, 360.0))
	ui_root.add_child(upgrade_overlay)
	var upgrade_box := VBoxContainer.new()
	upgrade_box.add_theme_constant_override("separation", 10)
	upgrade_overlay.add_child(upgrade_box)
	upgrade_box.add_child(_make_label("Choose a Run Upgrade", 26, Color(1.0, 0.88, 0.38)))
	upgrade_list = VBoxContainer.new()
	upgrade_list.add_theme_constant_override("separation", 8)
	upgrade_box.add_child(upgrade_list)

	chest_overlay = _make_overlay(Vector2(560.0, 300.0))
	ui_root.add_child(chest_overlay)
	var chest_box := VBoxContainer.new()
	chest_box.add_theme_constant_override("separation", 12)
	chest_overlay.add_child(chest_box)
	chest_title_label = _make_label("Earned Free Chest", 28, Color(1.0, 0.78, 0.22))
	chest_body_label = _make_label("This chest is earned by play only.", 20, Color.WHITE)
	chest_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chest_button = Button.new()
	chest_button.text = "Open earned chest"
	chest_button.custom_minimum_size = Vector2(420.0, 54.0)
	chest_button.pressed.connect(_on_chest_button_pressed)
	chest_box.add_child(chest_title_label)
	chest_box.add_child(chest_body_label)
	chest_box.add_child(chest_button)

	result_overlay = _make_overlay(Vector2(620.0, 460.0))
	ui_root.add_child(result_overlay)
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 10)
	result_overlay.add_child(result_box)
	result_box.add_child(_make_label("Run Results", 30, Color(1.0, 0.88, 0.38)))
	result_label = _make_label("", 18, Color.WHITE)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.custom_minimum_size = Vector2(540.0, 260.0)
	result_box.add_child(result_label)
	var restart_button := Button.new()
	restart_button.text = "Restart now"
	restart_button.custom_minimum_size = Vector2(420.0, 48.0)
	restart_button.pressed.connect(_on_restart_pressed)
	result_box.add_child(restart_button)
	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(420.0, 42.0)
	quit_button.pressed.connect(_on_quit_pressed)
	result_box.add_child(quit_button)


func _start_session() -> void:
	logger = EventLoggerScript.new()
	logger.log_event("session_started", 0.0, player_level, reward_count, selected_upgrade_ids.size())
	for i in range(3):
		_spawn_enemy(false)
		spawn_count += 1
	_show_message("Survive 3 minutes. Grab sparks. Pick upgrades. Open earned chest.", Color(0.95, 0.95, 0.78))
	_update_ui()


func _spawn_enemy(elite: bool) -> void:
	var enemy: Variant = EnemyScript.new()
	enemy.name = "EliteTarget" if elite else "BasicChaser"
	enemy.setup("elite" if elite else "basic", elapsed_time)
	enemy.target = player
	enemy.global_position = _random_spawn_position()
	enemy.defeated.connect(_on_enemy_defeated)
	enemies.append(enemy)
	arena_root.add_child(enemy)


func _random_spawn_position() -> Vector2:
	var side := rng.randi_range(0, 3)
	match side:
		0:
			return Vector2(rng.randf_range(-880.0, 880.0), -500.0)
		1:
			return Vector2(rng.randf_range(-880.0, 880.0), 500.0)
		2:
			return Vector2(-900.0, rng.randf_range(-480.0, 480.0))
	return Vector2(900.0, rng.randf_range(-480.0, 480.0))


func _fire_player_attack() -> void:
	var target_enemy: Variant = _nearest_enemy()
	if target_enemy == null:
		return

	_draw_attack_line(player.global_position, target_enemy.global_position, Color(0.34, 0.9, 1.0))
	target_enemy.take_damage(player.attack_damage)

	if player.chain_attack_enabled:
		for enemy: Variant in enemies:
			if enemy == target_enemy:
				continue
			if enemy.global_position.distance_to(target_enemy.global_position) <= 95.0:
				_draw_attack_line(target_enemy.global_position, enemy.global_position, Color(0.62, 1.0, 0.5))
				enemy.take_damage(1)
				break


func _nearest_enemy() -> Variant:
	var nearest: Variant = null
	var nearest_distance := INF
	for enemy: Variant in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance: float = player.global_position.distance_to(enemy.global_position)
		if distance <= player.attack_range and distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _draw_attack_line(from_position: Vector2, to_position: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = color
	line.points = PackedVector2Array([from_position, to_position])
	feedback_root.add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.16)
	tween.finished.connect(line.queue_free)


func _check_enemy_contact() -> void:
	for enemy: Variant in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(player.global_position) <= 32.0:
			player.take_damage(enemy.contact_damage)
			_show_floating_text("-1", player.global_position + Vector2(18.0, -20.0), Color(1.0, 0.2, 0.15))
			return


func _on_enemy_defeated(enemy: Variant, base_reward_value: int, enemy_score_value: int) -> void:
	enemies.erase(enemy)
	score += enemy_score_value
	_spawn_reward(enemy.global_position, player.reward_value(base_reward_value))
	_show_floating_text("+%d" % enemy_score_value, enemy.global_position, Color(1.0, 0.84, 0.28))
	enemy.queue_free()
	_update_ui()


func _spawn_reward(world_position: Vector2, drop_value: int) -> void:
	var pickup: Variant = PickupScript.new()
	pickup.name = "RewardSpark"
	pickup.global_position = world_position
	pickup.setup(drop_value, player)
	pickup.collected.connect(_on_reward_collected)
	pickups.append(pickup)
	pickup_root.add_child(pickup)


func _on_reward_collected(pickup: Variant, value: int) -> void:
	pickups.erase(pickup)
	pickup.queue_free()
	reward_count += 1
	xp += value
	score += value * 4
	_show_floating_text("spark +%d" % value, player.global_position + Vector2(0.0, -34.0), Color(1.0, 0.82, 0.2))
	_pulse_progress_bar()

	if not first_reward_logged:
		first_reward_logged = true
		logger.log_event("first_reward_collected", elapsed_time, player_level, reward_count, selected_upgrade_ids.size())
	logger.log_event("reward_collected", elapsed_time, player_level, reward_count, selected_upgrade_ids.size())

	if Rules.should_offer_upgrade(xp, player_level):
		_offer_upgrade()
	_update_ui()


func _offer_upgrade() -> void:
	var required_xp: int = Rules.xp_required_for_level(player_level)
	xp -= required_xp
	player_level += 1
	get_tree().paused = true
	if not first_upgrade_logged:
		first_upgrade_logged = true
		logger.log_event("first_upgrade_offered", elapsed_time, player_level, reward_count, selected_upgrade_ids.size())

	for child in upgrade_list.get_children():
		upgrade_list.remove_child(child)
		child.queue_free()

	var choices: Array[Dictionary] = Rules.upgrade_choices(player_level, selected_upgrade_ids, 3)
	for upgrade: Dictionary in choices:
		var button := Button.new()
		button.text = "%s\n%s" % [String(upgrade.get("title", "")), String(upgrade.get("description", ""))]
		button.custom_minimum_size = Vector2(500.0, 72.0)
		button.pressed.connect(_on_upgrade_selected.bind(upgrade))
		upgrade_list.add_child(button)

	upgrade_overlay.visible = true
	_show_message("Choose one upgrade. Each button changes this run.", Color(1.0, 0.88, 0.38))
	_update_ui()


func _on_upgrade_selected(upgrade: Dictionary) -> void:
	var selected_id: String = player.apply_upgrade(upgrade)
	selected_upgrade_ids.append(selected_id)
	selected_upgrade_titles.append(String(upgrade.get("title", selected_id)))
	logger.log_event("upgrade_selected", elapsed_time, player_level, reward_count, selected_upgrade_ids.size(), selected_id)
	upgrade_overlay.visible = false
	get_tree().paused = false
	_show_message("Upgrade active: %s" % String(upgrade.get("title", selected_id)), Color(0.5, 1.0, 0.62))
	_update_ui()


func _earn_free_chest() -> void:
	chest_earned = true
	pending_chest_reward = Rules.chest_reward_for(logger.session_id, reward_count, selected_upgrade_ids.size())
	logger.log_event("free_chest_earned", elapsed_time, player_level, reward_count, selected_upgrade_ids.size())
	chest_title_label.text = "Earned Free Chest"
	chest_body_label.text = "You earned this by surviving and collecting sparks. No payment, no premium currency, no ads."
	chest_button.text = "Open earned chest"
	chest_overlay.visible = true
	get_tree().paused = true
	_update_ui()


func _on_chest_button_pressed() -> void:
	if not chest_opened:
		chest_opened = true
		player.apply_chest_reward(pending_chest_reward)
		var reward_title := String(pending_chest_reward.get("title", "Reward"))
		chest_reward_titles.append(reward_title)
		match String(pending_chest_reward.get("effect_type", "")):
			"score_bonus":
				score += int(pending_chest_reward.get("amount", 0))
			"reward_multiplier":
				pass
			"attack_range":
				pass
			"cosmetic_tint":
				pass
		logger.log_event(
			"free_chest_opened",
			elapsed_time,
			player_level,
			reward_count,
			selected_upgrade_ids.size(),
			"",
			pending_chest_reward
		)
		chest_title_label.text = "Chest Revealed"
		chest_body_label.text = "%s\n%s" % [
			reward_title,
			String(pending_chest_reward.get("description", "Reward applied."))
		]
		chest_button.text = "Keep running"
		_show_message("Free chest reward applied: %s" % reward_title, Color(1.0, 0.84, 0.28))
		_update_ui()
		return

	chest_overlay.visible = false
	get_tree().paused = false


func _on_player_health_changed(current: int, maximum: int) -> void:
	if health_label != null:
		health_label.text = "Health %d/%d" % [current, maximum]


func _on_player_died() -> void:
	_end_session("fail")


func _end_session(reason: String) -> void:
	if session_ended:
		return
	session_ended = true
	get_tree().paused = true
	logger.log_event(
		"session_ended",
		elapsed_time,
		player_level,
		reward_count,
		selected_upgrade_ids.size(),
		"",
		{},
		elapsed_time,
		{"end_reason": reason}
	)
	result_label.text = _result_text(reason)
	result_overlay.visible = true
	_update_ui()


func _result_text(reason: String) -> String:
	var upgrade_text := "None" if selected_upgrade_titles.is_empty() else ", ".join(selected_upgrade_titles)
	var chest_text := "None opened" if chest_reward_titles.is_empty() else ", ".join(chest_reward_titles)
	return "Result: %s\nTime survived: %s\nScore: %d\nRewards collected: %d\nUpgrades chosen: %s\nFree chest rewards earned: %s\n\nRestart is available immediately." % [
		reason,
		_format_time(elapsed_time),
		score,
		reward_count,
		upgrade_text,
		chest_text,
	]


func _on_restart_pressed() -> void:
	logger.log_event("restart_clicked", elapsed_time, player_level, reward_count, selected_upgrade_ids.size())
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _update_ui() -> void:
	if time_label == null:
		return
	time_label.text = "Time %s / 3:00" % _format_time(elapsed_time)
	health_label.text = "Health %d/%d" % [player.health, player.max_health]
	score_label.text = "Score %d | Sparks %d" % [score, reward_count]
	progress_label.text = "Level %d progress %d/%d" % [player_level, xp, Rules.xp_required_for_level(player_level)]
	progress_bar.max_value = Rules.xp_required_for_level(player_level)
	progress_bar.value = xp


func _format_time(seconds: float) -> String:
	var total_seconds := int(floor(seconds))
	var minutes := total_seconds / 60
	var remainder := total_seconds % 60
	return "%d:%02d" % [minutes, remainder]


func _pulse_progress_bar() -> void:
	var tween := create_tween()
	progress_bar.modulate = Color(1.0, 0.9, 0.35)
	tween.tween_property(progress_bar, "modulate", Color.WHITE, 0.18)


func _show_message(text: String, color: Color) -> void:
	if message_label == null:
		return
	message_label.text = text
	message_label.modulate = color


func _show_floating_text(text: String, world_position: Vector2, color: Color) -> void:
	var floating_text: Variant = FloatingTextScript.new()
	floating_text.setup(text, world_position, color)
	feedback_root.add_child(floating_text)


func _make_label(label_text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_overlay(size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -size.x * 0.5
	panel.offset_top = -size.y * 0.5
	panel.offset_right = size.x * 0.5
	panel.offset_bottom = size.y * 0.5
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.10, 0.08, 0.94), Color(0.98, 0.72, 0.22)))
	return panel


func _panel_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 18.0
	style.content_margin_top = 16.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 16.0
	return style
