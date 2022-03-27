extends StaticBody

var i_interact: IInteract

func _ready() -> void:
	i_interact = Util.init_interface_node(self, IInteract.new())
	if i_interact.connect("interacted", self,"_on_interacted"):
		printerr(name + "doesn't have interacted")


func _on_interacted(_interactor) -> void:
	Score.reset_score()
	State.set_state("shooting_target_movement_mode", Global.SHOOTING_TARGET_MOVEMENT_MODE.MOVING)
