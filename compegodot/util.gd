extends Node

# Clamping the length of a single vector3
func clamp_vector3(vec: Vector3, max_length: float) -> Vector3:
	return Vector3(clamp(vec.x, -max_length, max_length), clamp(vec.y, -max_length, max_length), clamp(vec.z, -max_length, max_length))


func init_interface_node(target: Node, interface: Node) -> Node:
	target.add_child(interface)
	return interface


func get_interface(target: Node, interface_class) -> Node:
	for i in target.get_children():
		if i is interface_class:
			return i
	return null


func add_to_world(node: Node) -> void:
	var level: Node = get_tree().get_nodes_in_group(Global.GROUP.LEVEL).pop_back()
	if level:
		level.add_child(node)
	else:
		printerr("add_to_world doesn't work because no nodes is grouped as 'LEVEL'")


func array_get(array: Array, index: int, default = null):
	if index < 0:
		printerr("Getting array with index below zero {}", get_stack())
		return default
	elif index > array.size() - 1:
		return default
	else:
		return array[index]


func handle_err(error_code: int) -> void:
	if error_code > 0:
		printerr("ERROR CODE: ", error_code, "\n", get_stack())


func change_level(scene_path: String) -> void:
	State.reset_game()
	handle_err(get_tree().change_scene(scene_path))