# LLInput.gd
# Low Latency Input is a custom node that will poll the input from input event
extends Node

const NO_DATA_VALUE = -1

const TIMEOUT_FRAMES = 1

# All of the input that will be registered
const CAPTURED_EVENTS = [
	"player_crouch",
	"player_walk",
	"player_weapon_swap",
	"player_weapon_gun_primary",
	"player_weapon_gun_secondary",
	"player_weapon_gun_knife",
	"player_weapon_drop",
	"player_interact",
	"player_forward",
	"player_backward",
	"player_right",
	"player_left",
	"player_reload",
	"player_shoot_primary",
	"player_shoot_secondary",
]

const CAPTURED_EVENTS_PRESSED_ONLY = [
	"player_jump",
	"player_shoot_primary",
	"player_shoot_secondary",
]

# The format is
# "input_name" => frame
var inputs = {}


func _ready():
	for c in CAPTURED_EVENTS:
		inputs[c] = NO_DATA_VALUE

	for c in CAPTURED_EVENTS_PRESSED_ONLY:
		inputs["%s|%s" % [c, "pressed"]] = NO_DATA_VALUE
		inputs["%s|%s" % [c, "released"]] = NO_DATA_VALUE


func _input(event):
	for c in CAPTURED_EVENTS:
		if event.is_action_pressed(c):
			inputs[c] = Engine.get_physics_frames()
		elif event.is_action_released(c):
			inputs[c] = NO_DATA_VALUE

	for c in CAPTURED_EVENTS_PRESSED_ONLY:
		if event.is_action_pressed(c):
			inputs["%s|%s" % [c, "pressed"]] = Engine.get_physics_frames()
		elif event.is_action_released(c):
			inputs["%s|%s" % [c, "released"]] = Engine.get_physics_frames()


func consume_input(event_name: String) -> bool:
	var input_frame = inputs.get(event_name)

	if inputs.has(event_name):
		var current_physics_frame = Engine.get_physics_frames()
		var is_consumable = input_frame + TIMEOUT_FRAMES > current_physics_frame

		return is_consumable
	else:
		print_stack()
		printerr("Event name %s isn't registered in CAPTURED_EVENTS" % event_name)
		return false


func is_action_still_pressed(event_name: String) -> bool:
	var pressed_input = inputs.get(event_name + "|pressed")
	var released_input = inputs.get(event_name + "|released")

	return pressed_input >= released_input


func is_action_pressed(event_name: String) -> bool:
	var input_value = inputs.get(event_name)

	if input_value:
		var is_pressed = input_value > NO_DATA_VALUE
		return is_pressed
	else:
		print_stack()
		printerr("Event name %s isn't registered in CAPTURED_EVENTS" % event_name)
		return false
