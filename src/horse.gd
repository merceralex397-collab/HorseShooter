extends CharacterBody2D

@export var base_speed := 90.0
@export var direction_change_time := 2.0
@export var zigzag_amplitude := 48.0
@export var split_count := 2
@export var escape_margin := 180.0
@export var escape_grace_time := 1.25
@export var escape_screen_buffer := 48.0
@export var point_value := 100
@export var death_duration := 0.56
@export var death_spin := 15.0
@export var death_bounce := 64.0
@export var run_frame_rate := 10.0

signal horse_killed(points, world_position)
signal horse_escaped(world_position)
signal split_requested(world_position, directions)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const TEXTURE_SET = [
	preload("res://assets/sprites/horse_0.png"),
	preload("res://assets/sprites/horse_1.png"),
	preload("res://assets/sprites/horse_2.png"),
	preload("res://assets/sprites/horse_3.png"),
]
const GAME_MANAGER_PATH := "/root/GameManager"

var horse_type := "trotter"
var speed_multiplier := 1.0
var move_direction := Vector2.RIGHT
var direction_timer := 0.0
var is_dead := false
var death_clock := 0.0
var split_done := false
var wobble := 0.0
var _run_clock := 0.0
var _run_offset := 0
var _direction_bucket := 1
var _death_spin_dir := 1.0
var _alive_time := 0.0


func _get_game_manager() -> Node:
	return get_node_or_null(GAME_MANAGER_PATH)


func _ready() -> void:
	add_to_group("horses")
	_alive_time = 0.0
	_choose_sprite()
	_pick_new_direction()


func setup(_type: String, profile: Dictionary) -> void:
	horse_type = _type
	point_value = int(profile.get("point_value", point_value))
	speed_multiplier = float(profile.get("base_speed", base_speed)) / base_speed
	_direction_bucket = 1
	_run_clock = 0.0
	_run_offset = 0
	_alive_time = 0.0
	is_dead = false
	split_done = false
	if collision_shape:
		collision_shape.disabled = false
	_pick_new_direction()
	_choose_sprite()


func setup_as_split(profile: Dictionary) -> void:
	horse_type = "trotter"
	point_value = int(float(profile.get("point_value", point_value)) * 0.62)
	speed_multiplier = float(profile.get("base_speed", base_speed)) / base_speed * 1.1
	_run_clock = 0.0
	_run_offset = 0
	_alive_time = 0.0
	is_dead = false
	if collision_shape:
		collision_shape.disabled = false
	_pick_new_direction()
	_choose_sprite()


func _physics_process(delta: float) -> void:
	if is_dead:
		_process_death(delta)
		return
	_alive_time += delta

	match horse_type:
		"trotter", "splitter":
			_move_standard(delta)
		"zigzag":
			_move_zigzag(delta)
		"escape":
			_move_escape(delta)
		_:
			_move_standard(delta)

	_handle_bounce()


func _move_standard(delta: float) -> void:
	direction_timer -= delta
	if direction_timer <= 0.0:
		_pick_new_direction()
		direction_timer = randf_range(0.45, direction_change_time)
		if randf() < 0.2:
			_play_boing()

	velocity = move_direction * base_speed * speed_multiplier
	move_and_slide()
	_animate_sprite(delta)


func _move_zigzag(delta: float) -> void:
	direction_timer -= delta
	_animate_sprite(delta)
	var side = Vector2(-move_direction.y, move_direction.x)
	wobble += delta * 6.0
	velocity = move_direction * base_speed * speed_multiplier * 0.85 + side * sin(wobble) * 24.0
	move_and_slide()
	if direction_timer <= 0.0:
		_pick_new_direction()


func _move_escape(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		move_direction = (global_position - player.global_position).normalized()
	velocity = move_direction * base_speed * speed_multiplier * 1.2
	_animate_sprite(delta)
	move_and_slide()
	if _alive_time >= escape_grace_time and _has_left_playfield(escape_screen_buffer):
		_escape()


func _has_left_playfield(buffer: float) -> bool:
	var screen_size = get_viewport_rect().size
	return (
		global_position.x < -buffer
		or global_position.y < -buffer
		or global_position.x > screen_size.x + buffer
		or global_position.y > screen_size.y + buffer
	)


func _process_death(delta: float) -> void:
	death_clock += delta
	var t = clamp(death_clock / max(death_duration, 0.01), 0.0, 1.0)
	rotation += deg_to_rad(death_spin) * _death_spin_dir * delta * (1.0 - t) * 2.3
	scale = Vector2(1.0, 1.0).lerp(Vector2(0.05, 0.05), t)
	global_position += Vector2(0, -1) * death_bounce * (1.0 - t) * delta
	modulate = modulate.lerp(Color(1, 1, 1, 0), t)
	if t >= 1.0:
		queue_free()


func _handle_bounce() -> void:
	var screen_size = get_viewport_rect().size
	if horse_type == "escape":
		return
	if global_position.x < 10.0 or global_position.x > screen_size.x - 10.0:
		move_direction.x *= -1.0
		global_position.x = clamp(global_position.x, 10.0, screen_size.x - 10.0)
		_play_boing()
	if global_position.y < 10.0 or global_position.y > screen_size.y - 10.0:
		move_direction.y *= -1.0
		global_position.y = clamp(global_position.y, 10.0, screen_size.y - 10.0)
		_play_boing()


func take_hit() -> void:
	if is_dead:
		return
	is_dead = true
	death_clock = 0.0
	_death_spin_dir = 1.0 if randf() < 0.5 else -1.0
	collision_shape.disabled = true
	horse_killed.emit(point_value, global_position)
	var gm := _get_game_manager()
	if gm and gm.has_signal("request_audio"):
		gm.request_audio.emit("explosion", global_position, 1.0)

	if horse_type == "splitter" and not split_done:
		split_done = true
		var dirs = []
		for i in range(split_count):
			dirs.append(Vector2.RIGHT.rotated(i * TAU / max(split_count, 1)))
		split_requested.emit(global_position, dirs)


func _escape() -> void:
	if is_dead:
		return
	is_dead = true
	collision_shape.disabled = true
	horse_escaped.emit(global_position)
	queue_free()


func _animate_sprite(delta: float) -> void:
	_run_clock += delta * run_frame_rate
	if _run_clock >= 1.0:
		_run_clock = 0.0
		_run_offset = (_run_offset + 1) % 2

	_direction_bucket = _resolve_direction_bucket(move_direction)
	if _direction_bucket == 0:
		sprite.flip_h = false
	elif _direction_bucket == 3:
		sprite.flip_h = true

	var base_index = _direction_bucket % TEXTURE_SET.size()
	var final_index = (base_index + _run_offset) % TEXTURE_SET.size()
	if TEXTURE_SET.size() > final_index:
		sprite.texture = TEXTURE_SET[final_index]

	sprite.scale.y = 1.0 + 0.04 * sin(Time.get_ticks_msec() * 0.01)


func _pick_new_direction() -> void:
	var angle = randf() * TAU
	var next_direction = Vector2(cos(angle), sin(angle)).normalized()
	if next_direction == Vector2.ZERO:
		next_direction = Vector2.RIGHT
	move_direction = next_direction
	direction_timer = randf_range(0.3, direction_change_time)


func _resolve_direction_bucket(direction: Vector2) -> int:
	var normalized = direction.normalized()
	if abs(normalized.x) >= abs(normalized.y):
		return 3 if normalized.x < 0.0 else 1
	return 0 if normalized.y < 0.0 else 2


func _choose_sprite() -> void:
	if TEXTURE_SET.size() > 0:
		var idx = int(randi() % TEXTURE_SET.size())
		sprite.texture = TEXTURE_SET[idx]
	if horse_type == "escape":
		modulate = Color(0.75, 0.85, 1.0)
	elif horse_type == "splitter":
		modulate = Color(1.12, 0.95, 0.45)
	elif horse_type == "zigzag":
		modulate = Color(1.05, 1.2, 1.05)
	else:
		modulate = Color.WHITE


func _play_boing() -> void:
	var gm := _get_game_manager()
	if gm and gm.has_signal("request_audio"):
		gm.request_audio.emit("boing", global_position, 0.6)
