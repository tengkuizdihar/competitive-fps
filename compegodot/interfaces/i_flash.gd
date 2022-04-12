extends Node
class_name IFlash

signal flashed(flash_position)

func flash(flash_position: Vector3) -> void:
	emit_signal("flashed", flash_position)