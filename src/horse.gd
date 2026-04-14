extends CharacterBody2D

# Horse AI and slapstick reactions
# Cartoon horses with googly eyes that react comically when hit

@export var speed: float = 80.0
@export var change_direction_time: float = 2.0
@export var point_value: int = 100

var move_direction: Vector2 = Vector2.ZERO
var direction_timer: float = 0.0
var is_dead: bool = false
var death_animation_time: float = 0.0
var original_scale: Vector2 = Vector2.ONE

# Sprite references
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var death_sound = $DeathSound
@onready var boing_sound = $BoingSound

func _ready():
	# Random starting position
	pick_random_direction()
	original_scale = scale
	
	# Randomize appearance
	var horse_sprites = [
		preload("res://assets/sprites/horse_0.png"),
		preload("res://assets/sprites/horse_1.png"),
		preload("res://assets/sprites/horse_2.png"),
		preload("res://assets/sprites/horse_3.png")
	]
	sprite.texture = horse_sprites[randi() % horse_sprites.size()]
	
	# Add to horses group
	add_to_group("horses")

func _physics_process(delta):
	if is_dead:
		# Play death animation - spin and shrink comically
		death_animation_time += delta
		rotation += 15 * delta  # Spin fast
		scale = original_scale * (1.0 - death_animation_time * 2)  # Shrink
		
		# Float upward like a cartoon ghost
		position.y -= 100 * delta
		
		# Remove after animation
		if death_animation_time > 0.5:
			queue_free()
		return
	
	# Regular movement behavior
	direction_timer -= delta
	if direction_timer <= 0:
		pick_random_direction()
		# Occasionally play boing sound
		if randf() < 0.2 and boing_sound:
			boing_sound.play()
	
	# Move
	velocity = move_direction * speed
	move_and_slide()
	
	# Bounce off screen edges (slapstick style)
	var screen_size = get_viewport_rect().size
	if position.x < 24 or position.x > screen_size.x - 24:
		move_direction.x *= -1
		position.x = clamp(position.x, 24, screen_size.x - 24)
		if boing_sound:
			boing_sound.play()
	
	if position.y < 24 or position.y > screen_size.y - 24:
		move_direction.y *= -1
		position.y = clamp(position.y, 24, screen_size.y - 24)
		if boing_sound:
			boing_sound.play()
	
	# Face movement direction
	if move_direction.x > 0:
		sprite.flip_h = false
	elif move_direction.x < 0:
		sprite.flip_h = true
	
	# Animate legs by wobbling scale slightly
	var wobble = sin(Time.get_time_dict_from_system()["second"] * 10) * 0.05
	sprite.scale.y = 1.0 + wobble

func pick_random_direction():
	# Pick random normalized direction
	var angle = randf() * 2 * PI
	move_direction = Vector2(cos(angle), sin(angle))
	direction_timer = change_direction_time + randf() * 2

func take_hit():
	if is_dead:
		return
	
	is_dead = true
	
	# Play death sound
	if death_sound:
		death_sound.play()
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Add score
	GameManager.add_score(point_value)
	
	# Spawn comic explosion effect
	spawn_explosion()
	
	# Show comic text
	show_comic_text()

func spawn_explosion():
	# Spawn explosion animation at horse position
	var explosion = preload("res://scenes/explosion.tscn").instantiate()
	explosion.position = position
	explosion.scale = Vector2(1.5, 1.5)
	get_parent().add_child(explosion)

func show_comic_text():
	# Create a floating text with comic phrases
	var phrases = ["KA-BOOM!", "POW!", "SPLAT!", "WHAM!", "ZAP!"]
	var phrase = phrases[randi() % phrases.size()]
	
	# This would typically spawn a Label node
	# For simplicity, we'll just print or emit a signal
	print("Comic text: ", phrase)
