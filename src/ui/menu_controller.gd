extends RefCounted


static func primary_menu_actions(has_save: bool) -> Array[String]:
	var actions: Array[String] = ["New Game"]
	if has_save:
		actions.append("Continue")
	actions.append_array(["Settings", "Credits", "Quit"])
	return actions
