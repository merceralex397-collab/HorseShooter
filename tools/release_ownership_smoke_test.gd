extends Node


func _ready() -> void:
	await get_tree().process_frame

	var main_scene := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main_scene != "res://scenes/app/app_root.tscn":
		_fail("Release main scene must boot AppRoot, not the legacy wave scene.")
		return

	var release_scripts := [
		"res://src/app/app_root.gd",
		"res://src/world/world_root.gd",
		"res://src/player/rpg_player_controller.gd",
		"res://src/ui/rpg_overlay.gd",
	]
	for script_path in release_scripts:
		if _file_contains(script_path, "GameManager"):
			_fail("Release script still depends on GameManager: " + script_path)
			return

	var required_managers := [
		"/root/SaveManager",
		"/root/QuestManager",
		"/root/InventoryManager",
		"/root/ProgressionManager",
		"/root/FollowerManager",
		"/root/SettlementManager",
		"/root/CombatDirector",
		"/root/FactionManager",
		"/root/DialogueManager",
	]
	for manager_path in required_managers:
		var manager := get_node_or_null(manager_path)
		if manager == null:
			_fail("Missing RPG manager autoload: " + manager_path)
			return
		if not manager.has_method("export_state") or not manager.has_method("import_state"):
			_fail("RPG manager lacks release state API: " + manager_path)
			return

	print("RELEASE_OWNERSHIP_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _file_contains(path: String, needle: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var content := file.get_as_text()
	file.close()
	return content.contains(needle)


func _fail(message: String) -> void:
	push_error("RELEASE_OWNERSHIP: " + message)
	get_tree().quit(1)
