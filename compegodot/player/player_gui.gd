extends Control

onready var crosshair = $CrosshairProcedural
onready var gun_container = $GunContainer
onready var sniper_scope = $SniperScope
onready var sniper_dot = $CrosshairContainer/SniperDot
onready var weapon_name = $Indicators/AmmoIndicator/HBoxContainer/VBoxContainer2/WeaponName
onready var current_ammo = $Indicators/AmmoIndicator/HBoxContainer/VBoxContainer2/HBoxContainer/CurrentAmmo
onready var total_ammo = $Indicators/AmmoIndicator/HBoxContainer/VBoxContainer2/HBoxContainer/TotalAmmo
onready var health_bar = $Indicators/AmmoIndicator/HBoxContainer/VBoxContainer/HealthBar
onready var armor_bar = $Indicators/AmmoIndicator/HBoxContainer/VBoxContainer/ArmorBar


func _ready():
	Util.handle_err(State.connect("state_player_zoom_mode", self, "_on_state_player_zoom_made"))
	Util.handle_err(State.connect("state_player_weapon_name", self, "_on_state_player_weapon_name"))
	Util.handle_err(State.connect("state_player_weapon_current_ammo", self, "_on_state_player_weapon_current_ammo"))
	Util.handle_err(State.connect("state_player_weapon_total_ammo", self, "_on_state_player_weapon_total_ammo"))
	Util.handle_err(State.connect("state_player_health", self, "_on_state_player_health"))
	Util.handle_err(State.connect("state_player_armor", self, "_on_state_player_armor"))
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


func _on_state_player_weapon_name(value) -> void:
	weapon_name.text = str(value)


func _on_state_player_weapon_current_ammo(value) -> void:
	current_ammo.text = str(value)


func _on_state_player_weapon_total_ammo(value) -> void:
	total_ammo.text = str(value)


func _on_state_player_health(value) -> void:
	health_bar.value = value


func _on_state_player_armor(value) -> void:
	armor_bar.value = value
