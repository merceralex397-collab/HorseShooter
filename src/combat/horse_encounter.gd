class_name HorseEncounter
extends Node

var enemy_id := ""
var display_name := ""
var region_id := ""
var role := "runner"
var max_health := 30
var health := 30
var phase_index := 0
var phases: Array[String] = ["approach", "recover"]
var telegraph := "approach"
var defeated := false
var escaped := false
var status_effects := {}
var armor := 0
var resistances := {}
var encounter_modifiers := {}
var base_damage := 0


func setup(enemy_record: Dictionary) -> void:
	enemy_id = String(enemy_record.get("id", ""))
	display_name = String(enemy_record.get("name", enemy_record.get("display_name", enemy_id)))
	region_id = String(enemy_record.get("region_id", "region.greenbarrow"))
	role = String(enemy_record.get("role", enemy_record.get("enemy_role", "runner")))
	max_health = int(enemy_record.get("health", _default_health_for_role(role)))
	health = max_health
	armor = int(enemy_record.get("armor", _default_armor_for_role(role)))
	base_damage = int(enemy_record.get("damage", _default_damage_for_role(role)))
	resistances = enemy_record.get("resistances", {})
	phases = _typed_phase_array(enemy_record.get("phases", _default_phases_for_role(role)))
	phase_index = 0
	telegraph = phases[phase_index] if not phases.is_empty() else "approach"
	defeated = false
	escaped = false
	encounter_modifiers = {}


func apply_encounter_modifiers(modifiers: Dictionary) -> void:
	encounter_modifiers = modifiers.duplicate(true)
	var health_multiplier := maxf(float(encounter_modifiers.get("health_multiplier", 1.0)), 0.1)
	max_health = maxi(1, roundi(float(max_health) * health_multiplier))
	health = max_health
	base_damage = maxi(1, roundi(float(base_damage) * maxf(float(encounter_modifiers.get("damage_multiplier", 1.0)), 0.1)))


func preview_telegraph() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"phase": get_current_phase(),
		"tell": _tell_for_phase(get_current_phase()),
		"weakpoint": _weakpoint_for_phase(get_current_phase()),
		"weather_modifiers": encounter_modifiers.duplicate(true),
	}


func resolve_shot(shot: Dictionary) -> Dictionary:
	if defeated or escaped:
		return {"ok": false, "reason": "encounter_closed"}

	var base_damage := int(shot.get("damage", 1))
	var direction: Vector2 = shot.get("direction", Vector2.RIGHT)
	var weakpoint: Vector2 = _weakpoint_for_phase(get_current_phase())
	var alignment: float = maxf(direction.normalized().dot(weakpoint), 0.0) + float(encounter_modifiers.get("weakpoint_window_bonus", 0.0))
	var quality := "glancing"
	var multiplier := 0.45
	if alignment >= 0.9:
		quality = "weakpoint"
		multiplier = 1.45
	elif alignment >= 0.45:
		quality = "solid"
		multiplier = 1.0

	var damage_type := String(shot.get("damage_type", "physical"))
	var resistance := float(resistances.get(damage_type, 0.0))
	var damage: int = maxi(1, roundi(base_damage * multiplier * (1.0 - resistance)) - armor)
	health = max(health - damage, 0)
	for status_effect in shot.get("status_effects", []):
		apply_status(String(status_effect), 6.0)
	if health == 0:
		defeated = true
	else:
		_advance_phase()

	return {
		"ok": true,
		"quality": quality,
		"damage": damage,
		"remaining_health": health,
		"status_effects": status_effects.duplicate(true),
		"defeated": defeated,
		"next_telegraph": preview_telegraph(),
	}


func apply_status(status_id: String, duration: float) -> void:
	if status_id.strip_edges().is_empty():
		return
	status_effects[status_id] = max(float(status_effects.get(status_id, 0.0)), duration)


func tick_status(delta: float) -> void:
	for status_id in status_effects.keys():
		status_effects[status_id] = float(status_effects[status_id]) - delta
		if float(status_effects[status_id]) <= 0.0:
			status_effects.erase(status_id)


func force_escape() -> Dictionary:
	if defeated:
		return {"ok": false, "reason": "already_defeated"}
	escaped = true
	var combat_director: Node = get_node_or_null("/root/CombatDirector")
	var consequence: Dictionary = {}
	if combat_director:
		consequence = combat_director.call("register_enemy_escape", enemy_id, region_id)
	if not consequence.has("regional_threat_delta"):
		consequence["regional_threat_delta"] = 0
	consequence["regional_threat_delta"] = int(consequence.get("regional_threat_delta", 0)) + int(encounter_modifiers.get("escape_pressure_delta", 0))
	return {
		"ok": true,
		"escaped": true,
		"consequence": consequence,
	}


func get_current_phase() -> String:
	if phases.is_empty():
		return "approach"
	return phases[clamp(phase_index, 0, phases.size() - 1)]


func _advance_phase() -> void:
	if phases.is_empty():
		return
	phase_index = (phase_index + 1) % phases.size()
	telegraph = phases[phase_index]


func _typed_phase_array(value: Variant) -> Array[String]:
	var typed: Array[String] = []
	if value is Array:
		for entry in value:
			typed.append(String(entry))
	if typed.is_empty():
		typed = ["approach", "recover"]
	return typed


func _default_health_for_role(enemy_role: String) -> int:
	match enemy_role:
		"charger":
			return 44
		"spitter":
			return 32
		"pack_leader":
			return 70
		"armored":
			return 88
		"boss":
			return 420
		_:
			return 26


func _default_armor_for_role(enemy_role: String) -> int:
	match enemy_role:
		"armored":
			return 5
		"boss":
			return 8
		"charger":
			return 2
		_:
			return 0


func _default_damage_for_role(enemy_role: String) -> int:
	match enemy_role:
		"charger":
			return 14
		"spitter":
			return 11
		"pack_leader":
			return 16
		"armored":
			return 12
		"boss":
			return 28
		_:
			return 8


func _default_phases_for_role(enemy_role: String) -> Array[String]:
	match enemy_role:
		"charger":
			return ["hoof_scrape", "charge", "recover"]
		"spitter":
			return ["rear_back", "spit", "skitter"]
		"pack_leader":
			return ["call_pack", "flank", "recover"]
		"armored":
			return ["brace", "turn_plate", "stagger"]
		"boss":
			return ["charge", "summon", "road_smash"]
		_:
			return ["approach", "sidestep", "recover"]


func _tell_for_phase(phase: String) -> String:
	match phase:
		"charge", "hoof_scrape":
			return "front hooves dig in before a straight rush"
		"summon", "call_pack":
			return "head rises and the arena answers"
		"road_smash":
			return "whole body turns broadside before impact"
		"spit", "rear_back":
			return "neck snaps back before mud launches"
		_:
			return "movement slows for a readable shot window"


func _weakpoint_for_phase(phase: String) -> Vector2:
	match phase:
		"charge", "hoof_scrape", "approach":
			return Vector2.LEFT
		"summon", "call_pack", "rear_back":
			return Vector2.UP
		"road_smash", "turn_plate":
			return Vector2.RIGHT
		"spit", "skitter":
			return Vector2.DOWN
		_:
			return Vector2.LEFT
