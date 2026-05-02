extends Node

const WORLD_SCENE := preload("res://scenes/world/world_root.tscn")


func _ready() -> void:
	await get_tree().process_frame

	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	var required_biomes := {
		"region.greenbarrow": "grassland",
		"region.gallowpine": "forest",
		"region.frostreel": "snow",
		"region.saltwake": "coast",
		"region.blackglass": "mountain",
		"region.cinderjaw": "volcano",
		"region.pale_spur": "badlands",
		"region.withered_paddock": "corruption",
	}

	for region_id in required_biomes.keys():
		if not world.call("load_region", region_id):
			_fail("Could not load region " + region_id)
			return
		await get_tree().process_frame

		var weather: Dictionary = world.call("get_current_weather_state")
		if String(weather.get("display_name", "")).is_empty():
			_fail("Missing weather display name for " + region_id)
			return
		if String(weather.get("biome", "")) != String(required_biomes[region_id]):
			_fail("Weather biome mismatch for " + region_id)
			return
		var modifiers: Dictionary = world.call("get_active_encounter_modifiers")
		if float(modifiers.get("health_multiplier", 0.0)) <= 0.0 or float(modifiers.get("damage_multiplier", 0.0)) <= 0.0:
			_fail("Invalid encounter modifiers for " + region_id)
			return

	var encounter_result: Dictionary = world.call("start_horse_encounter", "enemy.horse.runner_greenbarrow")
	if not bool(encounter_result.get("ok", false)):
		_fail("Could not start weather-modified encounter.")
		return
	var telegraph: Dictionary = encounter_result.get("telegraph", {})
	if not (telegraph.get("weather_modifiers", {}) is Dictionary):
		_fail("Encounter telegraph missing weather modifiers.")
		return

	print("WORLD_WEATHER_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("WORLD_WEATHER: " + message)
	get_tree().quit(1)
