extends KinematicBody

###########################################################
# Interfaces
###########################################################

onready var i_health = $IHealth
onready var i_flash = $IFlash

###########################################################
# Variables
###########################################################

# Is a constant used by the kinematic for making the player stay on the ground.
# For example: It's used so that the player wouldn't fly off when going up and down
#              ramps.
const MAGIC_ON_GROUND_GRAVITY = 2.5 # m/s

# A constant used to mark how much time is the maximum for a person to be flashed.
# For example: A man is flashed for 10 seconds then flashed again when there's
#              5 seconds left for the flash to be active. The flash will not be active for
#              15 seconds, but for 10.
const FLASH_MAXIMUM_DURATION = 5.0

# Used to mark the maximum distance of flash from the player to affect them
const FLASH_MAXIMUM_DISTANCE = 100.0

# Used to determine how close the angle of flash must be to the camera to work.
# For example, a flash that's happening behind the player will not blind them.
const FLASH_MAXIMUM_ANGLE = deg2rad(110)

# A constant used to determine the flash overlay color
const DEFAULT_FLASH_COLOR = Color(1,1,1,1)

# is_player is used for marking whether an object is a player or not.
#
# The reason it needs a marker instead of checking the class itself is
# because Godot 3.x has a big cyclic dependency problems and it could ruin other scripts.
onready var is_player = true

onready var headlimit_raycast = $HeadLimitRayCast
onready var normal_input_direction = Vector3.ZERO # will be changed by outside actors
onready var camera = $Pivot/Camera
onready var pivot = $Pivot
onready var mouse_sensitivity = 0.0008  # radians/pixel, TODO: refactor to game settings

#-- Gun Variables --#
onready var gun_container = $Pivot/Camera/GunContainer
onready var weapon: GenericWeapon = $Pivot/Camera/GunContainer/KF1
onready var current_weapon = Global.WEAPON_SLOT.MELEE
onready var last_weapon_used = Global.WEAPON_SLOT.MELEE
onready var weapons = {
	Global.WEAPON_SLOT.PRIMARY: null,
	Global.WEAPON_SLOT.SECONDARY: null,
	Global.WEAPON_SLOT.MELEE: $Pivot/Camera/GunContainer/KF1,
	Global.WEAPON_SLOT.UTILITY: null
}

#-- The currently used max velocity for movement input --#
var current_max_movement_velocity = max_run_velocity

#-- The desired movement_velocity stored for acceleration purposes. --#
var desired_movement_velocity = Vector3()

#-- The the max XZ velocity when in the air --#
var max_air_velocity = 0

#-- Flag for crouching --#
var is_crouching = false
var debug_position_one_frame_ago = Vector3.ZERO
var held_weapon = null

#-- Weapon sway variables --#
onready var gun_container_original_rotation = Vector2(gun_container.rotation_degrees.x, gun_container.rotation_degrees.y)
var mouse_movement = Vector2()
var is_mouse_moving_time = false
var mouse_turn_max_sensitivity = 1

#-- Flashed variables --#
onready var flash_overlay = $Pivot/Camera/FlashOverlay
var flash_remaining_second = 0.0

onready var gun_container_original_transform = gun_container.transform
onready var pivot_original_local_translation = $Pivot.transform.origin
onready var body_original_local_translation = $Body.transform.origin
onready var body_original_height = $Body.shape.height
onready var crouch_height = 3.75

export(bool) var auto_bhop = true
export(float) var crouch_speed = 5.5 # meter per second
export(float) var jump_impulse_velocity = 12
export(float) var air_acceleration = 60
export(float) var ground_acceleration = 55
export(float) var ground_friction = 40
export(float) var gravity_constant = 25
export(float) var max_run_velocity = 13.0
export(float) var max_walk_velocity = 6.0
export(float) var max_velocity = 30.0 # meter per second
export(float) var max_jump_velocity_from_still = 2.0

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

	# set all weapon to equipped
	for i in weapons.keys():
		if weapons[i]:
			weapons[i].set_to_player_object()
			weapons[i].player = self

	_on_IHealth_health_changed(i_health.current_health, i_health.current_armor)


func _input(event):
	if !State.get_state("player_paused") and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var speed = Config.state.player.mouse_speed * mouse_sensitivity
		pivot.rotate_x(-event.relative.y * speed)
		rotate_y(-event.relative.x * speed)
		pivot.rotation.x = clamp(pivot.rotation.x, -PI/2 + 0.01, PI/2 - 0.01)

		mouse_movement = Vector2(clamp(event.relative.y, -mouse_turn_max_sensitivity, mouse_turn_max_sensitivity), clamp(event.relative.x, -mouse_turn_max_sensitivity, mouse_turn_max_sensitivity))
		is_mouse_moving_time = true


func _physics_process(delta: float) -> void:
	# TODO-BIG: refactor input so that it would be outside of this script
	#           this will ensure possibilities for multiplayer in the future

	if Input.is_action_just_pressed("ui_cancel"):
		State.set_state("player_paused", !State.get_state("player_paused"))

	handle_movement(get_movement_input(self.global_transform.basis), delta)
	handle_crouching(delta)

	handle_weapon_pickup()
	handle_weapon_drop()
	handle_weapon_reload()
	handle_weapon_selection()
	handle_gun_sway(delta)
	handle_flash_dissipation(delta)

	fire_to_direction(delta)
	apply_shooting_knockback(self, camera, weapon)

	# DEBUG: SELF INFLICTED DAMAGE
	if Input.is_action_just_pressed("ui_end"):
		i_health.change_health_and_armor(-23)

	State.set_state("player_weapon_name", weapon.weapon_name)
	State.set_state("player_weapon_current_ammo", weapon.current_ammo)
	State.set_state("player_weapon_total_ammo", weapon.current_total_ammo)


###########################################################
# Stateful function
###########################################################

### The body that's affected here is: Body size & position and Feet position only.
### When the body is reduced in height by N, it will go higher by N.
### The feet will follow the position of the body by getting higher N also.
### This process is reversible because of how crouching works which is:
###     * Crouch
###     * Come to normal
func handle_crouching(delta: float):
	# Handle pausing by zero-ing the input vector
	var is_paused = State.get_state("player_paused")

	if not is_paused and LLInput.is_action_pressed("player_crouch") or $Body.shape.height < body_original_height:
		is_crouching = true

	if not is_paused and not LLInput.is_action_pressed("player_crouch") and not headlimit_raycast.is_colliding():
		is_crouching = false

	if is_on_floor():
		if is_crouching:
			var crouch_delta = crouch_speed * delta
			var height_change = abs(crouch_height - body_original_height)
			var body_trans_target = body_original_local_translation + Vector3.DOWN * height_change / 2

			$Body.shape.height = move_toward($Body.shape.height, crouch_height, crouch_delta)
			$Body.transform.origin = $Body.transform.origin.move_toward(body_trans_target, crouch_delta / 2)
		else:
			var crouch_delta = crouch_speed * 1.5 * delta
			$Body.shape.height = move_toward($Body.shape.height, body_original_height, crouch_delta)
			$Body.transform.origin = $Body.transform.origin.move_toward(body_original_local_translation, crouch_delta / 2)

	else:
		if is_crouching:
			var height_change = abs(crouch_height - body_original_height)
			var body_trans_target = body_original_local_translation + Vector3.UP * height_change / 2

			$Body.shape.height = move_toward($Body.shape.height, crouch_height, crouch_speed * delta)
			$Body.transform.origin = $Body.transform.origin.move_toward(body_trans_target, crouch_speed * delta)
		else:
			var crouch_delta = crouch_speed * 1.5 * delta
			$Body.shape.height = move_toward($Body.shape.height, body_original_height, crouch_delta)
			$Body.transform.origin = $Body.transform.origin.move_toward(body_original_local_translation, crouch_delta)

	$Pivot.transform.origin = $Body.transform.origin + Vector3.UP * ($Body.shape.height / 2 - 1.0)
	$HeadLimitRayCast.transform.origin = $Body.transform.origin + Vector3.UP * ($Body.shape.height / 2)


# TODO: decouple these codes into other smaller more concise function
func handle_movement(input_vector: Vector3, delta: float):
	# Handle pausing by zero-ing the input vector
	var is_paused = State.get_state("player_paused")
	if is_paused:
		input_vector = Vector3.ZERO

	input_vector = input_vector.normalized()

	# vector used for snapping the character when on the ground
	var snap_vector = Vector3.ZERO

	if is_on_ceiling():
		desired_movement_velocity.y = 0

	# ON THE GROUND
	elif is_on_floor():
		# slide the input_vector so that it would be on the plane in which it walks
		var input_slanted = input_vector.slide(get_floor_normal()).normalized()
		snap_vector = -self.get_floor_normal()

		# Player walk action that will decrease max_velocity
		if LLInput.is_action_pressed("player_walk") and is_crouching:
			current_max_movement_velocity = max_walk_velocity * 0.815
		elif is_crouching:
			current_max_movement_velocity = max_walk_velocity
		elif LLInput.is_action_pressed("player_walk"):
			current_max_movement_velocity = max_walk_velocity
		else:
			current_max_movement_velocity = max_run_velocity

		# Apply Friction
		if input_slanted.length() > 0:
			if desired_movement_velocity.normalized().dot(input_slanted.normalized()) < -0.98:
				desired_movement_velocity = desired_movement_velocity.move_toward(input_slanted * current_max_movement_velocity, ground_acceleration * 2.5 * delta)
			elif is_crouching:
				desired_movement_velocity = desired_movement_velocity.move_toward(input_slanted * current_max_movement_velocity, ground_acceleration * 0.5 * delta)
			else:
				desired_movement_velocity = desired_movement_velocity.move_toward(input_slanted * current_max_movement_velocity, ground_acceleration * delta)
		else:
			desired_movement_velocity = apply_friction(desired_movement_velocity, ground_friction, delta)

	# IN THE AIR
	else:
		snap_vector = Vector3.ZERO

		# Temporarily disable velocity.y because we're about to calculate movement in the air
		# apart from the downward velocity of the player
		var current_gravity_velocity = desired_movement_velocity.y
		desired_movement_velocity.y = 0

		if input_vector.length() > 0:
			desired_movement_velocity = desired_movement_velocity.move_toward(input_vector * max_air_velocity, air_acceleration * delta)

		# Give back the original velocity.y after the air movement is calculated
		desired_movement_velocity.y = current_gravity_velocity

		desired_movement_velocity.y -= (gravity_constant * delta)
		current_max_movement_velocity = max_run_velocity

	# Jumping mechanics, affects desired_movement_velocity. this is because
	# the jumping height could be affected by the movement velocity, which is
	# affected by the angle of the surface.
	#
	# EXAMPLE: if the desired velocity isn't changed, player who went up a slope
	#          will have higher jumping velocity than the one going downwards.
	var action_pressed_jump = LLInput.consume_input("player_jump|pressed")
	var is_pressed_jump = Input.is_action_pressed("player_jump")
	if not is_paused and is_on_floor() and (action_pressed_jump or (auto_bhop and is_pressed_jump)):
		snap_vector = Vector3.ZERO
		max_air_velocity = max(desired_movement_velocity.length(), max_jump_velocity_from_still)
		desired_movement_velocity = Util.clamp_vector3(input_vector * current_max_movement_velocity, desired_movement_velocity.length())
		desired_movement_velocity.y = jump_impulse_velocity

	# clamp the velocity and gravity to max speed
	desired_movement_velocity = Util.clamp_vector3_y_axis(desired_movement_velocity, max_velocity)

	# apply to is_mouse_moving_time and slide
	# TODO: fix snapping to sides of walls when stepping fast away from it
	desired_movement_velocity = self.move_and_slide_with_snap(desired_movement_velocity, snap_vector, Vector3.UP, false, 4, 0.785398, false)

	State.set_state("debug_misc", str(stepify(desired_movement_velocity.length(), 0.01)))
	State.set_state("player_velocity_length", desired_movement_velocity.length())


func hide_all_weapon() -> void:
	for w in weapons.values():
		if w:
			w.hide()


func handle_weapon_selection() -> void:
	var is_paused = State.get_state("player_paused")

	if not is_paused:
		if Input.is_action_just_pressed("player_weapon_swap"):
			_switch_weapon_routine(last_weapon_used)
		if Input.is_action_just_pressed("player_weapon_gun_primary"):
			_switch_weapon_routine(Global.WEAPON_SLOT.PRIMARY)
		if Input.is_action_just_pressed("player_weapon_gun_secondary"):
			_switch_weapon_routine(Global.WEAPON_SLOT.SECONDARY)
		if Input.is_action_just_pressed("player_weapon_gun_knife"):
			_switch_weapon_routine(Global.WEAPON_SLOT.MELEE)
		if Input.is_action_just_pressed("player_cycle_grenade"):
			_switch_weapon_routine(Global.WEAPON_SLOT.UTILITY)


func fire_to_direction(delta) -> void:
	var is_paused = State.get_state("player_paused")

	# FIRST TRIGGER
	if not is_paused and LLInput.is_action_pressed("player_shoot_primary") and weapon.can_shoot() and weapon.trigger_on(delta):
		weapon.first_activate(pivot)

	if not is_paused and LLInput.is_action_released("player_shoot_primary"):
		weapon.trigger_off()


	# SECOND TRIGGER
	# TODO: make shooting routine to have many modes
	if not is_paused and LLInput.is_action_pressed("player_shoot_secondary") and weapon.second_trigger_on():
		pass

	if not is_paused and LLInput.is_action_released("player_shoot_secondary"):
		weapon.second_trigger_off()


func handle_weapon_drop() -> void:
	if Input.is_action_just_pressed("player_weapon_drop") and weapon.weapon_slot != Global.WEAPON_SLOT.MELEE:
		_drop_weapon(weapon)

# Unlike drop_weapon, this one will only remove it from the inventory and not add it to the world
func remove_weapon(weapon_slot):
	var w = weapons.get(weapon_slot)
	if w:
		# remove from child
		$Pivot/Camera/GunContainer.remove_child(w)

		# throw it into the world (for now just place it on the ground from where the camera origin is)
		Util.add_to_world(w)

		# make set_to_world_object
		w.set_to_world_object()

		# make the weapons (dict) currenly equipped to null
		if weapons[w.weapon_slot] == w:
			weapons[w.weapon_slot] = null

		if weapon == w:
			weapon = null

		# switch to the currently used weapon
		_switch_weapon_routine(current_weapon)


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
	var is_paused = State.get_state("player_paused")
	if not is_paused and LLInput.is_action_pressed("player_reload") and weapon.can_reload():
		State.set_state("player_reloaded", Engine.get_physics_frames())
		weapon.reload_trigger()


# Drop the given weapon and then return whether the weapon is dropped or not.
# Return true only when the weapon is dropped and false if the weapon can't be dropped.
func _drop_weapon(w: GenericWeapon) -> void:
	w.player = null
	w.unequip()
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
	w.global_rotate(Vector3(rand_range(-1, 1), rand_range(-1, 1), rand_range(-1, 1)).normalized(), PI * rand_range(0, 2))

	# add force to the gun
	w.apply_central_impulse(-camera.global_transform.basis.z * (10 + desired_movement_velocity.length() / 2))
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
	w.player = self
	w.equip()

	var existing_weapon = weapons[w.weapon_slot]

	var parent = w.get_parent()
	parent.remove_child(w)

	weapons[w.weapon_slot] = w

	# Add to gun container
	gun_container.add_child(w)
	w.global_transform = gun_container.get_global_transform()

	# Set the weapon to be equipped
	w.set_to_player_object()

	# TODO make an option for auto switch on pickup
	# Hide it at pickup
	w.hide()

	return existing_weapon


func _switch_weapon_routine(weapon_slot) -> void:
	hide_all_weapon()
	if weapon:
		weapon.unequip()

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
	weapon.equip()


# TODO: an effect where the player's sight is "nudged" when hit on the head
func handle_aim_punch() -> void:
	pass


func handle_gun_sway(delta) -> void:
	_handle_turning_sway(delta)
	_handle_movement_sway(delta)


# Will turn the gun left and right based on the head turn
# Modified version of this code https://godotengine.org/qa/68649/how-to-make-the-sway-effect-on-weapons-of-fps-3d-games
func _handle_turning_sway(delta) -> void:
	if is_mouse_moving_time:
		is_mouse_moving_time = false

		# Turning Up-Down
		var max_turn_up_down = 1
		var raw_next_x_rotation = move_toward(gun_container.rotation_degrees.x, gun_container.rotation_degrees.x - (mouse_movement.x), delta * 5)
		gun_container.rotation_degrees.x = clamp(raw_next_x_rotation, -max_turn_up_down, max_turn_up_down)

		# Turning Right-Left
		var max_turn_right_degree = 2.5
		var raw_next_y_rotation = move_toward(gun_container.rotation_degrees.y, gun_container.rotation_degrees.y - (mouse_movement.y), delta * 12)
		gun_container.rotation_degrees.y = clamp(raw_next_y_rotation, -max_turn_right_degree, max_turn_right_degree)
	else:
		# Recovery from moving to original rotation
		gun_container.rotation_degrees.x = move_toward(gun_container.rotation_degrees.x, gun_container_original_rotation.x, delta * 5)
		gun_container.rotation_degrees.y = move_toward(gun_container.rotation_degrees.y, gun_container_original_rotation.y, delta * 12)

func _handle_movement_sway(delta) -> void:
	var movement_ratio = min(desired_movement_velocity.length() / max_run_velocity, 1.0)

	var farthest_backward_sway = 0.08 * movement_ratio
	var backward_sway_destination = move_toward(gun_container.transform.origin.z, gun_container_original_transform.origin.z + farthest_backward_sway, delta)
	gun_container.transform.origin.z = backward_sway_destination

	var farthest_down_sway = -0.01 * movement_ratio
	var down_sway_destination = move_toward(gun_container.transform.origin.y, gun_container_original_transform.origin.y + farthest_down_sway, delta)
	gun_container.transform.origin.y = down_sway_destination



func handle_flash_dissipation(delta) -> void:
	var flash_color = Color(DEFAULT_FLASH_COLOR)
	flash_color.a = clamp(flash_remaining_second, 0, 1)
	flash_overlay.color = flash_color
	flash_remaining_second = clamp(flash_remaining_second - delta, 0, FLASH_MAXIMUM_DURATION)


###########################################################
# Static Function
###########################################################

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


###########################################################
# Signal Function
###########################################################


func _on_Area_body_entered(w):
	if w is GenericWeapon:
		if not weapons.get(w.weapon_slot) and w.is_auto_pickupable():
			_weapon_pickup_routine(w)


func _on_IHealth_health_changed(current_health: float, current_armor: float):
	State.set_state("player_health",  current_health)
	State.set_state("player_armor",  current_armor)


func _on_IHealth_dead():
	# TODO: add a routine to make the person dead and then respawn again
	pass


func _on_IFlash_flashed(flash_position: Vector3):
	var distance = clamp(camera.global_transform.origin.distance_to(flash_position), 0, FLASH_MAXIMUM_DISTANCE)
	var distance_ratio = range_lerp(distance, 0, FLASH_MAXIMUM_DISTANCE, 1, 0)

	var forward = -camera.global_transform.basis.z.normalized()
	var to_other = (flash_position - self.global_transform.origin).normalized()
	var angle = clamp(forward.angle_to(to_other), 0, FLASH_MAXIMUM_ANGLE)
	var angle_ratio = range_lerp(angle, 0, FLASH_MAXIMUM_ANGLE, 1, 0.1)

	var calc_flash_duration = FLASH_MAXIMUM_DURATION * distance_ratio * angle_ratio
	flash_remaining_second = clamp(calc_flash_duration, 0, FLASH_MAXIMUM_DURATION)
