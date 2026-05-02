extends Control

signal name_confirmed(character_name)
signal back_requested()

const SAVE_MANAGER_PATH := "/root/SaveManager"

var line_edit: LineEdit
var validation_label: Label
var confirm_button: Button


func _ready() -> void:
	_build()


func set_initial_name(value: String) -> void:
	if line_edit:
		line_edit.text = value
		_validate()


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	var background := ColorRect.new()
	background.name = "ScreenBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	background.color = Color(0.13, 0.17, 0.15)
	add_child(background)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	var panel_size := Vector2(520, 320)
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)
	panel.size = panel_size
	panel.custom_minimum_size = panel_size
	panel.position = (viewport_size - panel_size) * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.052, 0.047, 0.94)
	style.border_color = Color(0.78, 0.54, 0.28, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Name the horse-hating gunslinger"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	line_edit = LineEdit.new()
	line_edit.placeholder_text = "Character name"
	line_edit.max_length = 24
	line_edit.custom_minimum_size = Vector2(420, 48)
	box.add_child(line_edit)

	validation_label = Label.new()
	validation_label.text = ""
	validation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(validation_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(120, 48)
	row.add_child(back_button)

	confirm_button = Button.new()
	confirm_button.text = "Start"
	confirm_button.custom_minimum_size = Vector2(120, 48)
	row.add_child(confirm_button)

	line_edit.text_changed.connect(func(_text: String): _validate())
	back_button.pressed.connect(func(): back_requested.emit())
	confirm_button.pressed.connect(_confirm)
	_validate()


func _confirm() -> void:
	var result := _validate()
	if bool(result.get("valid", false)):
		name_confirmed.emit(String(result["name"]))


func _validate() -> Dictionary:
	var save_manager := get_node_or_null(SAVE_MANAGER_PATH)
	var result := {"valid": false, "name": "", "error": "Save system unavailable."}
	if save_manager and save_manager.has_method("validate_character_name"):
		result = save_manager.validate_character_name(line_edit.text)
	confirm_button.disabled = not bool(result.get("valid", false))
	validation_label.text = String(result.get("error", ""))
	return result
