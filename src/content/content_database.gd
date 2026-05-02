extends Node

const ContentValidator := preload("res://src/content/content_validator.gd")

var records: Array[Dictionary] = []
var resources: Array[Resource] = []
var resources_by_id := {}


func load_records(new_records: Array[Dictionary]) -> Dictionary:
	var report := ContentValidator.validate_records(new_records)
	if bool(report.get("valid", false)):
		records = new_records.duplicate(true)
	return report


func load_resources(new_resources: Array) -> Dictionary:
	var new_records: Array[Dictionary] = []
	for resource in new_resources:
		if resource is Resource and resource.has_method("to_record"):
			new_records.append(resource.to_record())
		else:
			new_records.append({"id": "", "name": ""})
	var report := load_records(new_records)
	if bool(report.get("valid", false)):
		resources = []
		resources_by_id = {}
		for resource in new_resources:
			if resource is Resource:
				resources.append(resource)
				var record: Dictionary = resource.to_record()
				resources_by_id[String(record.get("id", ""))] = resource
	return report


func get_record(content_id: String):
	if resources_by_id.has(content_id):
		return resources_by_id[content_id]
	for record in records:
		if String(record.get("id", "")) == content_id:
			return record
	return {}
