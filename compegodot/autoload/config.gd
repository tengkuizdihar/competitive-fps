extends Node

signal config_changed(config)

var state

# The configuration state that's going to be used by the game
# Preferably use primitive/dictionary/array instead of custom classes
const config_file_path = "user://config.ini"
const default_state = {
	game = {
		bullet_decal_max = 200
	},
	player = {
		mouse_speed = 1.0
	},
	audio = {
		master_volume = db2linear(0),	# Measured in 0 to 1 and then converted using linear2db
		gameplay_volume = db2linear(0),	# Measured in 0 to 1 and then converted using linear2db
		music_volume = db2linear(0)		# Measured in 0 to 1 and then converted using linear2db
	},
	keyboard_control = {
		# Set automatically by _ready()
	}
}


func _ready():
	# Set config default_state.keyboard_control
	for i in InputMap.get_actions():
		if i.begins_with("player_"):
			var found_scancode = 0
			var action_input_events = InputMap.get_action_list(i)

			if len(action_input_events) > 0:
				var action_input_event = action_input_events.front()
				if action_input_event is InputEventKey:
					found_scancode = action_input_event.scancode
					default_state.keyboard_control[i] = found_scancode
				elif action_input_event is InputEventMouse:
					print("[TODO] InputEventMouse isn't configurable yet please implement this one", " | ", i , " | ", action_input_event, " | ", get_stack())
				else:
					printerr("Non recognized input detected this code could only handle keyboard input event key", " | ", i , " | ", action_input_event ," | ", get_stack())

	load_config()
	apply_config()


func change_config(section: String, key: String, value):
	state[section][key] = value

func emit_config_changed():
	emit_signal("config_changed", state)


func reset_config():
	state = default_state.duplicate(true)
	apply_config()
	emit_signal("config_changed", state)


func apply_config():
	for section in state:
		for section_key in state[section]:
			var value = state[section][section_key]

			match section:
				'game':
					match section_key:
						'bullet_decal_max':
							# NOTHING TO DO
							# Player directly use this value from config
							pass
				'player':
					match section_key:
						'mouse_speed':
							# NOTHING TO DO
							# Player directly use this value from config
							pass
				'audio':
					match section_key:
						'master_volume':
							AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(value))
						'gameplay_volume':
							AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Gameplay"), linear2db(value))
						'music_volume':
							AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(value))
				'keyboard_control':
						# 1. Erase the InputMap action (section_key)
						InputMap.action_erase_events(section_key)

						# 2. Create an InputEventKey with a particular scancode (value) and then add an action using action name and scancode
						var scancode_event = InputEventKey.new()
						scancode_event.set_scancode(value)
						InputMap.action_add_event(section_key, scancode_event)

	save_config()



# Will load the configuration from a file then emit the signal of config changed
# The configuration might not be different the currently available one though
func load_config():
	var config_file = ConfigFile.new()

	state = default_state.duplicate(true)
	if config_file.load(config_file_path) == OK:
		from_config_file(config_file)

	emit_signal("config_changed", state)


# Save the configuration to a path in the user directory
# Preferably the format should be in JSON
func save_config():
	var config_file = to_config_file()
	config_file.save(config_file_path)


func from_config_file(file: ConfigFile):
	for s in file.get_sections():
		for k in file.get_section_keys(s):
			# NOTE: Might fail and crash if state doesn't have the correct key
			#       Maybe it's time to implement lodash-like dictionary utility?
			state[s][k] = file.get_value(s, k)


func to_config_file() -> ConfigFile:
	var config_file = ConfigFile.new()

	for s in state:
		for k in state[s]:
			# NOTE: Might fail and crash if state doesn't have the correct key
			#       Maybe it's time to implement lodash-like dictionary utility?
			config_file.set_value(s, k, state[s][k])

	return config_file
