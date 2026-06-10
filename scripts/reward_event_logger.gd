@tool
class_name RewardEventLogger
extends RefCounted

const DEFAULT_LOG_PATH := "user://reward_loop_seed_events.jsonl"

var log_path: String
var session_id: String


func _init(path: String = DEFAULT_LOG_PATH, forced_session_id: String = "") -> void:
	log_path = path
	session_id = forced_session_id
	if session_id.is_empty():
		session_id = _generate_session_id()


func build_event(
	event_name: String,
	time_since_session_start: float,
	player_level: int,
	reward_count: int,
	upgrade_count: int,
	selected_upgrade: String = "",
	chest_reward: Dictionary = {},
	session_duration: float = -1.0,
	extra_context: Dictionary = {}
) -> Dictionary:
	var event := {
		"event": event_name,
		"session_id": session_id,
		"timestamp": Time.get_datetime_string_from_system(true),
		"time_since_session_start": snappedf(time_since_session_start, 0.001),
		"player_level": player_level,
		"reward_count": reward_count,
		"upgrade_count": upgrade_count,
	}

	if not selected_upgrade.is_empty():
		event["selected_upgrade"] = selected_upgrade
	if not chest_reward.is_empty():
		event["chest_reward"] = chest_reward.duplicate(true)
	if session_duration >= 0.0:
		event["session_duration"] = snappedf(session_duration, 0.001)
	for key: Variant in extra_context.keys():
		event[key] = extra_context[key]

	return event


func log_event(
	event_name: String,
	time_since_session_start: float,
	player_level: int,
	reward_count: int,
	upgrade_count: int,
	selected_upgrade: String = "",
	chest_reward: Dictionary = {},
	session_duration: float = -1.0,
	extra_context: Dictionary = {}
) -> void:
	var event: Dictionary = build_event(
		event_name,
		time_since_session_start,
		player_level,
		reward_count,
		upgrade_count,
		selected_upgrade,
		chest_reward,
		session_duration,
		extra_context
	)
	var file: FileAccess
	if FileAccess.file_exists(log_path):
		file = FileAccess.open(log_path, FileAccess.READ_WRITE)
		if file != null:
			file.seek_end()
	else:
		file = FileAccess.open(log_path, FileAccess.WRITE)

	if file == null:
		push_error("RewardEventLogger failed to open %s: %s" % [log_path, error_string(FileAccess.get_open_error())])
		return

	file.store_line(JSON.stringify(event))
	file.close()


func clear_log_file() -> void:
	var file := FileAccess.open(log_path, FileAccess.WRITE)
	if file == null:
		push_error("RewardEventLogger failed to clear %s: %s" % [log_path, error_string(FileAccess.get_open_error())])
		return
	file.close()


func _generate_session_id() -> String:
	var random_part: int = randi() % 1000000
	return "reward-loop-%d-%06d" % [Time.get_unix_time_from_system(), random_part]
