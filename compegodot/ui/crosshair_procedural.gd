extends ColorRect


func _ready():
	Util.handle_err(Config.connect("config_changed", self, "set_crosshair_from_config"))
	set_crosshair_from_config(Config.state)


func set_crosshair_from_config(config: Dictionary) -> void:
	print(config)
	material.set_shader_param("center_enabled", config.player.crosshair_center_enabled)
	material.set_shader_param("legs_enabled", config.player.crosshair_legs_enabled)
	material.set_shader_param("inverted", config.player.crosshair_inverted)
	material.set_shader_param("color_0", config.player.crosshair_color_0)
	material.set_shader_param("center_radius", config.player.crosshair_center_radius)
	material.set_shader_param("width", config.player.crosshair_width)
	material.set_shader_param("len", config.player.crosshair_len)
	material.set_shader_param("spacing", config.player.crosshair_spacing)
	material.set_shader_param("spread", config.player.crosshair_spread)
	material.set_shader_param("leg_alpha", config.player.crosshair_leg_alpha)
	material.set_shader_param("top_leg_alpha", config.player.crosshair_top_leg_alpha)
