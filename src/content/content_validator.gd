extends RefCounted

const ContentIds := preload("res://src/content/content_ids.gd")


static func validate_records(records: Array) -> Dictionary:
	var errors: Array[String] = []
	var seen := {}
	for index in records.size():
		var record = records[index]
		if not (record is Dictionary):
			errors.append("Record %d is not a Dictionary." % index)
			continue
		var content_id := String(record.get("id", ""))
		var content_name := String(record.get("name", ""))
		if not ContentIds.is_valid_id(content_id):
			errors.append("Invalid content ID: " + content_id)
		if content_name.strip_edges().is_empty():
			errors.append("Missing name for content ID: " + content_id)
		if seen.has(content_id):
			errors.append("Duplicate content ID: " + content_id)
		seen[content_id] = true
	return {
		"valid": errors.is_empty(),
		"error_count": errors.size(),
		"errors": errors,
	}
