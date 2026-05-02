class_name RegionChunk
extends Node2D

@export var region_id := ""
@export var display_name := ""
@export var biome := ""
@export var locations: Array[Dictionary] = []

var biome_color := Color(0.18, 0.32, 0.18)
var accent_color := Color(0.72, 0.56, 0.32)
var weather_profile := {}
var visual_directives := {}
var world_bounds := Rect2(0.0, 0.0, 2400.0, 1700.0)
var spawn_location_id := ""
var road_paths: Array[PackedVector2Array] = []
var prop_count := 0
var population_count := 0
var horse_count := 0
var interaction_actor_count := 0

var _location_positions := {}
var _interaction_anchors := {}
var _scenery: Array[Dictionary] = []
var _structures: Array[Dictionary] = []
var _settlements: Array[Dictionary] = []
var _actors: Array[Dictionary] = []
var _marker_layer: Node2D
var _collision_layer: Node2D
var _anchor_layer: Node2D


func setup(region: Dictionary, interaction_definitions := {}) -> void:
	region_id = String(region.get("id", ""))
	display_name = String(region.get("display_name", ""))
	biome = String(region.get("biome", "grassland"))
	biome_color = _biome_color(biome)
	accent_color = _accent_color(biome)
	weather_profile = region.get("weather_profile", {}) if region.get("weather_profile", {}) is Dictionary else {}
	visual_directives = region.get("visual_directives", {}) if region.get("visual_directives", {}) is Dictionary else {}
	world_bounds = _rect_from_dict(region.get("bounds", {}), Rect2(0.0, 0.0, 2400.0, 1700.0))
	spawn_location_id = String(region.get("spawn_location_id", ""))
	locations = []
	road_paths = []
	prop_count = 0
	_location_positions = {}
	_interaction_anchors = {}
	_scenery.clear()
	_structures.clear()
	_settlements.clear()
	_actors.clear()
	population_count = 0
	horse_count = 0
	interaction_actor_count = 0

	for child in get_children():
		remove_child(child)
		child.free()

	_marker_layer = Node2D.new()
	_marker_layer.name = "LocationMarkers"
	add_child(_marker_layer)

	_collision_layer = Node2D.new()
	_collision_layer.name = "WorldCollision"
	add_child(_collision_layer)

	_anchor_layer = Node2D.new()
	_anchor_layer.name = "InteractionAnchors"
	add_child(_anchor_layer)

	for location in region.get("locations", []):
		if location is Dictionary:
			_add_location(location)

	_build_roads(region.get("roads", []))
	_settlements = _copy_dictionary_array(region.get("settlements", []))
	_build_boundaries()
	_build_settlements()
	_build_landmarks()
	_build_interaction_anchors(interaction_definitions)
	_build_living_world(interaction_definitions)
	_generate_scenery()
	prop_count = _scenery.size() + _structures.size() + _actors.size()
	queue_redraw()


func get_location_ids() -> Array[String]:
	var ids: Array[String] = []
	for location in locations:
		ids.append(String(location.get("id", "")))
	return ids


func get_visual_quality_report() -> Dictionary:
	var type_counts := _location_type_counts()
	return {
		"location_count": locations.size(),
		"label_count": _count_label_children(),
		"prop_count": prop_count,
		"has_biome": not biome.is_empty(),
		"has_location_names": locations.size() > 0 and String(locations[0].get("name", "")).length() > 0,
		"settlement_count": _settlements.size(),
		"world_width": world_bounds.size.x,
		"world_height": world_bounds.size.y,
		"weather": String(weather_profile.get("display_name", "")),
		"quality_mode": String(weather_profile.get("quality_mode", "standard")),
		"has_weather_overlay": not weather_profile.is_empty(),
		"has_extra_decals": bool(visual_directives.get("extra_decals", false)),
		"settlement_locations": _sum_type_counts(type_counts, ["camp", "village", "town", "city", "settlement", "harbor", "fort"]),
		"exploration_locations": _sum_type_counts(type_counts, ["cave", "dungeon", "temple", "mine", "ruin", "wreck", "shrine", "volcano"]),
		"horse_locations": _sum_type_counts(type_counts, ["horse_site", "horse_lair", "stable_fort", "boss"]),
		"location_types": type_counts,
		"visible_actor_count": _actors.size(),
		"visible_people": population_count,
		"visible_horses": horse_count,
		"visible_interactions": interaction_actor_count,
	}


func get_world_bounds() -> Rect2:
	return world_bounds


func get_spawn_position() -> Vector2:
	if not spawn_location_id.is_empty() and _location_positions.has(spawn_location_id):
		return _location_positions[spawn_location_id]
	if not locations.is_empty():
		return _location_position(locations[0])
	return world_bounds.get_center()


func get_location_position(location_id: String) -> Vector2:
	return _location_positions.get(location_id, Vector2.ZERO)


func get_interaction_anchor_position(interaction_id: String) -> Vector2:
	return _interaction_anchors.get(interaction_id, Vector2.ZERO)


func _draw() -> void:
	draw_rect(world_bounds, biome_color)
	_draw_ground_texture()
	_draw_biome_decals()
	_draw_structures_by_layer(0)
	_draw_roads()
	_draw_scenery()
	_draw_structures_by_layer(1)
	_draw_structures_by_layer(2)
	_draw_actors()
	_draw_location_emblems()
	_draw_weather_overlay()
	_draw_lighting_grade()
	_draw_region_frame()


func _add_location(location: Dictionary) -> void:
	locations.append(location.duplicate(true))
	var position := _location_position(location)
	var location_id := String(location.get("id", "location"))
	_location_positions[location_id] = position

	var marker := Marker2D.new()
	marker.name = location_id.replace(".", "_")
	marker.position = position
	_marker_layer.add_child(marker)

	var label := Label.new()
	label.name = marker.name + "_Label"
	label.text = String(location.get("name", "Unknown"))
	label.position = position + Vector2(-92.0, 34.0)
	label.custom_minimum_size = Vector2(184.0, 32.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.97, 0.93, 0.84))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	_marker_layer.add_child(label)


func _build_roads(raw_roads: Array) -> void:
	road_paths.clear()
	if raw_roads.is_empty():
		for index in range(1, locations.size()):
			var from_position := _location_position(locations[index - 1])
			var to_position := _location_position(locations[index])
			var middle := from_position.lerp(to_position, 0.5) + Vector2(0.0, 48.0 if index % 2 == 0 else -48.0)
			road_paths.append(PackedVector2Array([from_position, middle, to_position]))
		return

	for raw_road in raw_roads:
		var road := PackedVector2Array()
		for raw_point in raw_road:
			if raw_point is Dictionary:
				road.append(_vector_from_dict(raw_point))
		if road.size() >= 2:
			road_paths.append(road)


func _build_boundaries() -> void:
	var margin := 140.0
	_create_collider_rect(Rect2(world_bounds.position.x - margin, world_bounds.position.y - margin, world_bounds.size.x + margin * 2.0, margin), "TopBoundary")
	_create_collider_rect(Rect2(world_bounds.position.x - margin, world_bounds.end.y, world_bounds.size.x + margin * 2.0, margin), "BottomBoundary")
	_create_collider_rect(Rect2(world_bounds.position.x - margin, world_bounds.position.y, margin, world_bounds.size.y), "LeftBoundary")
	_create_collider_rect(Rect2(world_bounds.end.x, world_bounds.position.y, margin, world_bounds.size.y), "RightBoundary")

	_structures.append({"type": "edge_band", "layer": 0, "rect": {"x": world_bounds.position.x, "y": world_bounds.position.y, "w": world_bounds.size.x, "h": 116.0}, "strength": 0.08})
	_structures.append({"type": "edge_band", "layer": 0, "rect": {"x": world_bounds.position.x, "y": world_bounds.end.y - 132.0, "w": world_bounds.size.x, "h": 132.0}, "strength": 0.12})
	_structures.append({"type": "edge_band", "layer": 0, "rect": {"x": world_bounds.position.x, "y": world_bounds.position.y, "w": 110.0, "h": world_bounds.size.y}, "strength": 0.1})
	_structures.append({"type": "edge_band", "layer": 0, "rect": {"x": world_bounds.end.x - 110.0, "y": world_bounds.position.y, "w": 110.0, "h": world_bounds.size.y}, "strength": 0.1})
	for index in range(20):
		var x := world_bounds.position.x + 60.0 + float((index * 117) % int(world_bounds.size.x - 120.0))
		_structures.append({"type": "edge_obstacle", "layer": 1, "position": {"x": x, "y": world_bounds.position.y + 56.0}, "size": 22.0 + float(index % 3) * 6.0})
		_structures.append({"type": "edge_obstacle", "layer": 1, "position": {"x": x, "y": world_bounds.end.y - 58.0}, "size": 24.0 + float((index + 1) % 4) * 6.0})


func _build_settlements() -> void:
	for settlement in _settlements:
		var yard_rect := _rect_from_dict(settlement.get("rect", {}), Rect2(120.0, 120.0, 320.0, 280.0))
		_structures.append({"type": "yard", "layer": 0, "rect": _rect_to_dict(yard_rect), "style": String(settlement.get("style", "camp"))})
		_add_gate_palisade(yard_rect, String(settlement.get("gate_side", "south")))
		for building in settlement.get("buildings", []):
			if building is Dictionary:
				_add_building(building)
		for prop in settlement.get("props", []):
			if prop is Dictionary:
				var entry: Dictionary = prop.duplicate(true)
				entry["layer"] = 1
				_structures.append(entry)


func _build_landmarks() -> void:
	for location in locations:
		var location_id := String(location.get("id", ""))
		var location_type := String(location.get("type", ""))
		var position := _location_position(location)
		if ["camp", "village", "town", "city", "settlement", "harbor", "fort"].has(location_type):
			_structures.append({"type": "town_cluster", "layer": 2, "position": {"x": position.x, "y": position.y}, "site_type": location_type})
		elif location_type == "cave":
			_structures.append({"type": "cave_mouth", "layer": 2, "position": {"x": position.x, "y": position.y}})
			_create_collider_rect(Rect2(position.x - 44.0, position.y - 18.0, 88.0, 42.0), location_id + "_CaveMouth")
		elif location_type == "dungeon":
			_structures.append({"type": "dungeon_gate", "layer": 2, "position": {"x": position.x, "y": position.y}})
			_create_collider_rect(Rect2(position.x - 48.0, position.y - 28.0, 96.0, 58.0), location_id + "_DungeonGate")
		elif location_type == "temple" or location_type == "shrine":
			_structures.append({"type": "temple_ruin", "layer": 2, "position": {"x": position.x, "y": position.y}, "site_type": location_type})
			_create_collider_rect(Rect2(position.x - 52.0, position.y - 34.0, 104.0, 68.0), location_id + "_Temple")
		elif ["horse_site", "horse_lair", "stable_fort"].has(location_type):
			_structures.append({"type": "horse_site", "layer": 2, "position": {"x": position.x, "y": position.y}, "site_type": location_type})
		elif location_type == "boss" or location_id.contains("arena"):
			_structures.append({"type": "boss_arena", "layer": 0, "rect": {"x": position.x - 190.0, "y": position.y - 130.0, "w": 380.0, "h": 260.0}})
			_structures.append({"type": "arena_gate", "layer": 2, "position": {"x": position.x, "y": position.y - 138.0}})
			for pillar_offset in [-134.0, 134.0]:
				_create_collider_rect(Rect2(position.x + pillar_offset - 22.0, position.y - 154.0, 44.0, 82.0), location_id + "_Pillar_" + str(int(pillar_offset)))
		elif location_id.contains("camp"):
			_structures.append({"type": "campfire", "layer": 2, "position": {"x": position.x + 18.0, "y": position.y + 10.0}})
		elif location_id.contains("road"):
			_structures.append({"type": "broken_wagon", "layer": 1, "rect": {"x": position.x - 64.0, "y": position.y - 26.0, "w": 132.0, "h": 58.0}})
			_structures.append({"type": "signpost", "layer": 2, "position": {"x": position.x + 48.0, "y": position.y - 18.0}})
			_create_collider_rect(Rect2(position.x - 48.0, position.y - 18.0, 98.0, 36.0), location_id + "_RoadWreck")
		elif location_id.contains("farm"):
			_structures.append({"type": "field", "layer": 0, "rect": {"x": position.x - 120.0, "y": position.y - 54.0, "w": 220.0, "h": 110.0}})
			_structures.append({"type": "farmhouse", "layer": 1, "rect": {"x": position.x - 46.0, "y": position.y - 70.0, "w": 92.0, "h": 66.0}})
			_create_collider_rect(Rect2(position.x - 46.0, position.y - 70.0, 92.0, 66.0), location_id + "_Farmhouse")
		elif location_id.contains("forest"):
			_structures.append({"type": "watch_post", "layer": 1, "rect": {"x": position.x - 24.0, "y": position.y - 76.0, "w": 48.0, "h": 82.0}})
			_create_collider_rect(Rect2(position.x - 24.0, position.y - 40.0, 48.0, 46.0), location_id + "_WatchPost")
		elif location_type == "mine":
			_structures.append({"type": "mine_head", "layer": 2, "position": {"x": position.x, "y": position.y}})
			_create_collider_rect(Rect2(position.x - 52.0, position.y - 26.0, 104.0, 52.0), location_id + "_MineHead")
		elif location_type == "volcano":
			_structures.append({"type": "volcano", "layer": 2, "position": {"x": position.x, "y": position.y}})
			_create_collider_rect(Rect2(position.x - 70.0, position.y - 46.0, 140.0, 92.0), location_id + "_Volcano")


func _build_interaction_anchors(interaction_definitions) -> void:
	if not (interaction_definitions is Dictionary):
		return
	for interaction_id in interaction_definitions.keys():
		var interaction: Dictionary = interaction_definitions[interaction_id]
		var anchor_position := _resolve_interaction_position(interaction)
		_interaction_anchors[String(interaction_id)] = anchor_position
		var anchor := Marker2D.new()
		anchor.name = String(interaction_id).replace(".", "_")
		anchor.position = anchor_position
		_anchor_layer.add_child(anchor)

		var label := Label.new()
		label.name = anchor.name + "_Name"
		label.text = String(interaction.get("display_name", "Interact"))
		label.position = anchor_position + Vector2(-92.0, -70.0)
		label.custom_minimum_size = Vector2(184.0, 28.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		_anchor_layer.add_child(label)


func _build_living_world(interaction_definitions) -> void:
	_actors.clear()
	_spawn_settlement_population()
	_spawn_hostile_site_herds()
	_spawn_interaction_actors(interaction_definitions)
	_spawn_road_life()


func _spawn_settlement_population() -> void:
	for settlement in _settlements:
		var yard_rect := _rect_from_dict(settlement.get("rect", {}), Rect2())
		if yard_rect.size == Vector2.ZERO:
			continue
		var style := String(settlement.get("style", "camp"))
		var count := _population_for_settlement_style(style)
		for index in range(count):
			var lane := index % 5
			var row := int(index / 5)
			var position := yard_rect.position + Vector2(
				42.0 + float(lane) * maxf(48.0, (yard_rect.size.x - 84.0) / 5.0),
				70.0 + float(row % 4) * maxf(46.0, (yard_rect.size.y - 120.0) / 4.0)
			)
			position += Vector2(float((index * 19) % 23) - 11.0, float((index * 31) % 21) - 10.0)
			_add_actor({
				"kind": "person",
				"role": _settler_role(index, style),
				"position": _vector_to_dict(position),
				"scale": 0.82 + float(index % 3) * 0.08,
				"interactive": false,
				"palette": style,
			})
		if ["town", "city", "fort"].has(style):
			for guard_index in range(4 if style == "city" else 2):
				_add_actor({
					"kind": "person",
					"role": "guard",
					"position": _vector_to_dict(yard_rect.position + Vector2(36.0 + float(guard_index) * 52.0, yard_rect.size.y - 34.0)),
					"scale": 0.95,
					"interactive": false,
					"palette": "guard",
				})


func _spawn_hostile_site_herds() -> void:
	for location in locations:
		var location_type := String(location.get("type", ""))
		var enemy_id := String(location.get("enemy_id", ""))
		if enemy_id.is_empty() and not ["horse_site", "horse_lair", "stable_fort", "boss", "dungeon", "cave", "temple", "ruin", "road"].has(location_type):
			continue
		var center := _location_position(location)
		var herd_size := _herd_size_for_location(location_type)
		for index in range(herd_size):
			var angle := float(index) * TAU / float(maxi(herd_size, 1)) + 0.35
			var radius := 44.0 + float(index % 3) * 26.0
			var position := center + Vector2(cos(angle), sin(angle)) * radius
			_add_actor({
				"kind": "horse",
				"role": "boss" if location_type == "boss" else _horse_role_for_index(index, location_type),
				"position": _vector_to_dict(position),
				"scale": 1.55 if location_type == "boss" else 0.9 + float(index % 3) * 0.12,
				"interactive": false,
				"palette": biome,
			})


func _spawn_interaction_actors(interaction_definitions) -> void:
	if not (interaction_definitions is Dictionary):
		return
	for interaction_id in interaction_definitions.keys():
		var interaction: Dictionary = interaction_definitions[interaction_id]
		var interaction_type := String(interaction.get("type", ""))
		var position := _resolve_interaction_position(interaction)
		match interaction_type:
			"quest_giver":
				_add_actor({"kind": "person", "role": "quest_giver", "position": _vector_to_dict(position), "scale": 1.08, "interactive": true, "label": String(interaction.get("display_name", "Quest"))})
			"follower":
				_add_actor({"kind": "person", "role": "follower", "position": _vector_to_dict(position), "scale": 1.02, "interactive": true, "label": String(interaction.get("display_name", "Follower"))})
			"loot":
				_add_actor({"kind": "cache", "role": "loot", "position": _vector_to_dict(position), "scale": 1.0, "interactive": true, "label": String(interaction.get("display_name", "Loot"))})
			"settlement":
				_add_actor({"kind": "standard", "role": "founding_banner", "position": _vector_to_dict(position), "scale": 1.0, "interactive": true, "label": String(interaction.get("display_name", "Found"))})
			"region_gate":
				_add_actor({"kind": "standard", "role": "route_gate", "position": _vector_to_dict(position), "scale": 1.0, "interactive": true, "label": String(interaction.get("display_name", "Travel"))})
			"horse_site", "boss_gate":
				_add_actor({"kind": "standard", "role": "combat_marker", "position": _vector_to_dict(position), "scale": 1.0, "interactive": true, "label": String(interaction.get("display_name", "Fight"))})


func _spawn_road_life() -> void:
	for road_index in range(road_paths.size()):
		var road := road_paths[road_index]
		if road.size() < 2:
			continue
		if road_index % 3 == 0:
			var position := road[0].lerp(road[road.size() - 1], 0.54)
			_add_actor({
				"kind": "wagon",
				"role": "caravan",
				"position": _vector_to_dict(position + Vector2(float((road_index * 17) % 30) - 15.0, float((road_index * 23) % 24) - 12.0)),
				"scale": 0.92,
				"interactive": false,
			})


func _add_actor(actor: Dictionary) -> void:
	_actors.append(actor)
	if String(actor.get("kind", "")) == "horse":
		horse_count += 1
	elif String(actor.get("kind", "")) == "person":
		population_count += 1
	if bool(actor.get("interactive", false)):
		interaction_actor_count += 1


func _population_for_settlement_style(style: String) -> int:
	match style:
		"city":
			return 34
		"town", "harbor":
			return 22
		"village":
			return 14
		"fort":
			return 12
		"settlement":
			return 10
		_:
			return 7


func _settler_role(index: int, style: String) -> String:
	if style == "fort" and index % 3 == 0:
		return "guard"
	if index % 7 == 0:
		return "merchant"
	if index % 5 == 0:
		return "worker"
	if index % 4 == 0:
		return "scout"
	return "settler"


func _herd_size_for_location(location_type: String) -> int:
	match location_type:
		"boss":
			return 1
		"stable_fort", "horse_lair":
			return 8
		"horse_site", "dungeon":
			return 6
		"cave", "temple", "ruin":
			return 4
		"road":
			return 3
		_:
			return 2


func _horse_role_for_index(index: int, location_type: String) -> String:
	if location_type == "stable_fort":
		return "armored"
	if location_type == "temple":
		return "spectral"
	if index % 5 == 0:
		return "charger"
	if index % 3 == 0:
		return "spitter"
	return "runner"


func _generate_scenery() -> void:
	_scenery.clear()
	var horizontal_steps := int(world_bounds.size.x / 260.0)
	var vertical_steps := int(world_bounds.size.y / 220.0)
	for row in range(vertical_steps):
		for column in range(horizontal_steps):
			var position := Vector2(
				world_bounds.position.x + 110.0 + float(column) * 258.0 + float((row % 2) * 34),
				world_bounds.position.y + 110.0 + float(row) * 218.0
			)
			position += Vector2(float((row * 17 + column * 9) % 26) - 13.0, float((row * 11 + column * 19) % 22) - 11.0)
			if _point_is_reserved(position):
				continue
			match biome:
				"forest":
					_scenery.append({"type": "tree_cluster", "position": {"x": position.x, "y": position.y}, "size": 24.0 + float((row + column) % 3) * 7.0})
				"snow":
					_scenery.append({"type": "snow_patch", "position": {"x": position.x, "y": position.y}, "size": 18.0 + float((row + column) % 4) * 6.0})
				"coast":
					_scenery.append({"type": "reed_patch", "position": {"x": position.x, "y": position.y}, "size": 16.0 + float((row + column) % 3) * 5.0})
				"mountain":
					_scenery.append({"type": "rock_cluster", "position": {"x": position.x, "y": position.y}, "size": 18.0 + float((row + column) % 4) * 6.0})
				"volcano":
					_scenery.append({"type": "ember_patch", "position": {"x": position.x, "y": position.y}, "size": 14.0 + float((row + column) % 3) * 5.0})
				"badlands":
					_scenery.append({"type": "dry_scrub", "position": {"x": position.x, "y": position.y}, "size": 12.0 + float((row + column) % 4) * 4.0})
				"corruption":
					_scenery.append({"type": "blight_growth", "position": {"x": position.x, "y": position.y}, "size": 16.0 + float((row + column) % 4) * 6.0})
				_:
					if (row + column) % 4 == 0:
						_scenery.append({"type": "flower_patch", "position": {"x": position.x, "y": position.y}, "size": 14.0 + float((row + column) % 3) * 4.0})
					else:
						_scenery.append({"type": "grass_clump", "position": {"x": position.x, "y": position.y}, "size": 13.0 + float((row + column) % 4) * 4.0})


func _draw_ground_texture() -> void:
	var grade_color := _weather_overlay_color()
	var grade_intensity := float(weather_profile.get("overlay_intensity", 0.0))
	var cell := 320.0
	var columns := int(ceil(world_bounds.size.x / cell))
	var rows := int(ceil(world_bounds.size.y / cell))
	for row in range(rows):
		for column in range(columns):
			var noise_value := float((column * 37 + row * 53 + column * row * 11) % 100) / 100.0
			var patch_color := biome_color
			if noise_value < 0.28:
				patch_color = biome_color.darkened(0.055 + noise_value * 0.05)
			elif noise_value > 0.72:
				patch_color = biome_color.lightened(0.05 + (noise_value - 0.72) * 0.18)
			patch_color = patch_color.lerp(grade_color, grade_intensity * 0.16)
			var patch_rect := Rect2(
				world_bounds.position + Vector2(float(column) * cell, float(row) * cell),
				Vector2(cell + 2.0, cell + 2.0)
			)
			draw_rect(patch_rect, patch_color)
	for band in range(18):
		var y := world_bounds.position.y + 40.0 + float(band) * (world_bounds.size.y / 17.0)
		var x_offset := sin(float(band) * 0.7) * 80.0
		var band_color := biome_color.lightened(0.07).lerp(grade_color, grade_intensity * 0.20)
		draw_line(Vector2(world_bounds.position.x + x_offset, y), Vector2(world_bounds.end.x + x_offset * 0.4, y + sin(float(band) * 1.2) * 46.0), Color(band_color.r, band_color.g, band_color.b, 0.18), 18.0)
	for index in range(46):
		var x := world_bounds.position.x + 80.0 + float((index * 389) % int(max(world_bounds.size.x - 160.0, 1.0)))
		var y := world_bounds.position.y + 60.0 + float((index * 227) % int(max(world_bounds.size.y - 120.0, 1.0)))
		var radius := 28.0 + float(index % 7) * 9.0
		var patch := biome_color.darkened(0.04 + float(index % 4) * 0.025).lerp(grade_color, grade_intensity * 0.18)
		draw_colored_polygon(_ellipse_points(Vector2(x, y), Vector2(radius, radius * (0.42 + float(index % 3) * 0.08)), 14, float(index % 11) * 0.2), Color(patch.r, patch.g, patch.b, 0.34))
	for track_index in range(24):
		var position := Vector2(
			world_bounds.position.x + float((track_index * 541 + 71) % int(max(world_bounds.size.x, 1.0))),
			world_bounds.position.y + float((track_index * 317 + 43) % int(max(world_bounds.size.y, 1.0)))
		)
		_draw_hoof_pair(position, Color(0.05, 0.035, 0.02, 0.18))


func _draw_biome_decals() -> void:
	if not bool(visual_directives.get("extra_decals", true)):
		return
	var detail := String(visual_directives.get("ground_detail", "dry_grass_tracks"))
	for index in range(30):
		var position := Vector2(
			world_bounds.position.x + 120.0 + float((index * 151) % int(max(world_bounds.size.x - 240.0, 1.0))),
			world_bounds.position.y + 120.0 + float((index * 89) % int(max(world_bounds.size.y - 240.0, 1.0)))
		)
		if _point_is_reserved(position):
			continue
		match detail:
			"snow_crunch":
				draw_circle(position, 8.0 + float(index % 3) * 2.0, Color(0.90, 0.94, 0.98, 0.34))
				draw_line(position + Vector2(-10.0, -4.0), position + Vector2(10.0, 5.0), Color(0.70, 0.78, 0.88, 0.32), 2.0)
			"tide_foam":
				draw_arc(position, 18.0 + float(index % 4) * 4.0, 0.2, 2.8, 12, Color(0.82, 0.92, 0.88, 0.28), 2.0)
			"ash_embers":
				draw_circle(position, 13.0, Color(0.08, 0.06, 0.05, 0.34))
				draw_circle(position + Vector2(4.0, -3.0), 3.0, Color(0.95, 0.30, 0.10, 0.70))
			"salt_cracks":
				for spoke in range(4):
					var angle := float(spoke) * TAU / 4.0 + float(index % 5) * 0.14
					draw_line(position, position + Vector2(cos(angle), sin(angle)) * (16.0 + float(index % 3) * 6.0), Color(0.90, 0.72, 0.50, 0.24), 2.0)
			"black_reins":
				draw_line(position + Vector2(-18.0, 0.0), position + Vector2(18.0, sin(float(index)) * 8.0), Color(0.08, 0.02, 0.09, 0.48), 4.0)
				draw_circle(position + Vector2(20.0, sin(float(index)) * 8.0), 4.0, Color(0.58, 0.22, 0.72, 0.50))
			"scree":
				_draw_rock_cluster(position, 8.0 + float(index % 4) * 3.0)
			"moss_tracks":
				draw_circle(position, 10.0, Color(0.08, 0.22, 0.10, 0.36))
				_draw_hoof_pair(position + Vector2(5.0, 2.0), Color(0.02, 0.05, 0.025, 0.26))
			_:
				_draw_hoof_pair(position, Color(0.07, 0.04, 0.02, 0.30))


func _draw_hoof_pair(position: Vector2, color: Color) -> void:
	draw_arc(position + Vector2(-7.0, 0.0), 7.0, 0.25, PI - 0.25, 8, color, 3.0)
	draw_arc(position + Vector2(7.0, 5.0), 7.0, 0.25, PI - 0.25, 8, color, 3.0)


func _draw_weather_overlay() -> void:
	var budget := int(weather_profile.get("particle_budget", 0))
	if budget <= 0:
		return
	var weather := String(weather_profile.get("weather", ""))
	var overlay_color := _weather_overlay_color()
	var intensity := float(weather_profile.get("overlay_intensity", 0.0))
	match weather:
		"fog_bands":
			for band in range(8):
				var y := world_bounds.position.y + 80.0 + float(band) * world_bounds.size.y / 8.0
				draw_line(Vector2(world_bounds.position.x, y), Vector2(world_bounds.end.x, y + sin(float(band) * 1.3) * 34.0), Color(overlay_color.r, overlay_color.g, overlay_color.b, 0.10 + intensity * 0.18), 54.0)
		"snow_squall":
			for index in range(budget):
				var position := _weather_particle_position(index)
				draw_line(position, position + Vector2(-14.0, 20.0), Color(0.96, 0.98, 1.0, 0.34 + intensity * 0.45), 2.0)
		"ash_heat":
			for index in range(budget):
				var position := _weather_particle_position(index)
				draw_circle(position, 2.0 + float(index % 3), Color(overlay_color.r, overlay_color.g, overlay_color.b, 0.24 + intensity * 0.32))
			for band in range(5):
				var x := world_bounds.position.x + float(band + 1) * world_bounds.size.x / 6.0
				draw_line(Vector2(x, world_bounds.position.y), Vector2(x + sin(float(band)) * 42.0, world_bounds.end.y), Color(1.0, 0.28, 0.10, 0.05), 18.0)
		"salt_mist", "mirage_dust", "hard_wind", "dust_crosswind":
			for index in range(maxi(16, int(budget / 2))):
				var position := _weather_particle_position(index)
				draw_line(position, position + Vector2(42.0, -8.0), Color(overlay_color.r, overlay_color.g, overlay_color.b, 0.14 + intensity * 0.18), 3.0)
		"corruption_veil":
			for index in range(maxi(18, int(budget / 2))):
				var position := _weather_particle_position(index)
				draw_arc(position, 18.0 + float(index % 5) * 5.0, 0.0, PI, 12, Color(overlay_color.r, overlay_color.g, overlay_color.b, 0.12 + intensity * 0.18), 3.0)
		_:
			for index in range(maxi(12, int(budget / 3))):
				var position := _weather_particle_position(index)
				draw_line(position, position + Vector2(28.0, -6.0), Color(overlay_color.r, overlay_color.g, overlay_color.b, 0.12 + intensity * 0.16), 2.0)


func _draw_lighting_grade() -> void:
	if weather_profile.is_empty():
		return
	var overlay_color := _weather_overlay_color()
	var intensity := float(weather_profile.get("overlay_intensity", 0.0))
	draw_rect(world_bounds, Color(overlay_color.r, overlay_color.g, overlay_color.b, intensity * 0.22))
	draw_rect(Rect2(world_bounds.position, Vector2(world_bounds.size.x, world_bounds.size.y * 0.18)), Color(0.0, 0.0, 0.0, 0.10 + intensity * 0.10))
	draw_rect(Rect2(world_bounds.position.x, world_bounds.end.y - world_bounds.size.y * 0.16, world_bounds.size.x, world_bounds.size.y * 0.16), Color(0.0, 0.0, 0.0, 0.08 + intensity * 0.10))


func _weather_particle_position(index: int) -> Vector2:
	return Vector2(
		world_bounds.position.x + float((index * 191 + 37) % int(max(world_bounds.size.x, 1.0))),
		world_bounds.position.y + float((index * 107 + 53) % int(max(world_bounds.size.y, 1.0)))
	)


func _weather_overlay_color() -> Color:
	var value = weather_profile.get("overlay_color", accent_color)
	if value is Color:
		return value
	return accent_color


func _draw_roads() -> void:
	for road in road_paths:
		if road.size() < 2:
			continue
		for segment_index in range(road.size() - 1):
			var from_position := road[segment_index]
			var to_position := road[segment_index + 1]
			_draw_road_segment(from_position, to_position)


func _draw_road_segment(from_position: Vector2, to_position: Vector2) -> void:
	var direction := (to_position - from_position).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		from_position + normal * 34.0,
		to_position + normal * 34.0,
		to_position - normal * 34.0,
		from_position - normal * 34.0,
	])
	draw_colored_polygon(points, accent_color.darkened(0.5))
	draw_line(from_position, to_position, accent_color.darkened(0.12), 38.0)
	draw_line(from_position, to_position, accent_color.lightened(0.14), 22.0)
	draw_line(from_position, to_position, Color(0.18, 0.12, 0.07, 0.4), 4.0)


func _draw_scenery() -> void:
	for item in _scenery:
		var item_type := String(item.get("type", "grass_clump"))
		var position := _vector_from_dict(item.get("position", {}))
		var size := float(item.get("size", 16.0))
		match item_type:
			"tree_cluster":
				_draw_tree_cluster(position, size)
			"snow_patch":
				draw_circle(position, size, Color(0.95, 0.97, 0.99, 0.5))
				draw_circle(position + Vector2(8.0, -4.0), size * 0.6, Color(0.82, 0.88, 0.96, 0.36))
			"reed_patch":
				for offset in [-10.0, -3.0, 6.0, 13.0]:
					draw_line(position + Vector2(offset, 8.0), position + Vector2(offset * 0.4, -size), Color(0.78, 0.84, 0.58), 3.0)
			"rock_cluster":
				_draw_rock_cluster(position, size)
			"ember_patch":
				draw_circle(position, size * 0.8, Color(0.94, 0.18, 0.05, 0.36))
				draw_circle(position + Vector2(5.0, -4.0), size * 0.35, Color(1.0, 0.58, 0.16, 0.68))
			"dry_scrub":
				for angle_index in range(5):
					var angle := deg_to_rad(-60.0 + float(angle_index) * 28.0)
					draw_line(position, position + Vector2(cos(angle), sin(angle)) * size, Color(0.72, 0.60, 0.34), 2.0)
			"blight_growth":
				_draw_blight_growth(position, size)
			"flower_patch":
				draw_circle(position, size * 0.78, biome_color.lightened(0.18))
				for bloom_offset in [Vector2(-8.0, -3.0), Vector2(6.0, -6.0), Vector2(2.0, 7.0)]:
					draw_circle(position + bloom_offset, 3.0, Color(0.96, 0.76, 0.32))
			_:
				for blade_index in range(4):
					var blade_offset := -6.0 + float(blade_index) * 4.0
					draw_line(position + Vector2(blade_offset, 8.0), position + Vector2(blade_offset * 0.35, -size), biome_color.lightened(0.28), 3.0)


func _draw_actors() -> void:
	for actor in _actors:
		var kind := String(actor.get("kind", "person"))
		var position := _vector_from_dict(actor.get("position", {}))
		var actor_scale := float(actor.get("scale", 1.0))
		if bool(actor.get("interactive", false)):
			_draw_interaction_ring(position, actor_scale, String(actor.get("role", "")))
		match kind:
			"horse":
				_draw_horse_actor(position, String(actor.get("role", "runner")), actor_scale, String(actor.get("palette", biome)))
			"cache":
				_draw_cache_actor(position, actor_scale)
			"wagon":
				_draw_wagon_actor(position, actor_scale)
			"standard":
				_draw_standard_actor(position, String(actor.get("role", "marker")), actor_scale)
			_:
				_draw_person_actor(position, String(actor.get("role", "settler")), actor_scale, String(actor.get("palette", "")))


func _draw_interaction_ring(position: Vector2, actor_scale: float, role: String) -> void:
	var radius := 34.0 * actor_scale
	var ring_color := Color(1.0, 0.78, 0.28, 0.88)
	if role == "combat_marker":
		ring_color = Color(1.0, 0.24, 0.18, 0.92)
	elif role == "route_gate":
		ring_color = Color(0.45, 0.82, 1.0, 0.88)
	draw_arc(position, radius, 0.0, TAU, 34, Color(0.0, 0.0, 0.0, 0.62), 7.0)
	draw_arc(position, radius, 0.0, TAU, 34, ring_color, 3.0)
	draw_line(position + Vector2(-9.0, -radius - 8.0), position + Vector2(9.0, -radius - 8.0), ring_color, 4.0)


func _draw_person_actor(position: Vector2, role: String, actor_scale: float, palette: String) -> void:
	var s := actor_scale
	var coat_color := Color(0.26, 0.18, 0.12)
	var accent := Color(0.70, 0.52, 0.30)
	match role:
		"quest_giver":
			coat_color = Color(0.20, 0.13, 0.09)
			accent = Color(0.95, 0.70, 0.32)
		"follower", "scout":
			coat_color = Color(0.16, 0.22, 0.16)
			accent = Color(0.50, 0.72, 0.42)
		"guard":
			coat_color = Color(0.22, 0.24, 0.26)
			accent = Color(0.72, 0.72, 0.64)
		"merchant":
			coat_color = Color(0.30, 0.16, 0.24)
			accent = Color(0.90, 0.62, 0.36)
		"worker":
			coat_color = Color(0.34, 0.22, 0.12)
			accent = Color(0.78, 0.64, 0.38)
	if palette == "guard":
		coat_color = Color(0.18, 0.20, 0.22)
	draw_colored_polygon(_ellipse_points(position + Vector2(0.0, 24.0 * s), Vector2(18.0, 7.0) * s, 12, 0.0), Color(0.0, 0.0, 0.0, 0.32))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-12.0, -7.0) * s,
		position + Vector2(12.0, -7.0) * s,
		position + Vector2(16.0, 22.0) * s,
		position + Vector2(4.0, 32.0) * s,
		position + Vector2(0.0, 22.0) * s,
		position + Vector2(-4.0, 32.0) * s,
		position + Vector2(-16.0, 22.0) * s,
	]), coat_color)
	draw_line(position + Vector2(-9.0, 2.0) * s, position + Vector2(10.0, 22.0) * s, accent, 4.0 * s)
	draw_circle(position + Vector2(0.0, -22.0) * s, 11.0 * s, Color(0.70, 0.50, 0.38))
	if role == "quest_giver" or role == "follower":
		draw_colored_polygon(PackedVector2Array([
			position + Vector2(-14.0, -32.0) * s,
			position + Vector2(13.0, -32.0) * s,
			position + Vector2(17.0, -6.0) * s,
			position + Vector2(9.0, 13.0) * s,
			position + Vector2(0.0, 20.0) * s,
			position + Vector2(-9.0, 13.0) * s,
			position + Vector2(-17.0, -6.0) * s,
		]), Color(0.10, 0.055, 0.03))
	draw_line(position + Vector2(10.0, 0.0) * s, position + Vector2(26.0, 8.0) * s, Color(0.62, 0.46, 0.34), 5.0 * s)
	draw_line(position + Vector2(21.0, 7.0) * s, position + Vector2(42.0, 10.0) * s, Color(0.22, 0.25, 0.26), 4.0 * s)
	draw_circle(position + Vector2(-4.0, -24.0) * s, 1.5 * s, Color(0.05, 0.03, 0.02))
	draw_circle(position + Vector2(4.0, -24.0) * s, 1.5 * s, Color(0.05, 0.03, 0.02))


func _draw_horse_actor(position: Vector2, role: String, actor_scale: float, palette: String) -> void:
	var s := actor_scale
	var body_color := Color(0.34, 0.18, 0.11)
	var mane_color := Color(0.08, 0.05, 0.035)
	match role:
		"charger":
			body_color = Color(0.48, 0.22, 0.14)
		"spitter":
			body_color = Color(0.28, 0.32, 0.18)
		"armored":
			body_color = Color(0.24, 0.24, 0.22)
			mane_color = Color(0.72, 0.66, 0.52)
		"spectral":
			body_color = Color(0.62, 0.68, 0.64)
			mane_color = Color(0.86, 0.92, 0.86)
		"boss":
			body_color = Color(0.18, 0.08, 0.06)
			mane_color = Color(0.90, 0.22, 0.12)
	if palette == "snow":
		body_color = body_color.lightened(0.28)
	elif palette == "volcano":
		body_color = body_color.lerp(Color(0.66, 0.16, 0.08), 0.45)
	elif palette == "corruption":
		body_color = body_color.lerp(Color(0.32, 0.06, 0.38), 0.55)
	draw_colored_polygon(_ellipse_points(position + Vector2(0.0, 26.0 * s), Vector2(34.0, 10.0) * s, 16, 0.0), Color(0.0, 0.0, 0.0, 0.34))
	draw_colored_polygon(_ellipse_points(position, Vector2(34.0, 18.0) * s, 20, -0.04), body_color)
	draw_colored_polygon(_ellipse_points(position + Vector2(38.0, -9.0) * s, Vector2(14.0, 11.0) * s, 14, -0.25), body_color.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(24.0, -18.0) * s,
		position + Vector2(34.0, -36.0) * s,
		position + Vector2(39.0, -12.0) * s,
	]), body_color.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(40.0, -19.0) * s,
		position + Vector2(54.0, -34.0) * s,
		position + Vector2(51.0, -8.0) * s,
	]), body_color.darkened(0.22))
	draw_line(position + Vector2(-18.0, -12.0) * s, position + Vector2(20.0, -16.0) * s, mane_color, 7.0 * s)
	for leg_x in [-21.0, -8.0, 10.0, 24.0]:
		draw_line(position + Vector2(leg_x, 12.0) * s, position + Vector2(leg_x - 4.0, 38.0) * s, body_color.darkened(0.22), 5.0 * s)
		draw_line(position + Vector2(leg_x - 5.0, 38.0) * s, position + Vector2(leg_x + 5.0, 38.0) * s, Color(0.06, 0.04, 0.03), 4.0 * s)
	draw_line(position + Vector2(-34.0, -4.0) * s, position + Vector2(-55.0, -20.0) * s, mane_color, 5.0 * s)
	if role == "armored" or role == "boss":
		draw_line(position + Vector2(-20.0, -3.0) * s, position + Vector2(24.0, -6.0) * s, Color(0.78, 0.70, 0.52), 5.0 * s)
		draw_line(position + Vector2(-20.0, 7.0) * s, position + Vector2(24.0, 4.0) * s, Color(0.64, 0.58, 0.45), 3.0 * s)
	if role == "spitter":
		draw_circle(position + Vector2(54.0, -8.0) * s, 5.0 * s, Color(0.58, 0.82, 0.18, 0.78))
	if role == "boss":
		draw_arc(position, 58.0 * s, 0.0, TAU, 42, Color(1.0, 0.18, 0.08, 0.60), 6.0 * s)


func _draw_cache_actor(position: Vector2, actor_scale: float) -> void:
	var s := actor_scale
	draw_colored_polygon(_ellipse_points(position + Vector2(0.0, 20.0 * s), Vector2(23.0, 7.0) * s, 12, 0.0), Color(0.0, 0.0, 0.0, 0.34))
	draw_rect(Rect2(position + Vector2(-22.0, -13.0) * s, Vector2(44.0, 30.0) * s), Color(0.34, 0.22, 0.12))
	draw_rect(Rect2(position + Vector2(-17.0, -8.0) * s, Vector2(34.0, 20.0) * s), Color(0.58, 0.38, 0.20))
	draw_line(position + Vector2(-22.0, 2.0) * s, position + Vector2(22.0, 2.0) * s, Color(0.22, 0.13, 0.08), 3.0 * s)
	draw_circle(position + Vector2(0.0, 2.0) * s, 4.0 * s, Color(0.92, 0.70, 0.28))


func _draw_wagon_actor(position: Vector2, actor_scale: float) -> void:
	var s := actor_scale
	draw_colored_polygon(_ellipse_points(position + Vector2(0.0, 18.0 * s), Vector2(44.0, 10.0) * s, 16, 0.0), Color(0.0, 0.0, 0.0, 0.28))
	draw_rect(Rect2(position + Vector2(-34.0, -18.0) * s, Vector2(68.0, 34.0) * s), Color(0.42, 0.25, 0.14))
	draw_rect(Rect2(position + Vector2(-25.0, -12.0) * s, Vector2(50.0, 20.0) * s), Color(0.62, 0.44, 0.24))
	draw_circle(position + Vector2(-25.0, 18.0) * s, 10.0 * s, Color(0.12, 0.08, 0.05))
	draw_circle(position + Vector2(25.0, 18.0) * s, 10.0 * s, Color(0.12, 0.08, 0.05))
	draw_line(position + Vector2(34.0, -2.0) * s, position + Vector2(62.0, -8.0) * s, Color(0.30, 0.18, 0.10), 5.0 * s)


func _draw_standard_actor(position: Vector2, role: String, actor_scale: float) -> void:
	var s := actor_scale
	match role:
		"route_gate":
			draw_line(position + Vector2(-20.0, 30.0) * s, position + Vector2(-20.0, -30.0) * s, Color(0.22, 0.13, 0.08), 6.0 * s)
			draw_line(position + Vector2(20.0, 30.0) * s, position + Vector2(20.0, -30.0) * s, Color(0.22, 0.13, 0.08), 6.0 * s)
			draw_line(position + Vector2(-26.0, -24.0) * s, position + Vector2(26.0, -24.0) * s, Color(0.64, 0.44, 0.24), 7.0 * s)
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(0.0, -38.0) * s,
				position + Vector2(16.0, -30.0) * s,
				position + Vector2(0.0, -22.0) * s,
				position + Vector2(-16.0, -30.0) * s,
			]), Color(0.45, 0.82, 1.0, 0.88))
		"combat_marker":
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(0.0, -34.0) * s,
				position + Vector2(26.0, 10.0) * s,
				position + Vector2(0.0, 34.0) * s,
				position + Vector2(-26.0, 10.0) * s,
			]), Color(0.55, 0.05, 0.04, 0.86))
			_draw_hoof_pair(position + Vector2(0.0, 6.0) * s, Color(1.0, 0.85, 0.48))
		_:
			draw_line(position + Vector2(0.0, 36.0) * s, position + Vector2(0.0, -38.0) * s, Color(0.20, 0.12, 0.08), 6.0 * s)
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(0.0, -38.0) * s,
				position + Vector2(48.0, -28.0) * s,
				position + Vector2(34.0, 6.0) * s,
				position + Vector2(0.0, -4.0) * s,
			]), Color(0.74, 0.18, 0.12))


func _ellipse_points(center: Vector2, radii: Vector2, steps: int, rotation := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := float(index) * TAU / float(steps)
		var point := Vector2(cos(angle) * radii.x, sin(angle) * radii.y).rotated(rotation)
		points.append(center + point)
	return points


func _vector_to_dict(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _draw_structures_by_layer(target_layer: int) -> void:
	for structure in _structures:
		if int(structure.get("layer", 0)) != target_layer:
			continue
		var structure_type := String(structure.get("type", ""))
		match structure_type:
			"edge_band":
				var band_rect := _rect_from_dict(structure.get("rect", {}), Rect2())
				draw_rect(band_rect, biome_color.darkened(float(structure.get("strength", 0.08))))
			"edge_obstacle":
				var edge_position := _vector_from_dict(structure.get("position", {}))
				var edge_size := float(structure.get("size", 20.0))
				_draw_edge_obstacle(edge_position, edge_size)
			"yard":
				_draw_yard(_rect_from_dict(structure.get("rect", {}), Rect2()), String(structure.get("style", "camp")))
			"palisade":
				var wall_rect := _rect_from_dict(structure.get("rect", {}), Rect2())
				draw_rect(wall_rect, Color(0.20, 0.12, 0.08))
				draw_rect(Rect2(wall_rect.position + Vector2(0.0, 2.0), Vector2(wall_rect.size.x, max(wall_rect.size.y - 4.0, 2.0))), Color(0.42, 0.28, 0.16))
			"tent":
				_draw_tent_rect(_rect_from_dict(structure.get("rect", {}), Rect2()))
			"shack":
				_draw_shack(_rect_from_dict(structure.get("rect", {}), Rect2()))
			"hall":
				_draw_hall(_rect_from_dict(structure.get("rect", {}), Rect2()))
			"tower":
				_draw_tower(_rect_from_dict(structure.get("rect", {}), Rect2()))
			"banner":
				_draw_banner(_vector_from_dict(structure.get("position", {})))
			"crate_stack":
				_draw_crate_stack(_rect_from_dict(structure.get("rect", {}), Rect2()))
			"broken_wagon":
				_draw_broken_wagon(_rect_from_dict(structure.get("rect", {}), Rect2()))
			"field":
				_draw_field(_rect_from_dict(structure.get("rect", {}), Rect2()))
			"farmhouse":
				_draw_farmhouse(_rect_from_dict(structure.get("rect", {}), Rect2()))
			"watch_post":
				_draw_watch_post(_rect_from_dict(structure.get("rect", {}), Rect2()))
			"boss_arena":
				_draw_boss_arena(_rect_from_dict(structure.get("rect", {}), Rect2()))
			"campfire":
				_draw_campfire(_vector_from_dict(structure.get("position", {})))
			"signpost":
				_draw_signpost(_vector_from_dict(structure.get("position", {})))
			"arena_gate":
				_draw_arena_gate(_vector_from_dict(structure.get("position", {})))
			"town_cluster":
				_draw_town_cluster(_vector_from_dict(structure.get("position", {})), String(structure.get("site_type", "settlement")))
			"cave_mouth":
				_draw_cave_mouth(_vector_from_dict(structure.get("position", {})))
			"dungeon_gate":
				_draw_dungeon_gate(_vector_from_dict(structure.get("position", {})))
			"temple_ruin":
				_draw_temple_ruin(_vector_from_dict(structure.get("position", {})), String(structure.get("site_type", "temple")))
			"horse_site":
				_draw_horse_site(_vector_from_dict(structure.get("position", {})), String(structure.get("site_type", "horse_site")))
			"mine_head":
				_draw_mine_head(_vector_from_dict(structure.get("position", {})))
			"volcano":
				_draw_volcano(_vector_from_dict(structure.get("position", {})))


func _draw_location_emblems() -> void:
	for location in locations:
		var position := _location_position(location)
		var location_id := String(location.get("id", ""))
		var location_type := String(location.get("type", "landmark"))
		draw_circle(position + Vector2(0.0, 3.0), 22.0, Color(0.03, 0.02, 0.015, 0.6))
		draw_circle(position, 18.0, _emblem_color(location_type))
		draw_circle(position, 8.0, Color(0.15, 0.11, 0.08))
		if location_type == "city":
			draw_rect(Rect2(position + Vector2(-9.0, -13.0), Vector2(18.0, 20.0)), Color(0.86, 0.80, 0.64))
			draw_rect(Rect2(position + Vector2(-3.0, -18.0), Vector2(6.0, 10.0)), Color(0.86, 0.80, 0.64))
		elif location_type == "town" or location_type == "village" or location_type == "settlement":
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(-11.0, 1.0),
				position + Vector2(0.0, -11.0),
				position + Vector2(11.0, 1.0),
				position + Vector2(8.0, 10.0),
				position + Vector2(-8.0, 10.0),
			]), Color(0.88, 0.74, 0.50))
		elif location_type == "cave":
			draw_arc(position + Vector2(0.0, 5.0), 11.0, PI, TAU, 16, Color(0.06, 0.05, 0.045), 5.0)
		elif location_type == "dungeon":
			draw_rect(Rect2(position + Vector2(-9.0, -11.0), Vector2(18.0, 19.0)), Color(0.16, 0.14, 0.13))
			draw_line(position + Vector2(-7.0, -2.0), position + Vector2(7.0, -2.0), Color(0.74, 0.66, 0.50), 2.0)
		elif location_type == "temple" or location_type == "shrine":
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(-12.0, 6.0),
				position + Vector2(0.0, -13.0),
				position + Vector2(12.0, 6.0),
			]), Color(0.82, 0.78, 0.66))
		elif location_type == "horse_site" or location_type == "horse_lair" or location_type == "stable_fort":
			_draw_hoof_pair(position + Vector2(0.0, 1.0), Color(0.96, 0.88, 0.62))
		elif location_type == "mine":
			draw_line(position + Vector2(-9.0, 8.0), position + Vector2(9.0, -8.0), Color(0.82, 0.72, 0.56), 4.0)
			draw_line(position + Vector2(-9.0, -8.0), position + Vector2(9.0, 8.0), Color(0.82, 0.72, 0.56), 3.0)
		elif location_type == "volcano":
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(-12.0, 9.0),
				position + Vector2(0.0, -14.0),
				position + Vector2(12.0, 9.0),
			]), Color(0.70, 0.18, 0.08))
			draw_circle(position + Vector2(0.0, -3.0), 4.0, Color(1.0, 0.55, 0.12))
		elif location_type == "boss" or location_id.contains("arena"):
			draw_arc(position, 10.0, PI, TAU, 18, Color(0.82, 0.76, 0.66), 3.0)
		elif location_id.contains("camp"):
			draw_circle(position + Vector2(0.0, -2.0), 5.0, Color(0.90, 0.54, 0.24))
		elif location_id.contains("forest"):
			draw_circle(position + Vector2(0.0, -5.0), 7.0, Color(0.07, 0.25, 0.13))
		elif location_id.contains("farm"):
			draw_rect(Rect2(position + Vector2(-8.0, -10.0), Vector2(16.0, 14.0)), Color(0.54, 0.28, 0.18))


func _draw_region_frame() -> void:
	draw_rect(world_bounds, Color(0.0, 0.0, 0.0, 0.0), false, 6.0)


func _add_gate_palisade(rect: Rect2, gate_side: String) -> void:
	var thickness := 16.0
	var gate_width := 100.0
	var left_segment := Rect2(rect.position.x, rect.position.y, rect.size.x, thickness)
	var right_segment := Rect2(rect.position.x, rect.end.y - thickness, rect.size.x, thickness)
	var top_segment := Rect2(rect.position.x, rect.position.y, thickness, rect.size.y)
	var bottom_segment := Rect2(rect.end.x - thickness, rect.position.y, thickness, rect.size.y)
	_add_wall_segment(left_segment)
	_add_wall_segment(top_segment)
	_add_wall_segment(bottom_segment)
	if gate_side == "north":
		_add_wall_segment(Rect2(rect.position.x, rect.end.y - thickness, (rect.size.x - gate_width) * 0.5, thickness))
		_add_wall_segment(Rect2(rect.position.x + (rect.size.x + gate_width) * 0.5, rect.end.y - thickness, (rect.size.x - gate_width) * 0.5, thickness))
	else:
		_add_wall_segment(Rect2(rect.position.x, rect.position.y, (rect.size.x - gate_width) * 0.5, thickness))
		_add_wall_segment(Rect2(rect.position.x + (rect.size.x + gate_width) * 0.5, rect.position.y, (rect.size.x - gate_width) * 0.5, thickness))


func _add_wall_segment(rect: Rect2) -> void:
	_structures.append({"type": "palisade", "layer": 1, "rect": _rect_to_dict(rect)})
	_create_collider_rect(rect, "Wall_" + str(_structures.size()))


func _add_building(building: Dictionary) -> void:
	var building_rect := _rect_from_dict(building.get("rect", {}), Rect2(0.0, 0.0, 64.0, 48.0))
	var entry := building.duplicate(true)
	entry["layer"] = 1
	entry["rect"] = _rect_to_dict(building_rect)
	_structures.append(entry)
	var solid_margin := 6.0
	_create_collider_rect(Rect2(building_rect.position + Vector2(solid_margin, solid_margin), building_rect.size - Vector2(solid_margin * 2.0, solid_margin * 2.0)), String(building.get("type", "building")) + "_" + str(_structures.size()))


func _create_collider_rect(rect: Rect2, body_name: String) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = 8
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.position + rect.size * 0.5
	body.add_child(shape)
	_collision_layer.add_child(body)


func _resolve_interaction_position(interaction: Dictionary) -> Vector2:
	var explicit_position: Dictionary = interaction.get("position", {}) as Dictionary
	if not explicit_position.is_empty():
		return _vector_from_dict(explicit_position)

	var location_position := get_location_position(String(interaction.get("location_id", "")))
	var offset: Dictionary = interaction.get("anchor_offset", {}) as Dictionary
	if not offset.is_empty():
		return location_position + _vector_from_dict(offset)
	return location_position


func _point_is_reserved(position: Vector2) -> bool:
	for settlement in _settlements:
		var settlement_rect := _rect_from_dict(settlement.get("rect", {}), Rect2())
		if settlement_rect.grow(54.0).has_point(position):
			return true
	for road in road_paths:
		for point in road:
			if point.distance_to(position) < 54.0:
				return true
	for location in locations:
		if _location_position(location).distance_to(position) < 72.0:
			return true
	return false


func _draw_tree_cluster(position: Vector2, size: float) -> void:
	draw_rect(Rect2(position + Vector2(-4.0, 0.0), Vector2(8.0, size)), Color(0.26, 0.14, 0.07))
	draw_circle(position + Vector2(0.0, -size * 0.4), size, Color(0.08, 0.27, 0.15))
	draw_circle(position + Vector2(-size * 0.55, -size * 0.15), size * 0.72, Color(0.10, 0.33, 0.17))
	draw_circle(position + Vector2(size * 0.55, -size * 0.1), size * 0.68, Color(0.06, 0.24, 0.12))


func _draw_rock_cluster(position: Vector2, size: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-size, size * 0.6),
		position + Vector2(-size * 0.25, -size * 0.8),
		position + Vector2(size * 0.9, -size * 0.15),
		position + Vector2(size * 0.55, size * 0.82),
	]), Color(0.42, 0.42, 0.42))
	draw_line(position + Vector2(-size * 0.1, -size * 0.58), position + Vector2(size * 0.16, size * 0.2), Color(0.62, 0.62, 0.62), 2.0)


func _draw_blight_growth(position: Vector2, size: float) -> void:
	for angle_index in range(6):
		var angle := float(angle_index) * TAU / 6.0
		var tip := position + Vector2(cos(angle), sin(angle)) * size
		draw_line(position, tip, Color(0.68, 0.22, 0.80), 3.0)
		draw_circle(tip, 4.0, Color(0.88, 0.52, 0.92))
	draw_circle(position, size * 0.38, Color(0.28, 0.08, 0.34))


func _draw_edge_obstacle(position: Vector2, size: float) -> void:
	match biome:
		"forest", "grassland":
			_draw_tree_cluster(position, size)
		"snow":
			draw_circle(position, size, Color(0.88, 0.92, 0.96))
		"coast":
			draw_circle(position, size, Color(0.15, 0.34, 0.39))
		"mountain":
			_draw_rock_cluster(position, size)
		"volcano":
			draw_circle(position, size, Color(0.24, 0.14, 0.12))
			draw_circle(position + Vector2(4.0, -4.0), size * 0.25, Color(0.94, 0.30, 0.09))
		"badlands":
			draw_circle(position, size, Color(0.56, 0.32, 0.20))
		_:
			draw_circle(position, size, Color(0.22, 0.08, 0.24))


func _draw_yard(rect: Rect2, style: String) -> void:
	var base_color := accent_color.darkened(0.36)
	if style == "outpost":
		base_color = accent_color.darkened(0.28)
	draw_rect(rect, base_color)
	for stripe in range(5):
		var start := Vector2(rect.position.x + 18.0, rect.position.y + 26.0 + float(stripe) * 46.0)
		draw_line(start, start + Vector2(rect.size.x - 36.0, 0.0), base_color.lightened(0.16), 3.0)


func _draw_tent_rect(rect: Rect2) -> void:
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(0.0, rect.size.y),
		rect.position + Vector2(rect.size.x * 0.5, 0.0),
		rect.position + Vector2(rect.size.x, rect.size.y),
	]), Color(0.60, 0.42, 0.26))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(rect.size.x * 0.12, rect.size.y),
		rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.18),
		rect.position + Vector2(rect.size.x * 0.88, rect.size.y),
	]), Color(0.74, 0.58, 0.36))
	draw_line(rect.position + Vector2(rect.size.x * 0.5, 0.0), rect.position + Vector2(rect.size.x * 0.5, rect.size.y), Color(0.20, 0.12, 0.08), 3.0)


func _draw_shack(rect: Rect2) -> void:
	draw_rect(rect, Color(0.40, 0.24, 0.14))
	draw_rect(Rect2(rect.position + Vector2(8.0, 12.0), rect.size - Vector2(16.0, 16.0)), Color(0.58, 0.40, 0.24))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(-6.0, 12.0),
		rect.position + Vector2(rect.size.x * 0.5, -18.0),
		rect.position + Vector2(rect.size.x + 6.0, 12.0),
	]), Color(0.28, 0.16, 0.11))


func _draw_hall(rect: Rect2) -> void:
	draw_rect(rect, Color(0.32, 0.18, 0.11))
	draw_rect(Rect2(rect.position + Vector2(10.0, 14.0), rect.size - Vector2(20.0, 18.0)), Color(0.56, 0.38, 0.22))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(-10.0, 14.0),
		rect.position + Vector2(rect.size.x * 0.5, -24.0),
		rect.position + Vector2(rect.size.x + 10.0, 14.0),
	]), Color(0.22, 0.12, 0.09))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.5 - 12.0, rect.size.y - 30.0), Vector2(24.0, 30.0)), Color(0.18, 0.10, 0.07))


func _draw_tower(rect: Rect2) -> void:
	draw_rect(rect, Color(0.30, 0.18, 0.10))
	draw_rect(Rect2(rect.position + Vector2(8.0, 8.0), rect.size - Vector2(16.0, 16.0)), Color(0.48, 0.34, 0.22))
	draw_line(rect.position + Vector2(rect.size.x * 0.5, 0.0), rect.position + Vector2(rect.size.x * 0.5, rect.size.y), Color(0.22, 0.12, 0.08), 3.0)


func _draw_banner(position: Vector2) -> void:
	draw_line(position + Vector2(0.0, 34.0), position + Vector2(0.0, -34.0), Color(0.22, 0.12, 0.08), 4.0)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(0.0, -30.0),
		position + Vector2(42.0, -22.0),
		position + Vector2(28.0, 4.0),
		position + Vector2(0.0, -2.0),
	]), Color(0.66, 0.14, 0.10))


func _draw_crate_stack(rect: Rect2) -> void:
	var half_size := rect.size * 0.5
	draw_rect(Rect2(rect.position, half_size), Color(0.46, 0.30, 0.18))
	draw_rect(Rect2(rect.position + Vector2(half_size.x, 8.0), half_size), Color(0.40, 0.26, 0.16))
	draw_rect(Rect2(rect.position + Vector2(12.0, half_size.y), half_size), Color(0.54, 0.36, 0.20))


func _draw_broken_wagon(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(20.0, 18.0), rect.size - Vector2(40.0, 28.0)), Color(0.46, 0.30, 0.18))
	draw_circle(rect.position + Vector2(24.0, rect.size.y - 8.0), 16.0, Color(0.20, 0.14, 0.10))
	draw_circle(rect.position + Vector2(rect.size.x - 24.0, rect.size.y - 8.0), 16.0, Color(0.20, 0.14, 0.10))
	draw_line(rect.position + Vector2(0.0, 16.0), rect.position + Vector2(22.0, 24.0), Color(0.28, 0.18, 0.10), 5.0)


func _draw_field(rect: Rect2) -> void:
	draw_rect(rect, Color(0.34, 0.24, 0.14))
	for row in range(6):
		var start := rect.position + Vector2(12.0, 12.0 + float(row) * 16.0)
		draw_line(start, start + Vector2(rect.size.x - 24.0, 0.0), Color(0.64, 0.54, 0.24), 2.0)


func _draw_farmhouse(rect: Rect2) -> void:
	draw_rect(rect, Color(0.58, 0.36, 0.22))
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(-8.0, 12.0),
		rect.position + Vector2(rect.size.x * 0.5, -20.0),
		rect.position + Vector2(rect.size.x + 8.0, 12.0),
	]), Color(0.34, 0.16, 0.10))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.5 - 10.0, rect.size.y - 28.0), Vector2(20.0, 28.0)), Color(0.18, 0.10, 0.06))


func _draw_watch_post(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.38, 0.0), Vector2(rect.size.x * 0.24, rect.size.y)), Color(0.30, 0.18, 0.10))
	draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 20.0), rect.size), Color(0.50, 0.34, 0.20))
	draw_line(rect.position + Vector2(0.0, rect.size.y - 20.0), rect.position + Vector2(rect.size.x, rect.size.y - 20.0), Color(0.18, 0.10, 0.06), 3.0)


func _draw_boss_arena(rect: Rect2) -> void:
	draw_rect(rect, Color(0.18, 0.13, 0.10))
	draw_arc(rect.get_center(), min(rect.size.x, rect.size.y) * 0.36, 0.0, TAU, 40, Color(0.66, 0.52, 0.36), 8.0)
	for spike_index in range(8):
		var angle := float(spike_index) * TAU / 8.0
		var base: Vector2 = rect.get_center() + Vector2(cos(angle), sin(angle)) * min(rect.size.x, rect.size.y) * 0.42
		draw_line(base, base + Vector2(cos(angle), sin(angle)) * 24.0, Color(0.78, 0.72, 0.64), 5.0)


func _draw_campfire(position: Vector2) -> void:
	draw_circle(position, 10.0, Color(0.22, 0.12, 0.08))
	draw_line(position + Vector2(-10.0, 8.0), position + Vector2(10.0, -8.0), Color(0.42, 0.28, 0.16), 3.0)
	draw_line(position + Vector2(-8.0, -6.0), position + Vector2(8.0, 8.0), Color(0.42, 0.28, 0.16), 3.0)
	draw_circle(position + Vector2(0.0, -8.0), 6.0, Color(0.98, 0.54, 0.18))


func _draw_signpost(position: Vector2) -> void:
	draw_line(position + Vector2(0.0, 24.0), position + Vector2(0.0, -18.0), Color(0.22, 0.12, 0.08), 4.0)
	draw_rect(Rect2(position + Vector2(0.0, -22.0), Vector2(42.0, 18.0)), Color(0.56, 0.40, 0.22))


func _draw_arena_gate(position: Vector2) -> void:
	draw_line(position + Vector2(-44.0, 42.0), position + Vector2(-44.0, -22.0), Color(0.12, 0.08, 0.06), 8.0)
	draw_line(position + Vector2(44.0, 42.0), position + Vector2(44.0, -22.0), Color(0.12, 0.08, 0.06), 8.0)
	draw_line(position + Vector2(-52.0, -22.0), position + Vector2(52.0, -22.0), Color(0.46, 0.32, 0.18), 9.0)
	draw_circle(position + Vector2(0.0, -34.0), 14.0, Color(0.82, 0.76, 0.66))


func _draw_town_cluster(position: Vector2, site_type: String) -> void:
	var radius := 46.0
	if site_type == "city":
		radius = 86.0
	elif site_type == "town" or site_type == "harbor":
		radius = 68.0
	elif site_type == "village" or site_type == "fort":
		radius = 56.0
	draw_circle(position + Vector2(0.0, 10.0), radius, Color(0.03, 0.02, 0.015, 0.22))
	for index in range(6 if site_type != "city" else 10):
		var angle := float(index) * TAU / float(6 if site_type != "city" else 10)
		var center := position + Vector2(cos(angle), sin(angle)) * radius * 0.46
		var size := Vector2(24.0 + float(index % 3) * 8.0, 20.0 + float((index + 1) % 2) * 8.0)
		_draw_mini_roof_house(Rect2(center - size * 0.5, size), site_type)
	if site_type == "fort":
		draw_arc(position, radius * 0.72, 0.0, TAU, 28, Color(0.24, 0.15, 0.09), 6.0)
	elif site_type == "harbor":
		draw_line(position + Vector2(-radius * 0.8, radius * 0.45), position + Vector2(radius * 0.8, radius * 0.45), Color(0.84, 0.76, 0.48), 5.0)


func _draw_mini_roof_house(rect: Rect2, site_type: String) -> void:
	var wall_color := Color(0.62, 0.44, 0.28)
	var roof_color := Color(0.28, 0.13, 0.08)
	if site_type == "city":
		wall_color = Color(0.58, 0.54, 0.48)
		roof_color = Color(0.22, 0.20, 0.18)
	elif site_type == "fort":
		wall_color = Color(0.42, 0.34, 0.26)
	draw_rect(rect, wall_color)
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(-4.0, 6.0),
		rect.position + Vector2(rect.size.x * 0.5, -8.0),
		rect.position + Vector2(rect.size.x + 4.0, 6.0),
	]), roof_color)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.45, rect.size.y - 9.0), Vector2(6.0, 9.0)), Color(0.12, 0.08, 0.05))


func _draw_cave_mouth(position: Vector2) -> void:
	draw_circle(position + Vector2(0.0, 10.0), 56.0, Color(0.02, 0.018, 0.014, 0.42))
	_draw_rock_cluster(position + Vector2(-35.0, 2.0), 28.0)
	_draw_rock_cluster(position + Vector2(36.0, 4.0), 30.0)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-48.0, 18.0),
		position + Vector2(-26.0, -30.0),
		position + Vector2(0.0, -46.0),
		position + Vector2(28.0, -28.0),
		position + Vector2(50.0, 18.0),
	]), Color(0.20, 0.19, 0.17))
	draw_arc(position + Vector2(0.0, 20.0), 32.0, PI, TAU, 24, Color(0.015, 0.012, 0.01), 22.0)


func _draw_dungeon_gate(position: Vector2) -> void:
	draw_rect(Rect2(position + Vector2(-56.0, -34.0), Vector2(112.0, 82.0)), Color(0.13, 0.12, 0.11))
	draw_rect(Rect2(position + Vector2(-44.0, -22.0), Vector2(88.0, 58.0)), Color(0.30, 0.28, 0.24))
	for bar in range(5):
		var x := position.x - 32.0 + float(bar) * 16.0
		draw_line(Vector2(x, position.y - 20.0), Vector2(x, position.y + 35.0), Color(0.05, 0.04, 0.035), 4.0)
	draw_line(position + Vector2(-42.0, -2.0), position + Vector2(42.0, -2.0), Color(0.70, 0.56, 0.34), 3.0)


func _draw_temple_ruin(position: Vector2, site_type: String) -> void:
	draw_circle(position + Vector2(0.0, 12.0), 62.0, Color(0.05, 0.045, 0.035, 0.26))
	var stone := Color(0.62, 0.58, 0.50)
	for column in range(4):
		var x := position.x - 42.0 + float(column) * 28.0
		draw_rect(Rect2(Vector2(x, position.y - 24.0), Vector2(12.0, 56.0)), stone.darkened(float(column % 2) * 0.08))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-62.0, -24.0),
		position + Vector2(0.0, -58.0),
		position + Vector2(62.0, -24.0),
	]), stone.lightened(0.08))
	if site_type == "shrine":
		draw_circle(position + Vector2(0.0, 4.0), 12.0, Color(0.96, 0.72, 0.34, 0.72))


func _draw_horse_site(position: Vector2, site_type: String) -> void:
	draw_circle(position + Vector2(0.0, 8.0), 62.0, Color(0.03, 0.01, 0.01, 0.28))
	for rail in [-36.0, 36.0]:
		draw_line(position + Vector2(-58.0, rail), position + Vector2(58.0, rail), Color(0.30, 0.18, 0.10), 5.0)
	for post in range(5):
		var x := position.x - 52.0 + float(post) * 26.0
		draw_line(Vector2(x, position.y - 42.0), Vector2(x, position.y + 42.0), Color(0.20, 0.12, 0.08), 4.0)
	_draw_hoof_pair(position + Vector2(-14.0, 0.0), Color(0.02, 0.015, 0.01, 0.55))
	_draw_hoof_pair(position + Vector2(18.0, 18.0), Color(0.02, 0.015, 0.01, 0.55))
	if site_type == "stable_fort":
		draw_rect(Rect2(position + Vector2(-36.0, -22.0), Vector2(72.0, 42.0)), Color(0.38, 0.24, 0.14))
	elif site_type == "horse_lair":
		draw_circle(position + Vector2(0.0, -12.0), 18.0, Color(0.56, 0.10, 0.06, 0.48))


func _draw_mine_head(position: Vector2) -> void:
	draw_rect(Rect2(position + Vector2(-48.0, -18.0), Vector2(96.0, 52.0)), Color(0.16, 0.14, 0.12))
	draw_line(position + Vector2(-48.0, -18.0), position + Vector2(0.0, -50.0), Color(0.48, 0.34, 0.20), 7.0)
	draw_line(position + Vector2(48.0, -18.0), position + Vector2(0.0, -50.0), Color(0.48, 0.34, 0.20), 7.0)
	draw_line(position + Vector2(-24.0, 34.0), position + Vector2(-24.0, -10.0), Color(0.42, 0.30, 0.20), 5.0)
	draw_line(position + Vector2(24.0, 34.0), position + Vector2(24.0, -10.0), Color(0.42, 0.30, 0.20), 5.0)


func _draw_volcano(position: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-90.0, 58.0),
		position + Vector2(-36.0, -28.0),
		position + Vector2(-10.0, -72.0),
		position + Vector2(20.0, -70.0),
		position + Vector2(52.0, -26.0),
		position + Vector2(96.0, 58.0),
	]), Color(0.16, 0.12, 0.10))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-48.0, 40.0),
		position + Vector2(-12.0, -42.0),
		position + Vector2(18.0, -44.0),
		position + Vector2(56.0, 40.0),
	]), Color(0.28, 0.17, 0.12))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-18.0, -52.0),
		position + Vector2(0.0, -66.0),
		position + Vector2(20.0, -52.0),
		position + Vector2(10.0, -42.0),
		position + Vector2(-10.0, -42.0),
	]), Color(1.0, 0.38, 0.10))
	for stream_index in range(3):
		var x := -18.0 + float(stream_index) * 18.0
		draw_line(position + Vector2(x, -38.0), position + Vector2(x + 10.0, 30.0), Color(0.92, 0.18, 0.06, 0.72), 7.0)
		draw_line(position + Vector2(x, -38.0), position + Vector2(x + 10.0, 30.0), Color(1.0, 0.62, 0.16, 0.54), 3.0)
	draw_circle(position + Vector2(-42.0, 44.0), 12.0, Color(1.0, 0.25, 0.08, 0.42))
	draw_circle(position + Vector2(0.0, 42.0), 18.0, Color(0.08, 0.07, 0.06))


func _emblem_color(location_type: String) -> Color:
	match location_type:
		"city":
			return Color(0.92, 0.82, 0.56)
		"town", "harbor":
			return Color(0.82, 0.66, 0.38)
		"village", "settlement", "camp", "fort":
			return Color(0.68, 0.54, 0.34)
		"cave", "dungeon", "mine":
			return Color(0.44, 0.42, 0.38)
		"temple", "shrine":
			return Color(0.78, 0.74, 0.62)
		"horse_site", "horse_lair", "stable_fort":
			return Color(0.78, 0.28, 0.18)
		"boss":
			return Color(0.90, 0.16, 0.10)
		"route":
			return Color(0.54, 0.72, 0.58)
		_:
			return accent_color.lightened(0.14)


func _location_position(location: Dictionary) -> Vector2:
	var raw_position = location.get("position", {})
	if raw_position is Dictionary:
		return _vector_from_dict(raw_position)
	return Vector2.ZERO


func _count_label_children() -> int:
	var count := 0
	if _marker_layer == null:
		return count
	for child in _marker_layer.get_children():
		if child is Label:
			count += 1
	return count


func _location_type_counts() -> Dictionary:
	var counts := {}
	for location in locations:
		var location_type := String(location.get("type", "landmark"))
		counts[location_type] = int(counts.get(location_type, 0)) + 1
	return counts


func _sum_type_counts(counts: Dictionary, types: Array[String]) -> int:
	var total := 0
	for location_type in types:
		total += int(counts.get(location_type, 0))
	return total


func _rect_from_dict(value, fallback: Rect2) -> Rect2:
	if not value is Dictionary:
		return fallback
	return Rect2(
		float(value.get("x", fallback.position.x)),
		float(value.get("y", fallback.position.y)),
		float(value.get("w", fallback.size.x)),
		float(value.get("h", fallback.size.y))
	)


func _rect_to_dict(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"w": rect.size.x,
		"h": rect.size.y,
	}


func _vector_from_dict(value) -> Vector2:
	if not value is Dictionary:
		return Vector2.ZERO
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))


func _copy_dictionary_array(values: Array) -> Array[Dictionary]:
	var copied: Array[Dictionary] = []
	for value in values:
		if value is Dictionary:
			copied.append(value.duplicate(true))
	return copied


func _biome_color(value: String) -> Color:
	match value:
		"forest":
			return Color(0.08, 0.22, 0.14)
		"snow":
			return Color(0.70, 0.78, 0.82)
		"coast":
			return Color(0.10, 0.34, 0.42)
		"mountain":
			return Color(0.25, 0.27, 0.29)
		"volcano":
			return Color(0.22, 0.08, 0.06)
		"badlands":
			return Color(0.36, 0.20, 0.12)
		"corruption":
			return Color(0.16, 0.06, 0.18)
		_:
			return Color(0.18, 0.32, 0.18)


func _accent_color(value: String) -> Color:
	match value:
		"snow":
			return Color(0.44, 0.58, 0.70)
		"coast":
			return Color(0.77, 0.67, 0.42)
		"mountain":
			return Color(0.58, 0.54, 0.48)
		"volcano":
			return Color(0.92, 0.28, 0.08)
		"badlands":
			return Color(0.86, 0.48, 0.20)
		"corruption":
			return Color(0.74, 0.28, 0.84)
		_:
			return Color(0.72, 0.56, 0.32)
