extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	var overlay = world.get_node_or_null("RpgOverlay")
	if overlay == null:
		_fail("RPG overlay missing from world.")
		return

	overlay.call("show_map")
	var map_state: Dictionary = overlay.call("get_panel_state")
	if String(map_state.get("active_panel", "")) != "map" or not bool(map_state.get("visible", false)):
		_fail("Map panel did not open.")
		return
	if not String(map_state.get("body", "")).contains("Greenbarrow Grasslands"):
		_fail("Map panel did not include readable Greenbarrow state.")
		return
	if String(map_state.get("body", "")).contains("region.greenbarrow") or String(map_state.get("body", "")).contains("[\""):
		_fail("Map panel is dumping raw debug IDs instead of formatted map copy.")
		return
	var toolbar_actions: Array = map_state.get("toolbar_actions", [])
	if toolbar_actions.has("Town"):
		_fail("Town should not be a persistent toolbar button.")
		return

	world.call("interact_with", "interaction.greenbarrow.roadwarden")
	overlay.call("show_journal")
	var journal_state: Dictionary = overlay.call("get_panel_state")
	if not String(journal_state.get("body", "")).contains("Road Full Of Hooves"):
		_fail("Journal panel did not show active quest.")
		return

	world.call("interact_with", "interaction.greenbarrow.supply_cache")
	overlay.call("show_inventory")
	var inventory_state: Dictionary = overlay.call("get_panel_state")
	if not String(inventory_state.get("body", "")).contains("Roadwarden Pistol"):
		_fail("Inventory panel did not show starter pistol.")
		return

	print("RPG_OVERLAY_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("RPG_OVERLAY: " + message)
	get_tree().quit(1)
