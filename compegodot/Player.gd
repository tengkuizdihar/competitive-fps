extends KinematicBody

###########################################################
# Variables
###########################################################

### INFO - MAGIC_ON_GROUND_GRAVITY
### Is a constant used by the kinematic for making the player stay on the ground.
### For example: It's used so that the player wouldn't fly off when going up and down
###              ramps.
const MAGIC_ON_GROUND_GRAVITY = 9 # m/s

onready var headlimit_raycast = $HeadLimitRayCast
onready var normal_input_direction = Vector3.ZERO # will be changed by outside actors
onready var camera = $Pivot/Camera
onready var pivot = $Pivot
onready var mouse_sensitivity = 0.0008  # radians/pixel, TODO: refactor to game settings
onready var current_acceleration = GROUND_ACCELERATION
onready var center_raycast = $Pivot/Camera/CenterRaycast

### A counter that will increase as many times as it jumps until it's on the floor again
var jump_counter = 0

### The currently used max velocity for movement input
var current_max_movement_velocity = MAX_RUN_VELOCITY

### The current velocity for the gravity applied to the character. Will change based
### on the situation. For example it could be the same as MAGIC_ON_GROUND_GRAVITY.
var gravity_velocity = Vector3()

### The desired movement_velocity stored for acceleration purposes.
var desired_movement_velocity = Vector3()

### The final velocity used for debugging returned by move_and_slide
var final_velocity = Vector3()

### Flag for crouching
var is_crouching = false
var debug_position_one_frame_ago = Vector3.ZERO
var held_weapon = null

onready var feet_original_local_translation = $Feet.transform.origin
onready var body_original_local_translation = $Body.transform.origin
onready var body_original_height = $Body.shape.height
onready var crouch_height = 1.75

export(bool) var AUTO_BHOP = false
export(float) var CROUCH_SPEED = 3 # meter per second
export(float) var JUMP_IMPULSE_VELOCITY = 12
export(float) var AIR_ACCELERATION = 20
export(float) var GROUND_ACCELERATION = 80
export(float) var GRAVITY_CONSTANT = 25
export(float) var MAX_RUN_VELOCITY = 13.0
export(float) var MAX_WALK_VELOCITY = 6.0
export(float) var MAX_VELOCITY = 30.0 # meter per second

###########################################################
# State Enum
###########################################################

signal player_state_changed(enum_state)
signal gun_state_changed(enum_state)

enum PlayerState {
	WALKING,
	RUNNING,
	FALLING,
	DEAD,
	CROUCHING_WALK,
	CROUCHING_RUN,
}

enum GunState {
	SHOOTING,
	SHOOTING_OUT_OF_BULLETS,
	RELOADING,
}

###########################################################
# Engine Callbacks
###########################################################

# BUG: the screen is jittery because render and physics are done in two different FPS
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# height of the character from local origin + the crouch height delta with original height
	var body_height = $Body.shape.height
	headlimit_raycast.cast_to = Vector3.UP * (body_height - crouch_height)


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		rotate_y(-event.relative.x * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, -PI/2 + 0.01, PI/2 - 0.01)


func _physics_process(delta: float) -> void:
	# TODO-BIG: refactor input so that it would be outside of this script
	#           this will ensure possibilities for multiplayer in the future
	manage_crouching(delta)
	handle_movement(get_movement_input($Pivot/Camera.global_transform.basis), delta)
	fire_to_direction()

###########################################################
# Stateful function
###########################################################

### The body that's affected here is: Body size & position and Feet position only.
### When the body is reduced in height by N, it will go higher by N.
### The feet will follow the position of the body by getting higher N also.
### This process is reversible because of how crouching works which is:
###     * Crouch
###     * Come to normal
### BUG: if crouching under moving platform, player would stand up and down repeatedly
func manage_crouching(delta: float):
	if Input.is_action_pressed("player_crouch") or $Body.shape.height < body_original_height:
		self.is_crouching = true

	if not Input.is_action_pressed("player_crouch") and is_crouching and not headlimit_raycast.is_colliding():
		is_crouching = false

	if is_crouching:
		var height_change = abs(crouch_height - body_original_height)
		var body_trans_target = body_original_local_translation + Vector3.UP * height_change / 2
		var feet_trans_target = feet_original_local_translation + Vector3.UP * height_change

		$Body.shape.height = move_toward($Body.shape.height, crouch_height, CROUCH_SPEED * delta)
		$Body.transform.origin = $Body.transform.origin.move_toward(body_trans_target, CROUCH_SPEED * delta)
		$Feet.transform.origin = $Feet.transform.origin.move_toward(feet_trans_target, CROUCH_SPEED * delta)
	else:
		var crouch_delta = CROUCH_SPEED * 1.5 * delta
		$Body.shape.height = move_toward($Body.shape.height, body_original_height, crouch_delta)
		$Body.transform.origin = $Body.transform.origin.move_toward(body_original_local_translation, crouch_delta)
		$Feet.transform.origin = $Feet.transform.origin.move_toward(feet_original_local_translation, crouch_delta)

# TODO: decouple these codes into other smaller more concise function
func handle_movement(input_vector: Vector3, delta: float):
	input_vector = input_vector.normalized()

	# slide the input_vector so that it would be on the plane in which it walks
	var input_slanted = input_vector
	if is_on_floor():
		input_slanted = input_vector.slide(get_floor_normal()).normalized()
	if is_on_ceiling():
		gravity_velocity = Vector3.ZERO
	elif is_on_floor():
		gravity_velocity = -self.get_floor_normal() * MAGIC_ON_GROUND_GRAVITY
		current_acceleration = GROUND_ACCELERATION
	else:
		gravity_velocity.x = 0
		gravity_velocity.z = 0
		gravity_velocity += Vector3.DOWN * (GRAVITY_CONSTANT * delta)
		current_acceleration = AIR_ACCELERATION

	# Player walk action that will decrease MAX_VELOCITY
	if Input.is_action_pressed("player_walk") and is_crouching and is_on_floor():
		current_max_movement_velocity = MAX_WALK_VELOCITY * 0.5
	elif is_crouching and is_on_floor():
		current_max_movement_velocity = MAX_WALK_VELOCITY * 0.75
	elif Input.is_action_pressed("player_walk") and is_on_floor():
		current_max_movement_velocity = MAX_WALK_VELOCITY
	else:
		current_max_movement_velocity = MAX_RUN_VELOCITY

	desired_movement_velocity = desired_movement_velocity.move_toward(input_slanted * current_max_movement_velocity, current_acceleration * delta)

	# Jumping mechanics, affects desired_movement_velocity. this is because
	# the jumping height could be affected by the movement velocity, which is
	# affected by the angle of the surface.
	#
	# EXAMPLE: if the desired velocity isn't changed, player who went up a slope
	#          will have higher jumping velocity than the one going downwards.
	if is_on_floor() and (Input.is_action_just_pressed("player_jump") or (AUTO_BHOP and Input.is_action_pressed("player_jump"))):
		gravity_velocity = Vector3.UP * JUMP_IMPULSE_VELOCITY
		desired_movement_velocity = input_vector * current_max_movement_velocity
		desired_movement_velocity = Util.clamp_vector3(desired_movement_velocity, final_velocity.length())

	# finalize to current velocity
	var velocity_and_gravity = desired_movement_velocity + gravity_velocity

	# clamp the velocity and gravity to max speed
	velocity_and_gravity = Util.clamp_vector3(velocity_and_gravity, MAX_VELOCITY)

	# apply to move and slide
	final_velocity = self.move_and_slide(velocity_and_gravity, Vector3.UP, true, 4, 0.785398, false)

	State.change_state("DEBUG_PLAYER_VELOCITY", stepify(final_velocity.length(), 0.01))

# TODO: fire to direction on the same frame when pressed
# TODO: use gun inaccuracy + movement inaccuracy
# TODO: use gun information for ammo and reloading
func fire_to_direction() -> void:
	if Input.is_action_just_pressed("player_shoot"):
		var colliding = center_raycast.get_collider()
		if colliding and "i_health" in colliding:
			colliding.i_health.change_health(-100)
	elif Input.is_action_just_released("player_shoot"):
		pass


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
