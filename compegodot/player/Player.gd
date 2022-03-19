extends KinematicBody

###########################################################
# Interfaces
###########################################################

onready var i_health = $IHealth

###########################################################
# Variables
###########################################################

### INFO - MAGIC_ON_GROUND_GRAVITY
### Is a constant used by the kinematic for making the player stay on the ground.
### For example: It's used so that the player wouldn't fly off when going up and down
###              ramps.
const MAGIC_ON_GROUND_GRAVITY = 2.5 # m/s

onready var headlimit_raycast = $HeadLimitRayCast
onready var normal_input_direction = Vector3.ZERO # will be changed by outside actors
onready var camera = $Pivot/Camera
onready var pivot = $Pivot
onready var mouse_sensitivity = 0.0008  # radians/pixel, TODO: refactor to game settings

### Gun Variables
onready var gun_container = $Pivot/Camera/GunContainer
onready var weapon: GenericWeapon = $Pivot/Camera/GunContainer/RF7
onready var current_weapon = Global.WEAPON_SLOT.PRIMARY
onready var last_weapon_used = Global.WEAPON_SLOT.PRIMARY
onready var weapons = {
	Global.WEAPON_SLOT.PRIMARY: $Pivot/Camera/GunContainer/RF7,
	Global.WEAPON_SLOT.SECONDARY: $Pivot/Camera/GunContainer/PM9,
	Global.WEAPON_SLOT.MELEE: $Pivot/Camera/GunContainer/KF1
}

### The currently used max velocity for movement input
var current_max_movement_velocity = max_run_velocity

### The desired movement_velocity stored for acceleration purposes.
var desired_movement_velocity = Vector3()

### The the max XZ velocity when in the air
var max_air_velocity = 0

### Flag for crouching
var is_crouching = false
var debug_position_one_frame_ago = Vector3.ZERO
var held_weapon = null


onready var pivot_original_local_translation = $Pivot.transform.origin
onready var body_original_local_translation = $Body.transform.origin
onready var body_original_height = $Body.shape.height
onready var feet_original_local_translation = $Feet.transform.origin
onready var crouch_height = 1.75

export(bool) var auto_bhop = true
export(float) var crouch_speed = 5.5 # meter per second
export(float) var jump_impulse_velocity = 12
export(float) var air_acceleration = 70
export(float) var ground_acceleration = 60
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
			weapons[i].set_to_equipped()

	_on_IHealth_health_changed(i_health.current_health, i_health.current_armor)

func _input(event):
	if !State.get_state("player_paused") and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var speed = Config.state.player.mouse_speed * mouse_sensitivity
		pivot.rotate_x(-event.relative.y * speed)
		rotate_y(-event.relative.x * speed)
		pivot.rotation.x = clamp(pivot.rotation.x, -PI/2 + 0.01, PI/2 - 0.01)


func _physics_process(delta: float) -> void:
	# TODO-BIG: refactor input so that it would be outside of this script
	#           this will ensure possibilities for multiplayer in the future

	if Input.is_action_just_pressed("ui_cancel"):
		State.set_state("player_paused", !State.get_state("player_paused"))

	handle_movement(get_movement_input(self.global_transform.basis), delta)
	manage_crouching(delta)

	handle_weapon_pickup()
	handle_weapon_drop()
	handle_weapon_reload()
	handle_weapon_selection()

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
func manage_crouching(delta: float):
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
			$Feet.transform.origin = $Body.transform.origin + Vector3.DOWN * ($Body.shape.height / 2 + $Body.shape.radius) + Vector3.UP * $Feet.shape.height / 2
		else:
			var crouch_delta = crouch_speed * 1.5 * delta
			$Body.shape.height = move_toward($Body.shape.height, body_original_height, crouch_delta)
			$Body.transform.origin = $Body.transform.origin.move_toward(body_original_local_translation, crouch_delta / 2)
			$Feet.transform.origin = $Body.transform.origin + Vector3.DOWN * ($Body.shape.height / 2 + $Body.shape.radius) + Vector3.UP * $Feet.shape.height / 2

	else:
		if is_crouching:
			var height_change = abs(crouch_height - body_original_height)
			var body_trans_target = body_original_local_translation + Vector3.UP * height_change / 2
			var feet_trans_target = feet_original_local_translation + Vector3.UP * height_change

			$Body.shape.height = move_toward($Body.shape.height, crouch_height, crouch_speed * delta)
			$Body.transform.origin = $Body.transform.origin.move_toward(body_trans_target, crouch_speed * delta)
			$Feet.transform.origin = $Feet.transform.origin.move_toward(feet_trans_target, crouch_speed * delta)
		else:
			var crouch_delta = crouch_speed * 1.5 * delta
			$Body.shape.height = move_toward($Body.shape.height, body_original_height, crouch_delta)
			$Body.transform.origin = $Body.transform.origin.move_toward(body_original_local_translation, crouch_delta)
			$Feet.transform.origin = $Feet.transform.origin.move_toward(feet_original_local_translation, crouch_delta)

	$Pivot.transform.origin = $Body.transform.origin + Vector3.UP * $Body.shape.height / 2
	$HeadLimitRayCast.transform.origin = $Body.transform.origin + Vector3.UP * ($Body.shape.height / 2 + $Body.shape.radius)


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

	# apply to move and slide
	desired_movement_velocity = self.move_and_slide_with_snap(desired_movement_velocity, snap_vector, Vector3.UP, false, 4, 0.785398, false)

	State.set_state("debug_player_velocity", stepify(desired_movement_velocity.length(), 0.01))
	State.set_state("debug_misc", str(desired_movement_velocity.length()))
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


func fire_to_direction(delta) -> void:
	var is_paused = State.get_state("player_paused")

	# FIRST TRIGGER
	if not is_paused and LLInput.is_action_pressed("player_shoot_primary") and weapon.can_shoot() and weapon.trigger_on(delta):
		shooting_routine(self, pivot, weapon)

	if not is_paused and LLInput.is_action_released("player_shoot_primary"):
		weapon.trigger_off()


	# SECOND TRIGGER
	# TODO: make shooting routine to have many modes
	if not is_paused and LLInput.is_action_pressed("player_shoot_secondary"):
		weapon.second_trigger_on()
	if not is_paused and LLInput.is_action_released("player_shoot_secondary"):
		weapon.second_trigger_off()


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
	var is_paused = State.get_state("player_paused")
	if not is_paused and LLInput.is_action_pressed("player_reload") and weapon.can_reload():
		State.set_state("player_reloaded", Engine.get_physics_frames())
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
# Static Function
###########################################################

static func shooting_routine(player, p: Spatial, w: GenericWeapon) -> void:
	var from = p.global_transform.origin
	var direction = get_shooting_direction(player, p, w)
	var remaining_distance = w.max_distance

	var interacted = {}

	var ray_count = 0
	while remaining_distance > 0:
		ray_count += 1

		var to = null
		if ray_is_in_object(ray_count):
			to = from + direction * remaining_distance
		else:
			to = from + direction * w.max_distance

		var space_state = player.get_world().direct_space_state
		var shootable_collision_mask = Global.PHYSICS_LAYERS.WORLD | Global.PHYSICS_LAYERS.GUN
		var ray_result = space_state.intersect_ray(from, to, [player] + interacted.keys(), shootable_collision_mask)
		var colliding = ray_result.get("collider")

		if colliding:
			var collision_point = ray_result.position
			var collision_normal = ray_result.normal
			# only interact with objects which we haven't interacted yet in this physics frame
			if !interacted.has(colliding):
				# change the health based on the weapon's damage
				if "i_health" in colliding:
					# TODO: Make this to be a bit more complicated. Yes, complicated.
					var damage = ceil(-w.base_damage / float(ray_count))

					colliding.i_health.change_health_and_armor(damage)

					# tag this object as interacted
					interacted[colliding] = null

				# interact with the object if interface exist
				if "i_interact" in colliding:
					colliding.i_interact.interact()

					# tag this object as interacted
					interacted[colliding] = null

				# push the object if it's hit by the weapon
				if colliding is RigidBody:
					var imp_direction = -p.global_transform.basis.z.normalized()
					colliding.apply_impulse(collision_point - colliding.global_transform.origin, imp_direction * 10)

					# tag this object as interacted
					interacted[colliding] = null

			spawn_spark(collision_point)
			spawn_bullet_hole(colliding, collision_point, collision_normal)

			# Will only use the penetration if the ray is coming from outside of the thing and then inside
			# penetration will reduce the effective range of a bullet
			var penetration_coeficient = Global.get_material_penetration_coefficient(colliding)
			remaining_distance = min(max(remaining_distance / penetration_coeficient, 0), w.max_distance)
			from = collision_point + direction * 0.001
		else:
			remaining_distance = 0


static func ray_is_in_object(ray_count: int) -> bool:
	return (ray_count % 2) == 0


static func spawn_spark(collision_point: Vector3) -> void:
	var sparks = preload("res://world_item/spark.tscn").instance()
	Util.add_to_world(sparks)
	sparks.global_transform.origin = collision_point


static func spawn_bullet_hole(colliding: Spatial, collision_point: Vector3, collision_normal: Vector3) -> void:
	# free nodes in group if it exceeds an arbitrary number of nodes
	Util.free_in_group_when_exceeding(Global.GROUP.DECAL_BULLET, Config.state.game.bullet_decal_max)

	var bullet_hole = preload("res://world_item/environments/BulletHole.tscn").instance()

	# use the local coordinate of an object so it also moves when it moves
	colliding.add_child(bullet_hole)
	bullet_hole.global_transform.origin = collision_point

	# NOTE: this code is ugly because look_at is broken when the UP vector is perpendicular with the normal
	# BUG: What the fuck is this minus 0 kind of bullshit?! https://github.com/godotengine/godot/blob/f28771b7a8e88a134076037a3cca1affc882e58a/scene/3d/spatial.cpp#L672
	if Vector3.UP.cross(collision_normal).is_equal_approx(Vector3()):
		bullet_hole.rotation_degrees.x = 90
	else:
		bullet_hole.look_at(collision_point + collision_normal, Vector3.UP)

	# Randomly rotate the bullet hole to add some variance
	bullet_hole.rotation_degrees.z = rand_range(0, 355)


static func get_shooting_direction(player, p: Spatial, w: GenericWeapon) -> Vector3:
	var forward = -p.global_transform.basis.z

	var movement_ratio_to_still = player.desired_movement_velocity.length() / player.max_run_velocity
	var movement_modifier = 1 + (movement_ratio_to_still * w.movement_inaccuracy_multiplier)
	var jumping_modifier = 1 + (int(!player.is_on_floor())  * w.jumping_inaccuracy_multiplier)

	var inaccuracy = w.get_inaccuracy(movement_modifier, jumping_modifier)

	var inh_inacc = inaccuracy.inherent
	var spr_inacc = inaccuracy.spray

	var total_horizontal_inaccuracy = inh_inacc[0] + spr_inacc[0]
	var total_vertical_inaccuracy = inh_inacc[1] + spr_inacc[1]

	# If rotated by a positive number, it goes to the right, vice versa
	var horizontalized = forward.rotated(-p.global_transform.basis.y, total_horizontal_inaccuracy)

	# If rotated by a positive number, it goes to the top, vice versa
	var verticalized = horizontalized.rotated(p.global_transform.basis.x, total_vertical_inaccuracy)
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
