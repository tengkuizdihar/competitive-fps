extends Control

onready var crosshair = $Crosshair
onready var gun_container = $GunContainer
onready var sniper_scope = $SniperScope


func _ready():
	Util.handle_err(State.connect("state_player_zoom_mode", self, "_on_state_player_zoom_made"))
	_on_state_player_zoom_made(State.get_state("player_zoom_mode"))


func _on_state_player_zoom_made(value):
	sniper_scope.visible = is_player_zoom_visible(value)
	crosshair.visible = !is_player_zoom_visible(value)
	gun_container.visible = !is_player_zoom_visible(value)


func is_player_zoom_visible(zoom_state) -> bool:
	return zoom_state > 0
