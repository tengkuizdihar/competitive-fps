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
