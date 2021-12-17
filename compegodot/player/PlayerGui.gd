extends Control

onready var crosshair = $CenterContainer/Crosshair
onready var gun_container = $GunContainer
onready var sniper_scope = $SniperScope
onready var sniper_dot = $CenterContainer/SniperDot


func _ready():
	Util.handle_err(State.connect("state_player_zoom_mode", self, "_on_state_player_zoom_made"))
	_on_state_player_zoom_made(State.get_state("player_zoom_mode"))


func _physics_process(_delta):
	handle_sniper_dot_visiblity()


func _on_state_player_zoom_made(value):
	sniper_scope.visible = is_player_zoom_visible(value)
	crosshair.visible = !is_player_zoom_visible(value)
	gun_container.visible = !is_player_zoom_visible(value)


func is_player_zoom_visible(zoom_state) -> bool:
	return zoom_state > Global.WEAPON_ZOOM_MODE.DEFAULT


func handle_sniper_dot_visiblity() -> void:
	var is_visible = is_player_zoom_visible(State.get_state("player_zoom_mode"))
	is_visible = is_visible && State.get_state("player_velocity_length") == 0.0

	sniper_dot.visible = is_visible
