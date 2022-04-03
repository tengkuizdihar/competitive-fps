extends Node

# Clamping the length of a single vector3
func clamp_vector3(vec: Vector3, max_length: float) -> Vector3:
	return Vector3(clamp(vec.x, -max_length, max_length), clamp(vec.y, -max_length, max_length), clamp(vec.z, -max_length, max_length))


func clamp_vector3_y_axis(vec: Vector3, max_length: float) -> Vector3:
	return Vector3(clamp(vec.x, -max_length, max_length), vec.y, clamp(vec.z, -max_length, max_length))


func init_interface_node(target: Node, interface: Node) -> Node:
	target.add_child(interface)
	return interface


func get_interface(target: Node, interface_class) -> Node:
	for i in target.get_children():
		if i is interface_class:
			return i
	return null


func add_to_world(node: Node) -> void:
	for i in get_tree().root.get_children():
		if i is Spatial:
			i.add_child(node)


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


func get_groups_with_prefix(node: Node, prefix: String) -> Array:
	var result = []
	for g in node.get_groups():
		if g.begins_with(prefix):
			result.append(g)
	return result


func free_in_group_when_exceeding(group: String, limit: int):
	var nodes = get_tree().get_nodes_in_group(group)
	var freed_size = max(nodes.size() - limit, 0)

	for i in range(0, freed_size):
		var node = nodes[i]
		if !node.is_queued_for_deletion():
			node.queue_free()


func directory_file_names(directory_path, extension = null) -> Array:
	var dir = Directory.new()
	var file_names = []

	if dir.open(directory_path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if !extension or (extension and file_name.ends_with("." + extension)):
					file_names.append(file_name)
			file_name = dir.get_next()
	else:
		printerr("An error occurred when trying to access the path.")

	return file_names


func is_in_either_group(node: Node, group_name: Array):
	var check = false

	for g in group_name:
		check = check or node.is_in_group(g)

	return check