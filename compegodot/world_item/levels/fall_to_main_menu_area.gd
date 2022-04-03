extends Area

export (String, FILE, "*.tscn") var main_menu_scene_path


func _ready():
	Util.handle_err(connect("body_entered", self, "_on_fall_to_main_menu_area_body_entered"))


func _on_fall_to_main_menu_area_body_entered(body: Node):
	if Util.is_player(body):
		Util.change_level(main_menu_scene_path)