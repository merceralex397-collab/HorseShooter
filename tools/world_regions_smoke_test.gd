extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	var required_regions := [
		"region.greenbarrow",
		"region.gallowpine",
		"region.frostreel",
		"region.saltwake",
		"region.blackglass",
		"region.cinderjaw",
		"region.pale_spur",
		"region.withered_paddock",
	]
	var regions: Dictionary = world.get("regions")
	for region_id in required_regions:
		if not regions.has(region_id):
			_fail("Missing region " + region_id)
			return
		var region: Dictionary = regions[region_id]
		if region.get("locations", []).size() < 2:
			_fail("Region has too few locations: " + region_id)
			return
		if not world.call("load_region", region_id):
			_fail("Could not load region " + region_id)
			return
		await get_tree().process_frame
		var ids: Array = world.call("get_location_ids")
		if ids.is_empty():
			_fail("Loaded region has no location ids: " + region_id)
			return

	var required_bosses := [
		"enemy.boss.toll_mare",
		"enemy.boss.whiteout_stallion",
		"enemy.boss.reef_kelpie",
		"enemy.boss.glassback_colossus",
		"enemy.boss.cinder_mare",
		"enemy.boss.pale_herd_king",
		"enemy.boss.last_horse",
	]
	for boss_id in required_bosses:
		if not bool(world.call("has_boss", boss_id)):
			_fail("Missing boss " + boss_id)
			return

	print("WORLD_REGIONS_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("WORLD_REGIONS: " + message)
	get_tree().quit(1)
