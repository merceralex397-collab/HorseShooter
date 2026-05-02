extends Node

var level := 1
var xp := 0
var unlocked_abilities := {}


func grant_xp(amount: int) -> void:
	xp += max(amount, 0)
	level = 1 + int(xp / 100)


func unlock_ability(ability_id: String) -> void:
	unlocked_abilities[ability_id] = true


func has_ability(ability_id: String) -> bool:
	return bool(unlocked_abilities.get(ability_id, false))


func export_state() -> Dictionary:
	return {
		"level": level,
		"xp": xp,
		"unlocked_abilities": unlocked_abilities.duplicate(true),
	}


func import_state(state: Dictionary) -> void:
	level = maxi(1, int(state.get("level", 1)))
	xp = maxi(0, int(state.get("xp", 0)))
	if state.get("unlocked_abilities", {}) is Dictionary:
		unlocked_abilities = (state.get("unlocked_abilities", {}) as Dictionary).duplicate(true)
	elif state.get("abilities", []) is Array:
		unlocked_abilities = {}
		for ability_id in state.get("abilities", []):
			unlocked_abilities[String(ability_id)] = true
	else:
		unlocked_abilities = {}
