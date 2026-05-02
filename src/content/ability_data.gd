extends "res://src/content/content_record.gd"

@export_enum("gunslinger", "hunter", "survivor", "commander", "mechanist", "profane_focus") var tree := "gunslinger"
@export var tier := 1
@export var prerequisites: Array[String] = []
@export var effects := {}
