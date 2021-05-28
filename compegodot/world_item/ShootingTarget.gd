extends KinematicBody

var i_health: IHealth

func _ready() -> void:
	i_health = Util.init_interface_node(self, IHealth.new())
	if i_health.connect("dead", self, "_on_ShootingTarget_dead"):
		printerr("Shooting target has no IHealth")


func add_hit_count() -> void:
	var state_name = "SCOREBOARD_HIT_COUNT"
	var hit_count = State.get_state(state_name)
	State.change_state(state_name, hit_count + 1)


func _on_ShootingTarget_dead() -> void:
	add_hit_count()
	queue_free()
