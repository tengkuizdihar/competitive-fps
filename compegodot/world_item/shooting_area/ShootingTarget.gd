extends KinematicBody

var i_health: IHealth

func _ready() -> void:
	i_health = Util.init_interface_node(self, IHealth.new())
	if i_health.connect("dead", self, "_on_ShootingTarget_dead"):
		printerr("Shooting target has no IHealth")


func add_hit_count() -> void:
	Score.add_score()


func _on_ShootingTarget_dead() -> void:
	add_hit_count()
	queue_free()
