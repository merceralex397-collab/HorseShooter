extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	if not world.has_method("get_world_density_report"):
		_fail("World lacks density reporting.")
		return
	var density: Dictionary = world.call("get_world_density_report")
	if int(density.get("regions", 0)) < 8:
		_fail("Expected at least 8 regions.")
		return
	if int(density.get("locations", 0)) < 120:
		_fail("Expected a dense world with 120+ authored locations.")
		return
	if int(density.get("settlements", 0)) < 40:
		_fail("Expected 40+ towns, cities, villages, forts, camps, or settlements.")
		return
	if int(density.get("dungeons", 0)) < 30:
		_fail("Expected 30+ caves, dungeons, temples, ruins, mines, shrines, or wrecks.")
		return
	if int(density.get("horse_sites", 0)) < 25:
		_fail("Expected 25+ horse lairs, stables, horse sites, or boss arenas.")
		return

	var regions: Dictionary = world.get("regions")
	for region_id in regions.keys():
		if not world.call("load_region", String(region_id)):
			_fail("Could not load dense region " + String(region_id))
			return
		await get_tree().process_frame
		var chunk = world.get("region_chunk")
		var visual: Dictionary = chunk.call("get_visual_quality_report")
		if int(visual.get("location_count", 0)) < 15:
			_fail("Loaded region is too sparse: " + String(region_id))
			return
		if int(visual.get("settlement_locations", 0)) < 4:
			_fail("Loaded region lacks towns/villages/cities: " + String(region_id))
			return
		if int(visual.get("exploration_locations", 0)) < 3:
			_fail("Loaded region lacks caves/dungeons/temples: " + String(region_id))
			return
		if int(visual.get("horse_locations", 0)) < 2:
			_fail("Loaded region lacks horse places: " + String(region_id))
			return

	print("WORLD_DENSITY_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("WORLD_DENSITY: " + message)
	get_tree().quit(1)
