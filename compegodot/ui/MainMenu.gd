extends Control

export (PackedScene) var level_scene

onready var start_button = $ColumnContainer/MarginContainer/VBoxContainer/Start

func _ready():
	# Focus the player's cursor to the start button
	start_button.grab_focus()


func _on_Start_pressed():
	if get_tree().change_scene_to(level_scene) > 0:
		print("ERROR: can't instantiate level_scene")


func _on_Option_pressed():
	print("TODO: Create an option menu for graphics and what not.")


func _on_Exit_pressed():
	get_tree().quit()
