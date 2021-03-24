tool
extends Spatial

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

func get_random_points_inside_area() -> Vector3:
	var shape = collision_area.shape as BoxShape
	# TODO get random point inside of the box transformed by collision area transform
	return Vector3()

# TODO in ready, spawn and connect the dead signal in targets
# TODO set the spawn position to get_random_points_inside_area()
