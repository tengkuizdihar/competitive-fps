extends Control

export (String, FILE, "*.tscn") var main_menu_scene_path

# Called when the node enters the scene tree for the first time.
func _ready():
	Util.handle_err(State.connect("state_player_paused", self, "_on_state_player_paused"))
	handle_visibility(State.get_state("player_paused"))


func handle_visibility(is_visible: bool):
	if is_visible:
		show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_state_player_paused(is_paused: bool):
	handle_visibility(is_paused)


func _on_ResumeButton_pressed():
	State.set_state("player_paused", false)


func _on_MainMenuButton_pressed():
	Util.change_level(main_menu_scene_path)


func _on_ExitButton_pressed():
	get_tree().quit()
