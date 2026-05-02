class_name RpgOverlay
extends CanvasLayer

const RpgTheme := preload("res://src/ui/theme/rpg_theme.gd")

var world: Node
var active_panel := "none"
var _panel: PanelContainer
var _title: Label
var _body: Label
var _toolbar: HBoxContainer
var _hint_label: Label
var _combat_label: Label
var _status_label: Label
var _combat_feedback_timer := 0.0


func _ready() -> void:
	_build()


func bind_world(world_node: Node) -> void:
	world = world_node
	_refresh_body()


func show_map() -> void:
	active_panel = "map"
	_refresh_body()


func show_journal() -> void:
	active_panel = "journal"
	_refresh_body()


func show_inventory() -> void:
	active_panel = "inventory"
	_refresh_body()


func show_settlement() -> void:
	active_panel = "settlement"
	_refresh_body()


func show_dialogue() -> void:
	active_panel = "dialogue"
	_refresh_body()


func show_equipment() -> void:
	active_panel = "equipment"
	_refresh_body()


func show_abilities() -> void:
	active_panel = "abilities"
	_refresh_body()


func show_followers() -> void:
	active_panel = "followers"
	_refresh_body()


func show_crafting() -> void:
	active_panel = "crafting"
	_refresh_body()


func show_codex() -> void:
	active_panel = "codex"
	_refresh_body()


func show_boss_intro() -> void:
	active_panel = "boss_intro"
	_refresh_body()


func show_death_retry() -> void:
	active_panel = "death_retry"
	_refresh_body()


func hide_panel() -> void:
	active_panel = "none"
	_panel.visible = false


func get_panel_state() -> Dictionary:
	return {
		"active_panel": active_panel,
		"visible": _panel.visible if _panel else false,
		"title": _title.text if _title else "",
		"body": _body.text if _body else "",
		"combat_feedback": _combat_label.text if _combat_label else "",
		"combat_status": _status_label.text if _status_label else "",
		"toolbar_actions": _get_toolbar_actions(),
	}


func set_combat_feedback(feedback: Dictionary) -> void:
	if _combat_label == null:
		return
	var combat: Dictionary = feedback.get("combat", {})
	if bool(combat.get("defeated", false)):
		_combat_label.text = "Horse down."
	elif bool(combat.get("ok", false)):
		_combat_label.text = "Hit: %s damage" % str(combat.get("damage", 0))
	else:
		_combat_label.text = "Shot fired."
	_combat_feedback_timer = 1.4
	_combat_label.visible = true


func _build() -> void:
	var root := Control.new()
	root.name = "OverlayRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	root.theme = RpgTheme.build_theme()
	add_child(root)

	_toolbar = HBoxContainer.new()
	_toolbar.name = "Toolbar"
	_toolbar.set_anchors_preset(Control.PRESET_CENTER_TOP, true)
	_toolbar.size = Vector2(396, 52)
	_toolbar.position = Vector2(-198, 18)
	_toolbar.add_theme_constant_override("separation", 8)
	root.add_child(_toolbar)

	_add_toolbar_button(_toolbar, "Map", show_map)
	_add_toolbar_button(_toolbar, "Journal", show_journal)
	_add_toolbar_button(_toolbar, "Inventory", show_inventory)

	_hint_label = Label.new()
	_hint_label.name = "InteractionHint"
	_hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM, true)
	_hint_label.position = Vector2(-260, -86)
	_hint_label.custom_minimum_size = Vector2(520, 40)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 18)
	_hint_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.76))
	_hint_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	root.add_child(_hint_label)

	_combat_label = Label.new()
	_combat_label.name = "CombatFeedback"
	_combat_label.visible = false
	_combat_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM, true)
	_combat_label.position = Vector2(-210, -138)
	_combat_label.custom_minimum_size = Vector2(420, 40)
	_combat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combat_label.add_theme_font_size_override("font_size", 20)
	_combat_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30))
	_combat_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	root.add_child(_combat_label)

	_status_label = Label.new()
	_status_label.name = "CombatStatus"
	_status_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, true)
	_status_label.position = Vector2(18, -96)
	_status_label.custom_minimum_size = Vector2(360, 74)
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	_status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.88))
	root.add_child(_status_label)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER, true)
	_panel.size = Vector2(680, 540)
	_panel.custom_minimum_size = Vector2(680, 540)
	_panel.position = Vector2(-340, -260)
	root.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	box.add_child(_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(140, 46)
	close_button.pressed.connect(hide_panel)
	box.add_child(close_button)


func _add_toolbar_button(toolbar: HBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(124, 52)
	button.pressed.connect(callback)
	toolbar.add_child(button)


func _refresh_body() -> void:
	if _panel == null or _title == null or _body == null:
		return
	_panel.visible = active_panel != "none"
	match active_panel:
		"map":
			_title.text = "World Map"
			_body.text = _format_map()
		"journal":
			_title.text = "Journal"
			_body.text = _format_journal()
		"inventory":
			_title.text = "Inventory"
			_body.text = _format_inventory()
		"settlement":
			_title.text = "Town"
			_body.text = _format_settlement()
		"dialogue":
			_title.text = "Dialogue"
			_body.text = _format_dialogue()
		"equipment":
			_title.text = "Equipment"
			_body.text = _format_equipment()
		"abilities":
			_title.text = "Abilities"
			_body.text = _format_abilities()
		"followers":
			_title.text = "Followers"
			_body.text = _format_followers()
		"crafting":
			_title.text = "Crafting"
			_body.text = _format_crafting()
		"codex":
			_title.text = "Codex"
			_body.text = _format_codex()
		"boss_intro":
			_title.text = "Boss"
			_body.text = _format_boss_intro()
		"death_retry":
			_title.text = "Retry"
			_body.text = _format_death_retry()
		_:
			_title.text = ""
			_body.text = ""
	_refresh_hint()


func _process(delta: float) -> void:
	_refresh_hint()
	_refresh_status()
	if _combat_label and _combat_feedback_timer > 0.0:
		_combat_feedback_timer -= delta
		if _combat_feedback_timer <= 0.0:
			_combat_label.visible = false


func _format_map() -> String:
	if world == null or not world.has_method("get_world_map_state"):
		return "Map unavailable."
	var map_state: Dictionary = world.call("get_world_map_state")
	var current_region := String(map_state.get("current_region", ""))
	var discovered: Array = map_state.get("markers", [])
	var fogged: Array = map_state.get("fogged_regions", [])
	var regions: Dictionary = world.get("regions") if world else {}
	var lines: Array[String] = []
	lines.append("Current: " + _display_region_name(current_region, regions))
	if world.has_method("get_current_weather_state"):
		var weather: Dictionary = world.call("get_current_weather_state")
		var weather_name := String(weather.get("display_name", ""))
		if not weather_name.is_empty():
			lines.append("Weather: " + weather_name)
	lines.append("")
	lines.append("Known Routes")
	for region_id in regions.keys():
		var state := "Locked"
		if String(region_id) == current_region:
			state = "Here"
		elif not fogged.has(region_id):
			state = "Known"
		lines.append("- %s  [%s]" % [_display_region_name(String(region_id), regions), state])
	lines.append("")
	lines.append("Discovered Places")
	if discovered.is_empty():
		lines.append("- None yet")
	else:
		for marker_id in discovered:
			lines.append("- " + _humanize_id(String(marker_id)))
	var threat: Dictionary = map_state.get("regional_threat", {})
	if not threat.is_empty():
		lines.append("")
		lines.append("Regional Threat")
		for region_id in threat.keys():
			lines.append("- %s: %s" % [_display_region_name(String(region_id), regions), str(threat[region_id])])
	return "\n".join(lines)


func _format_journal() -> String:
	var quest_manager := get_node_or_null("/root/QuestManager")
	if quest_manager == null:
		return "No journal data."
	if quest_manager.has_method("get_journal_state"):
		var journal: Dictionary = quest_manager.call("get_journal_state")
		return _format_journal_section("Active", journal.get("active", {}).keys()) + "\n\n" + _format_journal_section("Completed", journal.get("completed", {}).keys()) + "\n\n" + _format_journal_section("Failed", journal.get("failed", {}).keys())
	return _format_journal_section("Active", quest_manager.get("active_quests").keys()) + "\n\n" + _format_journal_section("Completed", quest_manager.get("completed_quests").keys())


func _format_inventory() -> String:
	var inventory_manager := get_node_or_null("/root/InventoryManager")
	if inventory_manager == null:
		return "No inventory data."
	var lines: Array[String] = []
	lines.append("Equipped")
	var equipped: Dictionary = inventory_manager.get("equipped")
	if equipped.is_empty():
		lines.append("- No weapon equipped")
	else:
		for slot in equipped.keys():
			lines.append("- %s: %s" % [_humanize_id(String(slot)), _humanize_id(String(equipped[slot]))])
	lines.append("")
	lines.append("Pack")
	var items: Dictionary = inventory_manager.get("items")
	if items.is_empty():
		lines.append("- Empty")
	else:
		for item_id in items.keys():
			lines.append("- %s x%s" % [_humanize_id(String(item_id)), str(items[item_id])])
	return "\n".join(lines)


func _format_journal_section(title_text: String, quest_ids: Array) -> String:
	var lines: Array[String] = [title_text]
	if quest_ids.is_empty():
		lines.append("- None")
	else:
		for quest_id in quest_ids:
			lines.append("- " + _humanize_id(String(quest_id)))
	return "\n".join(lines)


func _display_region_name(region_id: String, regions: Dictionary) -> String:
	var region: Dictionary = regions.get(region_id, {})
	return String(region.get("display_name", _humanize_id(region_id)))


func _humanize_id(value: String) -> String:
	var parts := value.split(".")
	var tail := parts[parts.size() - 1] if parts.size() > 0 else value
	return String(tail).replace("_", " ").capitalize()


func _get_toolbar_actions() -> Array[String]:
	var actions: Array[String] = []
	if _toolbar:
		for child in _toolbar.get_children():
			if child is Button:
				actions.append(child.text)
	return actions


func _refresh_hint() -> void:
	if _hint_label == null or world == null or not world.has_method("get_nearby_interactions"):
		return
	var nearby: Array = world.call("get_nearby_interactions", 125.0)
	if nearby.is_empty():
		_hint_label.text = "E: interact   Mouse/Space: shoot   Q/right mouse: dodge   M: map   I: inventory"
		return
	nearby.sort_custom(func(a: Dictionary, b: Dictionary): return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0)))
	var interaction: Dictionary = nearby[0]
	_hint_label.text = "Press E: " + String(interaction.get("display_name", "Unknown")) + "  [" + _humanize_id(String(interaction.get("type", ""))) + "]"


func _refresh_status() -> void:
	if _status_label == null or world == null or not world.has_method("get_player_combat_state"):
		return
	var combat: Dictionary = world.call("get_player_combat_state")
	if combat.is_empty():
		_status_label.text = ""
		return
	var weapon_id := String(combat.get("weapon_id", "weapon"))
	var profile: Dictionary = combat.get("weapon_profile", {})
	var ammo: Dictionary = combat.get("ammo", {})
	var ammo_type := String(profile.get("ammo_type", "standard"))
	var heat: Dictionary = combat.get("weapon_heat", {})
	var stamina := int(round(float(combat.get("stamina", 0.0))))
	var max_stamina := int(round(float(combat.get("max_stamina", 100.0))))
	_status_label.text = "%s\nAmmo %s: %s   Heat: %s\nDodge: %s/%s" % [
		_humanize_id(weapon_id),
		ammo_type.capitalize(),
		str(ammo.get(ammo_type, "-")),
		str(heat.get(weapon_id, 0)),
		str(stamina),
		str(max_stamina),
	]


func _format_settlement() -> String:
	var settlement_manager := get_node_or_null("/root/SettlementManager")
	if settlement_manager == null:
		return "No settlement data."
	if settlement_manager.has_method("get_city_status"):
		var status: Dictionary = settlement_manager.call("get_city_status")
		return "Name: %s\nTier: %s\nPopulation: %s\nNext: %s\nResources: %s\nBuildings: %s\nJobs: %s" % [
			String(status.get("name")),
			String(status.get("tier")),
			str(status.get("population")),
			String(status.get("next_tier")),
			str(status.get("resources")),
			str(status.get("buildings")),
			str(status.get("follower_jobs")),
		]
	return "Name: %s\nTier: %s\nResources: %s\nBuildings: %s" % [
		String(settlement_manager.get("settlement_name")),
		String(settlement_manager.get("tier")),
		str(settlement_manager.get("resources")),
		str(settlement_manager.get("buildings")),
	]


func _format_dialogue() -> String:
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager == null or not dialogue_manager.has_method("get_dialogue_state"):
		return "No dialogue data."
	var state: Dictionary = dialogue_manager.call("get_dialogue_state")
	if not bool(state.get("active", false)):
		return "No active conversation."
	var lines: Array[String] = []
	lines.append(String(state.get("speaker", "Unknown")))
	lines.append("Portrait: " + String(state.get("portrait_id", "portrait.unknown")))
	lines.append("")
	lines.append(String(state.get("line", "")))
	var choices: Array = state.get("choices", [])
	if not choices.is_empty():
		lines.append("")
		lines.append("Responses")
		for choice in choices:
			if choice is Dictionary:
				lines.append("- " + String(choice.get("text", "")))
	lines.append("")
	lines.append("Subtitles: %s  Text Speed: %s" % [str(state.get("subtitles_enabled", true)), str(state.get("text_speed", 1.0))])
	return "\n".join(lines)


func _format_equipment() -> String:
	var inventory_manager := get_node_or_null("/root/InventoryManager")
	if inventory_manager == null:
		return "No equipment data."
	var equipped: Dictionary = inventory_manager.get("equipped")
	var heat: Dictionary = inventory_manager.get("weapon_heat")
	var lines: Array[String] = ["Equipped Gear"]
	for slot in ["weapon", "coat", "boots", "gloves", "charm", "utility"]:
		lines.append("- %s: %s" % [slot.capitalize(), _humanize_id(String(equipped.get(slot, "empty")))])
	lines.append("")
	lines.append("Weapon Heat: " + str(heat))
	return "\n".join(lines)


func _format_abilities() -> String:
	var progression_manager := get_node_or_null("/root/ProgressionManager")
	if progression_manager == null:
		return "No ability data."
	var abilities: Dictionary = progression_manager.get("unlocked_abilities")
	var lines: Array[String] = ["Level %s  XP %s" % [str(progression_manager.get("level")), str(progression_manager.get("xp"))], ""]
	if abilities.is_empty():
		lines.append("- No abilities unlocked")
	else:
		for ability_id in abilities.keys():
			lines.append("- " + _humanize_id(String(ability_id)))
	return "\n".join(lines)


func _format_followers() -> String:
	var follower_manager := get_node_or_null("/root/FollowerManager")
	if follower_manager == null:
		return "No follower data."
	var followers: Dictionary = follower_manager.get("followers")
	var lines: Array[String] = ["Roster"]
	if followers.is_empty():
		lines.append("- No followers recruited")
	for follower_id in followers.keys():
		var state: Dictionary = followers[follower_id]
		lines.append("- %s  Role: %s  Job: %s  Loyalty: %s  Injured: %s" % [
			_humanize_id(String(follower_id)),
			String(state.get("role", "")),
			String(state.get("settlement_job", "")),
			str(state.get("loyalty", 0)),
			str(state.get("injured", false)),
		])
	return "\n".join(lines)


func _format_crafting() -> String:
	var inventory_manager := get_node_or_null("/root/InventoryManager")
	if inventory_manager == null:
		return "No crafting data."
	return "Materials\n%s\n\nRecipes\n- Stablebreaker repairs: ore + ammo powder\n- Field medicine: medicine + timber\n- Anti-horse traps: ore + timber + research" % str(inventory_manager.get("crafting_materials"))


func _format_codex() -> String:
	if world == null:
		return "No codex data."
	var density: Dictionary = world.call("get_world_density_report") if world.has_method("get_world_density_report") else {}
	return "Bestiary and World\nRegions: %s\nLocations: %s\nHorse Places: %s\nDungeons/Temples/Caves: %s\n\nKnown Horse Roles\n- Runner\n- Charger\n- Spitter\n- Pack Leader\n- Armored\n- Boss" % [
		str(density.get("regions", 0)),
		str(density.get("locations", 0)),
		str(density.get("horse_sites", 0)),
		str(density.get("dungeons", 0)),
	]


func _format_boss_intro() -> String:
	if world == null:
		return "No boss data."
	var telegraph := {}
	if world.get("active_encounter") and world.get("active_encounter").has_method("preview_telegraph"):
		telegraph = world.get("active_encounter").call("preview_telegraph")
	return "Target: %s\nTell: %s\nWeak Point: %s\nWeather: %s" % [
		String(telegraph.get("enemy_id", "No active boss")),
		String(telegraph.get("tell", "Unknown")),
		str(telegraph.get("weakpoint", "")),
		str(telegraph.get("weather_modifiers", {})),
	]


func _format_death_retry() -> String:
	return "You were beaten back.\n\nRetry from the last autosave, return to map, or lower combat assists in Settings."
