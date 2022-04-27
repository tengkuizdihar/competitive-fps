extends PanelContainer


var keybind_setting_item_packed = preload("res://ui/keybind_setting_item.tscn")

onready var bullet_decal_max_spinbox = $VBoxContainer/TabContainer/Game/MarginContainer/ScrollContainer/VBoxContainer/BulletDecalMax/SpinBox
onready var mouse_speed_spinbox = $VBoxContainer/TabContainer/Player/MarginContainer/ScrollContainer/VBoxContainer/MouseSpeed/SpinBox
onready var master_volume_hslider = $VBoxContainer/TabContainer/Audio/ScrollContainer/MarginContainer/VBoxContainer/MasterVolume/HSlider
onready var gameplay_volume_hslider = $VBoxContainer/TabContainer/Audio/ScrollContainer/MarginContainer/VBoxContainer/GameplayVolume/HSlider
onready var music_volume_hslider = $VBoxContainer/TabContainer/Audio/ScrollContainer/MarginContainer/VBoxContainer/MusicVolume/HSlider
onready var player_control_container = $VBoxContainer/TabContainer/Controls/ScrollContainer/MarginContainer/VBoxContainer

onready var crosshair_color_picker = $VBoxContainer/TabContainer/Player/MarginContainer/ScrollContainer/VBoxContainer/CrosshairColor/ColorPicker
onready var crosshair_center_radius_slider = $VBoxContainer/TabContainer/Player/MarginContainer/ScrollContainer/VBoxContainer/CrosshairCenterRadius/Slider
onready var crosshair_width_slider = $VBoxContainer/TabContainer/Player/MarginContainer/ScrollContainer/VBoxContainer/CrosshairWidth/Slider
onready var crosshair_length_slider = $VBoxContainer/TabContainer/Player/MarginContainer/ScrollContainer/VBoxContainer/CrosshairLength/Slider
onready var crosshair_spacing_slider = $VBoxContainer/TabContainer/Player/MarginContainer/ScrollContainer/VBoxContainer/CrosshairSpacing/Slider
onready var crosshair_center_dot_checkbox = $VBoxContainer/TabContainer/Player/MarginContainer/ScrollContainer/VBoxContainer/CrosshairCenterDot/CheckBox
onready var crosshair_leg_checkbox = $VBoxContainer/TabContainer/Player/MarginContainer/ScrollContainer/VBoxContainer/CrosshairLeg/CheckBox

func _ready():
	apply_from_config(Config.state)
	Util.handle_err(Config.connect("config_changed", self, "apply_from_config"))


func apply_from_config(config_state: Dictionary):
	bullet_decal_max_spinbox.value = config_state.game.bullet_decal_max

	mouse_speed_spinbox.value = config_state.player.mouse_speed

	master_volume_hslider.value = config_state.audio.master_volume
	gameplay_volume_hslider.value = config_state.audio.gameplay_volume
	music_volume_hslider.value = config_state.audio.music_volume

	_init_keybinds_options(config_state)
	_init_crosshair_configs(config_state)


func apply_to_config():
	Config.change_config("game", "bullet_decal_max", bullet_decal_max_spinbox.value)

	Config.change_config("player", "mouse_speed", mouse_speed_spinbox.value)

	Config.change_config("audio", "master_volume", master_volume_hslider.value)
	Config.change_config("audio", "gameplay_volume", gameplay_volume_hslider.value)
	Config.change_config("audio", "music_volume", music_volume_hslider.value)

	for c in player_control_container.get_children():
		Config.change_config("keyboard_control", c.input_event_name, c.scancode)

	_set_crosshair_configs()

	Config.apply_config()
	Config.emit_config_changed()


func _init_keybinds_options(config_state: Dictionary):
	for c in player_control_container.get_children():
		c.queue_free()

	for k in config_state.keyboard_control.keys():
		var found_scancode = config_state.keyboard_control[k]
		_add_keybind_settings_item(k, found_scancode)


func _init_crosshair_configs(config_state: Dictionary):
	crosshair_color_picker.color = config_state.player.crosshair_color_0
	crosshair_center_radius_slider.value = config_state.player.crosshair_center_radius
	crosshair_width_slider.value = config_state.player.crosshair_width
	crosshair_length_slider.value = config_state.player.crosshair_len
	crosshair_spacing_slider.value = config_state.player.crosshair_spacing
	crosshair_center_dot_checkbox.pressed = config_state.player.crosshair_center_enabled
	crosshair_leg_checkbox.pressed = config_state.player.crosshair_legs_enabled


func _set_crosshair_configs():
	Config.change_config("player", "crosshair_color_0", crosshair_color_picker.color)
	Config.change_config("player", "crosshair_center_radius", crosshair_center_radius_slider.value)
	Config.change_config("player", "crosshair_width", crosshair_width_slider.value)
	Config.change_config("player", "crosshair_len", crosshair_length_slider.value)
	Config.change_config("player", "crosshair_spacing", crosshair_spacing_slider.value)
	Config.change_config("player", "crosshair_center_enabled", crosshair_center_dot_checkbox.pressed)
	Config.change_config("player", "crosshair_legs_enabled", crosshair_leg_checkbox.pressed)


func _add_keybind_settings_item(input_event_name: String, scancode: int) -> void:
	var keybind_setting_item = keybind_setting_item_packed.instance()
	keybind_setting_item.input_event_name = input_event_name
	keybind_setting_item.scancode = scancode

	player_control_container.add_child(keybind_setting_item)


func _on_ApplyAndSaveButton_pressed():
	apply_to_config()


func _on_ResetButton_pressed():
	Config.reset_config()
