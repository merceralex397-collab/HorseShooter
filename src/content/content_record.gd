extends Resource

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var tags: Array[String] = []


func to_record() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"description": description,
		"tags": tags,
		"resource": self,
	}
