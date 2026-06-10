@tool
extends McpTestSuite

const RULES_PATH := "res://scripts/reward_loop_rules.gd"
const LOGGER_PATH := "res://scripts/reward_event_logger.gd"
const TEST_LOG_PATH := "user://reward_loop_seed_test_events.jsonl"

var Rules: GDScript
var EventLoggerScript: GDScript


func suite_name() -> String:
	return "reward_loop_core"


func suite_setup(_ctx: Dictionary) -> void:
	if not ResourceLoader.exists(RULES_PATH):
		fail_setup("Missing reward loop rules script at %s" % RULES_PATH)
		return
	if not ResourceLoader.exists(LOGGER_PATH):
		fail_setup("Missing event logger script at %s" % LOGGER_PATH)
		return

	Rules = load(RULES_PATH)
	EventLoggerScript = load(LOGGER_PATH)
	if Rules == null:
		fail_setup("Failed to load %s" % RULES_PATH)
		return
	if EventLoggerScript == null:
		fail_setup("Failed to load %s" % LOGGER_PATH)


func teardown() -> void:
	if FileAccess.file_exists(TEST_LOG_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_LOG_PATH))


func test_upgrade_pool_has_six_distinct_real_choices() -> void:
	var upgrades: Array = Rules.upgrade_pool()
	var ids := {}
	for upgrade: Dictionary in upgrades:
		assert_has_key(upgrade, "id")
		assert_has_key(upgrade, "title")
		assert_has_key(upgrade, "description")
		assert_has_key(upgrade, "effect_type")
		ids[upgrade.id] = true

	assert_gt(upgrades.size(), 5, "Expected at least six upgrade choices")
	assert_eq(ids.size(), upgrades.size(), "Upgrade IDs must be unique")


func test_upgrade_choices_return_three_unique_options() -> void:
	var choices: Array = Rules.upgrade_choices(2, ["move_speed"], 3)
	var ids := {}
	for choice: Dictionary in choices:
		ids[choice.id] = true
		assert_ne(choice.id, "move_speed", "Already chosen one-time upgrades should be skipped")

	assert_eq(choices.size(), 3)
	assert_eq(ids.size(), 3, "Offered choices must not be duplicates")


func test_xp_threshold_scales_and_detects_level_up() -> void:
	assert_eq(Rules.xp_required_for_level(1), 45)
	assert_eq(Rules.xp_required_for_level(3), 81)
	assert_false(Rules.should_offer_upgrade(44, 1))
	assert_true(Rules.should_offer_upgrade(45, 1))


func test_chest_rewards_are_free_and_deterministic() -> void:
	var pool: Array = Rules.chest_reward_pool()
	assert_gt(pool.size(), 2)
	for reward: Dictionary in pool:
		assert_has_key(reward, "id")
		assert_has_key(reward, "title")
		assert_has_key(reward, "effect_type")
		assert_false(reward.has("price"), "Free chest rewards must not define payment fields")
		assert_false(str(reward).to_lower().contains("premium"), "Prototype chest rewards must stay non-premium")
		assert_false(str(reward).to_lower().contains("ad"), "Prototype chest rewards must not depend on ads")

	var first: Dictionary = Rules.chest_reward_for("fixed-session", 12, 2)
	var second: Dictionary = Rules.chest_reward_for("fixed-session", 12, 2)
	assert_eq(first.id, second.id, "Chest reward selection should be deterministic for a run context")


func test_event_builder_includes_required_context() -> void:
	var logger: RefCounted = EventLoggerScript.new(TEST_LOG_PATH, "session-under-test")
	var event: Dictionary = logger.build_event(
		"upgrade_selected",
		12.5,
		3,
		14,
		2,
		"attack_rate",
		{},
		-1.0
	)

	assert_eq(event.event, "upgrade_selected")
	assert_eq(event.session_id, "session-under-test")
	assert_eq(event.time_since_session_start, 12.5)
	assert_eq(event.player_level, 3)
	assert_eq(event.reward_count, 14)
	assert_eq(event.upgrade_count, 2)
	assert_eq(event.selected_upgrade, "attack_rate")
	assert_has_key(event, "timestamp")


func test_event_logger_writes_local_jsonl() -> void:
	var logger: RefCounted = EventLoggerScript.new(TEST_LOG_PATH, "session-under-test")
	logger.clear_log_file()
	logger.log_event("session_started", 0.0, 1, 0, 0)

	assert_true(FileAccess.file_exists(TEST_LOG_PATH), "Expected local JSONL file to be written")
	var content := FileAccess.get_file_as_string(TEST_LOG_PATH).strip_edges()
	var parsed: Variant = JSON.parse_string(content)
	assert_true(parsed is Dictionary, "Log line should parse as JSON")
	assert_eq(parsed.event, "session_started")
	assert_eq(parsed.session_id, "session-under-test")
