extends KinematicBody

# INFO - MAGIC_ON_GROUND_GRAVITY
# Is a constant used by the kinematic for making the player stay on the ground.
# For example: It's used so that the player wouldn't fly off when going up and down
#              ramps.
const MAGIC_ON_GROUND_GRAVITY = 9 # m/s

onready var normal_input_direction = Vector3.ZERO # will be changed by outside actors
onready var camera = $Pivot/Camera
onready var pivot = $Pivot
onready var mouse_sensitivity = 0.0008  # radians/pixel, TODO: refactor to game settings
onready var current_acceleration = ground_acceleration

var current_max_movement_velocity = max_run_velocity
var gravity_velocity = Vector3()
var desired_movement_velocity = Vector3()
var final_velocity = Vector3()

export(float) var jump_impulse_velocity = 12
export(float) var air_acceleration = 15
export(float) var ground_acceleration = 45
export(float) var gravity_constant = 25
export(float) var max_run_velocity = 12.0
export(float) var max_walk_velocity = 6.0
export(float) var max_velocity = 30.0 # meter per second

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		rotate_y(-event.relative.x * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, -PI/2 + 0.01, PI/2 - 0.01)


func _physics_process(delta: float) -> void:
	# TODO-BIG: refactor input so that it would be outside of this script
	#           this will ensure possibilities for multiplayer in the future
	apply_movement(get_movement_input($Pivot/Camera.global_transform.basis), delta)


###########################################################
# Stateful function
###########################################################

# BUG jumping will be shorter when going down
func apply_movement(input_vector: Vector3, delta: float):
	input_vector = input_vector.normalized()

	# slide the input_vector so that it would be on the plane in which it walks
	var input_slanted = input_vector
	if is_on_floor():
		input_slanted = input_vector.slide(get_floor_normal()).normalized()

	if not is_on_floor():
		gravity_velocity.x = 0
		gravity_velocity.z = 0
		gravity_velocity += Vector3.DOWN * (gravity_constant * delta)
		current_acceleration = air_acceleration
	else:
		gravity_velocity = -self.get_floor_normal() * MAGIC_ON_GROUND_GRAVITY
		current_acceleration = ground_acceleration

	# Player walk action that will decrease max_velocity
	if Input.is_action_pressed("player_walk"):
		current_max_movement_velocity = max_walk_velocity
	else:
		current_max_movement_velocity = max_run_velocity

	# counterstrafing, by gradualy increasing/decreasing acceleration
	if desired_movement_velocity.normalized().dot(input_slanted) < 0:
		desired_movement_velocity = desired_movement_velocity.move_toward(input_slanted * current_max_movement_velocity, current_acceleration * delta * 2)
	else:
		desired_movement_velocity = desired_movement_velocity.move_toward(input_slanted * current_max_movement_velocity, current_acceleration * delta)

	# Jumping mechanics, affects desired_movement_velocity. this is because
	# the jumping height could be affected by the movement velocity, which is
	# affected by the angle of the surface.
	#
	# EXAMPLE: if the desired velocity isn't changed, player who went up a slope
	#          will have higher jumping velocity than the one going downwards.
	#
	# BUG: can jump multiple times per frame. need a counter for this.
	if is_on_floor() and Input.is_action_just_pressed("player_jump"):
		gravity_velocity = Vector3.UP * jump_impulse_velocity
		desired_movement_velocity = input_vector * current_max_movement_velocity

	# finalize to current velocity
	var velocity_and_gravity = desired_movement_velocity + gravity_velocity

	# clamp the velocity and gravity to max speed
	velocity_and_gravity = Util.clamp_vector3(velocity_and_gravity, max_velocity)

	# apply to move and slide
	final_velocity = self.move_and_slide(velocity_and_gravity, Vector3.UP, true, 4, 0.785398, false)

	# DEBUG
	State.change_state("DEBUG_MISC", str(is_on_floor()))
	State.change_state("DEBUG_PLAYER_VELOCITY", stepify(final_velocity.length(), 0.01))


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
