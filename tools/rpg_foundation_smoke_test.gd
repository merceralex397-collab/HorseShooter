extends Node

const SAVE_MANAGER_PATH := "/root/SaveManager"
const DIALOGUE_MANAGER_PATH := "/root/DialogueManager"


func _ready() -> void:
	await get_tree().process_frame

	if not await _check_save_manager_contract():
		get_tree().quit(1)
		return
	if not _check_dialogue_name_token_contract():
		get_tree().quit(1)
		return

	print("RPG_FOUNDATION_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _check_save_manager_contract() -> bool:
	var save_manager := get_node_or_null(SAVE_MANAGER_PATH)
	if save_manager == null:
		push_error("RPG_FOUNDATION: SaveManager autoload missing.")
		return false

	if not save_manager.has_method("validate_character_name"):
		push_error("RPG_FOUNDATION: SaveManager.validate_character_name missing.")
		return false
	if save_manager.validate_character_name("")["valid"]:
		push_error("RPG_FOUNDATION: Empty names must be rejected.")
		return false
	if save_manager.validate_character_name("abcdefghijklmnopqrstuvwxyz")["valid"]:
		push_error("RPG_FOUNDATION: Names longer than 24 visible characters must be rejected.")
		return false
	if not save_manager.validate_character_name("Rowan")["valid"]:
		push_error("RPG_FOUNDATION: Normal names must be accepted.")
		return false

	var slot_id := "foundation_test"
	save_manager.delete_slot(slot_id)
	var created = save_manager.create_new_game(slot_id, "Rowan")
	if not (created is Dictionary):
		push_error("RPG_FOUNDATION: create_new_game must return a save dictionary.")
		return false
	if String(created.get("chosen_character_name", "")) != "Rowan":
		push_error("RPG_FOUNDATION: chosen_character_name was not persisted in created save.")
		return false
	if not save_manager.slot_exists(slot_id):
		push_error("RPG_FOUNDATION: slot_exists did not see the created save.")
		return false

	var loaded = save_manager.load_slot(slot_id)
	if not (loaded is Dictionary):
		push_error("RPG_FOUNDATION: load_slot must return a dictionary for valid save.")
		return false
	if String(loaded.get("chosen_character_name", "")) != "Rowan":
		push_error("RPG_FOUNDATION: loaded save lost chosen_character_name.")
		return false

	save_manager.delete_slot(slot_id)
	if save_manager.slot_exists(slot_id):
		push_error("RPG_FOUNDATION: delete_slot failed.")
		return false
	return true


func _check_dialogue_name_token_contract() -> bool:
	var dialogue_manager := get_node_or_null(DIALOGUE_MANAGER_PATH)
	if dialogue_manager == null:
		push_error("RPG_FOUNDATION: DialogueManager autoload missing.")
		return false
	if not dialogue_manager.has_method("render_line"):
		push_error("RPG_FOUNDATION: DialogueManager.render_line missing.")
		return false

	var rendered := String(dialogue_manager.render_line("Damn it, {player_name}, shoot the horse.", {"player_name": "Rowan"}))
	if rendered != "Damn it, Rowan, shoot the horse.":
		push_error("RPG_FOUNDATION: DialogueManager did not replace {player_name}. Got: " + rendered)
		return false
	return true
