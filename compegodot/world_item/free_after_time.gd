tool
extends Particles

export (NodePath) var free_timer_path

var timer: Timer = null

func _get_configuration_warning() -> String:
	var test = get_node(free_timer_path)
	if not (test and test is Timer):
		return "free_timer_path is not pointing at a timer"
	return ""


func _ready() -> void:
	if not Engine.editor_hint:
		emitting = true
		timer = get_node(free_timer_path)
		if timer.connect("timeout", self, "queue_free"):
			print("Failed connecting timer::timeout to self::queue_free")
