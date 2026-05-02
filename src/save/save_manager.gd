extends Node

const SAVE_VERSION := 2
const SAVE_DIR := "user://saves"
const MAX_NAME_LENGTH := 24
const MANAGER_PATHS := {
	"quests": "/root/QuestManager",
	"inventory": "/root/InventoryManager",
	"progression": "/root/ProgressionManager",
	"followers": "/root/FollowerManager",
	"settlement": "/root/SettlementManager",
	"factions": "/root/FactionManager",
	"combat": "/root/CombatDirector",
	"dialogue": "/root/DialogueManager",
}

var active_slot_id := ""
var active_save: Dictionary = {}


func _ready() -> void:
	_ensure_save_dir()


func validate_character_name(raw_name: String) -> Dictionary:
	var trimmed := raw_name.strip_edges()
	if trimmed.is_empty():
		return {"valid": false, "name": "", "error": "Enter a name."}
	if trimmed.length() > MAX_NAME_LENGTH:
		return {"valid": false, "name": trimmed, "error": "Use 24 characters or fewer."}
	for i in trimmed.length():
		var code := trimmed.unicode_at(i)
		if code < 32 or code == 127:
			return {"valid": false, "name": trimmed, "error": "Name contains unsupported characters."}
	var probe := JSON.stringify({"name": trimmed})
	if probe.is_empty():
		return {"valid": false, "name": trimmed, "error": "Name cannot be saved."}
	return {"valid": true, "name": trimmed, "error": ""}


func create_new_game(slot_id: String, character_name: String) -> Dictionary:
	var validation := validate_character_name(character_name)
	if not bool(validation.get("valid", false)):
		return {"error": validation.get("error", "Invalid name.")}

	var normalized_slot := _normalize_slot_id(slot_id)
	var now := Time.get_unix_time_from_system()
	var save_data := _default_save(normalized_slot, String(validation["name"]), now)
	if not save_slot(normalized_slot, save_data):
		return {"error": "Unable to write save slot."}
	active_slot_id = normalized_slot
	active_save = save_data.duplicate(true)
	return active_save.duplicate(true)


func save_slot(slot_id: String, save_data: Dictionary) -> bool:
	_ensure_save_dir()
	var normalized_slot := _normalize_slot_id(slot_id)
	var migrated := migrate_save(save_data)
	migrated["slot_id"] = normalized_slot
	migrated["timestamp"] = Time.get_unix_time_from_system()
	var file := FileAccess.open(_slot_path(normalized_slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(migrated, "\t"))
	file.close()
	return true


func load_slot(slot_id: String) -> Dictionary:
	var normalized_slot := _normalize_slot_id(slot_id)
	var path := _slot_path(normalized_slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	if not (parsed is Dictionary):
		return {}
	var migrated := migrate_save(parsed as Dictionary)
	active_slot_id = normalized_slot
	active_save = migrated.duplicate(true)
	return migrated


func delete_slot(slot_id: String) -> void:
	var normalized_slot := _normalize_slot_id(slot_id)
	var path := _slot_path(normalized_slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if active_slot_id == normalized_slot:
		active_slot_id = ""
		active_save = {}


func slot_exists(slot_id: String) -> bool:
	return FileAccess.file_exists(_slot_path(_normalize_slot_id(slot_id)))


func list_slots() -> Array:
	_ensure_save_dir()
	var slots := []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return slots
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var slot_id := file_name.get_basename()
			var data := load_slot(slot_id)
			if not data.is_empty():
				slots.append({
					"slot_id": slot_id,
					"chosen_character_name": String(data.get("chosen_character_name", "")),
					"timestamp": int(data.get("timestamp", 0)),
				})
		file_name = dir.get_next()
	dir.list_dir_end()
	return slots


func migrate_save(raw_save: Dictionary) -> Dictionary:
	var version := int(raw_save.get("version", 0))
	var migrated := raw_save.duplicate(true)
	if version <= 0:
		migrated["version"] = SAVE_VERSION
	if int(migrated.get("version", SAVE_VERSION)) > SAVE_VERSION:
		return {}

	var slot_id := _normalize_slot_id(String(migrated.get("slot_id", "slot_1")))
	var chosen_name := String(migrated.get("chosen_character_name", "Rider")).strip_edges()
	if not bool(validate_character_name(chosen_name).get("valid", false)):
		chosen_name = "Rider"
	var timestamp := int(migrated.get("timestamp", Time.get_unix_time_from_system()))
	var defaults := _default_save(slot_id, chosen_name, timestamp)
	_deep_merge(defaults, migrated)
	defaults["version"] = SAVE_VERSION
	defaults["slot_id"] = slot_id
	defaults["chosen_character_name"] = chosen_name
	return defaults


func get_active_character_name() -> String:
	return String(active_save.get("chosen_character_name", "Rider"))


func get_setting(setting_id: String, fallback: Variant = null) -> Variant:
	var settings: Dictionary = active_save.get("settings", _default_save("slot_1", "Rider", 0).get("settings", {}))
	return settings.get(setting_id, fallback)


func set_setting(setting_id: String, value: Variant) -> void:
	if active_save.is_empty():
		active_save = _default_save("slot_1", "Rider", Time.get_unix_time_from_system())
	if not active_save.has("settings") or not (active_save["settings"] is Dictionary):
		active_save["settings"] = {}
	active_save["settings"][setting_id] = value
	if not active_slot_id.is_empty():
		save_slot(active_slot_id, active_save)


func capture_release_state(world_node: Node = null) -> Dictionary:
	if active_save.is_empty():
		active_save = _default_save("slot_1", "Rider", Time.get_unix_time_from_system())
	for section in MANAGER_PATHS.keys():
		var manager := get_node_or_null(String(MANAGER_PATHS[section]))
		if manager and manager.has_method("export_state"):
			active_save[section] = manager.call("export_state")
	if world_node and world_node.has_method("export_state"):
		active_save["world"] = world_node.call("export_state")
	active_save["timestamp"] = Time.get_unix_time_from_system()
	return active_save.duplicate(true)


func apply_release_state(save_data: Dictionary, world_node: Node = null) -> bool:
	var migrated := migrate_save(save_data)
	if migrated.is_empty():
		return false
	active_save = migrated.duplicate(true)
	active_slot_id = _normalize_slot_id(String(migrated.get("slot_id", active_slot_id)))
	for section in MANAGER_PATHS.keys():
		var manager := get_node_or_null(String(MANAGER_PATHS[section]))
		if manager and manager.has_method("import_state") and migrated.get(section, {}) is Dictionary:
			manager.call("import_state", migrated.get(section, {}))
	if world_node and world_node.has_method("import_state") and migrated.get("world", {}) is Dictionary:
		world_node.call("import_state", migrated.get("world", {}))
	return true


func autosave_active_game(world_node: Node = null) -> bool:
	if active_slot_id.is_empty():
		active_slot_id = _normalize_slot_id(String(active_save.get("slot_id", "slot_1")))
	capture_release_state(world_node)
	return save_slot(active_slot_id, active_save)


func export_state() -> Dictionary:
	return {
		"active_slot_id": active_slot_id,
		"active_save": active_save.duplicate(true),
	}


func import_state(state: Dictionary) -> void:
	active_slot_id = _normalize_slot_id(String(state.get("active_slot_id", active_slot_id)))
	if state.get("active_save", {}) is Dictionary:
		active_save = migrate_save(state.get("active_save", {}))


func _default_save(slot_id: String, chosen_name: String, timestamp: int) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"slot_id": slot_id,
		"timestamp": timestamp,
		"chosen_character_name": chosen_name,
		"player": {
			"position": {"x": 0.0, "y": 0.0},
			"health": 100,
			"level": 1,
			"xp": 0,
		},
		"world": {
			"current_region_id": "region.greenbarrow",
			"current_region": "region.greenbarrow",
			"discovered_locations": {},
			"cleared_encounters": {},
			"regional_threat": {},
			"safe_fast_travel_locations": {},
			"region_states": {},
		},
		"quests": {
			"active": {},
			"completed": {},
			"failed": {},
		},
		"inventory": {
			"items": {},
			"equipped": {},
			"ammo": {},
			"weapon_heat": {},
			"weapon_mods": {},
			"crafting_materials": {},
			"rarity_by_item": {},
		},
		"progression": {
			"level": 1,
			"xp": 0,
			"unlocked_abilities": {},
			"weapon_mastery": {},
		},
		"settlement": {
			"name": "",
			"founded": false,
			"tier": "none",
			"resources": {},
			"buildings": [],
			"follower_jobs": {},
			"population": 0,
		},
		"followers": {},
		"factions": {},
		"combat": {
			"regional_threat": {},
		},
		"dialogue": {
			"bark_cooldowns": {},
		},
		"settings": {
			"aim_assist": true,
			"auto_fire": false,
			"text_size": 1.0,
			"camera_shake": 1.0,
			"reduced_effects": false,
			"low_end_graphics": false,
		},
	}


func _deep_merge(base: Dictionary, override: Dictionary) -> void:
	for key in override.keys():
		if base.has(key) and base[key] is Dictionary and override[key] is Dictionary:
			_deep_merge(base[key], override[key])
		else:
			base[key] = override[key]


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SAVE_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))


func _slot_path(slot_id: String) -> String:
	return SAVE_DIR.path_join(_normalize_slot_id(slot_id) + ".json")


func _normalize_slot_id(slot_id: String) -> String:
	var normalized := slot_id.strip_edges().to_lower()
	if normalized.is_empty():
		return "slot_1"
	var safe := ""
	for i in normalized.length():
		var character := normalized[i]
		if character.is_valid_identifier() or character.is_valid_int() or character == "_":
			safe += character
		elif character == "-" or character == " ":
			safe += "_"
	if safe.is_empty():
		return "slot_1"
	return safe
