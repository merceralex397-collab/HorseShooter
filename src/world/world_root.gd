extends Node2D

const RegionChunkScript := preload("res://src/world/region_chunk.gd")
const PlayerControllerScript := preload("res://src/player/rpg_player_controller.gd")
const RpgOverlayScript := preload("res://src/ui/rpg_overlay.gd")
const HorseEncounterScript := preload("res://src/combat/horse_encounter.gd")
const BiomeWeatherDirectorScript := preload("res://src/world/biome_weather_director.gd")

var current_region_id := "region.greenbarrow"
var current_region: Dictionary = {}
var regions := {}
var discovered_locations := {}
var cleared_encounters := {}
var regional_threat := {}
var safe_fast_travel_locations := {}
var streamed_region_cache := {}
var stream_graph := {}
var completed_site_instances := {}
var active_world_events: Array[Dictionary] = []
var max_streamed_regions := 5
var player: CharacterBody2D
var camera: Camera2D
var region_chunk: Node2D
var overlay: CanvasLayer
var biome_weather_director: Node
var shot_effect_layer: Node2D
var last_shot_feedback := {}
var last_combat_log: Array[String] = []

var quests: Array[Dictionary] = []
var followers: Array[Dictionary] = []
var weapons: Array[Dictionary] = []
var equipment: Array[Dictionary] = []
var abilities: Array[Dictionary] = []
var horse_archetypes: Array[Dictionary] = []
var bosses: Array[Dictionary] = []
var settlement_tiers: Array[String] = []
var interactions := {}
var active_encounter: Node
var current_location_id := ""


func _ready() -> void:
	_load_vertical_slice_data()
	_build_world()
	set_process(true)


func _process(delta: float) -> void:
	_update_player_aim_from_pointer()
	_update_camera(delta)
	_update_location_discovery()


func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return
	if event.is_action_pressed("shoot"):
		shoot_weapon()
	elif event.is_action_pressed("dodge") and player.has_method("dodge"):
		player.call("dodge")
	elif event.is_action_pressed("interact"):
		var result := perform_nearest_interaction(130.0)
		if bool(result.get("settlement_founded", false)) and overlay and overlay.has_method("show_settlement"):
			overlay.call("show_settlement")
		elif bool(result.get("dialogue_started", false)) and overlay and overlay.has_method("show_dialogue"):
			overlay.call("show_dialogue")
	elif event.is_action_pressed("open_map"):
		_toggle_overlay_panel("map")
	elif event.is_action_pressed("open_inventory"):
		_toggle_overlay_panel("inventory")
	elif event.is_action_pressed("pause") and overlay:
		overlay.call("hide_panel")


func get_location_ids() -> Array[String]:
	if region_chunk and region_chunk.has_method("get_location_ids"):
		return region_chunk.get_location_ids()
	return []


func get_vertical_slice_counts() -> Dictionary:
	return {
		"quests": quests.size(),
		"followers": followers.size(),
		"weapons": weapons.size(),
		"equipment": equipment.size(),
		"abilities": abilities.size(),
		"horse_archetypes": horse_archetypes.size(),
		"regions": regions.size(),
		"locations": _count_all_locations(),
		"settlements": _count_all_locations_of_types(["camp", "village", "town", "city", "settlement", "harbor", "fort"]),
		"exploration_sites": _count_all_locations_of_types(["cave", "dungeon", "temple", "mine", "ruin", "wreck", "shrine", "volcano"]),
		"horse_sites": _count_all_locations_of_types(["horse_site", "horse_lair", "stable_fort", "boss"]),
	}


func has_boss(content_id: String) -> bool:
	for boss in bosses:
		if String(boss.get("id", "")) == content_id:
			return true
	return false


func has_settlement_tier(tier: String) -> bool:
	return settlement_tiers.has(tier)


func start_horse_encounter(enemy_id: String) -> Dictionary:
	var enemy_record := _find_enemy(enemy_id)
	if enemy_record.is_empty():
		return {"ok": false, "reason": "missing_enemy"}
	if active_encounter:
		active_encounter.queue_free()
	active_encounter = HorseEncounterScript.new()
	active_encounter.name = "ActiveHorseEncounter"
	add_child(active_encounter)
	active_encounter.call("setup", enemy_record)
	if active_encounter.has_method("apply_encounter_modifiers"):
		active_encounter.call("apply_encounter_modifiers", get_active_encounter_modifiers())
	last_combat_log.append("Encounter started: " + String(enemy_record.get("name", enemy_id)))
	return {
		"ok": true,
		"enemy_id": enemy_id,
		"telegraph": active_encounter.call("preview_telegraph"),
	}


func fire_at_active_encounter(direction := Vector2.ZERO) -> Dictionary:
	if player == null or active_encounter == null:
		return {"ok": false, "reason": "missing_player_or_encounter"}
	var shot: Dictionary = player.call("fire_weapon", direction)
	var result: Dictionary = active_encounter.call("resolve_shot", shot)
	if bool(result.get("defeated", false)):
		var defeated_id := String(active_encounter.get("enemy_id"))
		clear_encounter(defeated_id)
		var combat_director := get_node_or_null("/root/CombatDirector")
		if combat_director:
			combat_director.call("register_enemy_defeated", defeated_id, current_region_id)
		active_encounter.queue_free()
		active_encounter = null
		if defeated_id == "enemy.boss.toll_mare":
			var quest_manager := get_node_or_null("/root/QuestManager")
			if quest_manager:
				quest_manager.call("start_quest", "quest.greenbarrow.toll_mare_hunt")
				quest_manager.call("complete_quest", "quest.greenbarrow.toll_mare_hunt")
	return result


func shoot_weapon(direction := Vector2.ZERO) -> Dictionary:
	if player == null or not player.has_method("fire_weapon"):
		return {"ok": false, "reason": "missing_player"}
	var resolved_direction := direction
	if resolved_direction.length() <= 0.05 and player.has_method("get_shot_direction"):
		resolved_direction = player.call("get_shot_direction")
	var shot: Dictionary = player.call("fire_weapon", resolved_direction)
	_spawn_shot_feedback(shot)
	var combat_result := _resolve_shot_against_world(shot)
	last_shot_feedback = {
		"ok": true,
		"shot": shot,
		"combat": combat_result,
		"tracer_count": shot_effect_layer.get_child_count() if shot_effect_layer else 0,
	}
	if overlay and overlay.has_method("set_combat_feedback"):
		overlay.call("set_combat_feedback", last_shot_feedback)
	return last_shot_feedback.duplicate(true)


func get_last_shot_feedback() -> Dictionary:
	return last_shot_feedback.duplicate(true)


func get_world_density_report() -> Dictionary:
	var site_type_counts := {}
	var safe_locations := 0
	var settlement_count := 0
	var dungeon_count := 0
	var horse_site_count := 0
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		for location in region.get("locations", []):
			if not (location is Dictionary):
				continue
			var location_type := String(location.get("type", "landmark"))
			site_type_counts[location_type] = int(site_type_counts.get(location_type, 0)) + 1
			if bool(location.get("safe_fast_travel", false)):
				safe_locations += 1
			if ["camp", "village", "town", "city", "settlement", "harbor", "fort"].has(location_type):
				settlement_count += 1
			if ["cave", "dungeon", "temple", "mine", "ruin", "wreck", "shrine", "volcano"].has(location_type):
				dungeon_count += 1
			if ["horse_site", "horse_lair", "stable_fort", "boss"].has(location_type):
				horse_site_count += 1
	return {
		"regions": regions.size(),
		"locations": _count_all_locations(),
		"safe_locations": safe_locations,
		"settlements": settlement_count,
		"dungeons": dungeon_count,
		"horse_sites": horse_site_count,
		"types": site_type_counts,
	}


func enter_site(location_id: String) -> Dictionary:
	var location := _find_location(location_id)
	if location.is_empty():
		return {"ok": false, "reason": "missing_location"}
	var location_type := String(location.get("type", "landmark"))
	if not ["cave", "dungeon", "temple", "mine", "ruin", "wreck", "shrine", "volcano", "stable_fort", "horse_lair"].has(location_type):
		return {"ok": false, "reason": "not_enterable"}
	var instance := _build_site_instance(location)
	var instance_id := String(instance.get("id", location_id + ".instance"))
	if bool(completed_site_instances.get(instance_id, false)):
		instance["completed"] = true
	return instance


func complete_site_objective(instance_id: String, objective_id: String) -> Dictionary:
	if instance_id.is_empty() or objective_id.is_empty():
		return {"ok": false, "reason": "missing_instance_or_objective"}
	completed_site_instances[instance_id + "." + objective_id] = true
	if objective_id == "clear_horses":
		clear_encounter(instance_id)
	if objective_id == "claim_cache":
		var inventory_manager := get_node_or_null("/root/InventoryManager")
		if inventory_manager:
			inventory_manager.call("add_material", "material.ore", 3)
			inventory_manager.call("add_ammo", "standard", 8)
	return {"ok": true, "instance_id": instance_id, "objective_id": objective_id}


func generate_world_event(seed_location_id := "") -> Dictionary:
	var source_location := _find_location(seed_location_id)
	if source_location.is_empty():
		var current_locations: Array = current_region.get("locations", [])
		if current_locations.is_empty():
			return {"ok": false, "reason": "no_locations"}
		source_location = current_locations[active_world_events.size() % current_locations.size()]
	var location_id := String(source_location.get("id", ""))
	var event_type := "road_ambush"
	var location_type := String(source_location.get("type", ""))
	if ["cave", "dungeon", "temple", "mine", "ruin", "wreck", "shrine"].has(location_type):
		event_type = "site_cache"
	elif ["village", "town", "city", "settlement", "fort"].has(location_type):
		event_type = "settlement_request"
	elif ["horse_site", "horse_lair", "stable_fort", "boss"].has(location_type):
		event_type = "horse_hunt"
	var event := {
		"id": "event." + location_id.replace("location.", "") + "." + str(active_world_events.size() + 1),
		"type": event_type,
		"location_id": location_id,
		"region_id": _region_id_for_location(location_id),
		"threat": get_region_threat(current_region_id),
		"reward": _event_reward(event_type),
		"expires_after_days": 3 + active_world_events.size() % 4,
	}
	active_world_events.append(event)
	return event.duplicate(true)


func get_active_world_events() -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for event in active_world_events:
		copy.append(event.duplicate(true))
	return copy


func get_streaming_state() -> Dictionary:
	return {
		"active_region": current_region_id,
		"cached_regions": streamed_region_cache.keys(),
		"adjacent_regions": stream_graph.get(current_region_id, []).duplicate(true) if stream_graph.get(current_region_id, []) is Array else [],
		"cache_size": streamed_region_cache.size(),
		"max_streamed_regions": max_streamed_regions,
	}


func force_active_encounter_escape() -> Dictionary:
	if active_encounter == null:
		return {"ok": false, "reason": "missing_encounter"}
	var result: Dictionary = active_encounter.call("force_escape")
	if bool(result.get("escaped", false)):
		var consequence: Dictionary = result.get("consequence", {})
		set_region_threat(current_region_id, get_region_threat(current_region_id) + int(consequence.get("regional_threat_delta", 0)))
	return result


func get_available_interactions(location_id: String) -> Array:
	var available: Array = []
	for interaction_id in interactions.keys():
		var interaction: Dictionary = interactions[interaction_id]
		if String(interaction.get("location_id", "")) == location_id and not bool(interaction.get("consumed", false)):
			available.append(interaction.duplicate(true))
	return available


func get_nearby_interactions(max_distance := 110.0) -> Array:
	if player == null:
		return []
	var nearby: Array = []
	for interaction_id in interactions.keys():
		var interaction: Dictionary = interactions[interaction_id]
		if bool(interaction.get("consumed", false)):
			continue
		var interaction_position := _interaction_position(interaction_id, interaction)
		if interaction_position == Vector2.ZERO:
			continue
		var distance := player.global_position.distance_to(interaction_position)
		if distance <= max_distance:
			var copy := interaction.duplicate(true)
			copy["distance"] = distance
			copy["position"] = {"x": interaction_position.x, "y": interaction_position.y}
			nearby.append(copy)
	return nearby


func perform_nearest_interaction(max_distance := 110.0) -> Dictionary:
	var nearby := get_nearby_interactions(max_distance)
	if nearby.is_empty():
		return {"ok": false, "reason": "no_nearby_interaction"}
	nearby.sort_custom(func(a: Dictionary, b: Dictionary): return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0)))
	return interact_with(String(nearby[0].get("id", "")))


func interact_with(interaction_id: String) -> Dictionary:
	if not interactions.has(interaction_id):
		return {"ok": false, "reason": "missing_interaction"}
	var interaction: Dictionary = interactions[interaction_id]
	if bool(interaction.get("consumed", false)):
		return {"ok": false, "reason": "consumed"}

	var result := {"ok": true, "interaction_id": interaction_id, "type": String(interaction.get("type", ""))}
	var quest_manager := get_node_or_null("/root/QuestManager")
	var inventory_manager := get_node_or_null("/root/InventoryManager")
	var follower_manager := get_node_or_null("/root/FollowerManager")
	var settlement_manager := get_node_or_null("/root/SettlementManager")
	match String(interaction.get("type", "")):
		"quest_giver":
			var quest_id := String(interaction.get("quest_id", ""))
			if quest_manager:
				quest_manager.call("start_quest", quest_id)
			var dialogue_manager := get_node_or_null("/root/DialogueManager")
			if dialogue_manager and dialogue_manager.has_method("start_conversation"):
				dialogue_manager.call("start_conversation", {
					"id": "dialogue." + interaction_id,
					"speaker": String(interaction.get("display_name", "Roadwarden")),
					"portrait_id": "portrait.roadwarden",
					"lines": [
						String(interaction.get("dialogue", "Take the job, {player_name}. The horses made this road hell.")),
						"{player_name}: Fine. I will shoot the damn horses and try to enjoy myself.",
					],
					"choices": [
						{"id": "accept", "text": "Accept the work.", "quest_id": quest_id, "complete_objective": "accepted", "set_flags": ["dialogue.accepted_" + quest_id.replace(".", "_")]},
						{"id": "ask_horses", "text": "Ask why it is always horses.", "set_flags": ["dialogue.asked_horse_problem"], "closes": false},
					],
				})
			result["started_quest"] = true
			result["quest_id"] = quest_id
			result["dialogue_started"] = dialogue_manager != null
		"loot":
			var item_id := String(interaction.get("item_id", ""))
			var count := int(interaction.get("count", 1))
			if inventory_manager:
				inventory_manager.call("add_item", item_id, count)
				if item_id.begins_with("weapon."):
					inventory_manager.call("equip_item", "weapon", item_id)
					if inventory_manager.has_method("add_ammo"):
						inventory_manager.call("add_ammo", "standard", 36)
						inventory_manager.call("add_ammo", "shell", 12)
						inventory_manager.call("add_ammo", "rifle", 18)
					if player and player.has_method("equip_weapon"):
						player.call("equip_weapon", item_id)
			interaction["consumed"] = true
			result["reward_item"] = item_id
			result["count"] = count
		"follower":
			var follower_id := String(interaction.get("follower_id", ""))
			if follower_manager:
				follower_manager.call("recruit", follower_id)
			interaction["consumed"] = true
			result["recruited"] = true
			result["follower_id"] = follower_id
		"settlement":
			var settlement_name := String(interaction.get("settlement_name", ""))
			if settlement_manager:
				settlement_manager.call("found", settlement_name)
				settlement_manager.call("add_resource", "timber", 25)
				settlement_manager.call("add_resource", "food", 18)
			if quest_manager:
				quest_manager.call("start_quest", "quest.greenbarrow.found_spitehold")
				quest_manager.call("advance_objective", "quest.greenbarrow.found_spitehold", "found_camp")
			result["settlement_founded"] = true
			result["settlement_name"] = settlement_name
		"boss_gate":
			result["boss_id"] = String(interaction.get("boss_id", ""))
			result["bark"] = player.call("get_bark", "boss_intro") if player and player.has_method("get_bark") else ""
			var boss_id := String(interaction.get("boss_id", ""))
			if not boss_id.is_empty():
				result["encounter"] = start_horse_encounter(boss_id)
		"region_gate":
			var target_region := String(interaction.get("target_region_id", ""))
			var target_location := String(interaction.get("target_location_id", ""))
			if not target_region.is_empty() and load_region(target_region):
				if not target_location.is_empty():
					discover_location(target_location)
					fast_travel_to(target_location)
				result["loaded_region"] = target_region
				result["target_location"] = target_location
				_autosave_release_state("region_travel:" + target_region)
			else:
				result["ok"] = false
				result["reason"] = "region_unavailable"
		"horse_site":
			var enemy_id := String(interaction.get("enemy_id", ""))
			if enemy_id.is_empty():
				enemy_id = _enemy_for_location_id(String(interaction.get("location_id", "")))
			result["encounter"] = start_horse_encounter(enemy_id)
		_:
			result["ok"] = false
			result["reason"] = "unsupported_interaction"
	interactions[interaction_id] = interaction
	if bool(result.get("ok", false)):
		_autosave_release_state("interaction:" + interaction_id)
	return result


func discover_location(location_id: String) -> void:
	discovered_locations[location_id] = true
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		for location in region.get("locations", []):
			if location is Dictionary and String(location.get("id", "")) == location_id and bool(location.get("safe_fast_travel", false)):
				safe_fast_travel_locations[location_id] = true


func is_location_discovered(location_id: String) -> bool:
	return bool(discovered_locations.get(location_id, false))


func clear_encounter(encounter_id: String) -> void:
	cleared_encounters[encounter_id] = true


func is_encounter_cleared(encounter_id: String) -> bool:
	return bool(cleared_encounters.get(encounter_id, false))


func set_region_threat(region_id: String, value: int) -> void:
	regional_threat[region_id] = max(value, 0)


func get_region_threat(region_id: String) -> int:
	return int(regional_threat.get(region_id, 0))


func get_world_map_state() -> Dictionary:
	var fogged_regions: Array[String] = []
	for region_id in regions.keys():
		if region_id != current_region_id and not _has_discovered_location_in_region(region_id):
			fogged_regions.append(region_id)
	return {
		"current_region": current_region_id,
		"markers": discovered_locations.keys(),
		"fogged_regions": fogged_regions,
		"regional_threat": regional_threat.duplicate(true),
	}


func export_state() -> Dictionary:
	return {
		"current_region_id": current_region_id,
		"current_region": current_region_id,
		"discovered_locations": discovered_locations.duplicate(true),
		"cleared_encounters": cleared_encounters.duplicate(true),
		"regional_threat": regional_threat.duplicate(true),
		"safe_fast_travel_locations": safe_fast_travel_locations.duplicate(true),
		"completed_site_instances": completed_site_instances.duplicate(true),
		"active_world_events": get_active_world_events(),
		"current_location_id": current_location_id,
		"player_position": _vector_to_dict(player.global_position) if player else {"x": 0.0, "y": 0.0},
	}


func import_state(state: Dictionary) -> void:
	discovered_locations = _dictionary_or_empty(state.get("discovered_locations", {}))
	cleared_encounters = _dictionary_or_empty(state.get("cleared_encounters", {}))
	regional_threat = _dictionary_or_empty(state.get("regional_threat", {}))
	safe_fast_travel_locations = _dictionary_or_empty(state.get("safe_fast_travel_locations", {}))
	completed_site_instances = _dictionary_or_empty(state.get("completed_site_instances", {}))
	active_world_events = []
	if state.get("active_world_events", []) is Array:
		for event in state.get("active_world_events", []):
			if event is Dictionary:
				active_world_events.append(event.duplicate(true))
	current_location_id = String(state.get("current_location_id", ""))
	var target_region := String(state.get("current_region_id", state.get("current_region", current_region_id)))
	if regions.has(target_region):
		load_region(target_region)
	if player and state.get("player_position", {}) is Dictionary:
		player.global_position = _vector_from_dict(state.get("player_position", {}))
		_apply_world_bounds()


func get_current_weather_state() -> Dictionary:
	var profile: Dictionary = current_region.get("weather_profile", {})
	if biome_weather_director and biome_weather_director.has_method("summarize_profile"):
		return biome_weather_director.call("summarize_profile", profile)
	return profile.duplicate(true)


func get_player_combat_state() -> Dictionary:
	if player and player.has_method("get_combat_state"):
		var state: Dictionary = player.call("get_combat_state")
		var inventory_manager := get_node_or_null("/root/InventoryManager")
		if inventory_manager:
			state["ammo"] = inventory_manager.get("ammo").duplicate(true)
			state["weapon_heat"] = inventory_manager.get("weapon_heat").duplicate(true)
		return state
	return {}


func get_active_encounter_modifiers() -> Dictionary:
	var biome := String(current_region.get("biome", "grassland"))
	if biome_weather_director and biome_weather_director.has_method("get_encounter_modifiers_for_biome"):
		return biome_weather_director.call("get_encounter_modifiers_for_biome", biome, get_region_threat(current_region_id))
	return current_region.get("encounter_modifiers", {}).duplicate(true)


func fast_travel_to(location_id: String) -> bool:
	if not bool(safe_fast_travel_locations.get(location_id, false)):
		return false
	var location := _find_location(location_id)
	if location.is_empty() or player == null:
		return false
	var position_dict := location.get("position", {}) as Dictionary
	player.global_position = Vector2(float(position_dict.get("x", 0.0)), float(position_dict.get("y", 0.0)))
	return true


func load_region(region_id: String) -> bool:
	if not regions.has(region_id):
		return false
	current_region_id = region_id
	current_region = regions[region_id]
	if biome_weather_director:
		biome_weather_director.call("set_low_end_mode", bool(_read_setting("low_end_graphics", false)) or bool(_read_setting("reduced_effects", false)))
		current_region = biome_weather_director.call("apply_profile_to_region", current_region)
	if region_chunk:
		remove_child(region_chunk)
		region_chunk.free()
	region_chunk = RegionChunkScript.new()
	region_chunk.name = String(region_id).replace(".", "_") + "_Chunk"
	add_child(region_chunk)
	region_chunk.setup(current_region, _current_region_interactions())
	if player:
		move_child(region_chunk, 0)
		player.global_position = region_chunk.call("get_spawn_position")
	_apply_world_bounds()
	if overlay and overlay.has_method("bind_world"):
		overlay.call("bind_world", self)
	_refresh_streamed_regions()
	return true


func _build_world() -> void:
	biome_weather_director = BiomeWeatherDirectorScript.new()
	biome_weather_director.name = "BiomeWeatherDirector"
	add_child(biome_weather_director)

	player = PlayerControllerScript.new()
	player.name = "Player"
	add_child(player)

	shot_effect_layer = Node2D.new()
	shot_effect_layer.name = "ShotEffects"
	add_child(shot_effect_layer)

	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)

	overlay = RpgOverlayScript.new()
	overlay.name = "RpgOverlay"
	add_child(overlay)

	load_region(current_region_id)
	if overlay.has_method("bind_world"):
		overlay.call("bind_world", self)


func _load_vertical_slice_data() -> void:
	regions = {}
	regions["region.greenbarrow"] = _make_greenbarrow_region()
	regions["region.gallowpine"] = _make_region("region.gallowpine", "Gallowpine Forest", "forest", _regional_location_specs("gallowpine"))
	regions["region.frostreel"] = _make_region("region.frostreel", "Frostreel Snowfields", "snow", _regional_location_specs("frostreel"))
	regions["region.saltwake"] = _make_region("region.saltwake", "Saltwake Coast", "coast", _regional_location_specs("saltwake"))
	regions["region.blackglass"] = _make_region("region.blackglass", "Blackglass Mountains", "mountain", _regional_location_specs("blackglass"))
	regions["region.cinderjaw"] = _make_region("region.cinderjaw", "Cinderjaw Volcanic Belt", "volcano", _regional_location_specs("cinderjaw"))
	regions["region.pale_spur"] = _make_region("region.pale_spur", "Pale Spur Badlands", "badlands", _regional_location_specs("pale_spur"))
	regions["region.withered_paddock"] = _make_region("region.withered_paddock", "Withered Paddock", "corruption", _regional_location_specs("withered_paddock"))
	current_region = regions[current_region_id]
	discover_location("location.greenbarrow.camp_site")
	quests = [
		{"id": "quest.greenbarrow.road_full_of_hooves", "name": "The Road Is Full of Hooves"},
		{"id": "quest.greenbarrow.found_spitehold", "name": "Found Spitehold"},
		{"id": "quest.greenbarrow.ruined_farm", "name": "The Farm They Trampled"},
		{"id": "quest.greenbarrow.first_follower", "name": "A Sensible Person With a Rifle"},
		{"id": "quest.greenbarrow.toll_mare_hunt", "name": "The Toll Mare"},
	]
	followers = [
		{"id": "follower.greenbarrow.first_scout", "name": "First Scout", "role": "scout"},
	]
	weapons = _make_numbered_records("weapon.greenbarrow", [
		"rusty_oath", "roadwarden_pistol", "mare_spite_revolver", "haymaker_shotgun",
		"fencepost_rifle", "stablebreaker", "brass_barker", "saltlock_carbine",
		"hoofsplitter", "angry_lantern", "toll_knife", "field_cannon",
	])
	equipment = _make_numbered_records("equipment.greenbarrow", [
		"travel_coat", "dark_hair_ribbon", "road_boots", "powder_gloves", "spite_belt",
		"field_charm", "patched_hat", "iron_clasp", "wanderer_scarf", "farmguard_vest",
		"ash_lined_coat", "quickdraw_wrap", "bitter_locket", "map_case", "ammo_sash",
		"watcher_badge", "thorn_spurs", "rain_cape", "camp_banner", "settler_gloves",
	])
	abilities = _make_numbered_records("ability.greenbarrow", [
		"quick_curse", "steady_hands", "horse_tracker", "roll_clear", "reload_spite",
		"camp_commander", "weakpoint_glare", "field_mender", "road_runner", "profane_focus",
	])
	horse_archetypes = [
		{"id": "enemy.horse.runner_greenbarrow", "name": "Grassland Runner"},
		{"id": "enemy.horse.charger_greenbarrow", "name": "Fence Charger"},
		{"id": "enemy.horse.spitter_greenbarrow", "name": "Mud Spitter"},
		{"id": "enemy.horse.pack_leader_greenbarrow", "name": "Road Pack Leader"},
		{"id": "enemy.horse.armored_greenbarrow", "name": "Tack-Armored Nag"},
	]
	bosses = [
		{"id": "enemy.boss.toll_mare", "name": "The Toll Mare", "phases": ["charge", "summon", "road_smash"]},
		{"id": "enemy.boss.whiteout_stallion", "name": "Whiteout Stallion", "region_id": "region.frostreel", "role": "boss", "health": 520, "phases": ["vanish", "ice_charge", "blizzard"]},
		{"id": "enemy.boss.reef_kelpie", "name": "Reef Kelpie", "region_id": "region.saltwake", "role": "boss", "health": 560, "phases": ["undertow", "wave_charge", "foam_split"]},
		{"id": "enemy.boss.glassback_colossus", "name": "Glassback Colossus", "region_id": "region.blackglass", "role": "boss", "health": 640, "phases": ["plate_turn", "rockfall", "peak_charge"]},
		{"id": "enemy.boss.cinder_mare", "name": "Cinder Mare", "region_id": "region.cinderjaw", "role": "boss", "health": 700, "phases": ["ember_kick", "lava_wake", "caldera_scream"]},
		{"id": "enemy.boss.pale_herd_king", "name": "Pale Herd King", "region_id": "region.pale_spur", "role": "boss", "health": 760, "phases": ["mirage", "dust_wall", "bone_charge"]},
		{"id": "enemy.boss.last_horse", "name": "The Last Horse", "region_id": "region.withered_paddock", "role": "boss", "health": 980, "phases": ["hatefield", "world_trample", "final_curse"]},
	]
	settlement_tiers = ["camp", "outpost"]
	interactions = {
		"interaction.greenbarrow.roadwarden": {
			"id": "interaction.greenbarrow.roadwarden",
			"type": "quest_giver",
			"location_id": "location.greenbarrow.camp_site",
			"display_name": "Roadwarden Mire",
			"quest_id": "quest.greenbarrow.road_full_of_hooves",
			"dialogue": "Take a pistol and clear the toll road before the damn horses own it.",
			"position": {"x": 236, "y": 206},
		},
		"interaction.greenbarrow.supply_cache": {
			"id": "interaction.greenbarrow.supply_cache",
			"type": "loot",
			"location_id": "location.greenbarrow.camp_site",
			"display_name": "Roadwarden Supply Cache",
			"item_id": "weapon.greenbarrow.roadwarden_pistol",
			"count": 1,
			"position": {"x": 350, "y": 254},
		},
		"interaction.greenbarrow.first_scout": {
			"id": "interaction.greenbarrow.first_scout",
			"type": "follower",
			"location_id": "location.greenbarrow.forest_edge",
			"display_name": "First Scout",
			"follower_id": "follower.greenbarrow.first_scout",
			"position": {"x": 1450, "y": 420},
		},
		"interaction.greenbarrow.found_spitehold": {
			"id": "interaction.greenbarrow.found_spitehold",
			"type": "settlement",
			"location_id": "location.greenbarrow.camp_site",
			"display_name": "Found Spitehold",
			"settlement_name": "Spitehold",
			"position": {"x": 264, "y": 336},
		},
		"interaction.greenbarrow.toll_mare_gate": {
			"id": "interaction.greenbarrow.toll_mare_gate",
			"type": "boss_gate",
			"location_id": "location.greenbarrow.toll_mare_arena",
			"display_name": "Challenge the Toll Mare",
			"boss_id": "enemy.boss.toll_mare",
			"position": {"x": 1880, "y": 846},
		},
	}
	_add_world_route_interactions()
	_add_horse_site_interactions()
	_build_stream_graph()


func _make_numbered_records(prefix: String, names: Array[String]) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for item_name in names:
		records.append({"id": prefix + "." + item_name, "name": item_name.capitalize()})
	return records


func _site(location_id: String, display_name: String, x: float, y: float, site_type: String, safe := false, enemy_id := "") -> Dictionary:
	var entry := {
		"id": location_id,
		"name": display_name,
		"position": {"x": x, "y": y},
		"type": site_type,
		"safe_fast_travel": safe,
	}
	if not enemy_id.is_empty():
		entry["enemy_id"] = enemy_id
	return entry


func _make_greenbarrow_region() -> Dictionary:
	var locations := [
		_site("location.greenbarrow.camp_site", "Spitehold Camp Site", 264, 244, "camp", true),
		_site("location.greenbarrow.road", "Broken Toll Road", 760, 282, "road", false, "enemy.horse.runner_greenbarrow"),
		_site("location.greenbarrow.ruined_farm", "Ruined Farm", 1096, 672, "ruin", false, "enemy.horse.charger_greenbarrow"),
		_site("location.greenbarrow.forest_edge", "Gallowpine Edge", 1460, 420, "route", true),
		_site("location.greenbarrow.toll_mare_arena", "Toll Mare Arena", 1880, 984, "boss", false, "enemy.boss.toll_mare"),
		_site("location.greenbarrow.millbrook_village", "Millbrook Village", 520, 820, "village", true),
		_site("location.greenbarrow.sableford_town", "Sableford Town", 1260, 1080, "town", true),
		_site("location.greenbarrow.old_stone_temple", "Old Stone Temple", 1720, 320, "temple", false, "enemy.horse.pack_leader_greenbarrow"),
		_site("location.greenbarrow.clatterhoof_cave", "Clatterhoof Cave", 2140, 540, "cave", false, "enemy.horse.spitter_greenbarrow"),
		_site("location.greenbarrow.understable_dungeon", "Understable Dungeon", 1960, 1360, "dungeon", false, "enemy.horse.armored_greenbarrow"),
		_site("location.greenbarrow.hay_saint_shrine", "Hay Saint Shrine", 760, 1240, "shrine", false, "enemy.horse.pack_leader_greenbarrow"),
		_site("location.greenbarrow.wagoner_rest", "Wagoner Rest", 420, 1420, "settlement", true),
		_site("location.greenbarrow.east_watch_fort", "East Watch Fort", 2240, 1180, "fort", true),
		_site("location.greenbarrow.trampled_orchard", "Trampled Orchard", 1480, 1480, "horse_site", false, "enemy.horse.runner_greenbarrow"),
		_site("location.greenbarrow.bitterwell", "Bitterwell", 980, 420, "village", true),
		_site("location.greenbarrow.no_reins_market", "No-Reins Market", 1640, 760, "town", true),
		_site("location.greenbarrow.sunk_stable", "Sunk Stable", 580, 560, "stable_fort", false, "enemy.horse.armored_greenbarrow"),
		_site("location.greenbarrow.south_pass", "South Pass", 2320, 1560, "route", true),
		_site("location.greenbarrow.hazelgate_city", "Hazelgate City", 3180, 520, "city", true),
		_site("location.greenbarrow.lowbridge_village", "Lowbridge Village", 3560, 940, "village", true),
		_site("location.greenbarrow.marebone_catacombs", "Marebone Catacombs", 3960, 420, "dungeon", false, "enemy.horse.pack_leader_greenbarrow"),
		_site("location.greenbarrow.ashhoof_caldera", "Ash-Hoof Caldera", 4580, 620, "volcano", false, "enemy.horse.charger_greenbarrow"),
		_site("location.greenbarrow.cinder_foal_stables", "Cinder Foal Stables", 5120, 980, "stable_fort", false, "enemy.horse.armored_greenbarrow"),
		_site("location.greenbarrow.noosewater_town", "Noosewater Town", 3000, 1480, "town", true),
		_site("location.greenbarrow.wheatglass_village", "Wheatglass Village", 3620, 1640, "village", true),
		_site("location.greenbarrow.hollowsong_cave", "Hollowsong Cave", 4200, 1500, "cave", false, "enemy.horse.spitter_greenbarrow"),
		_site("location.greenbarrow.fallen_saddle_temple", "Fallen Saddle Temple", 4780, 1660, "temple", false, "enemy.horse.pack_leader_greenbarrow"),
		_site("location.greenbarrow.red_mane_run", "Red Mane Run", 5480, 1500, "horse_lair", false, "enemy.horse.runner_greenbarrow"),
		_site("location.greenbarrow.bellmare_city", "Bellmare City", 2740, 2260, "city", true),
		_site("location.greenbarrow.sourhay_hamlet", "Sourhay Hamlet", 3420, 2320, "village", true),
		_site("location.greenbarrow.buried_bridle_mine", "Buried Bridle Mine", 4020, 2440, "mine", false, "enemy.horse.charger_greenbarrow"),
		_site("location.greenbarrow.moonwater_shrine", "Moonwater Shrine", 4660, 2360, "shrine", false, "enemy.horse.pack_leader_greenbarrow"),
		_site("location.greenbarrow.cracked_rein_fort", "Cracked Rein Fort", 5360, 2360, "fort", true),
		_site("location.greenbarrow.lanternmere_village", "Lanternmere Village", 3020, 3120, "village", true),
		_site("location.greenbarrow.stonehoof_quarry", "Stonehoof Quarry", 3700, 3180, "mine", false, "enemy.horse.armored_greenbarrow"),
		_site("location.greenbarrow.cursebell_crypt", "Cursebell Crypt", 4320, 3220, "dungeon", false, "enemy.horse.pack_leader_greenbarrow"),
		_site("location.greenbarrow.wild_blood_pasture", "Wild Blood Pasture", 5060, 3160, "horse_site", false, "enemy.horse.runner_greenbarrow"),
		_site("location.greenbarrow.eastmarch_market", "Eastmarch Market", 5700, 3220, "town", true),
		_site("location.greenbarrow.blackroot_fen", "Blackroot Fen", 2900, 3880, "ruin", false, "enemy.horse.spitter_greenbarrow"),
		_site("location.greenbarrow.tallow_cave", "Tallow Cave", 3500, 3960, "cave", false, "enemy.horse.spitter_greenbarrow"),
		_site("location.greenbarrow.saintless_temple", "Saintless Temple", 4160, 3920, "temple", false, "enemy.horse.pack_leader_greenbarrow"),
		_site("location.greenbarrow.paddock_of_teeth", "Paddock of Teeth", 4860, 3980, "horse_lair", false, "enemy.horse.charger_greenbarrow"),
		_site("location.greenbarrow.needlehorse_prairie", "Needlehorse Prairie", 5240, 3660, "horse_site", false, "enemy.horse.runner_greenbarrow"),
		_site("location.greenbarrow.far_south_city", "Far South City", 5600, 4040, "city", true),
	]
	return {
		"id": "region.greenbarrow",
		"display_name": "Greenbarrow Grasslands",
		"biome": "grassland",
		"bounds": {"x": 0.0, "y": 0.0, "w": 6400.0, "h": 4600.0},
		"spawn_location_id": "location.greenbarrow.camp_site",
		"locations": locations,
		"roads": _roads_for_locations(locations),
		"settlements": _settlements_for_locations("greenbarrow", locations),
	}


func _make_region(region_id: String, display_name: String, biome: String, location_specs: Array) -> Dictionary:
	var region_locations: Array[Dictionary] = []
	for spec in location_specs:
		if spec is Dictionary:
			region_locations.append(spec.duplicate(true))
		elif spec is Array and spec.size() >= 5:
			region_locations.append(_site(String(spec[0]), String(spec[1]), float(spec[2]), float(spec[3]), String(spec[5]) if spec.size() > 5 else "landmark", bool(spec[4])))
	var slug := region_id.get_slice(".", 1)
	return {
		"id": region_id,
		"display_name": display_name,
		"biome": biome,
		"locations": region_locations,
		"bounds": {"x": 0.0, "y": 0.0, "w": 3200.0, "h": 2300.0},
		"spawn_location_id": String(region_locations[0].get("id", "")) if not region_locations.is_empty() else "",
		"roads": _roads_for_locations(region_locations),
		"settlements": _settlements_for_locations(slug, region_locations),
	}


func _regional_location_specs(slug: String) -> Array[Dictionary]:
	match slug:
		"gallowpine":
			return [
				_site("location.gallowpine.entry", "Gallowpine Gate", 220, 220, "route", true),
				_site("location.gallowpine.briarwick_village", "Briarwick Village", 560, 420, "village", true),
				_site("location.gallowpine.mosschapel", "Mosschapel Temple", 920, 250, "temple", false, "enemy.horse.pack_leader_greenbarrow"),
				_site("location.gallowpine.deep_watch", "Deep Watch Town", 1340, 520, "town", true),
				_site("location.gallowpine.rootcellar_cave", "Rootcellar Cave", 1780, 360, "cave", false, "enemy.horse.spitter_greenbarrow"),
				_site("location.gallowpine.hollow_stable", "Hollow Stable Fort", 2140, 640, "stable_fort", false, "enemy.horse.armored_greenbarrow"),
				_site("location.gallowpine.sawtooth_mill", "Sawtooth Mill", 760, 840, "settlement", true),
				_site("location.gallowpine.blackleaf_dungeon", "Blackleaf Dungeon", 1180, 1080, "dungeon", false, "enemy.horse.charger_greenbarrow"),
				_site("location.gallowpine.twigmarket", "Twigmarket", 1600, 1060, "town", true),
				_site("location.gallowpine.fog_mare_grove", "Fog Mare Grove", 2060, 1140, "horse_lair", false, "enemy.horse.runner_greenbarrow"),
				_site("location.gallowpine.northroot_city", "Northroot City", 2520, 420, "city", true),
				_site("location.gallowpine.green_crypts", "Green Crypts", 2700, 900, "dungeon", false, "enemy.horse.pack_leader_greenbarrow"),
				_site("location.gallowpine.witchlight_shrine", "Witchlight Shrine", 2260, 1500, "shrine", false, "enemy.horse.spitter_greenbarrow"),
				_site("location.gallowpine.west_horse_run", "West Horse Run", 480, 1500, "horse_site", false, "enemy.horse.runner_greenbarrow"),
				_site("location.gallowpine.nettlemere_village", "Nettlemere Village", 1280, 1620, "village", true),
				_site("location.gallowpine.saltwake_road", "Saltwake Road", 3020, 1900, "route", true),
			]
		"frostreel":
			return [
				_site("location.frostreel.sled_gate", "Sled Gate", 180, 180, "route", true),
				_site("location.frostreel.glass_lake_village", "Glass Lake Village", 520, 340, "village", true),
				_site("location.frostreel.whiteout_road", "Whiteout Road", 840, 260, "horse_site", false, "enemy.horse.runner_greenbarrow"),
				_site("location.frostreel.ice_mare_den", "Ice Mare Den", 1160, 620, "horse_lair", false, "enemy.horse.charger_greenbarrow"),
				_site("location.frostreel.frostbell_town", "Frostbell Town", 1460, 420, "town", true),
				_site("location.frostreel.blue_knife_cave", "Blue Knife Cave", 1920, 260, "cave", false, "enemy.horse.spitter_greenbarrow"),
				_site("location.frostreel.snow_temple", "Snow Temple", 2320, 560, "temple", false, "enemy.horse.pack_leader_greenbarrow"),
				_site("location.frostreel.watchpost_nine", "Watchpost Nine", 2680, 360, "fort", true),
				_site("location.frostreel.buried_sanctum", "Buried Sanctum", 840, 1060, "dungeon", false, "enemy.horse.armored_greenbarrow"),
				_site("location.frostreel.icebridge_city", "Icebridge City", 1540, 1180, "city", true),
				_site("location.frostreel.frozen_stables", "Frozen Stables", 2220, 1260, "stable_fort", false, "enemy.horse.armored_greenbarrow"),
				_site("location.frostreel.whiteout_stallion_arena", "Whiteout Stallion Arena", 2800, 1500, "boss", false, "enemy.boss.whiteout_stallion"),
				_site("location.frostreel.blackglass_pass", "Blackglass Pass", 2960, 2040, "route", true),
				_site("location.frostreel.refuge_hamlet", "Refuge Hamlet", 430, 1640, "village", true),
				_site("location.frostreel.crackling_ice_mine", "Crackling Ice Mine", 1160, 1780, "mine", false, "enemy.horse.charger_greenbarrow"),
			]
		"saltwake":
			return [
				_site("location.saltwake.harbor", "Saltwake Harbor City", 180, 240, "city", true),
				_site("location.saltwake.tideflats", "Tideflats", 520, 360, "horse_site", false, "enemy.horse.runner_greenbarrow"),
				_site("location.saltwake.shipbone_reef", "Shipbone Reef", 900, 520, "wreck", false, "enemy.horse.spitter_greenbarrow"),
				_site("location.saltwake.lighthouse", "No-Hoof Lighthouse", 1260, 180, "settlement", true),
				_site("location.saltwake.ropewalk_town", "Ropewalk Town", 1660, 420, "town", true),
				_site("location.saltwake.brine_cave", "Brine Cave", 2060, 260, "cave", false, "enemy.horse.spitter_greenbarrow"),
				_site("location.saltwake.drowned_temple", "Drowned Temple", 2460, 620, "temple", false, "enemy.horse.pack_leader_greenbarrow"),
				_site("location.saltwake.kelp_stable", "Kelp Stable", 2860, 900, "stable_fort", false, "enemy.horse.armored_greenbarrow"),
				_site("location.saltwake.oyster_village", "Oyster Village", 620, 1120, "village", true),
				_site("location.saltwake.undertow_dungeon", "Undertow Dungeon", 1080, 1340, "dungeon", false, "enemy.horse.charger_greenbarrow"),
				_site("location.saltwake.tidewarden_keep", "Tidewarden Keep", 1620, 1220, "fort", true),
				_site("location.saltwake.reef_kelpie_arena", "Reef Kelpie Arena", 2400, 1500, "boss", false, "enemy.boss.reef_kelpie"),
				_site("location.saltwake.gallowpine_road", "Gallowpine Road", 260, 1940, "route", true),
				_site("location.saltwake.cinderjaw_steamship", "Cinderjaw Steamship", 2980, 1940, "route", true),
				_site("location.saltwake.smugglers_hollow", "Smugglers Hollow", 1980, 1880, "cave", false, "enemy.horse.runner_greenbarrow"),
			]
		"blackglass":
			return [
				_site("location.blackglass.pass", "Blackglass Pass", 160, 200, "route", true),
				_site("location.blackglass.mining_lift", "Mining Lift Village", 520, 460, "village", true),
				_site("location.blackglass.avalanche_shelf", "Avalanche Shelf", 930, 300, "horse_site", false, "enemy.horse.charger_greenbarrow"),
				_site("location.blackglass.peak_fort", "Peak Fort", 1400, 170, "fort", true),
				_site("location.blackglass.ironroot_mine", "Ironroot Mine", 1780, 460, "mine", false, "enemy.horse.armored_greenbarrow"),
				_site("location.blackglass.glassback_arena", "Glassback Arena", 2480, 540, "boss", false, "enemy.boss.glassback_colossus"),
				_site("location.blackglass.bridge_town", "Bridge Town", 960, 850, "town", true),
				_site("location.blackglass.echo_cave", "Echo Cave", 560, 1160, "cave", false, "enemy.horse.spitter_greenbarrow"),
				_site("location.blackglass.deep_anvil_city", "Deep Anvil City", 1520, 1220, "city", true),
				_site("location.blackglass.ram_stables", "Ram Stables", 2140, 1200, "stable_fort", false, "enemy.horse.armored_greenbarrow"),
				_site("location.blackglass.sky_temple", "Sky Temple", 2760, 1260, "temple", false, "enemy.horse.pack_leader_greenbarrow"),
				_site("location.blackglass.frostreel_trail", "Frostreel Trail", 300, 1900, "route", true),
				_site("location.blackglass.pale_spur_switchback", "Pale Spur Switchback", 2920, 1960, "route", true),
				_site("location.blackglass.old_cavalry_tomb", "Old Cavalry Tomb", 1140, 1740, "dungeon", false, "enemy.horse.pack_leader_greenbarrow"),
				_site("location.blackglass.windmill_hamlet", "Windmill Hamlet", 2140, 1780, "village", true),
			]
		"cinderjaw":
			return [
				_site("location.cinderjaw.ash_gate", "Ash Gate", 160, 190, "route", true),
				_site("location.cinderjaw.lava_road", "Lava Road", 560, 280, "horse_site", false, "enemy.horse.charger_greenbarrow"),
				_site("location.cinderjaw.fumarole_yard", "Fumarole Yard", 920, 520, "settlement", true),
				_site("location.cinderjaw.caldera", "Caldera of Broken Reins", 1380, 360, "boss", false, "enemy.boss.cinder_mare"),
				_site("location.cinderjaw.foundry_city", "Foundry City", 1780, 580, "city", true),
				_site("location.cinderjaw.ember_cave", "Ember Cave", 2180, 320, "cave", false, "enemy.horse.spitter_greenbarrow"),
				_site("location.cinderjaw.basalt_temple", "Basalt Temple", 2640, 760, "temple", false, "enemy.horse.pack_leader_greenbarrow"),
				_site("location.cinderjaw.magma_stables", "Magma Stables", 2880, 1120, "stable_fort", false, "enemy.horse.armored_greenbarrow"),
				_site("location.cinderjaw.coalbrook_village", "Coalbrook Village", 540, 1020, "village", true),
				_site("location.cinderjaw.ashfall_town", "Ashfall Town", 1160, 1240, "town", true),
				_site("location.cinderjaw.cinder_dungeon", "Cinder Dungeon", 1880, 1380, "dungeon", false, "enemy.horse.armored_greenbarrow"),
				_site("location.cinderjaw.lava_tube_mine", "Lava Tube Mine", 2460, 1660, "mine", false, "enemy.horse.runner_greenbarrow"),
				_site("location.cinderjaw.slagwater_village", "Slagwater Village", 1760, 1840, "village", true),
				_site("location.cinderjaw.saltwake_steamship", "Saltwake Steamship", 280, 1940, "route", true),
				_site("location.cinderjaw.pale_spur_road", "Pale Spur Road", 2900, 1980, "route", true),
				_site("location.cinderjaw.red_chapel", "Red Chapel", 860, 1740, "shrine", false, "enemy.horse.pack_leader_greenbarrow"),
			]
		"pale_spur":
			return [
				_site("location.pale_spur.dust_camp", "Dust Camp", 160, 150, "camp", true),
				_site("location.pale_spur.bone_road", "Bone Road", 480, 320, "horse_site", false, "enemy.horse.runner_greenbarrow"),
				_site("location.pale_spur.sunken_corral", "Sunken Corral", 860, 480, "stable_fort", false, "enemy.horse.armored_greenbarrow"),
				_site("location.pale_spur.mirage_city", "Mirage City", 1320, 220, "city", true),
				_site("location.pale_spur.saltflat_village", "Saltflat Village", 1720, 520, "village", true),
				_site("location.pale_spur.canyon_temple", "Canyon Temple", 2160, 360, "temple", false, "enemy.horse.pack_leader_greenbarrow"),
				_site("location.pale_spur.pale_herd_arena", "Pale Herd Arena", 2660, 680, "boss", false, "enemy.boss.pale_herd_king"),
				_site("location.pale_spur.cavalry_graves", "Cavalry Graves", 540, 980, "dungeon", false, "enemy.horse.spitter_greenbarrow"),
				_site("location.pale_spur.dustbite_town", "Dustbite Town", 1040, 1180, "town", true),
				_site("location.pale_spur.salt_cave", "Salt Cave", 1580, 1320, "cave", false, "enemy.horse.charger_greenbarrow"),
				_site("location.pale_spur.sunspike_fort", "Sunspike Fort", 2180, 1280, "fort", true),
				_site("location.pale_spur.mirage_stables", "Mirage Stables", 2840, 1440, "horse_lair", false, "enemy.horse.runner_greenbarrow"),
				_site("location.pale_spur.blackglass_switchback", "Blackglass Switchback", 260, 1960, "route", true),
				_site("location.pale_spur.cinderjaw_road", "Cinderjaw Road", 1500, 2020, "route", true),
				_site("location.pale_spur.withered_threshold", "Withered Threshold", 2920, 2040, "route", true),
			]
		"withered_paddock":
			return [
				_site("location.withered_paddock.threshold", "Threshold", 160, 180, "route", true),
				_site("location.withered_paddock.black_stables", "Black Stables", 560, 340, "stable_fort", false, "enemy.horse.armored_greenbarrow"),
				_site("location.withered_paddock.hateful_field", "Hateful Field", 940, 500, "horse_site", false, "enemy.horse.runner_greenbarrow"),
				_site("location.withered_paddock.final_pasture", "Final Pasture", 1460, 260, "boss", false, "enemy.boss.last_horse"),
				_site("location.withered_paddock.crooked_city", "Crooked City", 1900, 560, "city", true),
				_site("location.withered_paddock.rein_temple", "Rein Temple", 2320, 340, "temple", false, "enemy.horse.pack_leader_greenbarrow"),
				_site("location.withered_paddock.hoof_cavern", "Hoof Cavern", 2740, 700, "cave", false, "enemy.horse.spitter_greenbarrow"),
				_site("location.withered_paddock.bridle_dungeon", "Bridle Dungeon", 720, 980, "dungeon", false, "enemy.horse.charger_greenbarrow"),
				_site("location.withered_paddock.silent_village", "Silent Village", 1240, 1120, "village", true),
				_site("location.withered_paddock.broken_saints", "Broken Saints Shrine", 1700, 1260, "shrine", false, "enemy.horse.pack_leader_greenbarrow"),
				_site("location.withered_paddock.spiral_stables", "Spiral Stables", 2280, 1340, "horse_lair", false, "enemy.horse.armored_greenbarrow"),
				_site("location.withered_paddock.no_sun_mine", "No-Sun Mine", 2780, 1560, "mine", false, "enemy.horse.spitter_greenbarrow"),
				_site("location.withered_paddock.greywell_town", "Greywell Town", 1680, 1760, "town", true),
				_site("location.withered_paddock.pale_spur_exit", "Pale Spur Exit", 280, 1960, "route", true),
				_site("location.withered_paddock.last_watch", "Last Watch Fort", 1140, 1840, "fort", true),
				_site("location.withered_paddock.crown_corral", "Crown Corral", 2440, 1980, "horse_site", false, "enemy.horse.charger_greenbarrow"),
			]
	return []


func _roads_for_locations(region_locations: Array) -> Array:
	var region_roads: Array = []
	for index in range(1, region_locations.size()):
		var previous: Dictionary = region_locations[index - 1]
		var current: Dictionary = region_locations[index]
		var from_position := previous.get("position", {}) as Dictionary
		var to_position := current.get("position", {}) as Dictionary
		var midpoint := {
			"x": (float(from_position.get("x", 0.0)) + float(to_position.get("x", 0.0))) * 0.5,
			"y": (float(from_position.get("y", 0.0)) + float(to_position.get("y", 0.0))) * 0.5 + (54.0 if index % 2 == 0 else -54.0),
		}
		region_roads.append([from_position, midpoint, to_position])
	for index in range(0, region_locations.size(), 5):
		if index + 3 >= region_locations.size():
			continue
		var a: Dictionary = region_locations[index].get("position", {})
		var b: Dictionary = region_locations[index + 3].get("position", {})
		region_roads.append([a, {"x": (float(a.get("x", 0.0)) + float(b.get("x", 0.0))) * 0.5, "y": (float(a.get("y", 0.0)) + float(b.get("y", 0.0))) * 0.5 - 90.0}, b])
	return region_roads


func _settlements_for_locations(slug: String, region_locations: Array) -> Array[Dictionary]:
	var settlement_records: Array[Dictionary] = []
	for location in region_locations:
		var location_type := String(location.get("type", ""))
		if not ["camp", "village", "town", "city", "settlement", "harbor", "fort"].has(location_type):
			continue
		var position := _location_position(location)
		var size := _settlement_size_for_type(location_type)
		var rect := Rect2(position - size * 0.5, size)
		settlement_records.append({
			"id": "settlement." + slug + "." + String(location.get("id", "")).get_slice(".", 2),
			"name": String(location.get("name", "Settlement")),
			"style": location_type,
			"gate_side": "south",
			"rect": _rect_to_dict(rect),
			"buildings": _settlement_buildings(rect, location_type),
			"props": [
				{"type": "banner", "position": {"x": rect.position.x + rect.size.x * 0.35, "y": rect.position.y + 20.0}},
				{"type": "crate_stack", "rect": {"x": rect.position.x + rect.size.x * 0.52, "y": rect.position.y + rect.size.y * 0.62, "w": 52.0, "h": 40.0}},
			],
		})
	return settlement_records


func _settlement_size_for_type(location_type: String) -> Vector2:
	match location_type:
		"city":
			return Vector2(520.0, 380.0)
		"town", "harbor":
			return Vector2(420.0, 300.0)
		"village", "fort":
			return Vector2(340.0, 250.0)
		_:
			return Vector2(280.0, 210.0)


func _settlement_buildings(rect: Rect2, location_type: String) -> Array[Dictionary]:
	var building_count := 4
	if location_type == "city":
		building_count = 12
	elif location_type == "town" or location_type == "harbor":
		building_count = 8
	elif location_type == "village" or location_type == "fort":
		building_count = 6
	var records: Array[Dictionary] = []
	var building_types := ["hall", "shack", "tent", "tower", "shack", "hall", "tower", "shack", "tent", "tower", "hall", "shack"]
	for index in range(building_count):
		var col := index % 4
		var row := int(index / 4)
		var building_size := Vector2(62.0 + float(index % 3) * 14.0, 44.0 + float(index % 2) * 18.0)
		var position := rect.position + Vector2(34.0 + float(col) * (rect.size.x - 82.0) / 4.0, 42.0 + float(row) * 82.0)
		records.append({"type": building_types[index % building_types.size()], "rect": {"x": position.x, "y": position.y, "w": building_size.x, "h": building_size.y}})
	return records


func _current_region_interactions() -> Dictionary:
	var region_interactions := {}
	for interaction_id in interactions.keys():
		var interaction: Dictionary = interactions[interaction_id]
		var location_id := String(interaction.get("location_id", ""))
		if location_id.contains(current_region_id.get_slice(".", 1)):
			region_interactions[interaction_id] = interaction.duplicate(true)
	return region_interactions


func _interaction_position(interaction_id: String, interaction: Dictionary) -> Vector2:
	if region_chunk and region_chunk.has_method("get_interaction_anchor_position"):
		var anchor_position: Vector2 = region_chunk.call("get_interaction_anchor_position", interaction_id)
		if anchor_position != Vector2.ZERO:
			return anchor_position
	if interaction.get("position", null) is Dictionary:
		return _location_position({"position": interaction.get("position", {})})
	var location := _find_location(String(interaction.get("location_id", "")))
	if location.is_empty():
		return Vector2.ZERO
	return _location_position(location)


func _apply_world_bounds() -> void:
	if camera == null or region_chunk == null or not region_chunk.has_method("get_world_bounds"):
		return
	var bounds: Rect2 = region_chunk.call("get_world_bounds")
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	if player:
		player.global_position = player.global_position.clamp(bounds.position + Vector2(28.0, 28.0), bounds.end - Vector2(28.0, 28.0))


func _update_camera(delta: float) -> void:
	if camera == null or player == null:
		return
	camera.global_position = camera.global_position.lerp(player.global_position, min(delta * 7.0, 1.0))


func _update_location_discovery() -> void:
	if player == null:
		return
	var closest_location := ""
	var closest_distance := INF
	for location in current_region.get("locations", []):
		if not (location is Dictionary):
			continue
		var location_id := String(location.get("id", ""))
		var distance := player.global_position.distance_to(_location_position(location))
		if distance < 170.0:
			discover_location(location_id)
		if distance < closest_distance:
			closest_distance = distance
			closest_location = location_id
	current_location_id = closest_location


func _toggle_overlay_panel(panel_name: String) -> void:
	if overlay == null:
		return
	if String(overlay.get("active_panel")) == panel_name:
		overlay.call("hide_panel")
		return
	match panel_name:
		"map":
			overlay.call("show_map")
		"inventory":
			overlay.call("show_inventory")
		"journal":
			overlay.call("show_journal")
		"settlement":
			overlay.call("show_settlement")
		"dialogue":
			overlay.call("show_dialogue")


func _find_location(location_id: String) -> Dictionary:
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		for location in region.get("locations", []):
			if location is Dictionary and String(location.get("id", "")) == location_id:
				return location
	return {}


func _location_position(location: Dictionary) -> Vector2:
	var raw_position = location.get("position", {})
	if raw_position is Dictionary:
		return Vector2(float(raw_position.get("x", 0.0)), float(raw_position.get("y", 0.0)))
	return Vector2.ZERO


func _find_enemy(enemy_id: String) -> Dictionary:
	for enemy in horse_archetypes:
		if String(enemy.get("id", "")) == enemy_id:
			return enemy
	for boss in bosses:
		if String(boss.get("id", "")) == enemy_id:
			return boss
	return {}


func _build_site_instance(location: Dictionary) -> Dictionary:
	var location_id := String(location.get("id", ""))
	var location_type := String(location.get("type", "site"))
	var enemy_id := String(location.get("enemy_id", _enemy_for_location_id(location_id)))
	return {
		"ok": true,
		"id": "instance." + location_id.replace("location.", ""),
		"location_id": location_id,
		"name": String(location.get("name", "Unknown Site")),
		"type": location_type,
		"region_id": _region_id_for_location(location_id),
		"rooms": _rooms_for_site_type(location_type),
		"objectives": _objectives_for_site_type(location_type),
		"resource_nodes": _resource_nodes_for_site_type(location_type),
		"puzzle": _puzzle_for_site_type(location_type),
		"enemy_id": enemy_id,
		"reward": _site_reward_for_type(location_type),
		"completed": false,
	}


func _rooms_for_site_type(site_type: String) -> Array[String]:
	match site_type:
		"cave":
			return ["mouth", "echo tunnel", "nest hollow", "ore pocket"]
		"dungeon", "stable_fort":
			return ["gate", "cell block", "tack armory", "boss stall"]
		"temple", "shrine":
			return ["outer steps", "votive hall", "hoof-mark altar", "sealed reliquary"]
		"mine":
			return ["lift head", "lower shaft", "ore seam", "collapsed pocket"]
		"volcano":
			return ["ash slope", "lava shelf", "smoke vent", "caldera heart"]
		"wreck":
			return ["broken deck", "flooded hold", "captain cache"]
		"horse_lair":
			return ["trampled entry", "bone ring", "rage nest"]
		_:
			return ["approach", "main chamber", "hidden cache"]


func _objectives_for_site_type(site_type: String) -> Array[String]:
	var objectives: Array[String] = ["survey_site", "claim_cache"]
	if ["dungeon", "stable_fort", "horse_lair", "cave", "temple"].has(site_type):
		objectives.insert(1, "clear_horses")
	if ["temple", "shrine", "ruin"].has(site_type):
		objectives.append("solve_relic_puzzle")
	if site_type == "mine":
		objectives.append("secure_ore_seam")
	if site_type == "volcano":
		objectives.append("seal_lava_vent")
	return objectives


func _resource_nodes_for_site_type(site_type: String) -> Array[Dictionary]:
	match site_type:
		"mine":
			return [{"id": "ore_vein", "material": "material.ore", "count": 5}, {"id": "saltpeter", "material": "material.ammo_powder", "count": 3}]
		"volcano":
			return [{"id": "basalt_glass", "material": "material.ore", "count": 6}, {"id": "sulfur_vent", "material": "material.ammo_powder", "count": 4}]
		"cave":
			return [{"id": "mushrooms", "material": "material.medicine", "count": 2}, {"id": "loose_ore", "material": "material.ore", "count": 2}]
		"temple", "shrine":
			return [{"id": "relic_scrap", "material": "material.research", "count": 3}]
		"wreck":
			return [{"id": "cargo_crate", "material": "material.trade_goods", "count": 4}]
		_:
			return [{"id": "salvage", "material": "material.timber", "count": 2}]


func _puzzle_for_site_type(site_type: String) -> Dictionary:
	if ["temple", "shrine", "ruin"].has(site_type):
		return {"id": "rotate_hateful_relics", "type": "sequence", "solution": ["bridle", "hoof", "fire"], "reward": "material.research"}
	if site_type == "mine":
		return {"id": "restore_lift_power", "type": "switch_route", "solution": ["upper", "lower", "vent"], "reward": "material.ore"}
	return {"id": "track_the_hoofprints", "type": "trail_reading", "solution": ["fresh", "deep", "angry"], "reward": "material.ammo_powder"}


func _site_reward_for_type(site_type: String) -> Dictionary:
	match site_type:
		"dungeon", "stable_fort":
			return {"xp": 90, "item": "weapon.greenbarrow.stablebreaker", "materials": {"material.ore": 4}}
		"temple", "shrine":
			return {"xp": 70, "item": "equipment.greenbarrow.field_charm", "materials": {"material.research": 4}}
		"mine":
			return {"xp": 50, "materials": {"material.ore": 8}}
		"cave":
			return {"xp": 45, "materials": {"material.medicine": 2, "material.ore": 2}}
		_:
			return {"xp": 35, "materials": {"material.timber": 3}}


func _event_reward(event_type: String) -> Dictionary:
	match event_type:
		"horse_hunt":
			return {"xp": 80, "regional_threat_delta": -1, "materials": {"material.ammo_powder": 2}}
		"settlement_request":
			return {"xp": 35, "settlement_resources": {"food": 6, "morale": 3}}
		"site_cache":
			return {"xp": 45, "materials": {"material.ore": 2, "material.research": 1}}
		_:
			return {"xp": 40, "materials": {"material.timber": 2}}


func _resolve_shot_against_world(shot: Dictionary) -> Dictionary:
	if active_encounter == null:
		var target := _find_nearest_enemy_location(360.0)
		if not target.is_empty():
			var enemy_id := String(target.get("enemy_id", ""))
			if enemy_id.is_empty():
				enemy_id = _enemy_for_location_id(String(target.get("id", "")))
			start_horse_encounter(enemy_id)
	if active_encounter == null:
		last_combat_log.append("Shot fired into open ground.")
		return {"ok": false, "reason": "no_encounter_in_range"}
	var result: Dictionary = active_encounter.call("resolve_shot", shot)
	if bool(result.get("ok", false)):
		var log_line := "%s hit for %s (%s)" % [String(active_encounter.get("display_name")), str(result.get("damage", 0)), String(result.get("quality", ""))]
		last_combat_log.append(log_line)
	if bool(result.get("defeated", false)):
		var defeated_id := String(active_encounter.get("enemy_id"))
		var defeated_name := String(active_encounter.get("display_name"))
		clear_encounter(defeated_id)
		last_combat_log.append("Defeated " + defeated_name)
		active_encounter.queue_free()
		active_encounter = null
		_autosave_release_state("encounter_defeated:" + defeated_id)
	return result


func _find_nearest_enemy_location(max_distance: float) -> Dictionary:
	if player == null:
		return {}
	var best := {}
	var best_distance := INF
	for location in current_region.get("locations", []):
		if not (location is Dictionary):
			continue
		var location_type := String(location.get("type", ""))
		if not ["horse_site", "horse_lair", "stable_fort", "boss", "dungeon", "cave", "temple", "ruin", "volcano"].has(location_type):
			continue
		var enemy_id := String(location.get("enemy_id", _enemy_for_location_id(String(location.get("id", "")))))
		if enemy_id.is_empty() or is_encounter_cleared(enemy_id):
			continue
		var distance := player.global_position.distance_to(_location_position(location))
		if distance <= max_distance and distance < best_distance:
			best = location
			best_distance = distance
	return best


func _spawn_shot_feedback(shot: Dictionary) -> void:
	if shot_effect_layer == null:
		return
	var origin: Vector2 = shot.get("origin", Vector2.ZERO)
	var direction: Vector2 = shot.get("direction", Vector2.RIGHT)
	if direction.length() <= 0.05:
		direction = Vector2.RIGHT
	var shot_range := float(shot.get("range", 520.0))
	var tracer := Line2D.new()
	tracer.name = "ShotTracer"
	tracer.width = 5.0
	tracer.default_color = Color(1.0, 0.78, 0.30, 0.88)
	tracer.points = PackedVector2Array([origin, origin + direction.normalized() * shot_range])
	shot_effect_layer.add_child(tracer)
	var muzzle := Node2D.new()
	muzzle.name = "MuzzleFlash"
	muzzle.position = origin + direction.normalized() * 28.0
	shot_effect_layer.add_child(muzzle)
	var flash := Polygon2D.new()
	flash.color = Color(1.0, 0.58, 0.18, 0.92)
	flash.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(-8.0, -5.0),
		Vector2(22.0, 0.0),
		Vector2(-8.0, 5.0),
	])
	flash.rotation = direction.angle()
	muzzle.add_child(flash)
	var timer := Timer.new()
	timer.wait_time = 0.12
	timer.one_shot = true
	timer.timeout.connect(func():
		if is_instance_valid(tracer):
			tracer.queue_free()
		if is_instance_valid(muzzle):
			muzzle.queue_free()
		if is_instance_valid(timer):
			timer.queue_free()
	)
	add_child(timer)
	timer.start()


func _update_player_aim_from_pointer() -> void:
	if player == null or not player.has_method("set_aim_direction"):
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var pointer_world := viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	var direction := pointer_world - player.global_position
	if direction.length() > 12.0:
		player.call("set_aim_direction", direction)


func _enemy_for_location_id(location_id: String) -> String:
	if location_id.contains("boss") or location_id.contains("arena") or location_id.contains("pasture"):
		if current_region_id == "region.frostreel":
			return "enemy.boss.whiteout_stallion"
		if current_region_id == "region.saltwake":
			return "enemy.boss.reef_kelpie"
		if current_region_id == "region.blackglass":
			return "enemy.boss.glassback_colossus"
		if current_region_id == "region.cinderjaw":
			return "enemy.boss.cinder_mare"
		if current_region_id == "region.pale_spur":
			return "enemy.boss.pale_herd_king"
		if current_region_id == "region.withered_paddock":
			return "enemy.boss.last_horse"
		return "enemy.boss.toll_mare"
	if location_id.contains("stable") or location_id.contains("corral"):
		return "enemy.horse.armored_greenbarrow"
	if location_id.contains("temple") or location_id.contains("shrine"):
		return "enemy.horse.pack_leader_greenbarrow"
	if location_id.contains("cave") or location_id.contains("reef"):
		return "enemy.horse.spitter_greenbarrow"
	if location_id.contains("road") or location_id.contains("field"):
		return "enemy.horse.runner_greenbarrow"
	return "enemy.horse.charger_greenbarrow"


func _add_world_route_interactions() -> void:
	var route_map := {
		"location.greenbarrow.forest_edge": ["region.gallowpine", "location.gallowpine.entry"],
		"location.greenbarrow.south_pass": ["region.pale_spur", "location.pale_spur.dust_camp"],
		"location.gallowpine.saltwake_road": ["region.saltwake", "location.saltwake.gallowpine_road"],
		"location.saltwake.gallowpine_road": ["region.gallowpine", "location.gallowpine.saltwake_road"],
		"location.saltwake.cinderjaw_steamship": ["region.cinderjaw", "location.cinderjaw.saltwake_steamship"],
		"location.cinderjaw.saltwake_steamship": ["region.saltwake", "location.saltwake.cinderjaw_steamship"],
		"location.frostreel.blackglass_pass": ["region.blackglass", "location.blackglass.frostreel_trail"],
		"location.blackglass.frostreel_trail": ["region.frostreel", "location.frostreel.blackglass_pass"],
		"location.blackglass.pale_spur_switchback": ["region.pale_spur", "location.pale_spur.blackglass_switchback"],
		"location.pale_spur.blackglass_switchback": ["region.blackglass", "location.blackglass.pale_spur_switchback"],
		"location.cinderjaw.pale_spur_road": ["region.pale_spur", "location.pale_spur.cinderjaw_road"],
		"location.pale_spur.cinderjaw_road": ["region.cinderjaw", "location.cinderjaw.pale_spur_road"],
		"location.pale_spur.withered_threshold": ["region.withered_paddock", "location.withered_paddock.threshold"],
		"location.withered_paddock.pale_spur_exit": ["region.pale_spur", "location.pale_spur.withered_threshold"],
	}
	for raw_location_id in route_map.keys():
		var location_id := String(raw_location_id)
		var location := _find_location(location_id)
		if location.is_empty():
			continue
		var route: Array = route_map[location_id]
		var interaction_id := "interaction.route." + location_id.replace("location.", "")
		interactions[interaction_id] = {
			"id": interaction_id,
			"type": "region_gate",
			"location_id": location_id,
			"display_name": "Travel: " + String(location.get("name", "Road")),
			"target_region_id": String(route[0]),
			"target_location_id": String(route[1]),
			"position": location.get("position", {}),
		}


func _build_stream_graph() -> void:
	stream_graph = {}
	for region_id in regions.keys():
		stream_graph[region_id] = []
	for interaction in interactions.values():
		if not (interaction is Dictionary) or String(interaction.get("type", "")) != "region_gate":
			continue
		var source_region := _region_id_for_location(String(interaction.get("location_id", "")))
		var target_region := String(interaction.get("target_region_id", ""))
		if source_region.is_empty() or target_region.is_empty():
			continue
		if not stream_graph.has(source_region):
			stream_graph[source_region] = []
		if not (stream_graph[source_region] as Array).has(target_region):
			(stream_graph[source_region] as Array).append(target_region)


func _refresh_streamed_regions() -> void:
	if regions.is_empty():
		return
	var wanted: Array[String] = [current_region_id]
	for adjacent_region in stream_graph.get(current_region_id, []):
		if regions.has(String(adjacent_region)) and not wanted.has(String(adjacent_region)):
			wanted.append(String(adjacent_region))
	for region_id in wanted:
		_stream_region_into_cache(region_id)
	for cached_region in streamed_region_cache.keys():
		if not wanted.has(String(cached_region)) or streamed_region_cache.size() > max_streamed_regions:
			streamed_region_cache.erase(cached_region)


func _stream_region_into_cache(region_id: String) -> void:
	if not regions.has(region_id):
		return
	var region: Dictionary = regions[region_id]
	streamed_region_cache[region_id] = {
		"region_id": region_id,
		"display_name": String(region.get("display_name", region_id)),
		"biome": String(region.get("biome", "")),
		"location_count": region.get("locations", []).size(),
		"interaction_count": _count_interactions_for_region(region_id),
		"threat": get_region_threat(region_id),
		"preloaded_at": Time.get_ticks_msec(),
	}


func _count_interactions_for_region(region_id: String) -> int:
	var slug := region_id.get_slice(".", 1)
	var count := 0
	for interaction in interactions.values():
		if interaction is Dictionary and String(interaction.get("location_id", "")).contains(slug):
			count += 1
	return count


func _region_id_for_location(location_id: String) -> String:
	for region_id in regions.keys():
		var slug := String(region_id).get_slice(".", 1)
		if location_id.contains("." + slug + "."):
			return String(region_id)
	return ""


func _add_horse_site_interactions() -> void:
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		for location in region.get("locations", []):
			if not (location is Dictionary):
				continue
			var location_type := String(location.get("type", ""))
			if not ["horse_site", "horse_lair", "stable_fort", "boss", "dungeon", "cave", "temple", "ruin", "volcano"].has(location_type):
				continue
			var interaction_id := "interaction.combat." + String(location.get("id", "")).replace("location.", "")
			var enemy_id := String(location.get("enemy_id", ""))
			if enemy_id.is_empty():
				enemy_id = _enemy_for_location_id(String(location.get("id", "")))
			interactions[interaction_id] = {
				"id": interaction_id,
				"type": "boss_gate" if location_type == "boss" else "horse_site",
				"location_id": String(location.get("id", "")),
				"display_name": "Fight: " + String(location.get("name", "Horse Site")),
				"boss_id": enemy_id,
				"enemy_id": enemy_id,
				"position": location.get("position", {}),
			}


func _count_all_locations() -> int:
	var count := 0
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		count += region.get("locations", []).size()
	return count


func _count_all_locations_of_types(types: Array) -> int:
	var count := 0
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		for location in region.get("locations", []):
			if location is Dictionary and types.has(String(location.get("type", ""))):
				count += 1
	return count


func _has_discovered_location_in_region(region_id: String) -> bool:
	var region: Dictionary = regions.get(region_id, {})
	for location in region.get("locations", []):
		if location is Dictionary and bool(discovered_locations.get(String(location.get("id", "")), false)):
			return true
	return false


func _read_setting(setting_id: String, fallback: Variant) -> Variant:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_method("get_setting"):
		return save_manager.call("get_setting", setting_id, fallback)
	return fallback


func _autosave_release_state(_reason: String) -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_method("autosave_active_game"):
		save_manager.call("autosave_active_game", self)


func _rect_to_dict(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"w": rect.size.x,
		"h": rect.size.y,
	}


func _vector_to_dict(vector: Vector2) -> Dictionary:
	return {
		"x": vector.x,
		"y": vector.y,
	}


func _vector_from_dict(value: Variant) -> Vector2:
	if value is Dictionary:
		return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
	return Vector2.ZERO


func _dictionary_or_empty(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}
