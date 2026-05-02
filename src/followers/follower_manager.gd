extends Node

var followers := {}
var role_definitions := {
	"sniper": {"damage_bonus": 0.18, "weakpoint_bonus": 0.10, "settlement_job": "guard"},
	"medic": {"injury_recovery": 2, "morale_bonus": 2, "settlement_job": "doctor"},
	"scout": {"ambush_reduction": 0.20, "map_reveal": 1, "settlement_job": "scout"},
	"engineer": {"turret_bonus": 0.15, "build_cost_reduction": 0.12, "settlement_job": "builder"},
	"trader": {"trade_bonus": 3, "rare_goods": 1, "settlement_job": "trader"},
	"cook": {"stamina_bonus": 5, "morale_bonus": 3, "settlement_job": "cook"},
	"tracker": {"horse_tracking": 2, "boss_intel": 1, "settlement_job": "scout"},
	"explosives": {"stagger_bonus": 0.20, "trap_bonus": 0.15, "settlement_job": "guard"},
}


func recruit(follower_id: String) -> void:
	if not followers.has(follower_id):
		var role := _default_role_for_follower(follower_id)
		followers[follower_id] = {
			"role": role,
			"loyalty": 0,
			"assignment": "",
			"settlement_job": String(role_definitions.get(role, {}).get("settlement_job", "")),
			"injured": false,
			"injury_days": 0,
			"equipment": {},
			"personal_quest_id": _personal_quest_for_follower(follower_id),
			"personal_quest_started": false,
		}


func assign_to_settlement(follower_id: String, assignment: String) -> bool:
	if not followers.has(follower_id):
		return false
	followers[follower_id]["assignment"] = assignment
	var settlement_manager := get_node_or_null("/root/SettlementManager")
	if settlement_manager and settlement_manager.has_method("assign_follower"):
		settlement_manager.call("assign_follower", follower_id, assignment)
	return true


func get_assignment(follower_id: String) -> String:
	if not followers.has(follower_id):
		return ""
	return String(followers[follower_id].get("assignment", ""))


func set_loyalty(follower_id: String, value: int) -> void:
	recruit(follower_id)
	followers[follower_id]["loyalty"] = clamp(value, -100, 100)


func change_loyalty(follower_id: String, delta: int) -> void:
	recruit(follower_id)
	set_loyalty(follower_id, int(followers[follower_id].get("loyalty", 0)) + delta)


func assign_job(follower_id: String, job_id: String) -> bool:
	if not followers.has(follower_id):
		return false
	followers[follower_id]["settlement_job"] = job_id
	var settlement_manager := get_node_or_null("/root/SettlementManager")
	if settlement_manager and settlement_manager.has_method("assign_follower"):
		settlement_manager.call("assign_follower", follower_id, job_id)
	return true


func set_role(follower_id: String, role_id: String) -> bool:
	recruit(follower_id)
	if not role_definitions.has(role_id):
		return false
	followers[follower_id]["role"] = role_id
	if String(followers[follower_id].get("settlement_job", "")).is_empty():
		followers[follower_id]["settlement_job"] = String(role_definitions[role_id].get("settlement_job", ""))
	return true


func equip_follower(follower_id: String, slot: String, item_id: String) -> bool:
	recruit(follower_id)
	var equipment: Dictionary = followers[follower_id].get("equipment", {})
	equipment[slot] = item_id
	followers[follower_id]["equipment"] = equipment
	return true


func set_injury(follower_id: String, injured: bool, days := 1) -> void:
	recruit(follower_id)
	followers[follower_id]["injured"] = injured
	followers[follower_id]["injury_days"] = maxi(int(days), 0) if injured else 0


func rest_followers(days := 1) -> void:
	for follower_id in followers.keys():
		var state: Dictionary = followers[follower_id]
		var remaining: int = maxi(0, int(state.get("injury_days", 0)) - maxi(int(days), 0))
		state["injury_days"] = remaining
		state["injured"] = remaining > 0
		followers[follower_id] = state


func start_personal_quest(follower_id: String) -> String:
	recruit(follower_id)
	var quest_id := String(followers[follower_id].get("personal_quest_id", ""))
	if quest_id.is_empty():
		return ""
	followers[follower_id]["personal_quest_started"] = true
	var quest_manager := get_node_or_null("/root/QuestManager")
	if quest_manager:
		quest_manager.call("start_quest", quest_id)
	return quest_id


func get_support_modifiers() -> Dictionary:
	var modifiers := {
		"damage_bonus": 0.0,
		"weakpoint_bonus": 0.0,
		"ambush_reduction": 0.0,
		"build_cost_reduction": 0.0,
		"trade_bonus": 0,
		"morale_bonus": 0,
		"stamina_bonus": 0,
		"boss_intel": 0,
	}
	for follower_id in followers.keys():
		var state: Dictionary = followers[follower_id]
		if bool(state.get("injured", false)):
			continue
		var role := String(state.get("role", "scout"))
		var role_data: Dictionary = role_definitions.get(role, {})
		for key in role_data.keys():
			if key == "settlement_job":
				continue
			modifiers[key] = modifiers.get(key, 0) + role_data[key]
		var loyalty_scale := clampf(float(state.get("loyalty", 0)) / 100.0, -1.0, 1.0)
		modifiers["morale_bonus"] = int(modifiers.get("morale_bonus", 0)) + roundi(loyalty_scale * 2.0)
	return modifiers


func get_follower_state(follower_id: String) -> Dictionary:
	if not followers.has(follower_id):
		return {}
	return followers[follower_id].duplicate(true)


func export_state() -> Dictionary:
	return {
		"followers": followers.duplicate(true),
		"role_definitions": role_definitions.duplicate(true),
	}


func import_state(state: Dictionary) -> void:
	if state.has("followers") and state["followers"] is Dictionary:
		followers = (state["followers"] as Dictionary).duplicate(true)
	elif state is Dictionary:
		followers = state.duplicate(true)
	else:
		followers = {}
	if state.get("role_definitions", {}) is Dictionary:
		role_definitions = (state.get("role_definitions", {}) as Dictionary).duplicate(true)


func _default_role_for_follower(follower_id: String) -> String:
	if follower_id.contains("doctor") or follower_id.contains("medic"):
		return "medic"
	if follower_id.contains("trader"):
		return "trader"
	if follower_id.contains("engineer") or follower_id.contains("builder"):
		return "engineer"
	if follower_id.contains("sniper"):
		return "sniper"
	if follower_id.contains("cook"):
		return "cook"
	if follower_id.contains("tracker"):
		return "tracker"
	if follower_id.contains("explosive"):
		return "explosives"
	return "scout"


func _personal_quest_for_follower(follower_id: String) -> String:
	return "quest." + follower_id.replace("follower.", "follower_") + ".loyalty"
