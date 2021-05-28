extends Node
class_name IInteract

signal interacted

func interact() -> void:
	emit_signal("interacted")
