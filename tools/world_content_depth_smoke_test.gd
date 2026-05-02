extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	var cave: Dictionary = world.call("enter_site", "location.greenbarrow.clatterhoof_cave")
	if not bool(cave.get("ok", false)):
		_fail("Cave site could not be entered.")
		return
	if cave.get("rooms", []).size() < 3 or cave.get("resource_nodes", []).is_empty():
		_fail("Cave instance lacks rooms/resources.")
		return
	if not cave.get("objectives", []).has("clear_horses"):
		_fail("Dangerous cave lacks clear-horses objective.")
		return

	var temple: Dictionary = world.call("enter_site", "location.greenbarrow.old_stone_temple")
	if String(temple.get("puzzle", {}).get("type", "")) != "sequence":
		_fail("Temple lacks relic puzzle.")
		return
	if temple.get("reward", {}).is_empty():
		_fail("Temple lacks reward data.")
		return

	var completion: Dictionary = world.call("complete_site_objective", String(cave.get("id", "")), "claim_cache")
	if not bool(completion.get("ok", false)):
		_fail("Site objective completion failed.")
		return

	var event: Dictionary = world.call("generate_world_event", "location.greenbarrow.trampled_orchard")
	if String(event.get("type", "")) != "horse_hunt":
		_fail("Horse site did not generate horse hunt event.")
		return
	var town_event: Dictionary = world.call("generate_world_event", "location.greenbarrow.sableford_town")
	if String(town_event.get("type", "")) != "settlement_request":
		_fail("Town did not generate settlement request event.")
		return
	if world.call("get_active_world_events").size() < 2:
		_fail("Active world events were not retained.")
		return

	var exported: Dictionary = world.call("export_state")
	var restored := WORLD_SCENE.instantiate()
	add_child(restored)
	await get_tree().process_frame
	restored.call("import_state", exported)
	if restored.call("get_active_world_events").is_empty():
		_fail("World events did not round-trip through world state.")
		return

	print("WORLD_CONTENT_DEPTH_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("WORLD_CONTENT_DEPTH: " + message)
	get_tree().quit(1)
