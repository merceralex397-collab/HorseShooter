extends Node

var items := {}
var equipped := {}
var ammo := {}
var weapon_heat := {}
var weapon_mods := {}
var crafting_materials := {}
var rarity_by_item := {}


func add_item(item_id: String, count := 1) -> void:
	items[item_id] = int(items.get(item_id, 0)) + max(count, 1)


func remove_item(item_id: String, count := 1) -> bool:
	var current := int(items.get(item_id, 0))
	if current < count:
		return false
	items[item_id] = current - count
	if int(items[item_id]) <= 0:
		items.erase(item_id)
	return true


func equip_item(slot: String, item_id: String) -> bool:
	if not items.has(item_id):
		return false
	equipped[slot] = item_id
	return true


func get_equipped(slot: String) -> String:
	return String(equipped.get(slot, ""))


func set_item_rarity(item_id: String, rarity: String) -> void:
	rarity_by_item[item_id] = rarity


func get_item_rarity(item_id: String) -> String:
	return String(rarity_by_item.get(item_id, "common"))


func add_ammo(ammo_type: String, count: int) -> void:
	ammo[ammo_type] = int(ammo.get(ammo_type, 0)) + max(count, 0)


func consume_ammo(ammo_type: String, count := 1) -> bool:
	var current := int(ammo.get(ammo_type, 0))
	if current < count:
		return false
	ammo[ammo_type] = current - count
	return true


func can_fire_weapon(weapon_id: String, ammo_type := "standard", heat_cost := 8, max_heat := 100) -> bool:
	if int(ammo.get(ammo_type, 0)) <= 0:
		return false
	return int(weapon_heat.get(weapon_id, 0)) + heat_cost <= max_heat


func register_weapon_fire(weapon_id: String, ammo_type := "standard", heat_cost := 8) -> bool:
	if not consume_ammo(ammo_type, 1):
		return false
	weapon_heat[weapon_id] = int(weapon_heat.get(weapon_id, 0)) + heat_cost
	return true


func cool_weapon(weapon_id: String, amount: int) -> void:
	weapon_heat[weapon_id] = max(0, int(weapon_heat.get(weapon_id, 0)) - max(amount, 0))


func install_weapon_mod(weapon_id: String, mod_id: String, max_slots := 2) -> bool:
	if not items.has(weapon_id) or not items.has(mod_id):
		return false
	var mods: Array = weapon_mods.get(weapon_id, [])
	if mods.size() >= max_slots or mods.has(mod_id):
		return false
	mods.append(mod_id)
	weapon_mods[weapon_id] = mods
	return true


func add_material(material_id: String, count: int) -> void:
	crafting_materials[material_id] = int(crafting_materials.get(material_id, 0)) + max(count, 0)


func craft_item(item_id: String, costs: Dictionary) -> bool:
	for material_id in costs.keys():
		if int(crafting_materials.get(material_id, 0)) < int(costs[material_id]):
			return false
	for material_id in costs.keys():
		crafting_materials[material_id] = int(crafting_materials[material_id]) - int(costs[material_id])
	add_item(item_id, 1)
	return true


func export_state() -> Dictionary:
	return {
		"items": items.duplicate(true),
		"equipped": equipped.duplicate(true),
		"ammo": ammo.duplicate(true),
		"weapon_heat": weapon_heat.duplicate(true),
		"weapon_mods": weapon_mods.duplicate(true),
		"crafting_materials": crafting_materials.duplicate(true),
		"rarity_by_item": rarity_by_item.duplicate(true),
	}


func import_state(state: Dictionary) -> void:
	items = _dictionary_or_empty(state.get("items", {}))
	equipped = _dictionary_or_empty(state.get("equipped", {}))
	ammo = _dictionary_or_empty(state.get("ammo", {}))
	weapon_heat = _dictionary_or_empty(state.get("weapon_heat", {}))
	weapon_mods = _dictionary_or_empty(state.get("weapon_mods", {}))
	crafting_materials = _dictionary_or_empty(state.get("crafting_materials", state.get("materials", {})))
	rarity_by_item = _dictionary_or_empty(state.get("rarity_by_item", {}))


func _dictionary_or_empty(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}
