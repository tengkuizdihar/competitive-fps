extends PanelContainer

export (PackedScene) var level_item_scene
export (String, DIR) var level_directory = "res://world_item/levels"

onready var vbox_container = $ScrollContainer/VBoxContainer


func _ready():
	# Generate the items for the select menu
	# Filled with option for levels
	for n in Util.directory_file_names(level_directory, "tscn"):
		var level_path = level_directory + "/" + n

		var level_item = level_item_scene.instance()
		vbox_container.add_child(level_item)

		level_item.level_path = level_path
		level_item.item_text = n
