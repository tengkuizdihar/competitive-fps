extends KinematicBody

onready var normal_input_direction = Vector3.ZERO # will be changed by outside actors
onready var camera = $Pivot/Camera
onready var pivot = $Pivot
onready var mouse_sensitivity = 0.002  # radians/pixel, TODO: refactor to game settings
onready var floor_raycast = $RayCast

export(float) var gravity_constant = 17
export(float) var max_movement_velocity = 12.0
export(float) var max_velocity = 30.0 # meter per second

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		rotate_y(-event.relative.x * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, -1.2, 1.2)



func _physics_process(_delta: float) -> void:
	# TODO-BIG: refactor input so that it would be outside of this script
	#           this will ensure possibilities for multiplayer in the future
	var input_basis = $Pivot/Camera.global_transform.basis
	State.change_state("DEBUG_FLOOR_NORMAL", floor_raycast.get_collision_normal())
	apply_movement(get_movement_input(input_basis))


###########################################################
# Stateful function
###########################################################

# TODO change everything into acceleration instead of velocity
func apply_movement(input_vector: Vector3):
	var floor_normal = floor_raycast.get_collision_normal().normalized()
	input_vector = input_vector.normalized()

	# slide the input_vector so that it would be on the plane in which it walks
	if floor_normal.length() > 0:
		input_vector = input_vector.slide(floor_normal).normalized()

	# TODO add world velocity (gravity, explotion, etc)
	var gravity = Vector3.ZERO
	if not is_on_floor():
		gravity = Vector3.DOWN * gravity_constant
	else:
		gravity = -self.get_floor_normal()

	# TODO add deceleration if input vector is zero
	# TODO instant velocity redirection
	var desired_movement_velocity = Vector3.ZERO
	if input_vector == Vector3.ZERO:
		# decelerate
		pass
	else:
		# accelerate
		desired_movement_velocity = input_vector * max_movement_velocity

	# TODO add jump acceleration
#	var jump_velocity = Vector3.ZERO
#	if Input.is_action_just_pressed("player_jump"):
#		jump_velocity = Vector3.UP * 780

	# finalize to current velocity
	var velocity_and_gravity = desired_movement_velocity + gravity

	# clamp the velocity and gravity to max speed
	velocity_and_gravity = Util.clamp_vector3(velocity_and_gravity, max_velocity)

	# apply to move and slide
	var linear_velocity = self.move_and_slide(velocity_and_gravity, Vector3.UP, true, 4, 0.785398, false)
	State.change_state("DEBUG_PLAYER_VELOCITY", stepify(linear_velocity.length(), 0.01))


###########################################################
# Stateless Function
###########################################################


static func get_movement_input(camera_basis: Basis) -> Vector3:
	var input_direction = Vector3.ZERO
	if Input.is_action_pressed("player_forward"):
		input_direction += -camera_basis.z
	if Input.is_action_pressed("player_backward"):
		input_direction += camera_basis.z
	if Input.is_action_pressed("player_right"):
		input_direction += camera_basis.x
	if Input.is_action_pressed("player_left"):
		input_direction += -camera_basis.x

	input_direction.y = 0
	return input_direction.normalized()
