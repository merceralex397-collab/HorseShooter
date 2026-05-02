extends "res://src/content/content_record.gd"

@export_enum("runner", "charger", "spitter", "pack_leader", "burrower", "spectral", "armored", "elemental", "boss") var enemy_role := "runner"
@export var region_id := ""
@export var health := 30
@export var damage := 10
@export var phases: Array[String] = []
@export var loot_table: Array[String] = []
