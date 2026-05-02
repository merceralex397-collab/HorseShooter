extends Area2D

# Projectile with pooled life cycle.

@export var speed := 620.0
@export var lifetime := 2.2

var direction := Vector2.RIGHT
var active := false
var time_alive := 0.0
var hit_registered := false

const SCENE_PATH := "res://scenes/bullet.tscn"

const GAME_MANAGER_PATH := "/root/GameManager"
const OBJECT_POOL_PATH := "/root/ObjectPool"


func _get_game_manager() -> Node:
	var gm := get_node_or_null(GAME_MANAGER_PATH)
	return gm


func _get_object_pool() -> Node:
	var pool := get_node_or_null(OBJECT_POOL_PATH)
	return pool


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not active:
		return
	time_alive += delta
	if time_alive >= lifetime:
		_release()
		return

	global_position += direction * speed * delta


func launch(from_position: Vector2, shot_direction: Vector2) -> void:
	global_position = from_position
	direction = shot_direction.normalized()
	rotation = direction.angle()
	time_alive = 0.0
	active = true
	monitoring = true
	visible = true
	add_to_group("bullets")


func on_spawn() -> void:
	active = false
	hit_registered = false
	time_alive = 0.0
	set_process(true)


func on_released() -> void:
	active = false
	monitoring = false
	visible = false
	remove_from_group("bullets")


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	if not body.is_in_group("horses"):
		return
	if body.has_method("take_hit"):
		body.take_hit()
		hit_registered = true
		var gm := _get_game_manager()
		if gm:
			if gm.has_signal("request_vfx"):
				gm.request_vfx.emit("bullet_hit", global_position, {})
			if gm.has_signal("request_audio"):
				gm.request_audio.emit("hit", global_position, 1.0)
		_release()


func _on_visible_notifier_screen_exited() -> void:
	_release()


func _release() -> void:
	var gm := _get_game_manager()
	if active and not hit_registered:
		var player = get_tree().get_first_node_in_group("player") as Node
		var blocked_by_shield = false
		if player and player.has_method("use_shield"):
			blocked_by_shield = bool(player.use_shield())
		if not blocked_by_shield:
			if gm and gm.has_method("register_shot_missed"):
				gm.register_shot_missed()
		else:
			if gm and gm.has_method("request_vfx") and gm.has_signal("request_vfx"):
				gm.request_vfx.emit("shield_block", global_position, {})
			if gm and gm.has_method("request_audio") and gm.has_signal("request_audio"):
				gm.request_audio.emit("boing", global_position, 0.85)

	var object_pool := _get_object_pool()
	if object_pool == null:
		queue_free()
		return
	object_pool.release(SCENE_PATH, self)
