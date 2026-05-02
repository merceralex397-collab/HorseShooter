extends Node2D

signal wave_progress(spawned, active, time_left)

@export var horse_scene: PackedScene = preload("res://scenes/horse.tscn")
@export var powerup_scene: PackedScene = preload("res://scenes/powerup.tscn")
const GAME_MANAGER_PATH := "/root/GameManager"
const OBJECT_POOL_PATH := "/root/ObjectPool"
const POWERUP_SCENE_PATH := "res://scenes/powerup.tscn"
@export var spawn_margin := 70.0
@export var spawn_attempts := 12
@export var active_horse_soft_limit := 24
const MAX_ROUND_WARNING_TIME := 2.6

var active := false
var round_profile: Dictionary = {}
var current_round = 0
var spawn_timer = 0.0
var spawned_in_round = 0
var target_count = 0
var active_horses := []
var round_time_left = 0.0
var spawn_interval := 0.8
var spawn_variance := 0.2
var _warning_shown := false
var _corner_warning_shown := false
var _corner_warning_cooldown = 0.0
const CORNER_WARNING_COOLDOWN := 2.2


func _get_game_manager() -> Node:
	return get_node_or_null(GAME_MANAGER_PATH)


func _get_object_pool() -> Node:
	return get_node_or_null(OBJECT_POOL_PATH)


func _ready() -> void:
	var gm := _get_game_manager()
	if gm:
		if gm.is_connected("round_started", _on_round_started):
			gm.disconnect("round_started", _on_round_started)
		gm.connect("round_started", _on_round_started)

		if gm.is_connected("state_changed", _on_state_changed):
			gm.disconnect("state_changed", _on_state_changed)
		gm.connect("state_changed", _on_state_changed)

		if gm.is_connected("round_cleared", _on_round_stopped):
			gm.disconnect("round_cleared", _on_round_stopped)
		gm.connect("round_cleared", _on_round_stopped)
		if gm.is_connected("round_failed", _on_round_stopped):
			gm.disconnect("round_failed", _on_round_stopped)
		gm.connect("round_failed", _on_round_stopped)

		_on_state_changed(gm.state)


func _process(delta: float) -> void:
	if not active:
		return

	var gm := _get_game_manager()
	if gm == null:
		return
	if gm.has_method("update_round_clock"):
		gm.update_round_clock(delta)
	round_time_left = gm.round_time_remaining
	_apply_time_pressure_hint()
	_apply_corner_pressure_hint(delta)

	spawn_timer -= delta
	if spawn_timer <= 0.0 and spawned_in_round < target_count and _active_horse_capacity():
		_spawn_horse()
		spawn_timer = max(spawn_interval + randf_range(-spawn_variance, spawn_variance), 0.1)

	_clean_dead_horses()
	_try_round_completion()
	wave_progress.emit(spawned_in_round, active_horses.size(), max(round_time_left, 0.0))


func _on_state_changed(new_state: int) -> void:
	var gm := _get_game_manager()
	if gm == null:
		return
	active = new_state == gm.GameState.PLAYING or new_state == gm.GameState.GET_READY
	set_process(active)
	if not active:
		return
	# Keep timers in sync when returning to play.
	round_time_left = gm.round_time_remaining
	spawn_timer = 0.0
	_warning_shown = false


func _on_round_started(round_id: int, profile: Dictionary) -> void:
	current_round = round_id
	round_profile = profile.duplicate(true)
	target_count = int(profile.get("target_horses", 20))
	spawn_interval = float(profile.get("spawn_interval", 1.0))
	spawn_variance = float(profile.get("spawn_interval_variance", 0.2))
	spawned_in_round = 0
	active_horses.clear()
	round_time_left = float(profile.get("time_limit", 20.0))
	spawn_timer = 0.15
	_warning_shown = false
	_corner_warning_shown = false
	_corner_warning_cooldown = 0.0


func _on_round_stopped(_round_id: int, _summary: Dictionary) -> void:
	active = false
	set_process(false)
	_warning_shown = false
	for horse in active_horses:
		if is_instance_valid(horse):
			horse.queue_free()
	active_horses.clear()
	_corner_warning_shown = false
	_corner_warning_cooldown = 0.0

func _active_horse_capacity() -> bool:
	return active_horses.size() < active_horse_soft_limit


func _spawn_horse() -> void:
	var spawn_position = _pick_spawn_position()
	var horse: Node = horse_scene.instantiate()
	add_child(horse)
	horse.position = spawn_position
	var h_type = _pick_horse_type()
	horse.setup(h_type, round_profile)
	horse.horse_killed.connect(_on_horse_killed.bind(horse))
	horse.horse_escaped.connect(_on_horse_escaped.bind(horse))
	horse.split_requested.connect(_on_horse_split)
	active_horses.append(horse)

	var gm := _get_game_manager()
	if gm:
		gm.register_horse_spawned()
	spawned_in_round += 1
	gm_request_vfx("spawn_ping", horse.global_position, {})


func _pick_horse_type() -> String:
	var escape_ratio = float(round_profile.get("escape_ratio", 0.0))
	var split_ratio = float(round_profile.get("splitter_ratio", 0.0))
	var zigzag_ratio = float(round_profile.get("zigzag_ratio", 0.0))
	var value = randf()
	if value < escape_ratio:
		return "escape"
	value -= escape_ratio
	if value < split_ratio:
		return "splitter"
	value -= split_ratio
	if value < zigzag_ratio:
		return "zigzag"
	return "trotter"


func _pick_spawn_position() -> Vector2:
	var screen_size = get_viewport_rect().size
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var avoid_pos = Vector2(screen_size * 0.5)
	if player:
		avoid_pos = player.global_position
	var pos := Vector2.ZERO
	for _i in spawn_attempts:
		pos = Vector2(
			randf_range(spawn_margin, screen_size.x - spawn_margin),
			randf_range(spawn_margin, screen_size.y - spawn_margin)
		)
		if pos.distance_to(avoid_pos) > 140.0:
			break
	return pos


func _on_horse_killed(points: int, world_position: Vector2, sender: Node) -> void:
	var gm := _get_game_manager()
	if gm:
		gm.register_horse_hit(points, world_position)
	if is_instance_valid(sender):
		active_horses.erase(sender)
		if gm:
			gm_request_vfx("horse_killed", world_position, {})
	if gm and randf() < float(round_profile.get("powerup_chance", 0.05)):
		_spawn_powerup(world_position)
	_try_round_completion()


func _on_horse_escaped(world_position: Vector2, sender: Node) -> void:
	var gm := _get_game_manager()
	if is_instance_valid(sender):
		active_horses.erase(sender)
	if gm:
		gm.fail_round("Horse escaped")


func _on_horse_split(world_position: Vector2, directions: Array) -> void:
	for direction in directions:
		if active_horses.size() >= active_horse_soft_limit:
			return
		var child = horse_scene.instantiate()
		add_child(child)
		child.position = world_position + Vector2(direction).normalized() * 12.0
		child.setup_as_split(round_profile)
		child.horse_killed.connect(_on_horse_killed.bind(child))
		child.horse_escaped.connect(_on_horse_escaped.bind(child))
		child.split_requested.connect(_on_horse_split)
		active_horses.append(child)
		var gm = _get_game_manager()
		if gm:
			gm.register_horse_spawned()
			gm_request_vfx("spawn_ping", child.global_position, {})


func _spawn_powerup(world_position: Vector2) -> void:
	if not powerup_scene:
		return
	var object_pool := _get_object_pool()
	var powerup: Node = null
	if object_pool:
		powerup = object_pool.acquire(POWERUP_SCENE_PATH)
	if powerup == null:
		powerup = powerup_scene.instantiate()
	add_child(powerup)
	powerup.global_position = world_position
	powerup.setup(_pick_powerup_type())


func _pick_powerup_type() -> String:
	var pick = randf()
	if pick < 0.30:
		return "rapid_fire"
	if pick < 0.52:
		return "spread_shot"
	if pick < 0.75:
		return "shield"
	return "speed_boost"


func _try_round_completion() -> void:
	if not active:
		return
	var gm := _get_game_manager()
	if gm == null:
		return
	if not gm.round_active:
		return
	_clean_dead_horses()
	if spawned_in_round >= target_count and active_horses.is_empty():
		gm.complete_round()


func _clean_dead_horses() -> void:
	active_horses = active_horses.filter(func(h):
		if h == null:
			return false
		if not is_instance_valid(h):
			return false
		if h.is_queued_for_deletion():
			return false
		return true
	)


func _apply_time_pressure_hint() -> void:
	var gm := _get_game_manager()
	if gm == null:
		return
	if _warning_shown:
		return
	var near_end = round_time_left <= MAX_ROUND_WARNING_TIME and gm.state == gm.GameState.PLAYING
	if near_end and gm.round_active:
		_warning_shown = true
		gm_request_hint("Hurry! Time is almost up", 2.0)


func _apply_corner_pressure_hint(delta: float) -> void:
	var gm := _get_game_manager()
	if gm == null or not gm.round_active:
		return
	if _corner_warning_cooldown > 0.0:
		_corner_warning_cooldown -= delta
		return

	var screen_size = get_viewport_rect().size
	var edge_margin = 48.0
	for horse in active_horses:
		if horse == null or not is_instance_valid(horse):
			continue
		var pos: Vector2 = horse.global_position
		if pos.x < edge_margin or pos.y < edge_margin or pos.x > screen_size.x - edge_margin or pos.y > screen_size.y - edge_margin:
			if not _corner_warning_shown:
				_corner_warning_shown = true
				gm_request_hint("Watch your corners!", 1.3)
			_corner_warning_cooldown = CORNER_WARNING_COOLDOWN
			return

	_corner_warning_shown = false


func gm_request_vfx(vfx_name: String, position: Vector2, payload: Dictionary) -> void:
	var gm := _get_game_manager()
	if gm and gm.has_signal("request_vfx"):
		gm.request_vfx.emit(vfx_name, position, payload)


func gm_request_hint(text: String, duration := 2.2) -> void:
	var gm := _get_game_manager()
	if gm and gm.has_signal("hint_requested"):
		gm.request_hint(text, duration)








