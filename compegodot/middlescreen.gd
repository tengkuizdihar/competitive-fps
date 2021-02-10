extends TextureRect


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


func _process(_delta: float) -> void:
	rect_global_position = (OS.window_size / 2) - rect_size / 2
