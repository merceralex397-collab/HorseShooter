extends "res://src/content/content_record.gd"

@export_enum("pistol", "revolver", "rifle", "shotgun", "launcher", "trap", "experimental") var family := "revolver"
@export var damage := 10
@export var fire_rate := 1.0
@export var reload_time := 1.0
@export var range := 600.0
@export var spread := 0.0
@export var projectile_count := 1
@export var ammo_type := "standard"
@export var rarity := "common"
@export var status_effects: Array[String] = []
@export var mod_slots := 0
