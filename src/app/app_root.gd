extends Control

const SAVE_MANAGER_PATH := "/root/SaveManager"
const GAME_SCENE := "res://scenes/world/world_root.tscn"
const CharacterNameScreen := preload("res://src/ui/character_name_screen.gd")
const MenuController := preload("res://src/ui/menu_controller.gd")
const RpgTheme := preload("res://src/ui/theme/rpg_theme.gd")
const TitleBackdrop := preload("res://src/ui/title_backdrop.gd")

var current_screen := "title"
var _title_screen: Control
var _settings_screen: Control
var _credits_screen: Control
var _name_screen: Control
var _loaded_game: Node


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	theme = RpgTheme.build_theme()
	show_title_menu()


func show_title_menu() -> void:
	_clear_screens()
	current_screen = "title"
	_title_screen = _make_fullscreen_screen()
	add_child(_title_screen)
	_add_screen_background(_title_screen)

	var panel := _make_center_panel(Vector2(520, 500))
	_title_screen.add_child(panel)
	var box := _make_panel_box(panel, 18)

	var title := Label.new()
	title.text = "HorseShooter"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Equine Hate Saga. Name her, arm her, let her swear at horses."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle)

	var has_save := _has_any_save()
	for action in MenuController.primary_menu_actions(has_save):
		var button := Button.new()
		button.text = action
		button.custom_minimum_size = Vector2(360, 52)
		box.add_child(button)
		match action:
			"New Game":
				button.pressed.connect(show_name_entry)
			"Continue":
				button.pressed.connect(continue_game)
			"Settings":
				button.pressed.connect(show_settings)
			"Credits":
				button.pressed.connect(show_credits)
			"Quit":
				button.pressed.connect(func(): get_tree().quit())


func show_name_entry() -> void:
	_clear_screens()
	current_screen = "name_entry"
	_name_screen = CharacterNameScreen.new()
	add_child(_name_screen)
	_name_screen.name_confirmed.connect(func(character_name: String): start_new_game(character_name))
	_name_screen.back_requested.connect(show_title_menu)


func start_new_game(character_name: String) -> void:
	var save_manager := _get_save_manager()
	if save_manager:
		var created = save_manager.create_new_game("slot_1", character_name)
		if created is Dictionary and created.has("error"):
			return
	_load_game_scene()


func continue_game() -> void:
	var save_manager := _get_save_manager()
	if save_manager:
		save_manager.load_slot("slot_1")
	_load_game_scene()


func show_settings() -> void:
	_clear_screens()
	current_screen = "settings"
	_settings_screen = _make_settings_screen()


func show_credits() -> void:
	_clear_screens()
	current_screen = "credits"
	_credits_screen = _make_simple_text_screen("Credits", "HorseShooter: Equine Hate Saga")


func quit_to_menu() -> void:
	if is_instance_valid(_loaded_game):
		_loaded_game.queue_free()
		_loaded_game = null
	show_title_menu()


func _load_game_scene() -> void:
	_clear_screens()
	current_screen = "game"
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		push_error("Unable to load game scene: " + GAME_SCENE)
		show_title_menu()
		return
	_loaded_game = packed.instantiate()
	add_child(_loaded_game)


func _make_simple_text_screen(title_text: String, body_text: String) -> Control:
	var screen := _make_fullscreen_screen()
	add_child(screen)
	_add_screen_background(screen)
	var panel := _make_center_panel(Vector2(520, 260))
	screen.add_child(panel)
	var box := _make_panel_box(panel, 16)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(120, 48)
	box.add_child(back)
	back.pressed.connect(show_title_menu)
	return screen


func _make_settings_screen() -> Control:
	var screen := _make_fullscreen_screen()
	add_child(screen)
	_add_screen_background(screen)
	var panel := _make_center_panel(Vector2(640, 620))
	screen.add_child(panel)
	var box := _make_panel_box(panel, 18)

	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)

	box.add_child(_make_check_setting("Aim assist", "aim_assist", true))
	box.add_child(_make_check_setting("Auto-fire", "auto_fire", false))
	box.add_child(_make_check_setting("Reduced effects", "reduced_effects", false))
	box.add_child(_make_check_setting("Low-end graphics mode", "low_end_graphics", false))
	box.add_child(_make_slider_setting("Text size", "text_size", 0.8, 1.5, 0.05, 1.0))
	box.add_child(_make_slider_setting("Camera shake", "camera_shake", 0.0, 1.0, 0.05, 1.0))

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(180, 50)
	box.add_child(back)
	back.pressed.connect(show_title_menu)
	return screen


func _make_check_setting(label_text: String, setting_id: String, default_value: bool) -> CheckButton:
	var control := CheckButton.new()
	control.text = label_text
	control.button_pressed = bool(_get_setting(setting_id, default_value))
	control.custom_minimum_size = Vector2(520, 46)
	control.toggled.connect(func(value: bool): _set_setting(setting_id, value))
	return control


func _make_slider_setting(label_text: String, setting_id: String, min_value: float, max_value: float, step: float, default_value: float) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = "%s: %.2f" % [label_text, float(_get_setting(setting_id, default_value))]
	box.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = float(_get_setting(setting_id, default_value))
	slider.custom_minimum_size = Vector2(520, 42)
	box.add_child(slider)
	slider.value_changed.connect(func(value: float):
		label.text = "%s: %.2f" % [label_text, value]
		_set_setting(setting_id, value)
	)
	return box


func _get_setting(setting_id: String, fallback: Variant) -> Variant:
	var save_manager := _get_save_manager()
	if save_manager and save_manager.has_method("get_setting"):
		return save_manager.call("get_setting", setting_id, fallback)
	return fallback


func _set_setting(setting_id: String, value: Variant) -> void:
	var save_manager := _get_save_manager()
	if save_manager and save_manager.has_method("set_setting"):
		save_manager.call("set_setting", setting_id, value)


func _make_fullscreen_screen() -> Control:
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	return screen


func _make_center_panel(size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)
	panel.position = (viewport_size - size) * 0.5
	panel.size = size
	panel.custom_minimum_size = size
	panel.add_theme_stylebox_override("panel", RpgTheme.panel_style())
	return panel


func _add_screen_background(screen: Control) -> void:
	var background := TitleBackdrop.new()
	background.name = "ScreenBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	screen.add_child(background)

	var band := ColorRect.new()
	band.name = "AtmosphereBand"
	band.set_anchors_preset(Control.PRESET_TOP_WIDE, true)
	band.offset_bottom = 180.0
	band.color = Color(0.22, 0.12, 0.08, 0.55)
	screen.add_child(band)


func _make_panel_box(panel: PanelContainer, margin_size: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	margin.add_theme_constant_override("margin_left", margin_size)
	margin.add_theme_constant_override("margin_top", margin_size)
	margin.add_theme_constant_override("margin_right", margin_size)
	margin.add_theme_constant_override("margin_bottom", margin_size)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	return box


func _clear_screens() -> void:
	for child in get_children():
		child.queue_free()
	_title_screen = null
	_settings_screen = null
	_credits_screen = null
	_name_screen = null
	_loaded_game = null


func _has_any_save() -> bool:
	var save_manager := _get_save_manager()
	if save_manager == null:
		return false
	return save_manager.slot_exists("slot_1")


func _get_save_manager() -> Node:
	return get_node_or_null(SAVE_MANAGER_PATH)
