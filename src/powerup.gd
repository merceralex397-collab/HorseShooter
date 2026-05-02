extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
const GAME_MANAGER_PATH := "/root/GameManager"
const OBJECT_POOL_PATH := "/root/ObjectPool"
const SCENE_PATH := "res://scenes/powerup.tscn"
const POWERUP_TEXTURES := {
	"rapid_fire": preload("res://assets/sprites/powerup_rapid_fire.png"),
	"spread_shot": preload("res://assets/sprites/powerup_spread_shot.png"),
	"shield": preload("res://assets/sprites/powerup_shield.png"),
	"speed_boost": preload("res://assets/sprites/powerup_speed_boost.png"),
}

signal collected(power_type, multiplier)

var power_type := "rapid_fire"
var duration := 6.0
@export var lifespan := 8.0
var _picked := false
var _life_left := 0.0


func _get_game_manager() -> Node:
	return get_node_or_null(GAME_MANAGER_PATH)


func _get_object_pool() -> Node:
	return get_node_or_null(OBJECT_POOL_PATH)


func _ready() -> void:
	add_to_group("powerups")
	if not $CollisionShape2D.shape:
		var shape = CircleShape2D.new()
		shape.radius = 14.0
		$CollisionShape2D.shape = shape
	elif $CollisionShape2D.shape is CircleShape2D:
		($CollisionShape2D.shape as CircleShape2D).radius = 14.0

	if not is_connected("body_entered", _on_body_entered):
		body_entered.connect(_on_body_entered)


func setup(kind: String) -> void:
	power_type = kind
	if POWERUP_TEXTURES.has(kind):
		sprite.texture = POWERUP_TEXTURES[kind]
	match kind:
		"rapid_fire":
			sprite.modulate = Color.WHITE
			duration = 7.0
		"spread_shot":
			sprite.modulate = Color.WHITE
			duration = 5.0
		"shield":
			sprite.modulate = Color.WHITE
			duration = 8.0
		"speed_boost":
			sprite.modulate = Color.WHITE
			duration = 5.5
		_:
			sprite.modulate = Color(1.0, 1.0, 1.0)
			duration = 5.0
	_life_left = max(lifespan, 3.0)


func collect() -> void:
	if _picked:
		return
	_picked = true
	var gm := _get_game_manager()
	if gm:
		if gm.has_signal("request_vfx"):
			gm.request_vfx.emit("powerup_collect", global_position, {"type": power_type})
		if gm.has_signal("request_audio"):
			gm.request_audio.emit("powerup", global_position, 1.0)
	collected.emit(power_type, duration)
	_release()


func _process(delta: float) -> void:
	if _picked:
		return
	_life_left -= delta
	var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.008)
	sprite.scale = Vector2.ONE * pulse
	sprite.rotation += delta * 1.8
	if _life_left <= 0.0:
		_release()


func on_released() -> void:
	_picked = false
	_life_left = 0.0
	monitoring = false
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0


func on_spawn() -> void:
	_picked = false
	_life_left = max(lifespan, 3.0)
	monitoring = true
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0


func _on_body_entered(body: Node2D) -> void:
	if _picked:
		return
	if not body.is_in_group("player"):
		return
	var event = {
		"type": power_type,
		"duration": duration,
	}
	if body.has_method("collect_powerup"):
		body.collect_powerup(event)
	collect()


func _release() -> void:
	var pool := _get_object_pool()
	if pool:
		pool.release(SCENE_PATH, self)
	else:
		queue_free()
