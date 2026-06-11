@tool
extends McpTestSuite


func suite_name() -> String:
	return "project_compile_smoke"


func test_main_scene_loads_and_instantiates() -> void:
	var main_scene_path := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	assert_eq(main_scene_path, "res://scenes/Main.tscn", "main scene setting should point at the generated main scene")

	var packed_scene := load(main_scene_path) as PackedScene
	assert_true(packed_scene != null, "main scene should load without script compile errors")
	if packed_scene == null:
		return

	var instance := packed_scene.instantiate()
	assert_true(instance != null, "main scene should instantiate")
	if instance != null:
		instance.free()


func test_runtime_scripts_load_without_compile_errors() -> void:
	var runtime_scripts := [
		"res://scripts/core/audio_manager.gd",
		"res://scripts/enemies/enemy.gd",
		"res://scripts/game/game_world.gd",
		"res://scripts/game/orbiter.gd",
		"res://scripts/game/projectile.gd",
		"res://scripts/weapons/weapon_manager.gd",
	]
	for path: String in runtime_scripts:
		assert_true(load(path) != null, "script should load without compile errors: " + path)
