extends Spatial

const LABEL_PREFIX = "MODE: "

onready var label = $Label3D

func _ready():
	__set_current_mode_name()
	Util.handle_err(Score.connect("mode_changed", self, "_on_score_mode_changed"))


func _on_score_mode_changed(_mode: int):
	__set_current_mode_name()


func __set_current_mode_name():
	label.text = LABEL_PREFIX + Score.get_current_mode_name()