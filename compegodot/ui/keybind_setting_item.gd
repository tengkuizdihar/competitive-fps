tool
extends HSplitContainer

const BUTTON_UNREGISTERED_TEXT = "[PRESS THE DESIRED KEY TO SET]"

signal keybind_set(input_event_name, scancode)

export (String) var input_event_name = ""
export (int) var scancode = 0

onready var is_registering_action_from_input = false
onready var key_button_registration = $Button
onready var key_label_registration = $Label


func _get_configuration_warning() -> String:
	if input_event_name == "" or !input_event_name:
		return "input_event_name not be empty"

	return ""


func _ready():
	if !Engine.editor_hint:
		key_label_registration.text = input_event_name
		_set_button_registration_text(scancode)

		Util.handle_err(connect("keybind_set", self, "_on_self_keybind_set"))
		Util.handle_err(key_button_registration.connect("pressed", self, "_on_button_pressed"))


func _input(event):
	if !Engine.editor_hint:
		if event is InputEventKey and event.is_pressed() and is_registering_action_from_input:
			_set_input_event_to_action_routine(event)


func _set_input_event_to_action_routine(event: InputEventKey) -> void:
	if input_event_name != "" and input_event_name != null:
		emit_signal("keybind_set", input_event_name, event.scancode)


func _set_button_registration_text(given_scancode: int) -> void:
	var built_text = "[ INPUT KEY NOT SET ]"
	if given_scancode != 0:
		built_text = OS.get_scancode_string(given_scancode)

	key_button_registration.text = built_text


func _on_self_keybind_set(_input_event_name: String, given_scancode: int) -> void:
	is_registering_action_from_input = false
	scancode = given_scancode
	_set_button_registration_text(given_scancode)


func _on_button_pressed() -> void:
	is_registering_action_from_input = true