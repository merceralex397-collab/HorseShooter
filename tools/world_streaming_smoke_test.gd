extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	if not world.has_method("get_streaming_state"):
		_fail("World lacks streaming state reporting.")
		return
	var state: Dictionary = world.call("get_streaming_state")
	if String(state.get("active_region", "")) != "region.greenbarrow":
		_fail("Initial active region should be Greenbarrow.")
		return
	if not state.get("cached_regions", []).has("region.greenbarrow"):
		_fail("Active region is not cached.")
		return
	if not state.get("cached_regions", []).has("region.gallowpine"):
		_fail("Adjacent Gallowpine region was not preloaded.")
		return
	if not state.get("cached_regions", []).has("region.pale_spur"):
		_fail("Adjacent Pale Spur region was not preloaded.")
		return
	if int(state.get("cache_size", 0)) > int(state.get("max_streamed_regions", 0)):
		_fail("Streaming cache exceeded configured budget.")
		return

	world.call("load_region", "region.saltwake")
	await get_tree().process_frame
	var saltwake_state: Dictionary = world.call("get_streaming_state")
	if String(saltwake_state.get("active_region", "")) != "region.saltwake":
		_fail("Active region did not update after loading Saltwake.")
		return
	if not saltwake_state.get("cached_regions", []).has("region.gallowpine"):
		_fail("Saltwake did not preload Gallowpine route neighbor.")
		return
	if not saltwake_state.get("cached_regions", []).has("region.cinderjaw"):
		_fail("Saltwake did not preload Cinderjaw route neighbor.")
		return

	print("WORLD_STREAMING_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("WORLD_STREAMING: " + message)
	get_tree().quit(1)
