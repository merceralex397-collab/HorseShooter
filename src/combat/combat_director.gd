extends Node

var regional_threat := {}


func register_enemy_escape(enemy_id: String, region_id: String) -> Dictionary:
	var threat_delta := 1
	if enemy_id.contains("boss"):
		threat_delta = 5
	regional_threat[region_id] = int(regional_threat.get(region_id, 0)) + threat_delta
	return {
		"enemy_id": enemy_id,
		"region_id": region_id,
		"regional_threat_delta": threat_delta,
		"quest_hook": "hunt_escapee",
	}


func register_enemy_defeated(enemy_id: String, region_id: String) -> Dictionary:
	regional_threat[region_id] = max(0, int(regional_threat.get(region_id, 0)) - 1)
	return {
		"enemy_id": enemy_id,
		"region_id": region_id,
		"regional_threat_delta": -1,
	}


func export_state() -> Dictionary:
	return {
		"regional_threat": regional_threat.duplicate(true),
	}


func import_state(state: Dictionary) -> void:
	if state.get("regional_threat", {}) is Dictionary:
		regional_threat = (state.get("regional_threat", {}) as Dictionary).duplicate(true)
	elif state is Dictionary:
		regional_threat = state.duplicate(true)
	else:
		regional_threat = {}
