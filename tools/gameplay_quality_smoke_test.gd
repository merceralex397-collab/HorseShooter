extends Node

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const HORSE_SCENE := preload("res://scenes/horse.tscn")

var _escaped := false


func _ready() -> void:
	await get_tree().process_frame

	if not await _check_escape_horse_has_spawn_grace():
		get_tree().quit(1)
		return

	print("GAMEPLAY_QUALITY_SMOKE_STATUS: PASS")
	get_tree().quit(0)


func _check_escape_horse_has_spawn_grace() -> bool:
	var player := PLAYER_SCENE.instantiate() as Node2D
	add_child(player)
	await get_tree().process_frame

	var horse := HORSE_SCENE.instantiate() as Node2D
	add_child(horse)
	horse.global_position = player.global_position + Vector2(320.0, 0.0)
	horse.horse_escaped.connect(func(_position: Vector2) -> void:
		_escaped = true
	)
	horse.setup("escape", {"base_speed": 90.0, "point_value": 100})

	await get_tree().physics_frame
	await get_tree().physics_frame

	if _escaped or not is_instance_valid(horse) or horse.is_queued_for_deletion():
		push_error("GAMEPLAY_QUALITY: Escape horse escaped immediately after spawning away from the player.")
		return false

	horse.queue_free()
	player.queue_free()
	return true
