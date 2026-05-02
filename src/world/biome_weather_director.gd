class_name BiomeWeatherDirector
extends Node

var low_end_mode := false

var _profiles := {}


func _ready() -> void:
	_profiles = _make_profiles()


func set_low_end_mode(enabled: bool) -> void:
	low_end_mode = enabled


func is_low_end_mode() -> bool:
	if low_end_mode:
		return true
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_method("get_setting"):
		return bool(save_manager.call("get_setting", "low_end_graphics", false)) or bool(save_manager.call("get_setting", "reduced_effects", false))
	return false


func apply_profile_to_region(region: Dictionary) -> Dictionary:
	var region_copy := region.duplicate(true)
	var biome := String(region_copy.get("biome", "grassland"))
	var profile := get_profile_for_biome(biome)
	profile["region_id"] = String(region_copy.get("id", ""))
	profile["region_name"] = String(region_copy.get("display_name", ""))
	region_copy["weather_profile"] = profile
	region_copy["encounter_modifiers"] = profile.get("encounter_modifiers", {}).duplicate(true)
	region_copy["visual_directives"] = profile.get("visual_directives", {}).duplicate(true)
	return region_copy


func get_profile_for_biome(biome: String) -> Dictionary:
	if _profiles.is_empty():
		_profiles = _make_profiles()
	var profile: Dictionary = _profiles.get(biome, _profiles.get("grassland", {})).duplicate(true)
	if is_low_end_mode():
		profile["quality_mode"] = "low_end"
		profile["particle_budget"] = 0
		profile["overlay_intensity"] = float(profile.get("overlay_intensity", 0.0)) * 0.35
		var directives: Dictionary = profile.get("visual_directives", {}).duplicate(true)
		directives["animated_overlays"] = false
		directives["distortion"] = false
		directives["extra_decals"] = false
		profile["visual_directives"] = directives
	else:
		profile["quality_mode"] = "standard"
	return profile


func get_encounter_modifiers_for_biome(biome: String, regional_threat := 0) -> Dictionary:
	var profile := get_profile_for_biome(biome)
	var modifiers: Dictionary = profile.get("encounter_modifiers", {}).duplicate(true)
	var threat_scale := clampf(float(regional_threat) / 100.0, 0.0, 0.65)
	modifiers["health_multiplier"] = float(modifiers.get("health_multiplier", 1.0)) + threat_scale * 0.22
	modifiers["damage_multiplier"] = float(modifiers.get("damage_multiplier", 1.0)) + threat_scale * 0.18
	modifiers["escape_pressure_delta"] = int(modifiers.get("escape_pressure_delta", 0)) + int(round(threat_scale * 4.0))
	return modifiers


func summarize_profile(profile: Dictionary) -> Dictionary:
	return {
		"biome": String(profile.get("biome", "")),
		"weather": String(profile.get("weather", "")),
		"display_name": String(profile.get("display_name", "")),
		"quality_mode": String(profile.get("quality_mode", "")),
		"particle_budget": int(profile.get("particle_budget", 0)),
		"overlay_intensity": float(profile.get("overlay_intensity", 0.0)),
		"encounter_modifiers": profile.get("encounter_modifiers", {}).duplicate(true),
	}


func _make_profiles() -> Dictionary:
	return {
		"grassland": _profile(
			"grassland",
			"Hoof-Dust Crosswind",
			"dust_crosswind",
			Color(0.76, 0.62, 0.36),
			0.16,
			38,
			{"health_multiplier": 1.00, "damage_multiplier": 1.00, "weakpoint_window_bonus": 0.04, "escape_pressure_delta": 1},
			{"animated_overlays": true, "distortion": false, "extra_decals": true, "ground_detail": "dry_grass_tracks"}
		),
		"forest": _profile(
			"forest",
			"Low Green Fog",
			"fog_bands",
			Color(0.34, 0.48, 0.34),
			0.24,
			52,
			{"health_multiplier": 1.06, "damage_multiplier": 1.02, "weakpoint_window_bonus": -0.03, "escape_pressure_delta": 2},
			{"animated_overlays": true, "distortion": false, "extra_decals": true, "ground_detail": "moss_tracks"}
		),
		"snow": _profile(
			"snow",
			"Whiteout Needles",
			"snow_squall",
			Color(0.74, 0.86, 0.96),
			0.22,
			62,
			{"health_multiplier": 1.02, "damage_multiplier": 1.05, "weakpoint_window_bonus": -0.02, "escape_pressure_delta": 2},
			{"animated_overlays": true, "distortion": false, "extra_decals": true, "ground_detail": "snow_crunch"}
		),
		"coast": _profile(
			"coast",
			"Salt Mist Tide",
			"salt_mist",
			Color(0.45, 0.68, 0.74),
			0.20,
			46,
			{"health_multiplier": 1.04, "damage_multiplier": 1.01, "weakpoint_window_bonus": 0.00, "escape_pressure_delta": 1},
			{"animated_overlays": true, "distortion": true, "extra_decals": true, "ground_detail": "tide_foam"}
		),
		"mountain": _profile(
			"mountain",
			"Glasswind Gusts",
			"hard_wind",
			Color(0.62, 0.62, 0.58),
			0.15,
			34,
			{"health_multiplier": 1.08, "damage_multiplier": 1.04, "weakpoint_window_bonus": -0.01, "escape_pressure_delta": 2},
			{"animated_overlays": true, "distortion": false, "extra_decals": true, "ground_detail": "scree"}
		),
		"volcano": _profile(
			"volcano",
			"Ash Heat Shimmer",
			"ash_heat",
			Color(0.96, 0.34, 0.14),
			0.28,
			70,
			{"health_multiplier": 1.10, "damage_multiplier": 1.08, "weakpoint_window_bonus": -0.02, "escape_pressure_delta": 3},
			{"animated_overlays": true, "distortion": true, "extra_decals": true, "ground_detail": "ash_embers"}
		),
		"badlands": _profile(
			"badlands",
			"Mirage Dust",
			"mirage_dust",
			Color(0.86, 0.56, 0.28),
			0.21,
			44,
			{"health_multiplier": 1.05, "damage_multiplier": 1.06, "weakpoint_window_bonus": -0.03, "escape_pressure_delta": 2},
			{"animated_overlays": true, "distortion": true, "extra_decals": true, "ground_detail": "salt_cracks"}
		),
		"corruption": _profile(
			"corruption",
			"Black Stable Veil",
			"corruption_veil",
			Color(0.58, 0.20, 0.72),
			0.34,
			58,
			{"health_multiplier": 1.15, "damage_multiplier": 1.10, "weakpoint_window_bonus": -0.04, "escape_pressure_delta": 4},
			{"animated_overlays": true, "distortion": true, "extra_decals": true, "ground_detail": "black_reins"}
		),
	}


func _profile(biome: String, display_name: String, weather: String, overlay_color: Color, overlay_intensity: float, particle_budget: int, encounter_modifiers: Dictionary, visual_directives: Dictionary) -> Dictionary:
	return {
		"biome": biome,
		"display_name": display_name,
		"weather": weather,
		"overlay_color": overlay_color,
		"overlay_intensity": overlay_intensity,
		"particle_budget": particle_budget,
		"encounter_modifiers": encounter_modifiers,
		"visual_directives": visual_directives,
	}
