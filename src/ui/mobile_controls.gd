extends Control

signal movement_changed(direction)
signal aim_changed(direction)
signal fire_changed(active)
signal dodge_pressed()
signal interact_pressed()
signal ability_pressed(slot)
signal map_pressed()
signal inventory_pressed()
signal pause_pressed()

const REQUIRED_ACTIONS := [
	"move_left",
	"move_right",
	"move_up",
	"move_down",
	"shoot",
	"dodge",
	"interact",
	"ability_1",
	"ability_2",
	"open_map",
	"open_inventory",
	"pause",
]


func _ready() -> void:
	ensure_input_actions()


static func ensure_input_actions() -> void:
	for action_name in REQUIRED_ACTIONS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
