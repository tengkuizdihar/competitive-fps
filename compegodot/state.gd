extends Node

const SIGNAL_PREFIX = "state_"

const INITIAL_STATE = {
	"debug_player_velocity": 0.0,
	"debug_misc": "NOT USED",
	"debug_ammo": "NOT USED",

	# Should be "true" whenever the player pause the game
	# This should happen in situation such as; opening the escape menu
	"player_paused": false,

	# The physics frame which the player reloaded
	"player_reloaded": 0,

	# Use Global.WEAPON_ZOOM_MODE.DEFAULT for default value
	"player_zoom_mode": 0,

	# The current velocity length of the player
	# Unlike debug_player_velocity, value is real and not stepified
	"player_velocity_length": 0.0,

	# The current weapon's status
	"player_weapon_name": "Current Weapon",
	"player_weapon_current_ammo": 0,
	"player_weapon_total_ammo": 0,

	# Shooting Target Configurations
	# NOTE: The default movement mode is using Global.SHOOTING_TARGET_MOVEMENT_MODE.STATIC
	# NOTE: The default size is the same as the default scale (1)
	"shooting_target_movement_mode": 0,
	"shooting_target_size": 1.0,
}

# To add state, make sure that the key is STRING and the value is anything
# besides null. Also, please use duplicate, because dict is copy by reference
# not value.
onready var _state = INITIAL_STATE.duplicate(true)


func _ready():
	# Add a signal based on the keys on _state. This way, any entity can subscribe
	# to a state everytime it changes.
	for s in INITIAL_STATE.keys():
		add_user_signal(SIGNAL_PREFIX + s, [ typeof(_state[s]) ])


# Can only change state that's already inside of _state
func set_state(state_name: String, value):
	var signal_name = SIGNAL_PREFIX + state_name
	if has_signal(signal_name) and typeof(value) == typeof(_state[state_name]):
		_state[state_name] = value
		emit_signal(SIGNAL_PREFIX + state_name, value)
	else:
		push_error("Signal named: " + signal_name + " doesn't exist or value is not compatible with currently state value!")


func get_state(state_name:String):
	if _state.has(state_name):
		return _state[state_name]
	else:
		push_error("State named: " + state_name + " doesn't exist!")
		return null


# Reset the state through set_state so the signals and other routines could be
# executed and deployed by the existing scenes.
func reset_state():
	for k in INITIAL_STATE.keys():
		set_state(k, INITIAL_STATE[k])


# Reset the state and other autoloads that have in game knowledge that we
# need to reset.
func reset_game():
	reset_state()
	Score.reset_state()