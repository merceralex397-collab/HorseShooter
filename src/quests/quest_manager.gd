extends Node

var active_quests := {}
var completed_quests := {}
var failed_quests := {}


func start_quest(quest_id: String) -> void:
	if completed_quests.has(quest_id):
		return
	if not active_quests.has(quest_id):
		active_quests[quest_id] = {"objectives": {}}


func advance_objective(quest_id: String, objective_id: String) -> void:
	start_quest(quest_id)
	active_quests[quest_id]["objectives"][objective_id] = true


func is_objective_complete(quest_id: String, objective_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	return bool(active_quests[quest_id].get("objectives", {}).get(objective_id, false))


func complete_quest(quest_id: String) -> void:
	if active_quests.has(quest_id):
		completed_quests[quest_id] = active_quests[quest_id]
		active_quests.erase(quest_id)
		_apply_faction_consequence(quest_id, "completed")


func fail_quest(quest_id: String) -> void:
	if active_quests.has(quest_id):
		failed_quests[quest_id] = active_quests[quest_id]
		active_quests.erase(quest_id)
		_apply_faction_consequence(quest_id, "failed")


func get_journal_state() -> Dictionary:
	return {
		"active": active_quests.duplicate(true),
		"completed": completed_quests.duplicate(true),
		"failed": failed_quests.duplicate(true),
	}


func export_state() -> Dictionary:
	return get_journal_state()


func import_state(state: Dictionary) -> void:
	active_quests = _dictionary_or_empty(state.get("active", {}))
	completed_quests = _dictionary_or_empty(state.get("completed", {}))
	failed_quests = _dictionary_or_empty(state.get("failed", {}))


func _apply_faction_consequence(quest_id: String, outcome: String) -> void:
	var faction_manager := get_node_or_null("/root/FactionManager")
	if faction_manager and faction_manager.has_method("apply_quest_consequence"):
		faction_manager.call("apply_quest_consequence", quest_id, outcome)


func _dictionary_or_empty(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}
