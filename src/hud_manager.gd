extends CanvasLayer

# HUD, controls, and debug telemetry for HorseShooter.

signal movement_input_changed(direction)
signal aim_input_changed(direction)
signal fire_input_changed(active)
signal pause_pressed()
signal auto_fire_toggled(enabled)
signal quick_restart_pressed()
signal retry_pressed()

@onready var score_label = $Root/ScorePanel/Score
@onready var high_score_label = $Root/ScorePanel/HighScore
@onready var round_label = $Root/ScorePanel/Round
@onready var lives_label = $Root/ScorePanel/Lives
@onready var combo_label = $Root/ScorePanel/Combo
@onready var misses_label = $Root/ScorePanel/Misses
@onready var fps_label = $Root/DebugPanel/Fps
@onready var accuracy_label = $Root/DebugPanel/Accuracy
@onready var hint_label = $Root/Hint
@onready var round_timer_label = $Root/ScorePanel/Timer
@onready var state_label = $Root/ScorePanel/State
@onready var pause_button = $Root/Actions/Pause
@onready var restart_button = $Root/Actions/Restart
@onready var auto_fire_button = $Root/Actions/AutoFire
@onready var settings_button = $Root/Actions/Settings
@onready var move_base = $Root/TouchControls/MoveBase
@onready var move_knob = $Root/TouchControls/MoveBase/MoveKnob
@onready var aim_base = $Root/TouchControls/AimBase
@onready var aim_knob = $Root/TouchControls/AimBase/AimKnob
@onready var reload_label = $Root/ScorePanel/Reload
@onready var settings_panel = $Root/SettingsPanel
@onready var master_slider = $Root/SettingsPanel/VBoxContainer/MasterRow/MasterSlider
@onready var master_value = $Root/SettingsPanel/VBoxContainer/MasterRow/MasterValue
@onready var music_slider = $Root/SettingsPanel/VBoxContainer/MusicRow/MusicSlider
@onready var music_value = $Root/SettingsPanel/VBoxContainer/MusicRow/MusicValue
@onready var sfx_slider = $Root/SettingsPanel/VBoxContainer/SFXRow/SFXSlider
@onready var sfx_value = $Root/SettingsPanel/VBoxContainer/SFXRow/SFXValue
@onready var close_settings = $Root/SettingsPanel/VBoxContainer/CloseSettings

@export var show_debug_default := false
@export var deadzone := 14.0
@export var max_stick_radius := 72.0

var mobile_enabled := OS.has_feature("mobile")
var _move_touch := -1
var _aim_touch := -1
var _move_vector := Vector2.ZERO
var _aim_vector := Vector2.ZERO
var _firing := false
var _auto_fire = false
var _debug_enabled = false
var _syncing_settings := false
var _hint_tween: Tween


func _ready() -> void:
	add_to_group("hud")
	mobile_enabled = OS.has_feature("mobile")
	move_base.visible = mobile_enabled
	move_knob.visible = mobile_enabled
	aim_base.visible = mobile_enabled
	aim_knob.visible = mobile_enabled
	restart_button.visible = false
	_debug_enabled = show_debug_default
	$Root/DebugPanel.visible = _debug_enabled
	settings_panel.visible = false

	pause_button.pressed.connect(_on_pause_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	auto_fire_button.toggled.connect(_on_auto_fire_toggled)
	settings_button.pressed.connect(_toggle_settings_panel)
	close_settings.pressed.connect(_hide_settings_panel)
	auto_fire_button.button_pressed = false

	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.state_changed.connect(_on_state_changed)
		gm.score_changed.connect(_on_score_changed)
		gm.high_score_changed.connect(_on_high_score_changed)
		gm.lives_changed.connect(_on_lives_changed)
		gm.combo_changed.connect(_on_combo_changed)
		gm.accuracy_updated.connect(_on_accuracy_updated)
		gm.shot_missed.connect(_on_shot_missed)
		gm.round_started.connect(_on_round_started)
		gm.round_cleared.connect(_on_round_result)
		gm.round_failed.connect(_on_round_result)
		gm.settings_changed.connect(_on_settings_changed)

		_on_settings_changed()
		_on_score_changed(gm.score)
		_on_high_score_changed(gm.high_score)
		_on_lives_changed(gm.lives)

	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	if mobile_enabled:
		move_base.gui_input.connect(_on_move_input)
		aim_base.gui_input.connect(_on_aim_input)


func _unhandled_input(event) -> void:
	if event.is_action_pressed("auto_fire"):
		auto_fire_button.button_pressed = not auto_fire_button.button_pressed
		get_viewport().set_input_as_handled()
		return
	if mobile_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Right side of screen acts as aim/fire zone.
		var press = event.pressed
		var viewport_size = get_viewport().get_visible_rect().size
		var in_right_zone = event.position.x > viewport_size.x * 0.55
		if press and in_right_zone:
			emit_signal("fire_input_changed", true)
		elif event.is_released():
			emit_signal("fire_input_changed", false)


func _on_move_input(event: InputEvent) -> void:
	if not mobile_enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _move_touch == -1:
			_move_touch = event.index
			_handle_stick_input(event.position, move_base, move_knob, true, _move_touch, true)
		elif not event.pressed and event.index == _move_touch:
			_move_touch = -1
			emit_signal("movement_input_changed", Vector2.ZERO)
			_set_vector(Vector2.ZERO, true)
	elif event is InputEventScreenDrag and event.index == _move_touch:
		_handle_stick_input(event.position, move_base, move_knob, true, _move_touch, false)


func _on_aim_input(event: InputEvent) -> void:
	if not mobile_enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _aim_touch == -1:
			_aim_touch = event.index
			_handle_stick_input(event.position, aim_base, aim_knob, false, _aim_touch, true)
			_emit_fire()
		elif not event.pressed and event.index == _aim_touch:
			_aim_touch = -1
			emit_signal("aim_input_changed", Vector2.ZERO)
			_set_vector(Vector2.ZERO, false)
			_emit_fire()
	elif event is InputEventScreenDrag and event.index == _aim_touch:
		_handle_stick_input(event.position, aim_base, aim_knob, false, _aim_touch, false)
		_emit_fire()


func _handle_stick_input(event_pos: Vector2, base: Control, knob: Control, is_move: bool, _tracked_touch: int, is_press: bool) -> void:
	var base_center = base.size * 0.5
	var delta = event_pos - base_center
	var delta_length = delta.length()
	if delta_length < deadzone:
		delta = Vector2.ZERO
	else:
		delta = delta.limit_length(max_stick_radius)

	if is_move:
		_move_vector = delta / max_stick_radius
		emit_signal("movement_input_changed", _move_vector)
	else:
		_aim_vector = delta / max_stick_radius
		emit_signal("aim_input_changed", _aim_vector)
		_emit_fire()

	knob.position = base_center + delta - (knob.size * 0.5)


func _set_vector(value: Vector2, is_move: bool) -> void:
	if is_move:
		move_knob.position = (move_base.size * 0.5) - (move_knob.size * 0.5)
		_move_vector = value
	else:
		aim_knob.position = (aim_base.size * 0.5) - (aim_knob.size * 0.5)
		_aim_vector = value


func _emit_fire() -> void:
	_firing = auto_fire_button.button_pressed or _aim_vector.length() > 0.05
	emit_signal("fire_input_changed", _firing)


func _on_pause_pressed() -> void:
	emit_signal("pause_pressed")


func _on_restart_pressed() -> void:
	emit_signal("quick_restart_pressed")


func _on_auto_fire_toggled(button_pressed: bool) -> void:
	_auto_fire = button_pressed
	emit_signal("auto_fire_toggled", _auto_fire)
	_emit_fire()


func _toggle_settings_panel() -> void:
	if settings_panel.visible:
		_hide_settings_panel()
	else:
		_show_settings_panel()


func _show_settings_panel() -> void:
	settings_panel.visible = true


func _hide_settings_panel() -> void:
	settings_panel.visible = false


func _on_master_volume_changed(value: float) -> void:
	master_value.text = str(int(value * 100)) + "%"
	if _syncing_settings:
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.set_setting("master_volume", value)


func _on_music_volume_changed(value: float) -> void:
	music_value.text = str(int(value * 100)) + "%"
	if _syncing_settings:
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.set_setting("music_volume", value)


func _on_sfx_volume_changed(value: float) -> void:
	sfx_value.text = str(int(value * 100)) + "%"
	if _syncing_settings:
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.set_setting("sfx_volume", value)


func set_reload_feedback(ready: bool, time_left: float) -> void:
	if ready:
		reload_label.text = "Ready"
	else:
		reload_label.text = "Reload " + str(snapped(time_left, 0.1))


func set_wave_timer(time_left: float) -> void:
	round_timer_label.text = "Wave: " + str(int(max(time_left, 0.0)))


func set_state_badge(text: String) -> void:
	state_label.text = text


func set_round(text: int, target: int) -> void:
	round_label.text = "Round " + str(text) + " / " + str(target)


func show_hint(text: String, duration := 2.4) -> void:
	if _hint_tween and _hint_tween.is_running():
		_hint_tween.kill()
		_hint_tween = null
	if hint_label == null:
		return
	hint_label.text = text
	hint_label.visible = true
	hint_label.modulate.a = 1.0
	_hint_tween = get_tree().create_tween()
	_hint_tween.tween_interval(duration)
	_hint_tween.tween_property(hint_label, "modulate:a", 0.0, 0.35)
	_hint_tween.tween_callback(func():
		hint_label.visible = false
		hint_label.modulate.a = 1.0
	)


func _on_state_changed(state: int) -> void:
	set_state_badge("State: " + _state_to_text(state))
	restart_button.visible = state == 4 or state == 6  # WAVE_RETRY / GAME_OVER
	if state == 4:
		set_wave_timer(0)


func _on_score_changed(value: int) -> void:
	score_label.text = "Score: " + str(value)


func _on_high_score_changed(value: int) -> void:
	high_score_label.text = "Best: " + str(value)


func _on_lives_changed(value: int) -> void:
	lives_label.text = "Lives: " + str(value)


func _on_combo_changed(value: int) -> void:
	combo_label.text = "Combo: x" + str(value)


func _on_accuracy_updated(accuracy: float, shots: int, hits: int) -> void:
	accuracy_label.text = "Acc: " + str(int(accuracy)) + "%"
	var ratio = int(accuracy)
	hints_update_telemetry(shots, hits, ratio)


func _on_shot_missed(misses: int, misses_remaining: int) -> void:
	misses_label.text = "Misses: " + str(misses) + " (" + str(misses_remaining) + " left)"
	if misses_remaining <= 3:
		misses_label.modulate = Color(1.0, 0.42, 0.42)
	else:
		misses_label.modulate = Color.WHITE


func _on_round_started(round_id: int, profile: Dictionary) -> void:
	var target = int(profile.get("target_horses", 0))
	var max_misses = int(profile.get("max_misses", 0))
	set_round(round_id, target)
	if max_misses > 0:
		misses_label.text = "Misses: 0 (" + str(max_misses) + " allowed)"
		misses_label.modulate = Color.WHITE
	show_hint("Round " + str(round_id) + " starts. Keep moving and aim deliberately.")


func _on_round_result(_round_id: int, summary: Dictionary) -> void:
	restart_button.visible = true
	var misses_text = str(summary.get("misses", 0))
	var misses_remaining = int(summary.get("misses_remaining", 0))
	var total_misses = int(summary.get("misses", 0)) + misses_remaining
	restart_button.text = "Restart (" + misses_text + "M)"
	if summary.get("reason", "") == "":
		show_hint("Wave cleared: " + str(summary.get("kills", 0)) + " / " + str(summary.get("target", 0)) + " | M:" + str(total_misses))
	else:
		show_hint("Wave failed: " + str(summary.get("reason", ""))
			+ " | M:" + misses_text)


func hints_update_telemetry(shots: int, hits: int, accuracy_percent: int) -> void:
	if _debug_enabled:
		reload_label.text = "Shots: " + str(shots) + " | Hits: " + str(hits) + " | Acc: " + str(accuracy_percent) + "%"



func _on_settings_changed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	_syncing_settings = true
	_auto_fire = bool(gm.get_setting("auto_fire"))
	auto_fire_button.button_pressed = _auto_fire
	var master_value_setting = float(gm.get_setting("master_volume"))
	var music_value_setting = float(gm.get_setting("music_volume"))
	var sfx_value_setting = float(gm.get_setting("sfx_volume"))
	master_slider.value = master_value_setting
	music_slider.value = music_value_setting
	sfx_slider.value = sfx_value_setting
	master_value.text = str(int(master_value_setting * 100)) + "%"
	music_value.text = str(int(music_value_setting * 100)) + "%"
	sfx_value.text = str(int(sfx_value_setting * 100)) + "%"
	if not _debug_enabled:
		$Root/DebugPanel.visible = false
	_syncing_settings = false


func _state_to_text(value: int) -> String:
	match value:
		0:
			return "Menu"
		1:
			return "Get Ready"
		2:
			return "Playing"
		3:
			return "Clear"
		4:
			return "Retry"
		5:
			return "Paused"
		6:
			return "Game Over"
	return "?"


func _process(_delta: float) -> void:
	if _debug_enabled:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
		var draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var horse_count = len(get_tree().get_nodes_in_group("horses"))
		var bullet_count = len(get_tree().get_nodes_in_group("bullets"))
		var powerup_count = len(get_tree().get_nodes_in_group("powerups"))
		var node_count = get_tree().get_node_count()
		accuracy_label.text = accuracy_label.text.split("|")[0] + " | DC:" + str(draw_calls) + " | H:" + str(horse_count) + " B:" + str(bullet_count) + " P:" + str(powerup_count) + " N:" + str(node_count)
