extends Node2D

# Cartoon explosion/splat effect
# Animated sprite that plays once then disappears

@export var frame_duration: float = 0.1

var current_frame: int = 0
var frame_timer: float = 0.0
var sprites = []

func _ready():
	# Load explosion sprites
	sprites = [
		preload("res://assets/sprites/explosion_0.png"),
		preload("res://assets/sprites/explosion_1.png"),
		preload("res://assets/sprites/explosion_2.png"),
		preload("res://assets/sprites/explosion_3.png")
	]
	
	# Set initial sprite
	$Sprite2D.texture = sprites[0]
	
	# Play explosion sound
	$ExplosionSound.play()

func _process(delta):
	frame_timer += delta
	
	if frame_timer >= frame_duration:
		frame_timer = 0.0
		current_frame += 1
		
		if current_frame >= sprites.size():
			# Animation complete
			queue_free()
		else:
			# Update sprite
			$Sprite2D.texture = sprites[current_frame]
