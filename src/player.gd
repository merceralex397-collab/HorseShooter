extends CharacterBody2D

@export var base_speed := 360.0
@export var drag_speed := 23.0
@export var bullet_interval := 0.18
@export var rapid_multiplier := 0.45
@export var spread_count := 3
@export var bullet_scene_path := "res://scenes/bullet.tscn"
@export var move_response_curve := 1.35
@export var movement_deadzone := 0.06
@export var minimum_move_accel := 0.3
@export var visual_scale := 1.35
const GAME_MANAGER_PATH := "/root/GameManager"
const OBJECT_POOL_PATH := "/root/ObjectPool"

@onready var sprite: Sprite2D = $Sprite2D

var move_input := Vector2.ZERO
var aim_input := Vector2.ZERO
var fire_input := false
var auto_fire := false
var shoot_cooldown := 0.0
var can_shoot := true
var active_powerups: Dictionary = {}
var _debug_target: CanvasLayer = null
var _is_active := true
var _shield_charges := 0
var _run_offset := 0.0


func _get_game_manager() -> Node:
	return get_node_or_null(GAME_MANAGER_PATH)


func _get_object_pool() -> Node:
	return get_node_or_null(OBJECT_POOL_PATH)


func _ready() -> void:
	add_to_group("player")
	position = get_viewport_rect().size * 0.5
	if sprite:
		sprite.scale = Vector2.ONE * visual_scale
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		auto_fire = bool(gm.get_setting("auto_fire"))
		if not gm.is_connected("settings_changed", _on_settings_changed):
			gm.connect("settings_changed", _on_settings_changed)


func _on_settings_changed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		auto_fire = bool(gm.get_setting("auto_fire"))


func _physics_process(delta: float) -> void:
	_process_powerups(delta)
	if not _is_active:
		return

	var input_direction = move_input
	if input_direction == Vector2.ZERO:
		input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input_direction = _shape_move_input(input_direction)
	if input_direction == Vector2.ZERO:
		input_direction = Vector2.ZERO
	elif input_direction.length() > 1.0:
		input_direction = input_direction.normalized()

	var speed_target = _get_speed()
	var input_strength = min(input_direction.length(), 1.0)
	velocity = velocity.move_toward(
		input_direction.normalized() * speed_target * input_strength,
		drag_speed * 130.0 * (minimum_move_accel + input_strength) * delta
	)
	move_and_slide()

	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 16.0, screen_size.x - 16.0)
	position.y = clamp(position.y, 16.0, screen_size.y - 16.0)

	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
		can_shoot = false
		if _debug_target and _debug_target.has_method("set_reload_feedback"):
			_debug_target.set_reload_feedback(false, shoot_cooldown)
	else:
		can_shoot = true
		if _debug_target and _debug_target.has_method("set_reload_feedback"):
			_debug_target.set_reload_feedback(true, 0.0)
	_animate_player(input_direction, delta)

	var wants_fire = fire_input
	if auto_fire and OS.has_feature("mobile"):
		wants_fire = true
	if wants_fire and can_shoot:
		_fire_sequence()
	elif not fire_input and Input.is_action_pressed("shoot") and can_shoot and not auto_fire:
		_fire_sequence()


func set_movement_input(value: Vector2) -> void:
	move_input = value


func _shape_move_input(value: Vector2) -> Vector2:
	var strength = value.length()
	if strength <= movement_deadzone:
		return Vector2.ZERO
	var remapped = (strength - movement_deadzone) / max(1.0 - movement_deadzone, 0.001)
	var shaped = pow(clamp(remapped, 0.0, 1.0), move_response_curve)
	return value.normalized() * shaped


func set_aim_input(value: Vector2) -> void:
	aim_input = value


func set_fire_input(value: bool) -> void:
	fire_input = value


func set_auto_fire(value: bool) -> void:
	auto_fire = value
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.set_setting("auto_fire", value)


func _animate_player(move_vector: Vector2, delta: float) -> void:
	if sprite == null:
		return

	if move_vector.length() > 0.01:
		_run_offset += delta * 9.0
		if _run_offset >= 1.0:
			_run_offset = 0.0
		sprite.scale = Vector2(
			visual_scale * (1.0 + 0.02 * sin(_run_offset * TAU)),
			visual_scale * (1.0 + 0.05 * sin(_run_offset * TAU + 0.9))
		)
		sprite.flip_h = move_vector.x < 0.0
	else:
		sprite.scale = sprite.scale.lerp(Vector2.ONE * visual_scale, 0.22)
		sprite.flip_h = move_vector.x < 0.0

	var look_dir = aim_input
	if look_dir.length() > 0.2:
		sprite.rotation = clamp(look_dir.x * 0.15, -0.2, 0.2)
	else:
		sprite.rotation = move_vector.x * 0.08


func set_debug_target(hud: CanvasLayer) -> void:
	_debug_target = hud


func pause_for_state(active: bool) -> void:
	_is_active = active


func _fire_sequence() -> void:
	if not _is_active:
		return
	if aim_input.length() <= 0.1 and not OS.has_feature("mobile"):
		# Desktop fallback: aim with pointer.
		aim_input = get_global_mouse_position() - global_position

	var shots = 1
	if _has_powerup("spread_shot"):
		shots = spread_count

	var base_aim = _get_aim_direction()
	if base_aim == Vector2.ZERO:
		base_aim = Vector2(0, -1)

	var interval = bullet_interval * (rapid_multiplier if _has_powerup("rapid_fire") else 1.0)
	shoot_cooldown = max(interval, 0.04)
	if _debug_target and _debug_target.has_method("set_reload_feedback"):
		_debug_target.set_reload_feedback(false, shoot_cooldown)

	var total_shots = max(1, shots)
	var spread_step = 0.13
	for i in range(total_shots):
		var offset = float(i - (total_shots - 1) * 0.5) * spread_step
		var shot_dir = base_aim.rotated(offset)
		_fire_bullet(global_position, shot_dir)


func _fire_bullet(from_position: Vector2, shot_dir: Vector2) -> void:
	var object_pool := _get_object_pool()
	if object_pool == null:
		return
	var bullet = object_pool.acquire(bullet_scene_path)
	if bullet == null:
		return

	bullet.launch(from_position, shot_dir)
	var gm := _get_game_manager()
	if gm == null:
		return
	gm.add_shot_fired()
	gm.request_audio.emit("shoot", bullet.global_position, 1.0)


func _get_aim_direction() -> Vector2:
	if aim_input.length() > 0.1:
		return aim_input.normalized()
	var pointer = get_global_mouse_position()
	return (pointer - global_position).normalized()


func _get_speed() -> float:
	var speed = base_speed
	if _has_powerup("speed_boost"):
		speed *= 1.45
	return speed


func collect_powerup(payload: Dictionary) -> void:
	var ptype = String(payload.get("type", ""))
	var duration = float(payload.get("duration", 4.0))
	if ptype == "":
		return
	if ptype == "shield":
		_shield_charges = clamp(_shield_charges + 1, 1, 4)
	active_powerups[ptype] = duration
	_apply_powerup_visual()


func _process_powerups(delta: float) -> void:
	var expired: Array = []
	for key in active_powerups.keys():
		var remaining = float(active_powerups[key]) - delta
		if remaining <= 0.0:
			expired.append(key)
		else:
			active_powerups[key] = remaining
	for key in expired:
		active_powerups.erase(key)
		if key == "shield":
			_shield_charges = 0
	_apply_powerup_visual()


func use_shield() -> bool:
	if not _has_powerup("shield"):
		return false
	if _shield_charges <= 0:
		active_powerups.erase("shield")
		_apply_powerup_visual()
		return false
	_shield_charges = max(_shield_charges - 1, 0)
	if _shield_charges <= 0:
		active_powerups.erase("shield")
		_apply_powerup_visual()
	return true


func _apply_powerup_visual() -> void:
	if _has_powerup("shield"):
		modulate = Color(0.85, 1.0, 1.0, 1.0)
	elif _has_powerup("rapid_fire"):
		modulate = Color(1.1, 1.06, 0.9, 1.0)
	elif _has_powerup("speed_boost"):
		modulate = Color(0.95, 1.04, 1.0, 1.0)
	else:
		modulate = Color.WHITE


func _has_powerup(key: String) -> bool:
	if not active_powerups.has(key):
		return false
	return float(active_powerups[key]) > 0.0
