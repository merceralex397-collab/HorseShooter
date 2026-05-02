extends RefCounted

const ID_PATTERN := "^[a-z0-9]+(\\.[a-z0-9_]+)+$"


static func is_valid_id(content_id: String) -> bool:
	var regex := RegEx.new()
	regex.compile(ID_PATTERN)
	return regex.search(content_id) != null


static func describe_rule() -> String:
	return "Use lowercase dotted IDs: domain.category.name, with lowercase letters, numbers, and underscores."
