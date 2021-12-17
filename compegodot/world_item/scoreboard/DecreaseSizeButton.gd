extends StaticBody

var i_interact: IInteract

func _ready() -> void:
	i_interact = Util.init_interface_node(self, IInteract.new())
	if i_interact.connect("interacted", self,"_on_interacted"):
		printerr(name + "doesn't have interacted")


func _on_interacted() -> void:
	State.set_state("shooting_target_size", max(State.get_state("shooting_target_size") - 0.1, 0.1))
	Score.reset_score()
