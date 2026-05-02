extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var save_manager := get_node_or_null("/root/SaveManager")
	var quest_manager := get_node_or_null("/root/QuestManager")
	var inventory_manager := get_node_or_null("/root/InventoryManager")
	var progression_manager := get_node_or_null("/root/ProgressionManager")
	var follower_manager := get_node_or_null("/root/FollowerManager")
	var settlement_manager := get_node_or_null("/root/SettlementManager")
	var faction_manager := get_node_or_null("/root/FactionManager")
	var combat_director := get_node_or_null("/root/CombatDirector")
	if save_manager == null or quest_manager == null or inventory_manager == null or progression_manager == null or follower_manager == null or settlement_manager == null or faction_manager == null or combat_director == null:
		_fail("Required RPG autoload managers are missing.")
		return

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	save_manager.call("create_new_game", "state_roundtrip_test", "Mara")
	quest_manager.call("start_quest", "quest.greenbarrow.road_full_of_hooves")
	quest_manager.call("advance_objective", "quest.greenbarrow.road_full_of_hooves", "reach_road")
	inventory_manager.call("add_item", "weapon.greenbarrow.roadwarden_pistol", 1)
	inventory_manager.call("equip_item", "weapon", "weapon.greenbarrow.roadwarden_pistol")
	inventory_manager.call("add_ammo", "standard", 12)
	progression_manager.call("grant_xp", 240)
	progression_manager.call("unlock_ability", "ability.greenbarrow.profane_focus")
	follower_manager.call("recruit", "follower.greenbarrow.first_scout")
	follower_manager.call("assign_job", "follower.greenbarrow.first_scout", "scout")
	settlement_manager.call("found", "Spitehold")
	settlement_manager.call("add_resource", "timber", 50)
	settlement_manager.call("build", "settlement.building.watchtower_wood", "camp")
	faction_manager.call("change_reputation", "faction.roadwardens", 11)
	combat_director.call("register_enemy_escape", "enemy.horse.runner_greenbarrow", "region.greenbarrow")
	world.call("discover_location", "location.greenbarrow.sableford_town")

	var captured: Dictionary = save_manager.call("capture_release_state", world)
	if not _captured_has_expected_state(captured):
		_fail("Captured release state is incomplete.")
		return

	quest_manager.set("active_quests", {})
	inventory_manager.set("items", {})
	progression_manager.set("unlocked_abilities", {})
	follower_manager.set("followers", {})
	settlement_manager.set("founded", false)
	faction_manager.set("reputations", {})
	combat_director.set("regional_threat", {})
	world.set("discovered_locations", {})

	if not bool(save_manager.call("apply_release_state", captured, world)):
		_fail("Applying captured release state failed.")
		return
	if not quest_manager.call("is_objective_complete", "quest.greenbarrow.road_full_of_hooves", "reach_road"):
		_fail("Quest state did not round-trip.")
		return
	if String(inventory_manager.call("get_equipped", "weapon")) != "weapon.greenbarrow.roadwarden_pistol":
		_fail("Inventory state did not round-trip.")
		return
	if not progression_manager.call("has_ability", "ability.greenbarrow.profane_focus"):
		_fail("Progression state did not round-trip.")
		return
	if follower_manager.call("get_follower_state", "follower.greenbarrow.first_scout").is_empty():
		_fail("Follower state did not round-trip.")
		return
	if not bool(settlement_manager.get("founded")):
		_fail("Settlement state did not round-trip.")
		return
	if int(faction_manager.call("get_reputation", "faction.roadwardens")) != 11:
		_fail("Faction state did not round-trip.")
		return
	if int(combat_director.get("regional_threat").get("region.greenbarrow", 0)) < 1:
		_fail("Combat director state did not round-trip.")
		return
	if not world.call("is_location_discovered", "location.greenbarrow.sableford_town"):
		_fail("World state did not round-trip.")
		return

	save_manager.call("delete_slot", "state_roundtrip_test")
	print("SAVE_STATE_ROUNDTRIP_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _captured_has_expected_state(captured: Dictionary) -> bool:
	return captured.has("quests") \
		and captured.has("inventory") \
		and captured.has("progression") \
		and captured.has("followers") \
		and captured.has("settlement") \
		and captured.has("factions") \
		and captured.has("combat") \
		and captured.has("world")


func _fail(message: String) -> void:
	push_error("SAVE_STATE_ROUNDTRIP: " + message)
	get_tree().quit(1)
