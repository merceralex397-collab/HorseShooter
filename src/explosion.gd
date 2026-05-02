extends Node2D

# Reusable stylized impact animation with smoke burst and bounded particle load.

@export var frame_duration := 0.075
@export var max_particles_per_frame := 96
@export var max_concurrent_debris_emitters := 5

const SCENE_PATH := "res://scenes/explosion.tscn"
const OBJECT_POOL_PATH := "/root/ObjectPool"

static var _particle_budget_frame := -1
static var _particles_used_this_frame := 0
static var _active_debris_emitters := 0

func _get_object_pool() -> Node:
	var pool := get_node_or_null(OBJECT_POOL_PATH)
	return pool

var _frame_timer := 0.0
var _current_frame := 0
var _frame_textures := []
var _using_particles := 0


func _ready() -> void:
	_frame_textures = [
		load("res://assets/sprites/explosion_0.png"),
		load("res://assets/sprites/explosion_1.png"),
		load("res://assets/sprites/explosion_2.png"),
		load("res://assets/sprites/explosion_3.png"),
	]
	$Sprite2D.texture = _frame_textures[0] if _frame_textures.size() > 0 else null


func on_released() -> void:
	_release_particles()
	visible = false
	set_process(false)


func on_spawn() -> void:
	_frame_timer = 0.0
	_current_frame = 0
	modulate.a = 1.0
	visible = true
	_using_particles = 0
	_release_particles()
	if _frame_textures.size() > 0:
		$Sprite2D.texture = _frame_textures[0]
	_configure_particle_node($Particles2D)
	_configure_particle_node($SmokeParticles)
	set_process(true)


func _configure_particle_node(node: Node) -> void:
	var particles := node as CPUParticles2D
	if particles == null:
		return

	particles.emitting = false
	particles.amount = min(particles.amount, max_particles_per_frame)

	var current_frame = Engine.get_process_frames()
	if _particle_budget_frame != current_frame:
		_particle_budget_frame = current_frame
		_particles_used_this_frame = 0

	var potential = min(int(particles.amount), 32)
	if _particles_used_this_frame + potential <= max_particles_per_frame and _active_debris_emitters < max_concurrent_debris_emitters:
		_particles_used_this_frame += potential
		_active_debris_emitters += 1
		_using_particles += 1
		particles.restart()
		particles.emitting = true


func _process(delta: float) -> void:
	_frame_timer += delta
	if _frame_timer < frame_duration:
		return
	_frame_timer = 0.0
	_current_frame += 1
	if _frame_textures.is_empty() or _current_frame >= _frame_textures.size():
		_return_to_pool()
		return
	$Sprite2D.texture = _frame_textures[_current_frame]


func _release_particles() -> void:
	if $Particles2D:
		$Particles2D.emitting = false
	if $SmokeParticles:
		$SmokeParticles.emitting = false
	if _using_particles > 0:
		_active_debris_emitters = max(_active_debris_emitters - _using_particles, 0)
	_using_particles = 0


func _return_to_pool() -> void:
	_release_particles()
	var object_pool := _get_object_pool()
	if object_pool == null:
		queue_free()
		return
	object_pool.release(SCENE_PATH, self)
