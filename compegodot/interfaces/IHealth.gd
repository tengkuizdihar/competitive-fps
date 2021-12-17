extends Node
class_name IHealth

signal health_changed(current_health)
signal dead

export (float) var max_health = 100.0
onready var current_health = max_health


func change_health(difference) -> float:
	current_health += difference
	emit_signal("health_changed", current_health)
	emit_when_dead()
	return current_health


func set_health(new_health) -> void:
	current_health = new_health
	emit_signal("health_changed", current_health)
	emit_when_dead()


func emit_when_dead() -> void:
	if current_health <= 0.0:
		emit_signal("dead")
