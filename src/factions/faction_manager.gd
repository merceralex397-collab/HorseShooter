extends Node

var reputations := {}
var region_control := {}
var faction_flags := {}


func set_reputation(faction_id: String, value: int) -> void:
	reputations[faction_id] = clamp(value, -100, 100)


func change_reputation(faction_id: String, delta: int) -> int:
	set_reputation(faction_id, int(reputations.get(faction_id, 0)) + delta)
	return int(reputations[faction_id])


func get_reputation(faction_id: String) -> int:
	return int(reputations.get(faction_id, 0))


func set_region_control(region_id: String, faction_id: String) -> void:
	region_control[region_id] = faction_id


func get_region_control(region_id: String) -> String:
	return String(region_control.get(region_id, "unclaimed"))


func set_flag(flag_id: String, value: bool) -> void:
	faction_flags[flag_id] = value


func get_flag(flag_id: String) -> bool:
	return bool(faction_flags.get(flag_id, false))


func apply_quest_consequence(quest_id: String, outcome: String) -> Dictionary:
	var faction_id := "faction.roadwardens"
	var delta := 0
	if outcome == "completed":
		delta = 8
	elif outcome == "failed":
		delta = -8
	elif outcome == "horse_escape":
		faction_id = "faction.free_herd"
		delta = 5
	var reputation := change_reputation(faction_id, delta)
	var flag_id := "flag.%s.%s" % [quest_id.replace(".", "_"), outcome]
	set_flag(flag_id, true)
	return {
		"quest_id": quest_id,
		"outcome": outcome,
		"faction_id": faction_id,
		"reputation": reputation,
		"flag_id": flag_id,
	}


func export_state() -> Dictionary:
	return {
		"reputations": reputations.duplicate(true),
		"region_control": region_control.duplicate(true),
		"faction_flags": faction_flags.duplicate(true),
	}


func import_state(state: Dictionary) -> void:
	reputations = _dictionary_or_empty(state.get("reputations", state))
	region_control = _dictionary_or_empty(state.get("region_control", {}))
	faction_flags = _dictionary_or_empty(state.get("faction_flags", state.get("flags", {})))


func _dictionary_or_empty(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}
