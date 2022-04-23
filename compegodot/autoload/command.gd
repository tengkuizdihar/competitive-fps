extends Node

func _ready():
	register_commands()


func register_commands() -> void:
	register_infinite_ammo()


###############################################
# COMMAND: get_infinite_ammo
# COMMAND: set_infinite_ammo
###############################################

func register_infinite_ammo() -> void:
	get_register_infinite_ammo()
	set_register_infinite_ammo()


func get_register_infinite_ammo() -> void:
	Console.add_command('get_infinite_ammo', self, '_get_infinite_ammo')\
		.set_description('Get the value of infinite ammo according to Global.AMMO_INFINITE_MODE')\
		.register()


func set_register_infinite_ammo() -> void:
	Console.add_command('set_infinite_ammo', self, '_set_infinite_ammo')\
		.set_description('Set the value of infinite ammo according to Global.AMMO_INFINITE_MODE')\
		.add_argument("value", TYPE_STRING)\
		.register()


func _get_infinite_ammo() -> void:
	Console.write_line(State.get_state("ammo_infinite_mode"))


func _set_infinite_ammo(value: String) -> void:
	var parsed = int(value)
	State.set_state("ammo_infinite_mode", parsed)
