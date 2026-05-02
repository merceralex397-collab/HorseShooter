extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame
	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	world.discover_location("location.greenbarrow.road")
	world.clear_encounter("encounter.greenbarrow.road_raid")
	world.set_region_threat("region.greenbarrow", 3)
	if not world.is_location_discovered("location.greenbarrow.road"):
		_fail("Location discovery did not persist in world state.")
		return
	if not world.is_encounter_cleared("encounter.greenbarrow.road_raid"):
		_fail("Cleared encounter did not persist in world state.")
		return
	if world.get_region_threat("region.greenbarrow") != 3:
		_fail("Region threat did not persist.")
		return

	var map_state: Dictionary = world.get_world_map_state()
	if not map_state.get("markers", []).has("location.greenbarrow.road"):
		_fail("World map did not expose discovered marker.")
		return
	if map_state.get("fogged_regions", []).has("region.greenbarrow"):
		_fail("Current region should not be fogged after discovery.")
		return

	if not world.fast_travel_to("location.greenbarrow.camp_site"):
		_fail("Fast travel to discovered safe location failed.")
		return
	if not world.load_region("region.gallowpine"):
		_fail("Loading secondary region failed.")
		return
	if str(world.get("current_region_id")) != "region.gallowpine":
		_fail("Current region did not update after load_region.")
		return

	print("WORLD_STATE_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("WORLD_STATE: " + message)
	get_tree().quit(1)
