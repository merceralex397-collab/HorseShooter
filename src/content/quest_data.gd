extends "res://src/content/content_record.gd"

@export var region_id := ""
@export var giver_id := ""
@export var prerequisites: Array[String] = []
@export var objectives: Array[Dictionary] = []
@export var rewards: Array[Dictionary] = []
@export var failure_consequences: Array[Dictionary] = []
