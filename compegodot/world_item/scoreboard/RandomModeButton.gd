extends StaticBody

var i_interact: IInteract

func _ready() -> void:
	i_interact = Util.init_interface_node(self, IInteract.new())
	if i_interact.connect("interacted", self,"_on_interacted"):
		printerr(name + "doesn't have interacted")


func _on_interacted() -> void:
	Score.change_mode(Score.Mode.RANDOM_SINGLE)
