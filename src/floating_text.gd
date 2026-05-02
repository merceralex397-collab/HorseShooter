extends Node2D

@onready var label: Label = $Label
const OBJECT_POOL_PATH := "/root/ObjectPool"

var _life := 0.85
var _tween: Tween

func _get_object_pool() -> Node:
	var pool := get_node_or_null(OBJECT_POOL_PATH)
	return pool


func _ready() -> void:
	label.text = ""


func start(message: String, text_color: Color = Color.WHITE) -> void:
	label.text = message
	label.modulate = text_color
	modulate.a = 1.0
	position = Vector2.ZERO
	_animate()


func _animate() -> void:
	if _tween:
		_tween.kill()
	var end_pos = position + Vector2(0, -36)
	_tween = get_tree().create_tween()
	_tween.tween_property(self, "position", end_pos, _life)
	_tween.parallel().tween_property(label, "modulate:a", 0.0, _life)
	_tween.tween_callback(_return_to_pool)


func on_spawn() -> void:
	label.visible = true
	modulate.a = 1.0
	set_process(false)


func on_released() -> void:
	label.visible = false
	label.text = ""
	set_process(false)
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = null


func _return_to_pool() -> void:
	var object_pool := _get_object_pool()
	if object_pool == null:
		queue_free()
		return
	object_pool.release("res://scenes/floating_text.tscn", self)
