extends Node2D

# Horse spawner
# Spawns horses at random positions on a timer

@export var spawn_interval: float = 2.0
@export var max_horses: int = 15
@export var spawn_margin: float = 50.0

var spawn_timer: float = 0.0
var horse_scene = preload("res://scenes/horse.tscn")

func _ready():
	# Spawn initial horses
	for i in range(5):
		spawn_horse()

func _process(delta):
	spawn_timer -= delta
	
	if spawn_timer <= 0:
		# Count current horses
		var horses = get_tree().get_nodes_in_group("horses")
		if horses.size() < max_horses:
			spawn_horse()
		spawn_timer = spawn_interval

func spawn_horse():
	var screen_size = get_viewport_rect().size
	
	# Pick random position (away from player)
	var spawn_pos = Vector2.ZERO
	var player = get_tree().get_first_node_in_group("player")
	
	# Try to spawn away from player
	for attempt in range(10):
		spawn_pos = Vector2(
			randf_range(spawn_margin, screen_size.x - spawn_margin),
			randf_range(spawn_margin, screen_size.y - spawn_margin)
		)
		
		if player:
			var dist = spawn_pos.distance_to(player.position)
			if dist > 150:  # Don't spawn too close to player
				break
	
	# Create horse
	var horse = horse_scene.instantiate()
	horse.position = spawn_pos
	add_child(horse)
	
	# Register spawn
	GameManager.register_horse_spawned()
