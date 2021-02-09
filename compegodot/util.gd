extends Node


# Clamping the length of a single vector3
func clamp_vector3(vec: Vector3, max_length: float) -> Vector3:
	return Vector3(clamp(vec.x, -max_length, max_length), clamp(vec.y, -max_length, max_length), clamp(vec.z, -max_length, max_length))
