extends Node
class_name IHealth

signal health_changed(current_health, current_armor)
signal dead

export (float) var max_health = 100.0
export (float) var max_armor = 0.0

onready var current_health = max_health
onready var current_armor = max_armor


func change_health_and_armor(difference) -> float:
	if difference < 0:
		# Damaging the thing
		var modified_difference = min(0, difference + current_armor)
		current_armor = max(0, current_armor + difference)
		current_health = max(0, current_health + modified_difference)
	else:
		# Healing the thing
		current_health = min(max_health, current_health + difference)

	emit_health_changed()
	emit_when_dead()

	return current_health


func set_health(new_health) -> void:
	current_health = new_health
	emit_health_changed()
	emit_when_dead()


func set_armor(new_armor) -> void:
	current_armor = new_armor
	emit_health_changed()
	emit_when_dead()


func emit_health_changed() -> void:
	emit_signal("health_changed", current_health, current_armor)


func emit_when_dead() -> void:
	if current_health <= 0.0:
		emit_signal("dead")
