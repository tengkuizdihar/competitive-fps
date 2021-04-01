tool
extends ViewportContainer

export (NodePath) var world_camera_path

var my_camera: Camera
var world_camera: Camera


func _get_configuration_warning() -> String:
	var cam_node = get_node(world_camera_path)
	if not cam_node and not (cam_node is Camera):
		return "World Camera Path need to be set!"
	return ""


func _ready() -> void:
	if not Engine.editor_hint:
		my_camera = $GunViewport/Camera
		world_camera = get_node(world_camera_path)


func _process(_delta: float) -> void:
	if not Engine.editor_hint:
		my_camera.global_transform = world_camera.global_transform
