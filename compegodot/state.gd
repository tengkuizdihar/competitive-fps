extends Node

const SIGNAL_PREFIX = "STATE_"

const INITIAL_STATE = {
	"DEBUG_PLAYER_VELOCITY": 0.0,
	"DEBUG_MISC": "NOT USED",
	"DEBUG_AMMO": "NOT USED",
	"PLAYER_PAUSED": false
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