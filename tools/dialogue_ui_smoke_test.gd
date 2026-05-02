extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var save_manager := get_node_or_null("/root/SaveManager")
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	var quest_manager := get_node_or_null("/root/QuestManager")
	if save_manager == null or dialogue_manager == null or quest_manager == null:
		_fail("Missing dialogue test managers.")
		return
	save_manager.call("create_new_game", "dialogue_ui_test", "Rowan")
	dialogue_manager.call("set_subtitle_settings", true, 1.25)

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	var result: Dictionary = world.call("interact_with", "interaction.greenbarrow.roadwarden")
	if not bool(result.get("dialogue_started", false)):
		_fail("Quest interaction did not start dialogue.")
		return
	var state: Dictionary = dialogue_manager.call("get_dialogue_state")
	if not bool(state.get("active", false)):
		_fail("Dialogue state is not active.")
		return
	if not String(state.get("line", "")).contains("Rowan") and not String(state.get("line", "")).contains("horse"):
		_fail("Dialogue line did not render expected chosen-name/tone text.")
		return
	if String(state.get("portrait_id", "")).is_empty():
		_fail("Dialogue lacks portrait id.")
		return
	if state.get("choices", []).is_empty():
		_fail("Dialogue lacks response choices.")
		return

	var overlay = world.get("overlay")
	overlay.call("show_dialogue")
	var panel_state: Dictionary = overlay.call("get_panel_state")
	if String(panel_state.get("active_panel", "")) != "dialogue":
		_fail("Overlay did not open dialogue panel.")
		return
	if not String(panel_state.get("body", "")).contains("Subtitles"):
		_fail("Dialogue panel does not expose subtitle state.")
		return

	dialogue_manager.call("choose_response", "accept")
	if not quest_manager.call("is_objective_complete", "quest.greenbarrow.road_full_of_hooves", "accepted"):
		_fail("Dialogue choice did not set quest objective.")
		return

	save_manager.call("delete_slot", "dialogue_ui_test")
	print("DIALOGUE_UI_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("DIALOGUE_UI: " + message)
	get_tree().quit(1)
