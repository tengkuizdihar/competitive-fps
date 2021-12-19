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
	}
}


func _ready():
	state = default_state.duplicate(true)
	load_config()


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

	save_config()



# Will load the configuration from a file then emit the signal of config changed
# The configuration might not be different the currently available one though
func load_config():
	var config_file = ConfigFile.new()

	if config_file.load(config_file_path) == OK:
		from_config_file(config_file)
	else:
		state = default_state.duplicate(true)

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
