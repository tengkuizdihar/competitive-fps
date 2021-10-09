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

### Gun Variables
onready var gun_container = $Pivot/Camera/GunContainer
onready var weapon: GenericWeapon = $Pivot/Camera/GunContainer/PM9
onready var current_weapon = Global.WEAPON_SLOT.SECONDARY
onready var last_weapon_used = Global.WEAPON_SLOT.MELEE
onready var weapons = {
	Global.WEAPON_SLOT.PRIMARY: null,
	Global.WEAPON_SLOT.SECONDARY: $Pivot/Camera/GunContainer/PM9,
	Global.WEAPON_SLOT.MELEE: $Pivot/Camera/GunContainer/KF1
}

### A counter that will increase as many times as it jumps until it's on the floor again
var jump_counter = 0

### The currently used max velocity for movement input
var current_max_movement_velocity = MAX_RUN_VELOCITY

### The current velocity for the gravity applied to the character. Will change based
### on the situation. For example it could be the same as MAGIC_ON_GROUND_GRAVITY.
var gravity_velocity = Vector3()

### The desired movement_velocity stored for acceleration purposes.
var desired_movement_velocity = Vector3()

### The the max XZ velocity when in the air
var max_air_velocity = 0

### The final velocity used for debugging returned by move_and_slide
var final_velocity = Vector3()

### Flag for crouching
var is_crouching = false
var debug_position_one_frame_ago = Vector3.ZERO
var held_weapon = null

### Storage for Input Pools
### The storage is structured as such that the key corresponds to the action
### and its value depends on whether or not it was unconsumed (true) or consumed (false).
### {
###   [action_name]: boolean
### }
var input_dict = {}
const captured_events = [
	"player_crouch",
	"player_walk",
	"player_jump",
	"player_weapon_swap",
	"player_weapon_gun_primary",
	"player_weapon_gun_secondary",
	"player_weapon_gun_knife",
	"player_shoot_primary",
	"player_shoot_secondary",
	"player_weapon_drop",
	"player_interact",
	"player_forward",
	"player_backward",
	"player_right",
	"player_left",
]

onready var pivot_original_local_translation = $Pivot.transform.origin
onready var body_original_local_translation = $Body.transform.origin
onready var body_original_height = $Body.shape.height
onready var feet_original_local_translation = $Feet.transform.origin
onready var crouch_height = 1.75

export(bool) var AUTO_BHOP = true
export(float) var CROUCH_SPEED = 5.5 # meter per second
export(float) var JUMP_IMPULSE_VELOCITY = 12
export(float) var AIR_ACCELERATION = 60
export(float) var GROUND_ACCELERATION = 100
export(float) var GROUND_FRICTION = 35
export(float) var GRAVITY_CONSTANT = 25
export(float) var MAX_RUN_VELOCITY = 13.0
export(float) var MAX_WALK_VELOCITY = 6.0
export(float) var MAX_VELOCITY = 30.0 # meter per second
export(float) var MAX_JUMP_VELOCITY_FROM_STILL = 2.0

###########################################################
# State Enum
###########################################################

# Uncomment when you want to start refactoring it into states
#signal player_state_changed(enum_state)
#signal gun_state_changed(enum_state)
#
#enum PlayerState {
#	WALKING,
#	RUNNING,
#	FALLING,
#	DEAD,
#	CROUCHING_WALK,
#	CROUCHING_RUN,
#}
#
#enum GunState {
#	SHOOTING,
#	SHOOTING_OUT_OF_BULLETS,
#	RELOADING,
#}

###########################################################
# Engine Callbacks
###########################################################

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# height of the character from local origin + the crouch height delta with original height
	var body_height = $Body.shape.height
	headlimit_raycast.cast_to = Vector3.UP * (body_height - crouch_height)

	# Init input pool for... pooling input.
	for i in captured_events:
		input_dict[i] = -1

	# set all weapon to equipped
	$Pivot/Camera/GunContainer/KF1.set_to_equipped()
	$Pivot/Camera/GunContainer/PM9.set_to_equipped()


func _unhandled_input(event):
	input_pooling(event)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		rotate_y(-event.relative.x * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, -PI/2 + 0.01, PI/2 - 0.01)


func _physics_process(delta: float) -> void:
	# TODO-BIG: refactor input so that it would be outside of this script
	#           this will ensure possibilities for multiplayer in the future
	manage_crouching(delta)
	handle_movement(get_movement_input(self.global_transform.basis), delta)
	handle_weapon_pickup()
	handle_weapon_drop()
	handle_weapon_selection()
	handle_weapon_reload()

#	handle_aim_punch()
	fire_to_direction()
	apply_shooting_knockback(self, camera, weapon)

	State.change_state("DEBUG_AMMO", "%d - %d" % [weapon.current_ammo, weapon.current_total_ammo])


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
### TODO: NEW METHOD WHEN IN GROUND, CURRENT METHOD WHEN AIRBORNE
func manage_crouching(delta: float):
	if LLInput.is_action_pressed("player_crouch") or $Body.shape.height < body_original_height:
		is_crouching = true

	if not LLInput.is_action_pressed("player_crouch") and not headlimit_raycast.is_colliding():
		is_crouching = false

	if is_on_floor():
		if is_crouching:
			var crouch_delta = CROUCH_SPEED * delta
			var height_change = abs(crouch_height - body_original_height)
			var body_trans_target = body_original_local_translation + Vector3.DOWN * height_change / 2

			$Body.shape.height = move_toward($Body.shape.height, crouch_height, crouch_delta)
			$Body.transform.origin = $Body.transform.origin.move_toward(body_trans_target, crouch_delta / 2)
			$Feet.transform.origin = $Body.transform.origin + Vector3.DOWN * ($Body.shape.height / 2 + $Body.shape.radius) + Vector3.UP * $Feet.shape.height / 2
		else:
			var crouch_delta = CROUCH_SPEED * 1.5 * delta
			$Body.shape.height = move_toward($Body.shape.height, body_original_height, crouch_delta)
			$Body.transform.origin = $Body.transform.origin.move_toward(body_original_local_translation, crouch_delta / 2)
			$Feet.transform.origin = $Body.transform.origin + Vector3.DOWN * ($Body.shape.height / 2 + $Body.shape.radius) + Vector3.UP * $Feet.shape.height / 2

	else:
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

	$Pivot.transform.origin = $Body.transform.origin + Vector3.UP * $Body.shape.height / 2
	$HeadLimitRayCast.transform.origin = $Body.transform.origin + Vector3.UP * ($Body.shape.height / 2 + $Body.shape.radius)


# TODO: decouple these codes into other smaller more concise function
func handle_movement(input_vector: Vector3, delta: float):
	input_vector = input_vector.normalized()

	# slide the input_vector so that it would be on the plane in which it walks
	var input_slanted = input_vector

	if is_on_ceiling():
		gravity_velocity = Vector3.ZERO

	# ON THE GROUND
	elif is_on_floor():
		input_slanted = input_vector.slide(get_floor_normal()).normalized()
		gravity_velocity = -self.get_floor_normal() * MAGIC_ON_GROUND_GRAVITY

		# Player walk action that will decrease MAX_VELOCITY
		if LLInput.is_action_pressed("player_walk") and is_crouching:
			current_max_movement_velocity = MAX_WALK_VELOCITY * 0.815
		elif is_crouching:
			current_max_movement_velocity = MAX_WALK_VELOCITY
		elif LLInput.is_action_pressed("player_walk"):
			current_max_movement_velocity = MAX_WALK_VELOCITY
		else:
			current_max_movement_velocity = MAX_RUN_VELOCITY

		# Apply Friction
		if input_slanted.length() > 0:
			if is_crouching:
				desired_movement_velocity = desired_movement_velocity.move_toward(input_slanted * current_max_movement_velocity, GROUND_ACCELERATION * 0.5 * delta)
			else:
				desired_movement_velocity = desired_movement_velocity.move_toward(input_slanted * current_max_movement_velocity, GROUND_ACCELERATION * delta)
		else:
			desired_movement_velocity = apply_friction(desired_movement_velocity, GROUND_FRICTION, delta)

	# IN THE AIR
	else:
		gravity_velocity.x = 0
		gravity_velocity.z = 0
		gravity_velocity += Vector3.DOWN * (GRAVITY_CONSTANT * delta)
		current_max_movement_velocity = MAX_RUN_VELOCITY

		if input_vector.length() > 0:
			if input_vector.dot(final_velocity.normalized()) < 0:
				desired_movement_velocity = desired_movement_velocity.move_toward(input_vector * max_air_velocity, GROUND_ACCELERATION * delta)
			else:
				desired_movement_velocity = desired_movement_velocity.move_toward(input_vector * max_air_velocity, AIR_ACCELERATION * delta)

	# Jumping mechanics, affects desired_movement_velocity. this is because
	# the jumping height could be affected by the movement velocity, which is
	# affected by the angle of the surface.
	#
	# EXAMPLE: if the desired velocity isn't changed, player who went up a slope
	#          will have higher jumping velocity than the one going downwards.
	var action_pressed_jump = LLInput.consume_input("player_jump|pressed")
	var is_pressed_jump = Input.is_action_pressed("player_jump")
	if is_on_floor() and (action_pressed_jump or (AUTO_BHOP and is_pressed_jump)):
		gravity_velocity = Vector3.UP * JUMP_IMPULSE_VELOCITY
		max_air_velocity = max(final_velocity.length(), MAX_JUMP_VELOCITY_FROM_STILL)
		desired_movement_velocity = Util.clamp_vector3(input_vector * current_max_movement_velocity, final_velocity.length())

	# finalize to current velocity
	var velocity_and_gravity = desired_movement_velocity + gravity_velocity

	# clamp the velocity and gravity to max speed
	velocity_and_gravity = Util.clamp_vector3(velocity_and_gravity, MAX_VELOCITY)

	# apply to move and slide
	final_velocity = self.move_and_slide(velocity_and_gravity, Vector3.UP, true, 4, 0.785398, false)

	State.change_state("DEBUG_PLAYER_VELOCITY", stepify(desired_movement_velocity.length(), 0.01))


func hide_all_weapon() -> void:
	for w in weapons.values():
		if w:
			w.hide()


func handle_weapon_selection() -> void:
	if Input.is_action_just_pressed("player_weapon_swap"):
		_switch_weapon_routine(last_weapon_used)
	if Input.is_action_just_pressed("player_weapon_gun_primary"):
		_switch_weapon_routine(Global.WEAPON_SLOT.PRIMARY)
	if Input.is_action_just_pressed("player_weapon_gun_secondary"):
		_switch_weapon_routine(Global.WEAPON_SLOT.SECONDARY)
	if Input.is_action_just_pressed("player_weapon_gun_knife"):
		_switch_weapon_routine(Global.WEAPON_SLOT.MELEE)


# TODO: use weapon inaccuracy + movement inaccuracy
# TODO: use weapon information for ammo and reloading
func fire_to_direction() -> void:
	# FIRST TRIGGER
	if (LLInput.consume_input("player_shoot_primary|pressed") or LLInput.is_action_pressed("player_shoot_primary")) and weapon.can_shoot() and weapon.trigger_on():
		shooting_routine(self, pivot, weapon)

	if LLInput.consume_input("player_shoot_primary|released"):
		weapon.trigger_off()


	# SECOND TRIGGER
	# TODO: make shooting routine to have many modes
#	elif Input.is_action_just_pressed("player_shoot_secondary") and weapon.can_shoot():
#		weapon.second_trigger_on()
#		shooting_routine(self, camera, weapon)
#	elif Input.is_action_just_released("player_shoot_secondary"):
#		weapon.second_trigger_off()


func handle_weapon_drop() -> void:
	if Input.is_action_just_pressed("player_weapon_drop") and weapon.weapon_slot != Global.WEAPON_SLOT.MELEE:
		_drop_weapon(weapon)


# TODO: add weapon pickup when near
func handle_weapon_pickup() -> void:
	if Input.is_action_just_pressed("player_interact"):
		var from = camera.global_transform.origin
		var to = from + -camera.global_transform.basis.z * 5.0

		# get the weapon being looked at
		var space_state = camera.get_world().direct_space_state
		var ray_result = space_state.intersect_ray(from, to, [self], Global.PHYSICS_LAYERS.GUN)
		var colliding = ray_result.get("collider")

		if colliding and colliding is GenericWeapon:
			_weapon_pickup_routine(colliding)


func _weapon_pickup_routine(w: GenericWeapon) -> void:
	# set the weapon to the one chosen by the player
	var existing_weapon = _set_weapon(w)

	# if player already have a weapon in the chosen weapon slot
	if existing_weapon:
		_drop_weapon(existing_weapon)


func handle_weapon_reload() -> void:
	if LLInput.is_action_pressed("player_reload") and weapon.can_reload():
		weapon.reload_trigger()


# Drop the given weapon and then return whether the weapon is dropped or not.
# Return true only when the weapon is dropped and false if the weapon can't be dropped.
func _drop_weapon(w: GenericWeapon) -> void:
	w.deactivate()
	w.show()

	# remove from child
	$Pivot/Camera/GunContainer.remove_child(w)

	# throw it into the world (for now just place it on the ground from where the camera origin is)
	for i in get_tree().root.get_children():
		if i is Spatial:
			i.add_child(w)

	# make set_to_world_object
	w.set_to_world_object()

	randomize()
	w.global_transform.origin = camera.global_transform.origin - camera.global_transform.basis.z.normalized() * 2

	# add force to the gun
	w.apply_central_impulse(-camera.global_transform.basis.z * (10 + final_velocity.length() / 2))
	w.apply_torque_impulse(-camera.global_transform.basis.z.rotated(Vector3.UP, rand_range(-PI/2, PI/2)) * rand_range(0.1,0.5))

	# make the weapons (dict) currenly equipped to null
	if weapons[w.weapon_slot] == w:
		weapons[w.weapon_slot] = null

	if weapon == w:
		weapon = null

	# switch to the currently used weapon
	_switch_weapon_routine(current_weapon)


# Set the given weapon to the inventory then return an already existing weapon.
# If player doesn't have weapon already, then return null.
func _set_weapon(w: GenericWeapon) -> GenericWeapon:
	w.activate()

	var existing_weapon = weapons[w.weapon_slot]

	var parent = w.get_parent()
	parent.remove_child(w)

	weapons[w.weapon_slot] = w

	# Add to gun container
	gun_container.add_child(w)
	w.global_transform = gun_container.get_global_transform()

	# Set the weapon to be equipped
	w.set_to_equipped()

	# TODO make an option for auto switch on pickup
	# Hide it at pickup
	w.hide()

	return existing_weapon


func _switch_weapon_routine(weapon_slot) -> void:
	hide_all_weapon()
	if weapon:
		weapon.deactivate()

	if weapons[weapon_slot]:
		if current_weapon != weapon_slot:
			last_weapon_used = current_weapon
			current_weapon = weapon_slot

		weapon = weapons[weapon_slot]
	else:
		for k in weapons.keys():
			if weapons[k]:
				weapon = weapons[k]
				current_weapon = weapon.weapon_slot
				last_weapon_used = weapon.weapon_slot

	weapon.show()
	weapon.activate()


# TODO: an effect where the player's sight is "nudged" when hit on the head
func handle_aim_punch() -> void:
	pass


###########################################################
# Input Pooling Functions
###########################################################

### This function will refresh the pool action events that's inside of the
### caputered_events array.
func input_pooling(event: InputEvent) -> void:
	for i in captured_events:
		if event.is_action_pressed(i):
			input_dict[i] = Engine.get_physics_frames()


func consume_input(event_name: String) -> bool:
	var current_physics_frame = Engine.get_physics_frames()
	var timeout_frames = 1
	var p_frame_input = input_dict[event_name]

	# Reset it anyway
	input_dict[event_name] = -1

	# Return if the input hasn't expired yet
	return p_frame_input + timeout_frames > current_physics_frame



###########################################################
# Static Function
###########################################################

static func shooting_routine(player, p: Spatial, w: GenericWeapon) -> void:
	var from = p.global_transform.origin
	var direction = get_shooting_direction(player, p, w)
	var to = from + direction * w.max_distance

	var space_state = player.get_world().direct_space_state
	var ray_result = space_state.intersect_ray(from, to, [player], 1)
	var colliding = ray_result.get("collider")
	var collision_point = ray_result.get("position")

	if colliding:
		# change the health based on the weapon's damage
		if "i_health" in colliding:
			colliding.i_health.change_health(-w.base_damage)

		# interact with the object if interface exist
		if "i_interact" in colliding:
			colliding.i_interact.interact()

		# push the object if it's hit by the weapon
		if colliding is RigidBody:
			var imp_direction = -p.global_transform.basis.z.normalized()
			colliding.apply_impulse(collision_point - colliding.global_transform.origin, imp_direction * 10)

		# spawn sparks
		# TODO change the location where you preload sparks. Maybe in the global??
		var sparks = preload("res://world_item/spark.tscn").instance()

		for i in player.get_tree().root.get_children():
			if i is Spatial:
				i.add_child(sparks)
				sparks.global_transform.origin = collision_point


static func get_shooting_direction(player, p: Spatial, w: GenericWeapon) -> Vector3:
	var forward = -p.global_transform.basis.z

	var inaccuracy = w.get_inaccuracy()

	var inh_inacc = inaccuracy.inherent
	var spr_inacc = inaccuracy.spray

	var movement_ratio_to_still = player.final_velocity.length() / player.MAX_RUN_VELOCITY
	var movement_inaccuracy = 1 + (movement_ratio_to_still * w.movement_inaccuracy_multiplier)
	var jumping_inaccuracy = 1 + (int(!player.is_on_floor())  * w.jumping_inaccuracy_multiplier)

	# If rotated by a positive number, it goes to the right, vice versa
	var horizontalized = forward.rotated(-p.global_transform.basis.y, (inh_inacc[0] * movement_inaccuracy * jumping_inaccuracy) + spr_inacc[0])

	# If rotated by a positive number, it goes to the top, vice versa
	var verticalized = horizontalized.rotated(p.global_transform.basis.x, (inh_inacc[1] * movement_inaccuracy * jumping_inaccuracy) + spr_inacc[1])
	return verticalized


# TODO: use the player variable and knock the head upwards when getting headshot
static func apply_shooting_knockback(_player, c: CameraSmoothPhysics, w: GenericWeapon):
	var spr_inacc = w.get_knockback_inaccuracy()

	# If rotated by a positive number, it goes to the right, vice versa
	c.rotated_angle_horizontal = spr_inacc[0]

	# If rotated by a positive number, it goes to the top, vice versa
	c.rotated_angle_vertical = spr_inacc[1]

###########################################################
# Stateless Function
###########################################################

static func get_movement_input(camera_basis: Basis) -> Vector3:
	var input_direction = Vector3.ZERO
	if LLInput.is_action_pressed("player_forward"):
		input_direction += -camera_basis.z
	if LLInput.is_action_pressed("player_backward"):
		input_direction += camera_basis.z
	if LLInput.is_action_pressed("player_right"):
		input_direction += camera_basis.x
	if LLInput.is_action_pressed("player_left"):
		input_direction += -camera_basis.x

	input_direction.y = 0
	return input_direction.normalized()

static func apply_friction(new_velocity: Vector3, friction_constant: float, delta: float) -> Vector3:
	if new_velocity.length() <= friction_constant * delta:
		return Vector3()
	else:
		var friction_vector = new_velocity.normalized() * friction_constant * delta
		return new_velocity - friction_vector


func _on_Area_body_entered(w):
	if w is GenericWeapon:
		if not weapons.get(w.weapon_slot) and w.is_auto_pickupable():
			_weapon_pickup_routine(w)
