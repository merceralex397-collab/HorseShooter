extends Node


func _ready() -> void:
	await get_tree().process_frame

	var quest_manager := get_node_or_null("/root/QuestManager")
	var faction_manager := get_node_or_null("/root/FactionManager")
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if quest_manager == null or faction_manager == null or dialogue_manager == null:
		_fail("Required story autoloads missing.")
		return

	quest_manager.start_quest("quest.greenbarrow.road_full_of_hooves")
	quest_manager.advance_objective("quest.greenbarrow.road_full_of_hooves", "clear_road")
	quest_manager.complete_quest("quest.greenbarrow.road_full_of_hooves")
	if faction_manager.call("get_reputation", "faction.roadwardens") <= 0:
		_fail("Completing quest did not affect Roadwarden reputation.")
		return

	var rendered: Array = dialogue_manager.call("render_exchange", [
		"{player_name}: I hate horses.",
		"Scout: That is becoming operational doctrine.",
	], {"player_name": "TestName"})
	if not String(rendered[0]).contains("TestName"):
		_fail("Dialogue exchange did not resolve player-chosen name.")
		return

	var bark_one := String(dialogue_manager.call("request_bark", "horse_seen", 100.0, 8.0))
	var bark_two := String(dialogue_manager.call("request_bark", "horse_seen", 101.0, 8.0))
	if bark_one.is_empty() or not bark_two.is_empty():
		_fail("Bark cooldown did not work.")
		return
	if not bark_one.to_lower().contains("horse") or not _contains_profanity(bark_one):
		_fail("Bark does not satisfy protagonist tone.")
		return

	print("STORY_FACTION_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _contains_profanity(value: String) -> bool:
	var lowered := value.to_lower()
	return lowered.contains("damn") or lowered.contains("shit") or lowered.contains("bastard")


func _fail(message: String) -> void:
	push_error("STORY_FACTION: " + message)
	get_tree().quit(1)
