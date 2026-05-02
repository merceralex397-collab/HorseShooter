extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	var camp_interactions: Array = world.call("get_available_interactions", "location.greenbarrow.camp_site")
	if camp_interactions.size() < 3:
		_fail("Expected camp site to expose multiple interactions.")
		return

	var quest_result: Dictionary = world.call("interact_with", "interaction.greenbarrow.roadwarden")
	if not bool(quest_result.get("started_quest", false)):
		_fail("Roadwarden interaction did not start a quest.")
		return
	var quest_manager := get_node_or_null("/root/QuestManager")
	var inventory_manager := get_node_or_null("/root/InventoryManager")
	var follower_manager := get_node_or_null("/root/FollowerManager")
	var settlement_manager := get_node_or_null("/root/SettlementManager")
	if quest_manager == null or not quest_manager.get("active_quests").has("quest.greenbarrow.road_full_of_hooves"):
		_fail("QuestManager did not receive the road quest.")
		return

	var loot_result: Dictionary = world.call("interact_with", "interaction.greenbarrow.supply_cache")
	if String(loot_result.get("reward_item", "")) != "weapon.greenbarrow.roadwarden_pistol":
		_fail("Supply cache did not grant the starter pistol.")
		return
	if inventory_manager == null or not inventory_manager.get("items").has("weapon.greenbarrow.roadwarden_pistol"):
		_fail("InventoryManager did not receive the starter pistol.")
		return
	if String(inventory_manager.call("get_equipped", "weapon")) != "weapon.greenbarrow.roadwarden_pistol":
		_fail("Starter pistol was not equipped.")
		return

	var follower_result: Dictionary = world.call("interact_with", "interaction.greenbarrow.first_scout")
	if not bool(follower_result.get("recruited", false)):
		_fail("Follower interaction did not recruit.")
		return
	if follower_manager == null or not follower_manager.get("followers").has("follower.greenbarrow.first_scout"):
		_fail("FollowerManager did not register the first scout.")
		return

	var settlement_result: Dictionary = world.call("interact_with", "interaction.greenbarrow.found_spitehold")
	if not bool(settlement_result.get("settlement_founded", false)):
		_fail("Settlement founding interaction failed.")
		return
	if settlement_manager == null or not bool(settlement_manager.get("founded")) or String(settlement_manager.get("tier")) != "camp":
		_fail("SettlementManager did not found camp tier.")
		return

	var route_result: Dictionary = world.call("interact_with", "interaction.route.greenbarrow.forest_edge")
	if String(route_result.get("loaded_region", "")) != "region.gallowpine":
		_fail("Route gate did not load Gallowpine.")
		return
	if String(world.get("current_region_id")) != "region.gallowpine":
		_fail("World did not switch current region through route gate.")
		return
	if not bool(world.call("is_location_discovered", "location.gallowpine.entry")):
		_fail("Route target was not discovered for arrival travel.")
		return

	var player = world.get_node("Player")
	var first_shot: Dictionary = player.call("fire_weapon", Vector2.LEFT)
	var second_shot: Dictionary = player.call("fire_weapon", Vector2.DOWN)
	var first_direction: Vector2 = first_shot.get("direction", Vector2.ZERO)
	var second_direction: Vector2 = second_shot.get("direction", Vector2.ZERO)
	if first_direction.dot(Vector2.LEFT) < 0.99:
		_fail("Player did not fire left.")
		return
	if second_direction.dot(Vector2.DOWN) < 0.99:
		_fail("Player did not fire down.")
		return

	print("WORLD_INTERACTION_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("WORLD_INTERACTION: " + message)
	get_tree().quit(1)
