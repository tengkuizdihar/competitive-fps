extends AudioStreamPlayer3D
class_name AutoFreeStreamPlayer

func play(from_position: float = 0.0) -> void:
	.play(from_position)
	yield(self, "finished")
	queue_free()
