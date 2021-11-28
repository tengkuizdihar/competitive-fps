extends Control

export (PackedScene) var level_scene
export (PackedScene) var training_scene

onready var start_button = $ColumnContainer/MarginContainer/VBoxContainer/StartTesting

func _ready():
	# Focus the player's cursor to the start button
	start_button.grab_focus()


func _on_StartTraining_pressed():
	State.reset_state()
	if get_tree().change_scene_to(training_scene) > 0:
		printerr("ERROR: can't instantiate level_scene")


func _on_Start_pressed():
	State.reset_state()
	if get_tree().change_scene_to(level_scene) > 0:
		printerr("ERROR: can't instantiate level_scene")


func _on_Option_pressed():
	printerr("TODO: Create an option menu for graphics and what not.")


func _on_Exit_pressed():
	get_tree().quit()
