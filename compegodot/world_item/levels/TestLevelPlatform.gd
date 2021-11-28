# quick dirty platform codes for testing
extends KinematicBody

class Direction:
	const forward = Vector3(-1,0,0)
	const right = Vector3(0,0,-1)
	const backward = Vector3(1,0,0)
	const left = Vector3(0,0,1)

var timing = 4 # second
var right_now = timing
var current_direction = Direction.forward

func _physics_process(delta: float) -> void:
	if right_now <= 0:
		right_now = timing

		# cycle through direction to make a loop
		if current_direction == Direction.forward:
			current_direction = Direction.right
		elif current_direction == Direction.right:
			current_direction = Direction.backward
		elif current_direction == Direction.backward:
			current_direction = Direction.left
		elif current_direction == Direction.left:
			current_direction = Direction.forward
	else:
		right_now -= delta
		var _lmao = move_and_slide(current_direction * 5)
