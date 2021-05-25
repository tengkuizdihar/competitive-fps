extends KinematicBody

var i_health: IHealth
onready var ding_audio_player = $AudioStreamPlayer

func _ready() -> void:
	i_health = Util.init_interface_node(self, IHealth.new())
	if i_health.connect("dead", self, "_on_ShootingTarget_dead"):
		printerr("Shooting target has no IHealth")

# BUG: ding_audio_player is not removed when finished
func _on_ShootingTarget_dead() -> void:
	remove_child(ding_audio_player)
	Util.add_to_world(ding_audio_player)
	ding_audio_player.play()
	queue_free()
