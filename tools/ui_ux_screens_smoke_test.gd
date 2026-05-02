extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var inventory_manager := get_node_or_null("/root/InventoryManager")
	var progression_manager := get_node_or_null("/root/ProgressionManager")
	var follower_manager := get_node_or_null("/root/FollowerManager")
	if inventory_manager == null or progression_manager == null or follower_manager == null:
		_fail("Required UI managers missing.")
		return
	inventory_manager.call("add_item", "weapon.greenbarrow.roadwarden_pistol", 1)
	inventory_manager.call("equip_item", "weapon", "weapon.greenbarrow.roadwarden_pistol")
	inventory_manager.call("add_material", "material.ore", 4)
	progression_manager.call("grant_xp", 120)
	progression_manager.call("unlock_ability", "ability.greenbarrow.profane_focus")
	follower_manager.call("recruit", "follower.greenbarrow.first_scout")

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame
	world.call("start_horse_encounter", "enemy.boss.toll_mare")
	var overlay = world.get("overlay")
	var screens := {
		"show_equipment": "Equipment",
		"show_abilities": "Abilities",
		"show_followers": "Followers",
		"show_crafting": "Crafting",
		"show_codex": "Codex",
		"show_boss_intro": "Boss",
		"show_death_retry": "Retry",
	}
	for method_name in screens.keys():
		if not overlay.has_method(method_name):
			_fail("Overlay missing screen method " + String(method_name))
			return
		overlay.call(method_name)
		var state: Dictionary = overlay.call("get_panel_state")
		if String(state.get("title", "")) != String(screens[method_name]):
			_fail("Wrong panel title for " + String(method_name))
			return
		if String(state.get("body", "")).length() < 12:
			_fail("Panel body too thin for " + String(method_name))
			return

	print("UI_UX_SCREENS_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("UI_UX_SCREENS: " + message)
	get_tree().quit(1)
