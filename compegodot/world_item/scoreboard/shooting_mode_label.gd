extends Spatial

const LABEL_MODE_PREFIX = "MODE: "
const LABEL_TARGET_SIZE_PREFIX = "TARGET SIZE: "
const LABEL_TARGET_MODE_PREFIX = "TARGET MODE: "

onready var label_mode = $Label3D
onready var label_target_size = $Label3D2
onready var label_target_movement_mode = $Label3D3

func _ready():
	__set_current_mode_name()
	__set_shooting_target_size_name()
	__set_shooting_target_movement_mode_name()

	Util.handle_err(Score.connect("mode_changed", self, "_on_score_mode_changed"))
	Util.handle_err(State.connect("state_shooting_target_size", self, "_on_state_shooting_target_size"))
	Util.handle_err(State.connect("state_shooting_target_movement_mode", self, "_on_state_shooting_target_movement_mode"))


func _on_score_mode_changed(_mode: int):
	__set_current_mode_name()


func _on_state_shooting_target_size(_size: float):
	__set_shooting_target_size_name()

func _on_state_shooting_target_movement_mode(_mode: float):
	__set_shooting_target_movement_mode_name()

func __set_current_mode_name():
	label_mode.text = LABEL_MODE_PREFIX + Score.get_current_mode_name()


func __set_shooting_target_size_name():
	label_target_size.text = LABEL_TARGET_SIZE_PREFIX + str(State.get_state("shooting_target_size"))

func __set_shooting_target_movement_mode_name():
	var value = State.get_state("shooting_target_movement_mode")
	var name = ""

	match value:
		Global.SHOOTING_TARGET_MOVEMENT_MODE.STATIC:
			name = "STATIC"
		Global.SHOOTING_TARGET_MOVEMENT_MODE.MOVING:
			name = "MOVING"

	label_target_movement_mode.text = LABEL_TARGET_MODE_PREFIX + name
