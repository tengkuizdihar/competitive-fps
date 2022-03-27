extends PanelContainer

onready var level_path = ""
onready var item_text = ""
onready var label = $HBoxContainer/Label


func _physics_process(_delta):
	label.text = item_text


func _on_SelectButton_pressed():
	Util.change_level(level_path)
