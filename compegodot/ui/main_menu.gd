extends Control

export (String, FILE, "*.tscn") var level_scene_path
export (String, FILE, "*.tscn") var tutorial_scene_path
export (String, FILE, "*.tscn") var training_scene_path

onready var start_button = $ColumnContainer/MarginContainer/VBoxContainer/StartTraining
onready var start_tutorial_button = $ColumnContainer/MarginContainer/VBoxContainer/StartTutorial
onready var menu_container = $ColumnContainer/MarginContainer2

onready var option_menu = $ColumnContainer/MarginContainer2/OptionMenu
onready var select_level_menu = $ColumnContainer/MarginContainer2/SelectLevelMenu

func _ready():
	# Focus the player's cursor to the start button
	start_tutorial_button.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Hide every single menu
	hide_all_menu()


func hide_all_menu():
	for i in menu_container.get_children():
		i.hide()


func _on_StartTraining_pressed():
	Util.change_level(training_scene_path, Global.GAME_MODE.AIM_TRAINING)


func _on_SelectLevel_pressed():
	hide_all_menu()
	select_level_menu.visible = true


func _on_Option_pressed():
	hide_all_menu()
	option_menu.visible = true


func _on_Exit_pressed():
	get_tree().quit()


func _on_StartTutorial_pressed():
	Util.change_level(tutorial_scene_path)
