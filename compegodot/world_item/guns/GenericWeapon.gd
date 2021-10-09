tool
extends RigidBody
class_name GenericWeapon


######################################
#       BULLET RELATED EXPORTS       #
######################################

# Amount of ammo in a magazine of the gun
# Disable with the value of -1
export (int) var magazine_ammo = 1

# Default total ammo that a gun has
# Disable with the value of -1
export (int) var total_ammo = 1

# The base damage inflicted for this gun
export (float) var base_damage = 100.0

# The gun's rounds per second. Use 0 to disable it
export (float) var round_per_second = 1

# The gun's maximum distance toward the target
export (float) var max_distance = 300.0



######################################
#       ENUM RELATED EXPORTS         #
######################################

# The type of the weapon
export (Global.WEAPON_TYPE) var weapon_type = Global.WEAPON_TYPE.SEMI_AUTOMATIC

# The slot that the weapon use if held by a player
export (Global.WEAPON_SLOT) var weapon_slot = Global.WEAPON_SLOT.PRIMARY



######################################
#       PATH RELATED EXPORTS         #
######################################

# The nodepath going to the animation player of the gun
export (NodePath) var gun_animation_player_path

# The nodepath going to the AudioStreamPlayer3D for shooting
export (NodePath) var gun_shoot_audio_player

# The nodepath going to the AudioStreamPlayer3D for when the gun is empty but the trigger is pulled
export (NodePath) var gun_shoot_empty_audio_player

# The nodepath going to the currently used mesh instance
export (NodePath) var gun_mesh_instance



######################################
#       ANIM RELATED EXPORTS         #
######################################

# The startup animation name in the gun AnimationPlayer
# For example, cocking the gun
export (String) var anim_startup_name = "startup"

# The shooting animation name in the gun AnimationPlayer
export (String) var anim_shoot_name = "shoot"

# The secondary animation name in the gun AnimationPlayer
export (String) var anim_shoot_secondary_name = "shoot_secondary"

# The reload animation name in the gun AnimationPlayer
export (String) var anim_reload_name = "reload"



######################################
#     INACCURACY RELATED EXPORTS     #
######################################

# An array of spray recoils that the gun will go through
export (Array, String) var spray_recoils = []

# An array of infinite spray recoils, used after spray_recoil is used up
export (Array, String) var spray_infinite_recoils = []

# The gun's spray reset time in second.
export (float) var spray_reset_time = 1

# The gun's inaccuracy scale
export (float) var inaccuracy_scale = 0

# The gun's movement
export (float) var movement_inaccuracy_multiplier = 1

# The gun's jumping inaccuracy
export (float) var jumping_inaccuracy_multiplier = 1



######################################
#         INTERNAL VARIABLES         #
######################################

# Interal reference to the gun animation player
var anim_player: AnimationPlayer

# Interal reference to the gun audio player
var shoot_audio_player: AudioStreamPlayer

# Interal reference to the empty gun audio player
var shoot_empty_audio_player: AudioStreamPlayer

# Internal timer reference for rate of fire
var rof_timer: Timer

# Internal timer reference for spray pattern
var spray_timer: Timer

# Internal timer to check whether this can be picked up or not
# Will be started as soon as it's into the world
# After it stops, the gun should be auto picked up again
var auto_pickupable_timer: Timer

# The index used for the spray recoil
var spray_array_index: int = 0

# The sum of the current spray's recoil
# Will get reset when spray timer reach 0
var spray_cummulative = [0.0, 0.0]

# Amount of ammo in the magazine/clip/whatever
var current_ammo = 0

# Amount of ammo that the gun has
var current_total_ammo = 0

# Flag to allow semi automatic or knife to be used
var semi_could_shoot = true

# An array of spray recoils that the gun will go through
var _spray_recoils = []

# An array of infinite spray recoils, used after spray_recoil is used up
var _spray_infinite_recoils = []


func _is_animation_player() -> bool:
	var test = get_node(gun_animation_player_path)
	return test and (test is AnimationPlayer)


func _is_shoot_audio_player() -> bool:
	var test = get_node(gun_shoot_audio_player)
	return test and (test is AudioStreamPlayer)


func _is_shoot_empty_audio_player() -> bool:
	var test = get_node(gun_shoot_empty_audio_player)
	return test and (test is AudioStreamPlayer)


func _is_gun_mesh_instance() -> bool:
	var test = get_node(gun_mesh_instance)
	return test and (test is MeshInstance)


func _get_configuration_warning() -> String:
	if not _is_animation_player():
		return "Set gun_animation_player_path to valid AnimationPlayer"
	if not _is_shoot_audio_player():
		return "Set gun_shoot_audio_player to valid AudioStreamPlayer"
	if not _is_shoot_empty_audio_player():
		return "Set gun_shoot_empty_audio_player to valid AudioStreamPlayer"
	if not _is_gun_mesh_instance():
		return "Set gun_mesh_instance to valid MeshInstance"

	return ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.editor_hint:
		# init anim
		anim_player = get_node(gun_animation_player_path)

		# init audio player
		shoot_audio_player = get_node(gun_shoot_audio_player)
		shoot_empty_audio_player = get_node(gun_shoot_empty_audio_player)

		# init rate of fire timer
		rof_timer = Timer.new()
		rof_timer.wait_time = 1.0 / round_per_second
		rof_timer.one_shot = true
		rof_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
		add_child(rof_timer)

		# init rate of fire timer
		spray_timer = Timer.new()
		spray_timer.wait_time = spray_reset_time
		spray_timer.one_shot = true
		spray_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
		add_child(spray_timer)
		Util.print_err(spray_timer.connect("timeout", self, "_on_spray_timer_timeout"))

		# init rate of fire timer
		auto_pickupable_timer = Timer.new()
		auto_pickupable_timer.wait_time = 1
		auto_pickupable_timer.one_shot = true
		auto_pickupable_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
		add_child(auto_pickupable_timer)

		# Init recoil arrays
		_spray_recoils = transform_to_recoil_array(spray_recoils)
		_spray_infinite_recoils =  transform_to_recoil_array(spray_infinite_recoils)

		# Init ammo count
		current_ammo = magazine_ammo
		current_total_ammo = total_ammo


func can_shoot() -> bool:
	var is_not_playing_reload = not (anim_player.current_animation == "reload")
	var is_not_starting_up = not (anim_player.current_animation == "startup")

	return rof_timer.is_stopped() and is_not_playing_reload and is_not_starting_up


func can_reload() -> bool:
	var is_not_playing_reload = not (anim_player.current_animation == "reload")
	var is_not_starting_up = not (anim_player.current_animation == "startup")
	var is_ammo_exist = current_total_ammo > 0
	var is_ammo_not_full = current_ammo < magazine_ammo

	return is_not_playing_reload and is_ammo_exist and is_ammo_not_full and is_not_starting_up


# Call when you want to animate and make a shooting sound
# Will also start the timer for round per minute
#
# Returns the state of the gun, whether it's firing or not
# It might not be able to fire because it's out of bullets for example
func trigger_on() -> bool:
	if weapon_type == Global.WEAPON_TYPE.SEMI_AUTOMATIC or weapon_type == Global.WEAPON_TYPE.KNIFE:
		if semi_could_shoot:
			var is_ammo_usable = _ammo_depletion_routine()
			semi_could_shoot = false
			if is_ammo_usable:
				shoot_audio_player.play()
				rof_timer.start()
				anim_player.stop()
				anim_player.play(anim_shoot_name)
				_spray_routine()
				return true
			else:
				shoot_empty_audio_player.play()
				return false
	elif weapon_type == Global.WEAPON_TYPE.AUTOMATIC:
		var is_ammo_usable = _ammo_depletion_routine()
		if is_ammo_usable:
			shoot_audio_player.play()
			rof_timer.start()
			anim_player.stop()
			anim_player.play(anim_shoot_name)
			_spray_routine()
			return true

		if semi_could_shoot:
			semi_could_shoot = false
			shoot_empty_audio_player.play()
			return false

	return false


func trigger_off() -> void:
	semi_could_shoot = true


# TODO add second audio
func second_trigger_on() -> void:
	if weapon_type == Global.WEAPON_TYPE.KNIFE:
		rof_timer.start()
		anim_player.stop()
		anim_player.play(anim_shoot_secondary_name)


func second_trigger_off() -> void:
	if weapon_type == Global.WEAPON_TYPE.KNIFE:
		pass


func reload_trigger() -> void:
	anim_player.stop()
	anim_player.play(anim_reload_name)


# A reload routine that's supposed to be used by the animation player
# when the magazine is already in the gun and ready to shoot again
func _reload_routine() -> void:
	if total_ammo > 0:
		var needed_ammo = magazine_ammo - current_ammo
		var next_total_ammo = current_total_ammo - needed_ammo

		if needed_ammo > current_total_ammo:
			current_ammo += current_total_ammo
		else:
			current_ammo = magazine_ammo

		current_total_ammo = max(next_total_ammo, 0)
	else:
		current_ammo = magazine_ammo


func set_to_equipped() -> void:
	var gun_mesh: MeshInstance = get_node(gun_mesh_instance)
	gun_mesh.layers = Global.RENDER_LAYERS.PLAYER
	gun_mesh.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF

	self.mode = RigidBody.MODE_KINEMATIC
	self.collision_layer = 0
	self.collision_mask = 0


func set_to_world_object() -> void:
	var gun_mesh: MeshInstance = get_node(gun_mesh_instance)
	gun_mesh.layers = Global.RENDER_LAYERS.WORLD
	gun_mesh.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF

	self.mode = RigidBody.MODE_RIGID
	self.collision_layer = Global.PHYSICS_LAYERS.GUN
	self.collision_mask = Global.PHYSICS_LAYERS.WORLD

	auto_pickupable_timer.start()
	semi_could_shoot = false


func is_auto_pickupable() -> bool:
	return auto_pickupable_timer.is_stopped()


func _spray_routine():
	spray_timer.start()
	var spray = get_spray_inaccuracy(spray_array_index)

	var ratio = spray_timer.time_left / spray_timer.wait_time

	spray_cummulative[0] = spray_cummulative[0] * ratio + spray[0] * ratio
	spray_cummulative[1] = spray_cummulative[1] * ratio + spray[1] * ratio
	spray_array_index += 1


func _ammo_depletion_routine() -> bool:
	var next_ammo = current_ammo - 1
	current_ammo = max(next_ammo, 0)

	return next_ammo >= 0 or magazine_ammo < 0


func transform_to_recoil_array(recoil_array: Array) -> Array:
	var result = []
	result.resize(recoil_array.size())

	for i in range(recoil_array.size()):
		var recoil = recoil_array[i]
		result[i] = parse_json(recoil)

	return result


func get_spray_inaccuracy(spray_index: int):
	var default_recoil = [0.0, 0.0]

	if spray_index > _spray_recoils.size() - 1:
		var infinite_index = spray_index - _spray_recoils.size()
		infinite_index = wrapi(infinite_index, 0, _spray_infinite_recoils.size())

		return Util.array_get(_spray_infinite_recoils, infinite_index, default_recoil).duplicate()

	else:
		return Util.array_get(_spray_recoils, spray_index, default_recoil).duplicate()


# Will do a routine where the gun is switched on to
# For example, playing an unskippable startup animation like cocking the gun
func activate():
	anim_player.play("startup")


# Will do a routine where everything that's running will be reseted
# For example, reseting a reload animation in the middle.
func deactivate():
	anim_player.stop()


# Will give a dictionary of inherent and spray inaccuracy filled with the
# vertical and horizontal, measured in radians.
#
# For example:
# {
#     "inherent": [1.1, 1.2]
#     "spray": [-2.1, -2.2]
# }
#
# Means the inherent inaccuracy will go up and right by 1.1 and 1.2 radian respectively.
# It also means, the spray inaccuracy will down and left by 2.1 and 2.2 radian respectively.
func get_inaccuracy() -> Dictionary:
	randomize()
	return {
		"inherent": [
			rand_range(-inaccuracy_scale, inaccuracy_scale),
			rand_range(-inaccuracy_scale, inaccuracy_scale)
		],

		"spray": spray_cummulative
	}


# BUG: first shot will always have get_aim_punch_ratio of 0
func get_knockback_inaccuracy():
	var spray = get_spray_inaccuracy(spray_array_index + 1)

	var aim_punch_ratio = spray_timer.time_left / spray_timer.wait_time

	spray[0] = (spray_cummulative[0] * aim_punch_ratio + spray[0] * aim_punch_ratio) * 0.5
	spray[1] = (spray_cummulative[1] * aim_punch_ratio + spray[1] * aim_punch_ratio) * 0.5

	return spray


func get_aim_punch_ratio() -> float:
	return spray_timer.time_left / spray_timer.wait_time


func _on_spray_timer_timeout() -> void:
	spray_array_index = 0
	spray_cummulative = [0.0, 0.0]
