extends Node
## Local progression persistence. Autoloaded as SaveSystem.
## Stores high score and lifetime stats in user:// as JSON. No online services.

const SAVE_PATH := "user://cursed_keep_save.json"

var data: Dictionary = _defaults()


static func _defaults() -> Dictionary:
	return {
		"high_score": 0,
		"fastest_victory_time": 0.0, # 0 means no victory yet
		"total_runs": 0,
		"total_kills": 0,
		"best_wave": 0,
		"victories": 0,
		"sfx_volume": 1.0,
		"music_volume": 1.0,
	}


func _ready() -> void:
	load_save()


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_warning("SaveSystem: could not open save file for reading.")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		var defaults := _defaults()
		for key: String in defaults.keys():
			if parsed.has(key):
				defaults[key] = parsed[key]
		data = defaults


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveSystem: could not open save file for writing.")
		return
	f.store_string(JSON.stringify(data, "\t"))


## Records a finished run. Returns a dictionary of which records were beaten,
## so result screens can celebrate new bests.
func record_run(stats: Dictionary) -> Dictionary:
	var records := {"new_high_score": false, "new_best_wave": false, "new_fastest_victory": false}
	data["total_runs"] = int(data["total_runs"]) + 1
	data["total_kills"] = int(data["total_kills"]) + int(stats.get("kills", 0))
	var score := int(stats.get("score", 0))
	if score > int(data["high_score"]):
		data["high_score"] = score
		records["new_high_score"] = true
	var wave := int(stats.get("wave", 0))
	if wave > int(data["best_wave"]):
		data["best_wave"] = wave
		records["new_best_wave"] = true
	if bool(stats.get("victory", false)):
		data["victories"] = int(data["victories"]) + 1
		var t := float(stats.get("time", 0.0))
		var best := float(data["fastest_victory_time"])
		if best <= 0.0 or t < best:
			data["fastest_victory_time"] = t
			records["new_fastest_victory"] = true
	save()
	return records
