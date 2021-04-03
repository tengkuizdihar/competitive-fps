tool
extends Area

# Target that's going to be randomly spawned in the level
export (PackedScene) var target_scene
var collision_area: CollisionShape

func _get_configuration_warning() -> String:
	for i in get_children():
		if i is CollisionShape and i.shape is BoxShape:
			return ""
	return "Must have a CollisionShape with BoxShape for area of randomness."


func _ready() -> void:
	if not Engine.editor_hint:
		for i in get_children():
			if i is CollisionShape and i.shape is BoxShape:
				collision_area = i
				break

	spawn_target(collision_area.global_transform.origin)


func spawn_target(target_origin: Vector3 = Vector3.INF) -> void:
	var new_target = target_scene.instance() as Node
	add_child(new_target)

	if target_origin == Vector3.INF:
		new_target.global_transform.origin = get_random_points_inside_area()
	else:
		new_target.global_transform.origin = target_origin

	var interface = Util.get_interface(new_target, IHealth) as IHealth
	interface.connect("dead", self, "_on_Target_dead")


func get_random_points_inside_area() -> Vector3:
	var shape = collision_area.shape as BoxShape
	var extents = shape.extents
	var collision_area_glob_trans = collision_area.global_transform
	randomize()
	var random_in_box = Vector3(rand_range(-extents.x, extents.x), rand_range(-extents.y, extents.y), rand_range(-extents.z, extents.z))

	return collision_area_glob_trans.xform(random_in_box)

func _on_Target_dead() -> void:
	# spawn one more
	spawn_target()
