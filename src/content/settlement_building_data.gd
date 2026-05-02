extends "res://src/content/content_record.gd"

@export_enum("camp", "outpost", "hamlet", "village", "town", "city") var tier_required := "camp"
@export var category := ""
@export var resource_cost := {}
@export var resource_output := {}
@export var assignment_slots := 0
