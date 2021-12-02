extends Node

enum Mode {
	RANDOM_SINGLE = 1,
	SPRAY_SINGLE = 2,
}

signal score_changed(score)
signal mode_changed(mode)

var score: int = 0
var mode = Mode.RANDOM_SINGLE

func change_score(new_value: int) -> void:
	score = new_value
	emit_signal("score_changed", score)


func change_mode(mode_value) -> void:
	mode = mode_value
	emit_signal("mode_changed", mode)


func add_score() -> void:
	change_score(score + 1)


func reset_score() -> void:
	change_score(0)


func reset_state():
	reset_score()
	change_mode(Mode.RANDOM_SINGLE)


func get_current_mode_name() -> String:
	return get_mode_name(mode)


func get_mode_name(value: int) -> String:
	match value:
		Mode.RANDOM_SINGLE:
			return "RANDOM"
		Mode.SPRAY_SINGLE:
			return "SPRAY"
		_:
			printerr("Getting mode name based on value that doesn't exist!")
			return ""
