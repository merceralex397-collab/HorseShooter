extends Area2D

# Bullet physics and collision handling
# Travels in a straight line, destroys on impact or after time

@export var speed: float = 600.0
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var time_alive: float = 0.0
var hit_something: bool = false

@onready var hit_sound = $HitSound

func _ready():
	# Rotate sprite to match direction
	rotation = direction.angle()

func _process(delta):
	# Move bullet
	position += direction * speed * delta
	
	# Check lifetime
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_body_entered(body):
	# Don't hit if already hit something
	if hit_something:
		return
	
	# Check if we hit a horse
	if body.is_in_group("horses"):
		hit_something = true
		body.take_hit()  # Tell the horse it was hit
		play_hit_effect()
		queue_free()

func _on_area_entered(area):
	# Handle hitting other areas if needed
	pass

func play_hit_effect():
	# Spawn hit effect
	if hit_sound:
		hit_sound.play()
