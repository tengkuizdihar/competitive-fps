extends Control

export (String, FILE, "*.tscn") var main_menu_scene_path

# Called when the node enters the scene tree for the first time.
func _ready():
	Util.handle_err(State.connect("STATE_PLAYER_PAUSED", self, "_on_state_player_paused"))
	handle_visibility(State.get_state("PLAYER_PAUSED"))


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
	State.set_state("PLAYER_PAUSED", false)


func _on_MainMenuButton_pressed():
	Util.handle_err(get_tree().change_scene(main_menu_scene_path))


func _on_ExitButton_pressed():
	get_tree().quit()
