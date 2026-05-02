extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	var chunk = world.get("region_chunk")
	if chunk == null or not chunk.has_method("get_visual_quality_report"):
		_fail("Region chunk lacks visual quality reporting.")
		return
	var report: Dictionary = chunk.call("get_visual_quality_report")
	if int(report.get("location_count", 0)) < 5:
		_fail("World visual has too few locations.")
		return
	if int(report.get("label_count", 0)) < int(report.get("location_count", 0)):
		_fail("World locations are not labelled.")
		return
	if int(report.get("prop_count", 0)) < 12:
		_fail("World terrain has too few props/details.")
		return
	if not bool(report.get("has_weather_overlay", false)):
		_fail("World visual is missing biome weather overlay data.")
		return
	if not bool(report.get("has_extra_decals", false)):
		_fail("World visual is missing biome decal directives.")
		return
	var player = world.get_node_or_null("Player")
	if player == null or player.get_node_or_null("ReadablePlayerVisual/LongDarkBrownHair") == null:
		_fail("Readable player visual or long dark brown hair node missing.")
		return

	print("WORLD_VISUAL_QUALITY_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("WORLD_VISUAL_QUALITY: " + message)
	get_tree().quit(1)
