extends Node


func _ready() -> void:
	var packed := load("res://scenes/world/world_root.tscn") as PackedScene
	if packed == null:
		_fail("world_root scene missing")
		return

	var world := packed.instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame

	var chunk = world.get("region_chunk")
	if chunk == null or not chunk.has_method("get_visual_quality_report"):
		_fail("region chunk visual report missing")
		return

	var report: Dictionary = chunk.call("get_visual_quality_report")
	if not _assert_at_least(report, "world_width", 6000):
		return
	if not _assert_at_least(report, "world_height", 4300):
		return
	if not _assert_at_least(report, "visible_people", 180):
		return
	if not _assert_at_least(report, "visible_horses", 80):
		return
	if not _assert_at_least(report, "visible_interactions", 12):
		return
	if not _assert_at_least(report, "settlement_locations", 14):
		return
	if not _assert_at_least(report, "exploration_locations", 12):
		return
	if not _assert_at_least(report, "horse_locations", 8):
		return

	var nearby: Array = world.call("get_nearby_interactions", 130.0)
	if nearby.is_empty():
		_fail("player spawn has no visible nearby interaction")
		return
	var interaction_result: Dictionary = world.call("perform_nearest_interaction", 130.0)
	if not bool(interaction_result.get("ok", false)):
		_fail("nearest spawn interaction failed: " + str(interaction_result))
		return

	for action in ["interact", "dodge", "open_map", "open_inventory", "shoot"]:
		if InputMap.action_get_events(action).is_empty():
			_fail("input action has no bindings: " + action)
			return

	print("VISIBLE_WORLD_REGRESSION_SMOKE_STATUS: PASS")
	get_tree().quit()


func _assert_at_least(report: Dictionary, key: String, expected: int) -> bool:
	var actual := int(report.get(key, 0))
	if actual < expected:
		_fail("%s expected >= %s, got %s in %s" % [key, expected, actual, str(report)])
		return false
	return true


func _fail(message: String) -> void:
	push_error("VISIBLE_WORLD_REGRESSION_SMOKE_STATUS: FAIL - " + message)
	get_tree().quit(1)
