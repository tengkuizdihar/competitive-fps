extends Node

enum Mode {
	RANDOM_SINGLE = 1, # Abreviated to RS or rs
	SPRAY_SINGLE = 2, # Abreviated to SS or ss
	RANDOM_SINGLE_TIMED = 3, # Abreviated to RST or rst
}

signal score_changed(score)
signal mode_changed(mode)
signal rst_finished(elapsed_seconds, max_hit)

var mode = Mode.RANDOM_SINGLE_TIMED
var score: int = 0
var rst_physics_tick_start: int = 0
var rst_max_hit_before_timer: int = 5


func _ready():
	Util.validated_connect(self, "score_changed", self, "_on_self_score_changed")
	Util.validated_connect(self, "rst_finished", self, "_on_self_rst_finished")


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


func reset_state(new_mode = Mode.RANDOM_SINGLE_TIMED):
	reset_score()
	change_mode(new_mode)


func get_current_mode_name() -> String:
	return get_mode_name(mode)


func get_mode_name(value: int) -> String:
	match value:
		Mode.RANDOM_SINGLE:
			return "RANDOM"
		Mode.SPRAY_SINGLE:
			return "SPRAY"
		Mode.RANDOM_SINGLE_TIMED:
			return "RANDOM TIMED"
		_:
			printerr("Getting mode name based on value that doesn't exist!")
			return ""


func _on_self_score_changed(new_score: int) -> void:
	match mode:
		Mode.RANDOM_SINGLE, Mode.SPRAY_SINGLE:
			pass
		Mode.RANDOM_SINGLE_TIMED:
			if new_score == 1:
				rst_physics_tick_start = Engine.get_physics_frames()
			elif new_score == rst_max_hit_before_timer:
				var current_tick = Engine.get_physics_frames()
				var elapsed_tick = current_tick - rst_physics_tick_start
				var second_per_tick = 1.0 / Engine.iterations_per_second
				var elapsed_seconds = elapsed_tick * second_per_tick

				emit_signal("rst_finished", elapsed_seconds, rst_max_hit_before_timer)
		_:
			printerr("Getting mode name based on value that doesn't exist!")


func  _on_self_rst_finished(elapsed_seconds: float, max_hit_before_timer: int) -> void:
	# TODO: a way to store the score already made here
	print(elapsed_seconds, " - ", max_hit_before_timer)

	# Because reset score needed to happen after the logic of target finishes
	# God that's such a horrid looking Spaghetti
	# https://www.youtube.com/watch?v=r7DQDrRwNgI (SOMEBODY TOUCH A MY SPAGHETTI)
	yield(get_tree(), "idle_frame")
	reset_score()
