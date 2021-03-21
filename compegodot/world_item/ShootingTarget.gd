extends KinematicBody

var i_health: IHealth

func _ready() -> void:
	i_health = Util.init_interface_node(self, IHealth.new())
	i_health.connect("dead", self, "_on_ShootingTarget_dead")

func _on_ShootingTarget_dead() -> void:
	queue_free()
