extends Node

const PlayerScript := preload("res://src/player/rpg_player_controller.gd")
const HorseEncounterScript := preload("res://src/combat/horse_encounter.gd")


func _ready() -> void:
	await get_tree().process_frame

	var weapon_cases := [
		{"weapon": "weapon.greenbarrow.roadwarden_pistol", "family": "pistol", "direction": Vector2.LEFT, "min_damage": 8},
		{"weapon": "weapon.greenbarrow.mare_spite_revolver", "family": "revolver", "direction": Vector2.LEFT, "min_damage": 10},
		{"weapon": "weapon.greenbarrow.haymaker_shotgun", "family": "shotgun", "direction": Vector2.LEFT, "min_damage": 12, "status": "stagger"},
		{"weapon": "weapon.greenbarrow.fencepost_rifle", "family": "rifle", "direction": Vector2.LEFT, "min_damage": 14},
		{"weapon": "weapon.greenbarrow.angry_lantern", "family": "experimental", "direction": Vector2.LEFT, "min_damage": 6, "status": "burning"},
		{"weapon": "weapon.greenbarrow.stablebreaker", "family": "hand_cannon", "direction": Vector2.LEFT, "min_damage": 18, "status": "stagger"},
	]
	var enemy_roles := ["runner", "charger", "spitter", "pack_leader", "armored", "boss"]

	for weapon_case in weapon_cases:
		var player := PlayerScript.new()
		add_child(player)
		player.equip_weapon(str(weapon_case["weapon"]))
		var shot: Dictionary = player.fire_weapon(weapon_case["direction"])
		var profile: Dictionary = player.get_combat_state().get("weapon_profile", {})
		if str(profile.get("family", "")) != str(weapon_case["family"]):
			_fail("Wrong weapon family for " + str(weapon_case["weapon"]))
			return
		if float(shot.get("range", 0.0)) <= 0.0 or int(shot.get("projectile_count", 0)) <= 0:
			_fail("Shot profile lacks range/projectile data for " + str(weapon_case["weapon"]))
			return
		if weapon_case.has("status") and not shot.get("status_effects", []).has(str(weapon_case["status"])):
			_fail("Shot missing expected status for " + str(weapon_case["weapon"]))
			return
		for role in enemy_roles:
			var encounter := HorseEncounterScript.new()
			add_child(encounter)
			encounter.setup({
				"id": "enemy.matrix." + str(role),
				"name": str(role).capitalize() + " Matrix Horse",
				"enemy_role": str(role),
				"health": 140 if role != "boss" else 520,
				"phases": ["approach", "recover"] if role != "boss" else ["charge", "summon", "road_smash"],
			})
			var result: Dictionary = encounter.resolve_shot(shot)
			if not bool(result.get("ok", false)):
				_fail("Matrix shot failed for " + str(weapon_case["weapon"]) + " vs " + str(role))
				return
			if int(result.get("damage", 0)) < int(weapon_case["min_damage"]) and role != "armored":
				_fail("Matrix damage too low for " + str(weapon_case["weapon"]) + " vs " + str(role))
				return
			var telegraph: Dictionary = result.get("next_telegraph", {})
			if str(telegraph.get("tell", "")).is_empty() or str(telegraph.get("weakpoint", "")).is_empty():
				_fail("Telegraph lacks tell/weakpoint for " + str(role))
				return
			encounter.queue_free()
		player.stamina = player.max_stamina
		if not player.dodge():
			_fail("Player dodge should succeed with full stamina.")
			return
		if player.stamina >= player.max_stamina:
			_fail("Dodge did not spend stamina.")
			return
		player.queue_free()

	print("COMBAT_MATRIX_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("COMBAT_MATRIX: " + message)
	get_tree().quit(1)
