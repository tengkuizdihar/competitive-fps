tool
extends Area

export (String, MULTILINE) var text = "" setget set_text
onready var label = $Label3D
onready var player_count_inside = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.editor_hint:
		label.text = text
	else:
		label.text = text
		label.hide()
		Util.handle_err(connect("body_entered", self, "_on_proximity_label_body_entered"))
		Util.handle_err(connect("body_exited", self, "_on_proximity_label_body_exited"))


func set_text(new_text: String):
	text = new_text
	if label:
		label.text = new_text


func _on_proximity_label_body_entered(body: Node) -> void:
	player_count_inside += 1

	if Util.is_player(body) and player_count_inside > 0:
		label.show()


func _on_proximity_label_body_exited(body: Node) -> void:
	player_count_inside -= 1

	if Util.is_player(body) and player_count_inside == 0:
		label.hide()
