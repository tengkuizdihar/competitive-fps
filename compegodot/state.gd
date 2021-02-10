extends Node

const SIGNAL_PREFIX = "state_changed_"

# To add state, make sure that the key is STRING and the value is anything
# besides null.
onready var _state = {
	"DEBUG_PLAYER_VELOCITY": 0.0,
	"DEBUG_MISC": "NOT USED"
}


func _ready():
	# Add a signal based on the keys on _state. This way, any entity can subscribe
	# to a state everytime it changes.
	for s in _state.keys():
		add_user_signal(SIGNAL_PREFIX + s, [ typeof(_state[s]) ])


# Can only change state that's already inside of _state
func change_state(state_name: String, value):
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
