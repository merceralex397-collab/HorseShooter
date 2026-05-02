class_name RpgPlayerController
extends CharacterBody2D

@export var move_speed := 330.0
@export var dodge_speed := 760.0
@export var dodge_duration := 0.16
@export var max_stamina := 100.0
@export var stamina_recovery_per_second := 28.0
@export var dodge_stamina_cost := 24.0
@export var is_female := true
@export var has_long_dark_brown_hair := true

var aim_vector := Vector2.RIGHT
var last_nonzero_aim := Vector2.RIGHT
var equipped_weapon_id := "weapon.greenbarrow.rusty_oath"
var stamina := 100.0
var shots_fired: Array[Dictionary] = []
var _dodge_timer := 0.0
var _visual_root: Node2D
var _hair: Polygon2D
var _coat: Polygon2D
var _gun_arm: Polygon2D
var _left_arm: Polygon2D
var _left_leg: Polygon2D
var _right_leg: Polygon2D
var _gun: Polygon2D
var _head: Polygon2D
var _walk_cycle := 0.0


func _ready() -> void:
	add_to_group("rpg_player")
	collision_layer = 1
	collision_mask = 8
	_build_placeholder_visual()


func _physics_process(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _dodge_timer > 0.0:
		_dodge_timer -= delta
		velocity = last_nonzero_aim.normalized() * dodge_speed
	else:
		stamina = min(max_stamina, stamina + stamina_recovery_per_second * delta)
		velocity = movement * move_speed
		if movement.length() > 0.1:
			last_nonzero_aim = movement.normalized()
	move_and_slide()
	_update_visual(delta, movement)


func set_aim_direction(direction: Vector2) -> void:
	if direction.length() > 0.05:
		aim_vector = direction.normalized()
		last_nonzero_aim = aim_vector


func get_shot_direction() -> Vector2:
	if aim_vector.length() > 0.05:
		return aim_vector.normalized()
	return last_nonzero_aim.normalized()


func equip_weapon(weapon_id: String) -> void:
	if not weapon_id.strip_edges().is_empty():
		equipped_weapon_id = weapon_id


func fire_weapon(direction := Vector2.ZERO) -> Dictionary:
	if direction.length() > 0.05:
		set_aim_direction(direction)
	var profile := _get_weapon_profile(equipped_weapon_id)
	var inventory_manager := get_node_or_null("/root/InventoryManager")
	var ammo_type := String(profile.get("ammo_type", "standard"))
	var heat_cost := int(profile.get("heat_cost", 8))
	var fired_with_inventory := false
	if inventory_manager and inventory_manager.has_method("register_weapon_fire"):
		var ammo: Dictionary = inventory_manager.get("ammo")
		if int(ammo.get(ammo_type, 0)) > 0:
			fired_with_inventory = bool(inventory_manager.call("register_weapon_fire", equipped_weapon_id, ammo_type, heat_cost))
	var shot := {
		"weapon_id": equipped_weapon_id,
		"origin": global_position,
		"direction": get_shot_direction(),
		"damage": int(profile.get("damage", 12)),
		"damage_type": String(profile.get("damage_type", "physical")),
		"range": float(profile.get("range", 520.0)),
		"spread": float(profile.get("spread", 0.0)),
		"projectile_count": int(profile.get("projectile_count", 1)),
		"status_effects": profile.get("status_effects", []).duplicate(true),
		"ammo_type": ammo_type,
		"heat_cost": heat_cost,
		"inventory_registered": fired_with_inventory,
	}
	shots_fired.append(shot)
	return shot


func dodge() -> bool:
	if stamina < dodge_stamina_cost:
		return false
	stamina -= dodge_stamina_cost
	_dodge_timer = dodge_duration
	return true


func interact() -> void:
	pass


func get_combat_state() -> Dictionary:
	return {
		"weapon_id": equipped_weapon_id,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"dodge_ready": stamina >= dodge_stamina_cost and _dodge_timer <= 0.0,
		"weapon_profile": _get_weapon_profile(equipped_weapon_id),
	}


func get_bark(trigger: String) -> String:
	match trigger:
		"horse_seen":
			return "Damn horse. I hate every hoof on that bastard."
		"tracks_seen":
			return "Horse tracks. Of course. Shit road, shit day."
		"low_health":
			return "If a horse kills me, I am haunting the damn species."
		"boss_intro":
			return "That is a big horse. I am going to make it a big problem solved."
		_:
			return "I hate horses. Keep moving."


func _build_placeholder_visual() -> void:
	_visual_root = Node2D.new()
	_visual_root.name = "ReadablePlayerVisual"
	add_child(_visual_root)

	var shadow := Polygon2D.new()
	shadow.name = "GroundShadow"
	shadow.color = Color(0.0, 0.0, 0.0, 0.32)
	shadow.polygon = PackedVector2Array([
		Vector2(-24, 36),
		Vector2(24, 36),
		Vector2(18, 48),
		Vector2(-18, 48),
	])
	_visual_root.add_child(shadow)

	_hair = Polygon2D.new()
	_hair.name = "LongDarkBrownHair"
	_hair.color = Color(0.10, 0.05, 0.03)
	_hair.polygon = PackedVector2Array([
		Vector2(-18, -38),
		Vector2(18, -38),
		Vector2(22, -6),
		Vector2(20, 24),
		Vector2(12, 54),
		Vector2(0, 62),
		Vector2(-12, 54),
		Vector2(-20, 24),
		Vector2(-22, -6),
	])
	_visual_root.add_child(_hair)

	var hair_highlight := Polygon2D.new()
	hair_highlight.name = "HairHighlight"
	hair_highlight.color = Color(0.20, 0.10, 0.045)
	hair_highlight.polygon = PackedVector2Array([
		Vector2(-8, -36),
		Vector2(6, -36),
		Vector2(12, -10),
		Vector2(5, 42),
		Vector2(-4, 54),
		Vector2(0, -6),
	])
	_visual_root.add_child(hair_highlight)

	_head = Polygon2D.new()
	_head.name = "Head"
	_head.color = Color(0.70, 0.48, 0.36)
	_head.polygon = PackedVector2Array([
		Vector2(-10, -28),
		Vector2(10, -28),
		Vector2(12, -10),
		Vector2(0, 0),
		Vector2(-12, -10),
	])
	_visual_root.add_child(_head)

	var face := Polygon2D.new()
	face.name = "Face"
	face.color = Color(0.78, 0.58, 0.46)
	face.polygon = PackedVector2Array([
		Vector2(-8, -24),
		Vector2(8, -24),
		Vector2(9, -10),
		Vector2(0, -2),
		Vector2(-9, -10),
	])
	_visual_root.add_child(face)

	var brow := Line2D.new()
	brow.default_color = Color(0.16, 0.08, 0.05)
	brow.width = 2.0
	brow.points = PackedVector2Array([
		Vector2(-5, -18),
		Vector2(0, -19),
		Vector2(5, -18),
	])
	_visual_root.add_child(brow)

	_coat = Polygon2D.new()
	_coat.name = "Coat"
	_coat.color = Color(0.18, 0.10, 0.08)
	_coat.polygon = PackedVector2Array([
		Vector2(-14, -2),
		Vector2(14, -2),
		Vector2(22, 22),
		Vector2(18, 44),
		Vector2(8, 52),
		Vector2(0, 38),
		Vector2(-8, 52),
		Vector2(-18, 44),
		Vector2(-22, 22),
	])
	_visual_root.add_child(_coat)

	var bandolier := Polygon2D.new()
	bandolier.name = "Bandolier"
	bandolier.color = Color(0.62, 0.18, 0.12)
	bandolier.polygon = PackedVector2Array([
		Vector2(-6, 2),
		Vector2(2, 2),
		Vector2(12, 28),
		Vector2(4, 28),
	])
	_visual_root.add_child(bandolier)

	_left_leg = Polygon2D.new()
	_left_leg.name = "LeftLeg"
	_left_leg.color = Color(0.16, 0.13, 0.12)
	_left_leg.polygon = PackedVector2Array([
		Vector2(-10, 38),
		Vector2(-1, 38),
		Vector2(-3, 66),
		Vector2(-12, 66),
	])
	_visual_root.add_child(_left_leg)

	_right_leg = Polygon2D.new()
	_right_leg.name = "RightLeg"
	_right_leg.color = Color(0.16, 0.13, 0.12)
	_right_leg.polygon = PackedVector2Array([
		Vector2(1, 38),
		Vector2(10, 38),
		Vector2(12, 66),
		Vector2(3, 66),
	])
	_visual_root.add_child(_right_leg)

	var boots := Polygon2D.new()
	boots.name = "Boots"
	boots.color = Color(0.08, 0.06, 0.05)
	boots.polygon = PackedVector2Array([
		Vector2(-14, 64),
		Vector2(14, 64),
		Vector2(12, 72),
		Vector2(-12, 72),
	])
	_visual_root.add_child(boots)

	_left_arm = Polygon2D.new()
	_left_arm.name = "LeftArm"
	_left_arm.color = Color(0.70, 0.48, 0.36)
	_left_arm.polygon = PackedVector2Array([
		Vector2(-14, 4),
		Vector2(-30, 14),
		Vector2(-26, 24),
		Vector2(-10, 14),
	])
	_visual_root.add_child(_left_arm)

	_gun_arm = Polygon2D.new()
	_gun_arm.name = "GunArm"
	_gun_arm.color = Color(0.70, 0.48, 0.36)
	_gun_arm.polygon = PackedVector2Array([
		Vector2(14, 4),
		Vector2(30, 8),
		Vector2(28, 20),
		Vector2(12, 14),
	])
	_visual_root.add_child(_gun_arm)

	_gun = Polygon2D.new()
	_gun.name = "EquippedGun"
	_gun.color = Color(0.42, 0.42, 0.44)
	_gun.polygon = PackedVector2Array([
		Vector2(28, 8),
		Vector2(60, 8),
		Vector2(60, 13),
		Vector2(32, 15),
		Vector2(25, 24),
		Vector2(20, 20),
	])
	_visual_root.add_child(_gun)

	_visual_root.scale = Vector2(0.82, 0.82)


func _update_visual(delta: float, movement: Vector2) -> void:
	if _visual_root == null:
		return
	var locomotion := movement.length()
	if locomotion > 0.08:
		_walk_cycle += delta * 8.0
	else:
		_walk_cycle = lerpf(_walk_cycle, 0.0, min(delta * 8.0, 1.0))
	_visual_root.rotation = lerpf(_visual_root.rotation, get_shot_direction().angle() * 0.12, min(delta * 10.0, 1.0))
	_visual_root.position.y = sin(_walk_cycle * 2.0) * min(locomotion, 1.0) * 3.0
	if _left_leg:
		_left_leg.position.y = sin(_walk_cycle) * min(locomotion, 1.0) * 3.0
	if _right_leg:
		_right_leg.position.y = -sin(_walk_cycle) * min(locomotion, 1.0) * 3.0
	if _left_arm:
		_left_arm.rotation = -sin(_walk_cycle) * 0.08 * locomotion
	if _gun_arm:
		_gun_arm.rotation = get_shot_direction().angle() * 0.22
	if _gun:
		_gun.rotation = get_shot_direction().angle() * 0.12
	if _hair:
		_hair.position.y = cos(_walk_cycle) * min(locomotion, 1.0) * 2.0
	if _coat:
		_coat.position.y = sin(_walk_cycle * 2.0 + 0.6) * min(locomotion, 1.0) * 2.0


func _get_weapon_profile(weapon_id: String) -> Dictionary:
	match weapon_id:
		"weapon.greenbarrow.roadwarden_pistol":
			return {"family": "pistol", "damage": 18, "range": 560.0, "spread": 0.03, "projectile_count": 1, "ammo_type": "standard", "heat_cost": 7, "damage_type": "physical", "status_effects": []}
		"weapon.greenbarrow.mare_spite_revolver":
			return {"family": "revolver", "damage": 24, "range": 610.0, "spread": 0.02, "projectile_count": 1, "ammo_type": "standard", "heat_cost": 10, "damage_type": "physical", "status_effects": []}
		"weapon.greenbarrow.haymaker_shotgun":
			return {"family": "shotgun", "damage": 34, "range": 360.0, "spread": 0.18, "projectile_count": 5, "ammo_type": "shell", "heat_cost": 16, "damage_type": "physical", "status_effects": ["stagger"]}
		"weapon.greenbarrow.fencepost_rifle":
			return {"family": "rifle", "damage": 31, "range": 820.0, "spread": 0.005, "projectile_count": 1, "ammo_type": "rifle", "heat_cost": 13, "damage_type": "physical", "status_effects": []}
		"weapon.greenbarrow.angry_lantern":
			return {"family": "experimental", "damage": 20, "range": 460.0, "spread": 0.09, "projectile_count": 2, "ammo_type": "volatile", "heat_cost": 24, "damage_type": "fire", "status_effects": ["burning"]}
		"weapon.greenbarrow.stablebreaker":
			return {"family": "hand_cannon", "damage": 42, "range": 500.0, "spread": 0.06, "projectile_count": 1, "ammo_type": "heavy", "heat_cost": 22, "damage_type": "physical", "status_effects": ["stagger"]}
		_:
			return {"family": "starter", "damage": 12, "range": 500.0, "spread": 0.04, "projectile_count": 1, "ammo_type": "standard", "heat_cost": 6, "damage_type": "physical", "status_effects": []}
