extends StaticBody

var i_interact: IInteract

func _ready() -> void:
	i_interact = Util.init_interface_node(self, IInteract.new())
