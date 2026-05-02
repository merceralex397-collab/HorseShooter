extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	var player = world.get_node_or_null("Player")
	var chunk = world.get("region_chunk")
	if player == null or chunk == null:
		_fail("World did not spawn a player and region chunk.")
		return

	var target_position: Vector2 = chunk.call("get_location_position", "location.greenbarrow.sunk_stable")
	if target_position == Vector2.ZERO:
		_fail("Could not find the test horse site.")
		return
	player.global_position = target_position + Vector2(-80.0, 0.0)
	if player.has_method("set_aim_direction"):
		player.call("set_aim_direction", Vector2.RIGHT)

	var feedback: Dictionary = world.call("shoot_weapon", Vector2.RIGHT)
	if not bool(feedback.get("ok", false)):
		_fail("World shoot action failed.")
		return
	if player.get("shots_fired").size() < 1:
		_fail("Player did not record a shot.")
		return
	if int(feedback.get("tracer_count", 0)) < 1:
		_fail("Shot did not create visible tracer feedback.")
		return
	var combat: Dictionary = feedback.get("combat", {})
	if not bool(combat.get("ok", false)):
		_fail("Shot near a horse site did not resolve against a combat encounter.")
		return

	var overlay = world.get("overlay")
	if overlay == null or not overlay.has_method("get_panel_state"):
		_fail("Overlay is missing after shooting.")
		return
	var panel_state: Dictionary = overlay.call("get_panel_state")
	if String(panel_state.get("combat_feedback", "")).is_empty():
		_fail("Shooting did not surface combat feedback in the UI.")
		return

	print("RPG_SHOOTING_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("RPG_SHOOTING: " + message)
	get_tree().quit(1)
