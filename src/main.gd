extends Node2D

# Gameplay scene coordinator:
# - Inputs and HUD are funneled through `hud` (HudLayer + hud_manager.gd).
# - Lifecycle and scoring come from GameManager via event signals.
# - Transient effects are requested via request_vfx/audio bus and serviced by pools.

@onready var player: CharacterBody2D = $Player
@onready var wave_manager: Node2D = $WaveManager
@onready var hud: CanvasLayer = $HudLayer
@onready var camera: Camera2D = $Camera2D
@onready var vfx_layer: Node = $VFX
@onready var audio_manager: Node = get_node_or_null("/root/AudioManager")
const GAME_MANAGER_PATH := "/root/GameManager"
const OBJECT_POOL_PATH := "/root/ObjectPool"

@export var background_far_speed := 0.12
@export var background_mid_speed := 0.22
@export var background_near_speed := 0.34
@export var max_shake_distance := 12.0
@export var background_padding := 320.0

var background_far: TextureRect
var background_mid: TextureRect
var background_near: TextureRect
var _last_player_pos := Vector2.ZERO
var _camera_shake_tween: Tween
var _tutorial_step := 0
var _tutorial_timer: Timer


func _get_game_manager() -> Node:
	var gm := get_node_or_null(GAME_MANAGER_PATH)
	return gm


func _get_object_pool() -> Node:
	var pool := get_node_or_null(OBJECT_POOL_PATH)
	return pool


func _ready() -> void:
	background_far = $Parallax/FarLayer/Far
	background_mid = $Parallax/MidLayer/Mid
	background_near = $Parallax/NearLayer/Near

	if not get_viewport().size_changed.is_connected(_sync_playfield_to_viewport):
		get_viewport().size_changed.connect(_sync_playfield_to_viewport)
	_sync_playfield_to_viewport()

	_last_player_pos = player.global_position
	if player and player.has_method("set_debug_target"):
		player.set_debug_target(hud)

	var object_pool := _get_object_pool()
	if object_pool and object_pool.has_method("set_pool_owner"):
		object_pool.set_pool_owner(vfx_layer)

	_bind_game_events()
	_validate_runtime_resources()
	_apply_startup_state()


func _validate_runtime_resources() -> void:
	var required := PackedStringArray([
		"res://scenes/explosion.tscn",
		"res://scenes/floating_text.tscn",
		"res://scenes/horse.tscn",
		"res://scenes/player.tscn",
		"res://scenes/powerup.tscn",
		"res://scenes/bullet.tscn",
		"res://assets/sprites/grass.png",
		"res://assets/sprites/player.png",
		"res://assets/sprites/horse_0.png",
		"res://assets/sprites/horse_1.png",
		"res://assets/sprites/horse_2.png",
		"res://assets/sprites/horse_3.png",
		"res://assets/sprites/powerup_rapid_fire.png",
		"res://assets/sprites/powerup_spread_shot.png",
		"res://assets/sprites/powerup_shield.png",
		"res://assets/sprites/powerup_speed_boost.png",
	])
	for resource_path in required:
		if not ResourceLoader.exists(resource_path):
			push_warning("Missing required resource: " + resource_path)


func _apply_startup_state() -> void:
	if audio_manager and audio_manager.has_method("play_menu_music") and DisplayServer.get_name() != "headless":
		audio_manager.play_menu_music()
	var gm := _get_game_manager()
	if gm:
		if gm.state != gm.GameState.PLAYING:
			gm.reset_game()
	else:
		push_warning("GameManager not found at /root/GameManager")


func _bind_game_events() -> void:
	var gm := _get_game_manager()
	if not gm:
		push_warning("GameManager not found at /root/GameManager")
		return
	if not gm.state_changed.is_connected(_on_state_changed):
		gm.state_changed.connect(_on_state_changed)
	if not gm.round_started.is_connected(_on_round_started):
		gm.round_started.connect(_on_round_started)
	if not gm.hint_requested.is_connected(_on_hint_requested):
		gm.hint_requested.connect(_on_hint_requested)
	if not gm.round_cleared.is_connected(_on_round_result):
		gm.round_cleared.connect(_on_round_result)
	if not gm.round_failed.is_connected(_on_round_result):
		gm.round_failed.connect(_on_round_result)
	if not gm.request_vfx.is_connected(_on_request_vfx):
		gm.request_vfx.connect(_on_request_vfx)
	if not gm.request_score_popup.is_connected(_on_request_score_popup):
		gm.request_score_popup.connect(_on_request_score_popup)

	if not is_instance_valid(hud):
		return
	if not hud.movement_input_changed.is_connected(_on_movement_input):
		hud.movement_input_changed.connect(_on_movement_input)
	if not hud.aim_input_changed.is_connected(_on_aim_input):
		hud.aim_input_changed.connect(_on_aim_input)
	if not hud.fire_input_changed.is_connected(_on_fire_input):
		hud.fire_input_changed.connect(_on_fire_input)
	if not hud.pause_pressed.is_connected(_on_pause_pressed):
		hud.pause_pressed.connect(_on_pause_pressed)
	if not hud.auto_fire_toggled.is_connected(_on_auto_fire_toggled):
		hud.auto_fire_toggled.connect(_on_auto_fire_toggled)
	if not hud.quick_restart_pressed.is_connected(_on_restart):
		hud.quick_restart_pressed.connect(_on_restart)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventAction and event.is_action_pressed("ui_cancel"):
		_handle_back_button()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_handle_back_button()


func _process(delta: float) -> void:
	var gm := _get_game_manager()
	if gm == null:
		return
	if player:
		var player_active = gm.state == gm.GameState.PLAYING or gm.state == gm.GameState.GET_READY
		player.pause_for_state(player_active)
		var current_pos = player.global_position
		_last_player_pos = current_pos
		_update_background_parallax(current_pos)
	if gm and hud and hud.has_method("set_wave_timer"):
		if gm.state == gm.GameState.PLAYING:
			hud.set_wave_timer(gm.round_time_remaining)
		else:
			hud.set_wave_timer(max(gm.round_time_remaining, 0.0))


func _sync_playfield_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	if camera:
		camera.enabled = true
		camera.zoom = Vector2.ONE
		camera.global_position = viewport_size * 0.5
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(viewport_size.x)
		camera.limit_bottom = int(viewport_size.y)
		camera.reset_smoothing()

	_resize_background(background_far, background_padding * 0.65)
	_resize_background(background_mid, background_padding * 0.85)
	_resize_background(background_near, background_padding)

	if player:
		var player_margin := 24.0
		player.global_position = Vector2(
			clamp(player.global_position.x, player_margin, viewport_size.x - player_margin),
			clamp(player.global_position.y, player_margin, viewport_size.y - player_margin)
		)
		_last_player_pos = player.global_position
		_update_background_parallax(player.global_position)
	else:
		_update_background_parallax(viewport_size * 0.5)


func _resize_background(rect: TextureRect, padding: float) -> void:
	if rect == null:
		return
	var viewport_size := get_viewport_rect().size
	rect.position = Vector2(-padding, -padding)
	rect.size = viewport_size + Vector2(padding * 2.0, padding * 2.0)


func _update_background_parallax(player_position: Vector2) -> void:
	if not background_far or not background_mid or not background_near:
		return
	var center := get_viewport_rect().size * 0.5
	$Parallax/FarLayer.position = (center - player_position) * background_far_speed
	$Parallax/MidLayer.position = (center - player_position) * background_mid_speed
	$Parallax/NearLayer.position = (center - player_position) * background_near_speed


func _handle_back_button() -> void:
	var gm = _get_game_manager()
	if gm == null:
		return
	match gm.state:
		gm.GameState.PLAYING, gm.GameState.GET_READY:
			gm.pause_game()
		gm.GameState.PAUSED:
			gm.resume_game()
		gm.GameState.GAME_OVER, gm.GameState.WAVE_RETRY:
			gm.start_game()


func _on_movement_input(vector: Vector2) -> void:
	if player:
		player.set_movement_input(vector)


func _on_aim_input(vector: Vector2) -> void:
	if player:
		player.set_aim_input(vector)


func _on_fire_input(active: bool) -> void:
	if player:
		player.set_fire_input(active)


func _on_auto_fire_toggled(enabled: bool) -> void:
	if player:
		player.set_auto_fire(enabled)


func _on_pause_pressed() -> void:
	var gm = _get_game_manager()
	if gm == null:
		return
	if gm.state == gm.GameState.PAUSED:
		gm.resume_game()
	else:
		gm.pause_game()


func _on_restart() -> void:
	var gm := _get_game_manager()
	if gm == null:
		return
	match gm.state:
		gm.GameState.WAVE_RETRY:
			gm.retry_round()
		_:
			gm.start_game()


func _on_state_changed(new_state: int) -> void:
	var gm := _get_game_manager()
	if gm == null:
		return
	match new_state:
		gm.GameState.PAUSED:
			shake_camera(10.0, 0.14)
		gm.GameState.WAVE_CLEAR:
			shake_camera(max_shake_distance, 0.18)
		gm.GameState.GAME_OVER:
			shake_camera(max_shake_distance * 1.2, 0.24)


func _on_round_started(_round_id: int, profile: Dictionary) -> void:
	var gm := _get_game_manager()
	if audio_manager and audio_manager.has_method("play_music"):
		audio_manager.play_music("wave_ambient", false)

	if gm and hud and hud.has_method("show_hint"):
		var round_message = "Round " + str(_round_id) + " begins. Shoot, dodge escapes, and keep a clean stream."
		hud.show_hint(round_message, 1.3)
	if gm and gm.get_setting("tutorial_seen") == false:
		_start_tutorial_flow(_round_id)
		gm.set_setting("tutorial_seen", true)


func _start_tutorial_flow(round_id: int) -> void:
	if hud == null:
		return
	if _tutorial_timer:
		_tutorial_timer.queue_free()
		_tutorial_timer = null

	var tutorial_messages = [
		{"text": "Round " + str(round_id) + ": move with left thumb, aim with right thumb.", "duration": 2.0},
		{"text": "Release on touch and let auto-fire carry your burst safely.", "duration": 1.6},
		{"text": "Shoot fast but hold your corners — escaped horses cost a life!", "duration": 1.9},
	]

	_tutorial_step = 0
	_show_next_tutorial_hint(tutorial_messages)


func _show_next_tutorial_hint(tutorial_messages: Array) -> void:
	if _tutorial_timer and is_instance_valid(_tutorial_timer):
		_tutorial_timer.queue_free()
		_tutorial_timer = null

	if hud == null or _tutorial_step >= tutorial_messages.size():
		_tutorial_timer = null
		return
	var payload = tutorial_messages[_tutorial_step] as Dictionary
	_tutorial_step += 1
	var text = String(payload.get("text", ""))
	var duration = float(payload.get("duration", 2.0))
	hud.show_hint(text, duration)

	_tutorial_timer = Timer.new()
	_tutorial_timer.one_shot = true
	add_child(_tutorial_timer)
	_tutorial_timer.start(duration + 0.25)
	_tutorial_timer.timeout.connect(_show_next_tutorial_hint.bind(tutorial_messages), CONNECT_ONE_SHOT)


func _on_hint_requested(message: String, duration: float) -> void:
	if hud and hud.has_method("show_hint"):
		hud.show_hint(message, duration)


func _on_round_result(_round_id: int, summary: Dictionary) -> void:
	if summary.get("reason", "") == "":
		if hud and hud.has_method("show_hint"):
			hud.show_hint("Round clear!", 1.6)
	else:
		if hud and hud.has_method("show_hint"):
			hud.show_hint("Round failed. Retry.", 1.2)


func _on_request_vfx(vfx_name: String, world_position: Vector2, payload: Dictionary) -> void:
	match vfx_name:
		"horse_killed":
			_spawn_explosion(world_position, 0.58)
		"horse_hit", "round_fail", "game_over", "round_clear", "spawn_ping":
			_spawn_explosion(world_position, 0.4)
		"shield_block":
			_spawn_text("SHIELD", world_position - Vector2(0, 16), _color_from_name("Wild"))
		"combo_text":
			var combo = int(payload.get("combo", 0))
			if combo > 0:
				_spawn_text("x" + str(combo), world_position - Vector2(0, 18), _color_from_name("Epic"))
		_:
			pass


func _on_request_score_popup(text: String, world_position: Vector2, color_name: String) -> void:
	_spawn_text(text, world_position - Vector2(0, 30), _color_from_name(color_name))


func _spawn_explosion(world_position: Vector2, scale := 1.0) -> void:
	var object_pool := _get_object_pool()
	if object_pool == null:
		return
	var node = object_pool.acquire("res://scenes/explosion.tscn")
	if node == null:
		return
	node.global_position = world_position
	node.scale = Vector2(scale, scale)


func _spawn_text(text: String, world_position: Vector2, color: Color = Color.WHITE) -> void:
	var object_pool := _get_object_pool()
	if object_pool == null:
		return
	var node = object_pool.acquire("res://scenes/floating_text.tscn")
	if node == null:
		return
	node.global_position = world_position
	node.start(text, color)


func shake_camera(intensity: float, duration: float) -> void:
	if not camera:
		return
	if _camera_shake_tween and _camera_shake_tween.is_running():
		_camera_shake_tween.kill()

	_camera_shake_tween = get_tree().create_tween()
	var random_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	_camera_shake_tween.tween_property(camera, "offset", random_offset, duration * 0.5)
	_camera_shake_tween.tween_property(camera, "offset", Vector2.ZERO, duration * 0.5)


func _color_from_name(name: String) -> Color:
	match name:
		"Hot":
			return Color(1.0, 0.85, 0.2)
		"Wild":
			return Color(0.95, 0.3, 0.3)
		"Epic":
			return Color(0.4, 0.8, 1.0)
		_:
			return Color(1.0, 1.0, 1.0)
