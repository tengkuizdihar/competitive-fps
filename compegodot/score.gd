extends Node

signal score_changed(score_count)

var score_count: int = 0


func change_score(new_value: int) -> void:
	score_count = new_value
	emit_signal("score_changed", score_count)


func add_score() -> void:
	change_score(score_count + 1)


func reset_score() -> void:
	change_score(0)
