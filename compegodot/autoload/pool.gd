extends Node

const DEFAULT_MAX_NODE_COUNT = 100
const SHOOTING_TARGET_KEY = "shooting_target"

var _pool = {
	shooting_target = {
		instance = preload("res://world_item/shooting_area/shooting_target.tscn"),
		pool = { active = {}, inactive = {}, max_node_count = 10 },
	},
}


func _ready():
	for node_key in _pool:
		var max_node_count = _pool[node_key].pool.max_node_count
		for _i in range(max_node_count):
			init_node_in_pool(node_key)


func init_node_in_pool(node_key: String):
	if _pool[node_key].pool.active.size() + _pool[node_key].pool.inactive.size() + 1 > _pool[node_key].pool.max_node_count:
		printerr("Init node more than the size of the pool key %s." % node_key , get_stack())
		return

	var new_node = _pool[node_key].instance.instance()
	deactivate_node(node_key, new_node)
	Util.add_to_world(new_node)
	new_node.connect("tree_exiting", self, "_on_node_exiting", [node_key, new_node])


func activate_node(node_key: String) -> Node:
	var new_node = _pool[node_key].pool.inactive.keys().front()

	if not new_node:
		printerr("No more inactive node to activate for key %s." % node_key , get_stack())
		return null

	_pool[node_key].pool.inactive.erase(new_node)
	_pool[node_key].pool.active[new_node] = null
	set_node_activation(new_node, true)

	if not new_node.is_inside_tree():
		Util.call_deferred("add_to_world", new_node)

	return new_node


func deactivate_node(node_key: String, node: Node) -> void:
	_pool[node_key].pool.active.erase(node)
	_pool[node_key].pool.inactive[node] = null
	set_node_activation(node, false)


static func set_node_activation(node: Node, enable: bool) -> void:
	node.set_physics_process(enable)
	node.set_process(enable)
	node.set_process_input(enable)
	node.set_process_unhandled_input(enable)
	node.set_process_unhandled_key_input(enable)

	if node.is_inside_tree():
		if node is Spatial:
			node.visible = enable
			node.global_transform.origin = Vector3(1000000000, 1000000000, 1000000000)

		if node is CanvasItem:
			node.visible = enable
			node.global_transform.origin = Vector2(1000000000, 1000000000)


func _on_node_exiting(node_key: String, node: Node) -> void:
	node.queue_free()
	_pool[node_key].pool.active.erase(node)
	_pool[node_key].pool.inactive.erase(node)

	call_deferred("init_node_in_pool", node_key)
