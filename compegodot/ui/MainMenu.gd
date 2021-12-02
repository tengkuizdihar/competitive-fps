extends Control

export (String, FILE, "*.tscn") var level_scene_path
export (String, FILE, "*.tscn") var training_scene_path

onready var start_button = $ColumnContainer/MarginContainer/VBoxContainer/StartTraining

func _ready():
	# Focus the player's cursor to the start button
	start_button.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_StartTraining_pressed():
	Util.change_level(training_scene_path)


func _on_Start_pressed():
	Util.change_level(level_scene_path)


func _on_Option_pressed():
	printerr("TODO: Create an option menu for graphics and what not.")


func _on_Exit_pressed():
	get_tree().quit()
