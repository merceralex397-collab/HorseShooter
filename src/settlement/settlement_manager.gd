extends Node

var settlement_name := ""
var founded := false
var tier := "none"
var resources := {}
var buildings := []
var placed_buildings := {}
var follower_jobs := {}
var population := 0
var trade_routes := {}
var event_log: Array[Dictionary] = []
var corruption_pressure := 0
var city_metrics := {
	"food": 0,
	"water": 0,
	"timber": 0,
	"ore": 0,
	"medicine": 0,
	"ammo": 0,
	"morale": 0,
	"defense": 0,
	"trade": 0,
	"research": 0,
}


func found(new_name: String) -> void:
	settlement_name = new_name.strip_edges()
	if settlement_name.is_empty():
		settlement_name = "Spitehold"
	founded = true
	tier = "camp"
	population = max(population, 6)
	for key in city_metrics.keys():
		resources[key] = int(resources.get(key, city_metrics[key]))


func add_resource(resource_id: String, amount: int) -> void:
	resources[resource_id] = int(resources.get(resource_id, 0)) + amount


func build(building_id: String, required_tier := "camp") -> bool:
	if not founded:
		return false
	if not _tier_allows(required_tier):
		return false
	if not buildings.has(building_id):
		buildings.append(building_id)
		_apply_building_output(building_id)
	return true


func can_place_building(building_id: String, position: Vector2, size := Vector2(80.0, 60.0)) -> Dictionary:
	if not founded:
		return {"ok": false, "reason": "settlement_not_founded"}
	if building_id.strip_edges().is_empty():
		return {"ok": false, "reason": "missing_building_id"}
	var footprint := Rect2(position, size)
	for placed in placed_buildings.values():
		if not (placed is Dictionary):
			continue
		var rect := _rect_from_dict(placed.get("rect", {}))
		if rect.intersects(footprint.grow(8.0)):
			return {"ok": false, "reason": "blocked", "blocking_building": String(placed.get("id", ""))}
	return {"ok": true, "rect": _rect_to_dict(footprint)}


func place_building(building_id: String, position: Vector2, size := Vector2(80.0, 60.0), required_tier := "camp") -> Dictionary:
	var placement := can_place_building(building_id, position, size)
	if not bool(placement.get("ok", false)):
		return placement
	if not build(building_id, required_tier):
		return {"ok": false, "reason": "build_failed"}
	placed_buildings[building_id] = {
		"id": building_id,
		"rect": placement.get("rect", {}),
		"tier": tier,
	}
	return {"ok": true, "building_id": building_id, "rect": placement.get("rect", {})}


func has_building(building_id: String) -> bool:
	return buildings.has(building_id)


func upgrade_to(next_tier: String) -> void:
	if founded and can_upgrade_to(next_tier):
		tier = next_tier
		population = max(population, _population_floor_for_tier(next_tier))


func can_upgrade_to(next_tier: String) -> bool:
	if not founded:
		return false
	if not _is_next_or_current_tier(next_tier):
		return false
	var requirements := _tier_requirements(next_tier)
	if buildings.size() < int(requirements.get("buildings", 0)):
		return false
	for resource_id in requirements.get("resources", {}).keys():
		if int(resources.get(resource_id, 0)) < int(requirements["resources"][resource_id]):
			return false
	return true


func assign_follower(follower_id: String, job_id: String) -> bool:
	if not founded:
		return false
	follower_jobs[follower_id] = job_id
	_apply_job_output(job_id)
	return true


func create_trade_route(route_id: String, target_region_id: String, safety := 1, faction_id := "faction.roadwardens") -> Dictionary:
	if not founded:
		return {"ok": false, "reason": "settlement_not_founded"}
	trade_routes[route_id] = {
		"id": route_id,
		"target_region_id": target_region_id,
		"safety": clampi(safety, 0, 5),
		"faction_id": faction_id,
		"interrupted": false,
	}
	add_resource("trade", 4 + clampi(safety, 0, 5))
	var faction_manager := get_node_or_null("/root/FactionManager")
	if faction_manager and faction_manager.has_method("change_reputation"):
		faction_manager.call("change_reputation", faction_id, 2)
	return {"ok": true, "route": trade_routes[route_id].duplicate(true)}


func simulate_day() -> Dictionary:
	if not founded:
		return {"ok": false, "reason": "settlement_not_founded"}
	var production := {
		"food": 1 + int(population / 80),
		"water": 1 + int(population / 120),
		"timber": 1,
		"morale": 1,
	}
	for building_id in buildings:
		if String(building_id).contains("farm"):
			production["food"] = int(production.get("food", 0)) + 4
		elif String(building_id).contains("well"):
			production["water"] = int(production.get("water", 0)) + 4
		elif String(building_id).contains("trade") or String(building_id).contains("market"):
			production["trade"] = int(production.get("trade", 0)) + 3
		elif String(building_id).contains("research"):
			production["research"] = int(production.get("research", 0)) + 2
	for route in trade_routes.values():
		if route is Dictionary and not bool(route.get("interrupted", false)):
			production["trade"] = int(production.get("trade", 0)) + 2 + int(route.get("safety", 0))
			production["ore"] = int(production.get("ore", 0)) + 1
	for resource_id in production.keys():
		add_resource(resource_id, int(production[resource_id]))
	population += maxi(1, int(int(resources.get("morale", 0)) / 35))
	return {"ok": true, "production": production.duplicate(true), "population": population}


func trigger_raid(raid_id: String, strength: int, horse_faction := "faction.free_herd") -> Dictionary:
	if not founded:
		return {"ok": false, "reason": "settlement_not_founded"}
	var defense: int = int(resources.get("defense", 0)) + _job_count("guard") * 8 + _job_count("scout") * 3
	var raid_strength: int = maxi(strength, 1)
	var success: bool = defense >= raid_strength
	var damage: int = maxi(0, raid_strength - defense)
	if success:
		add_resource("morale", 5)
		add_resource("research", 1)
	else:
		resources["morale"] = maxi(0, int(resources.get("morale", 0)) - damage)
		resources["food"] = maxi(0, int(resources.get("food", 0)) - damage)
		population = maxi(0, population - int(ceil(float(damage) / 8.0)))
	for route_id in trade_routes.keys():
		if damage > 0 and int(trade_routes[route_id].get("safety", 0)) < 3:
			trade_routes[route_id]["interrupted"] = true
	var event := {
		"id": raid_id,
		"type": "horse_raid",
		"strength": raid_strength,
		"defense": defense,
		"success": success,
		"damage": damage,
	}
	event_log.append(event)
	var faction_manager := get_node_or_null("/root/FactionManager")
	if faction_manager and faction_manager.has_method("change_reputation"):
		faction_manager.call("change_reputation", horse_faction, 3 if not success else -2)
	return event.duplicate(true)


func get_ending_projection() -> Dictionary:
	var outcome := "survivor_camp"
	if tier == "city" and int(resources.get("defense", 0)) >= 50 and int(resources.get("morale", 0)) >= 30:
		outcome = "fortified_free_city"
	elif tier == "town" or tier == "city":
		outcome = "hard_won_town"
	elif corruption_pressure >= 50:
		outcome = "corrupted_holdout"
	return {
		"outcome": outcome,
		"tier": tier,
		"population": population,
		"trade_routes": trade_routes.size(),
		"raids_survived": _count_successful_raids(),
		"campaign_effects": _campaign_effects_for_outcome(outcome),
	}


func get_city_status() -> Dictionary:
	return {
		"name": settlement_name,
		"founded": founded,
		"tier": tier,
		"population": population,
		"resources": resources.duplicate(true),
		"buildings": buildings.duplicate(true),
		"placed_buildings": placed_buildings.duplicate(true),
		"follower_jobs": follower_jobs.duplicate(true),
		"trade_routes": trade_routes.duplicate(true),
		"event_log": event_log.duplicate(true),
		"corruption_pressure": corruption_pressure,
		"can_upgrade": _next_tier() != "" and can_upgrade_to(_next_tier()),
		"next_tier": _next_tier(),
	}


func export_state() -> Dictionary:
	return {
		"name": settlement_name,
		"founded": founded,
		"tier": tier,
		"resources": resources.duplicate(true),
		"buildings": buildings.duplicate(true),
		"placed_buildings": placed_buildings.duplicate(true),
		"follower_jobs": follower_jobs.duplicate(true),
		"population": population,
		"trade_routes": trade_routes.duplicate(true),
		"event_log": event_log.duplicate(true),
		"corruption_pressure": corruption_pressure,
		"city_metrics": city_metrics.duplicate(true),
	}


func import_state(state: Dictionary) -> void:
	settlement_name = String(state.get("name", state.get("settlement_name", "")))
	founded = bool(state.get("founded", false))
	tier = String(state.get("tier", "none"))
	resources = _dictionary_or_empty(state.get("resources", {}))
	buildings = _array_or_empty(state.get("buildings", []))
	placed_buildings = _dictionary_or_empty(state.get("placed_buildings", {}))
	follower_jobs = _dictionary_or_empty(state.get("follower_jobs", {}))
	population = int(state.get("population", 0))
	trade_routes = _dictionary_or_empty(state.get("trade_routes", {}))
	event_log = _array_or_empty(state.get("event_log", []))
	corruption_pressure = int(state.get("corruption_pressure", 0))
	if state.get("city_metrics", {}) is Dictionary:
		city_metrics = (state.get("city_metrics", {}) as Dictionary).duplicate(true)


func _tier_allows(required_tier: String) -> bool:
	var order := ["camp", "outpost", "hamlet", "village", "town", "city"]
	return order.find(tier) >= order.find(required_tier)


func _is_next_or_current_tier(next_tier: String) -> bool:
	var order := ["camp", "outpost", "hamlet", "village", "town", "city"]
	var current_index := order.find(tier)
	var next_index := order.find(next_tier)
	return next_index >= 0 and current_index >= 0 and next_index <= current_index + 1


func _next_tier() -> String:
	var order := ["camp", "outpost", "hamlet", "village", "town", "city"]
	var index := order.find(tier)
	if index < 0 or index >= order.size() - 1:
		return ""
	return order[index + 1]


func _tier_requirements(value: String) -> Dictionary:
	match value:
		"outpost":
			return {"buildings": 2, "resources": {"timber": 20, "food": 10}}
		"hamlet":
			return {"buildings": 5, "resources": {"timber": 45, "food": 30, "water": 20}}
		"village":
			return {"buildings": 9, "resources": {"timber": 80, "food": 60, "water": 45, "medicine": 15}}
		"town":
			return {"buildings": 14, "resources": {"timber": 130, "food": 100, "water": 80, "ore": 45, "trade": 25}}
		"city":
			return {"buildings": 20, "resources": {"timber": 220, "food": 160, "water": 140, "ore": 90, "medicine": 50, "defense": 50, "research": 35}}
		_:
			return {"buildings": 0, "resources": {}}


func _population_floor_for_tier(value: String) -> int:
	match value:
		"outpost":
			return 18
		"hamlet":
			return 45
		"village":
			return 110
		"town":
			return 320
		"city":
			return 900
		_:
			return 6


func _apply_building_output(building_id: String) -> void:
	if building_id.contains("watch") or building_id.contains("defense"):
		add_resource("defense", 5)
	elif building_id.contains("clinic") or building_id.contains("medicine"):
		add_resource("medicine", 4)
	elif building_id.contains("trade"):
		add_resource("trade", 4)
	elif building_id.contains("research"):
		add_resource("research", 4)
	elif building_id.contains("housing"):
		population += 8
	else:
		add_resource("timber", 2)


func _apply_job_output(job_id: String) -> void:
	match job_id:
		"scout":
			add_resource("defense", 2)
		"builder":
			add_resource("timber", 4)
		"doctor":
			add_resource("medicine", 3)
		"trader":
			add_resource("trade", 3)
		"researcher":
			add_resource("research", 3)
		_:
			add_resource("morale", 1)


func _job_count(job_id: String) -> int:
	var count := 0
	for assigned_job in follower_jobs.values():
		if String(assigned_job) == job_id:
			count += 1
	return count


func _count_successful_raids() -> int:
	var count := 0
	for event in event_log:
		if event is Dictionary and String(event.get("type", "")) == "horse_raid" and bool(event.get("success", false)):
			count += 1
	return count


func _campaign_effects_for_outcome(outcome: String) -> Array[String]:
	match outcome:
		"fortified_free_city":
			return ["finale_defense_bonus", "follower_morale_bonus", "roadwarden_alliance"]
		"hard_won_town":
			return ["finale_supply_bonus", "trade_route_support"]
		"corrupted_holdout":
			return ["finale_corruption_penalty", "refugee_pressure"]
		_:
			return ["small_supply_cache"]


func _rect_from_dict(value: Variant) -> Rect2:
	if value is Dictionary:
		return Rect2(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("w", 0.0)), float(value.get("h", 0.0)))
	return Rect2()


func _rect_to_dict(rect: Rect2) -> Dictionary:
	return {"x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y}


func _dictionary_or_empty(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}


func _array_or_empty(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []
