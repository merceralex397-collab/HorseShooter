extends CharacterBody2D

# Player movement and shooting script
# Handles keyboard/touch input and bullet spawning

@export var speed: float = 300.0
@export var shoot_cooldown: float = 0.2

var can_shoot: bool = true
var shoot_timer: float = 0.0

# Preload the bullet scene
@onready var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var shoot_sound = $ShootSound

func _ready():
	# Center the player initially
	position = Vector2(640, 360)

func _physics_process(delta):
	# Handle movement
	var direction = Vector2.ZERO
	
	# Keyboard input
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	
	# Touch/joystick input (for mobile)
	# Simplified virtual joystick - mouse position relative to center
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		var screen_center = get_viewport_rect().size / 2
		var touch_offset = mouse_pos - screen_center
		if touch_offset.length() > 50:  # Deadzone
			direction = touch_offset.normalized()
	
	# Normalize diagonal movement
	if direction.length() > 1:
		direction = direction.normalized()
	
	# Apply movement
	velocity = direction * speed
	move_and_slide()
	
	# Keep player on screen
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 16, screen_size.x - 16)
	position.y = clamp(position.y, 16, screen_size.y - 16)
	
	# Handle shooting
	if shoot_timer > 0:
		shoot_timer -= delta
	else:
		can_shoot = true
	
	# Shoot with space or mouse
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

func shoot():
	can_shoot = false
	shoot_timer = shoot_cooldown
	
	# Spawn bullet
	var bullet = bullet_scene.instantiate()
	bullet.position = position
	
	# Aim at mouse position
	var mouse_pos = get_global_mouse_position()
	bullet.direction = (mouse_pos - position).normalized()
	
	# Add to scene
	get_parent().add_child(bullet)
	
	# Play sound
	if shoot_sound:
		shoot_sound.play()
