extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	if str(world.get("current_region_id")) != "region.greenbarrow":
		push_error("WORLD_VERTICAL: Expected Greenbarrow current region.")
		get_tree().quit(1)
		return

	var locations = world.call("get_location_ids")
	for required_id in [
		"location.greenbarrow.camp_site",
		"location.greenbarrow.road",
		"location.greenbarrow.ruined_farm",
		"location.greenbarrow.forest_edge",
		"location.greenbarrow.toll_mare_arena",
	]:
		if not locations.has(required_id):
			push_error("WORLD_VERTICAL: Missing location " + required_id)
			get_tree().quit(1)
			return

	var protagonist = world.get_node_or_null("Player")
	if protagonist == null:
		push_error("WORLD_VERTICAL: Player node missing.")
		get_tree().quit(1)
		return
	if not bool(protagonist.get("is_female")) or not bool(protagonist.get("has_long_dark_brown_hair")):
		push_error("WORLD_VERTICAL: Protagonist identity placeholder does not meet requirements.")
		get_tree().quit(1)
		return
	if not protagonist.has_method("get_bark"):
		push_error("WORLD_VERTICAL: Protagonist bark method missing.")
		get_tree().quit(1)
		return
	var bark := String(protagonist.call("get_bark", "horse_seen"))
	if not bark.to_lower().contains("horse") or not _contains_profanity(bark):
		push_error("WORLD_VERTICAL: Bark must hate horses with profanity. Got: " + bark)
		get_tree().quit(1)
		return

	var counts: Dictionary = world.call("get_vertical_slice_counts")
	var expected := {
		"quests": 5,
		"followers": 1,
		"weapons": 12,
		"equipment": 20,
		"abilities": 10,
		"horse_archetypes": 5,
	}
	for key in expected.keys():
		if int(counts.get(key, 0)) < int(expected[key]):
			push_error("WORLD_VERTICAL: Count for %s was %s, expected at least %s" % [key, str(counts.get(key, 0)), str(expected[key])])
			get_tree().quit(1)
			return

	if not bool(world.call("has_boss", "enemy.boss.toll_mare")):
		push_error("WORLD_VERTICAL: Toll Mare boss missing.")
		get_tree().quit(1)
		return
	if not bool(world.call("has_settlement_tier", "camp")) or not bool(world.call("has_settlement_tier", "outpost")):
		push_error("WORLD_VERTICAL: Settlement camp/outpost tiers missing.")
		get_tree().quit(1)
		return

	print("WORLD_VERTICAL_SLICE_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _contains_profanity(value: String) -> bool:
	var lowered := value.to_lower()
	return lowered.contains("damn") or lowered.contains("shit") or lowered.contains("bastard")
