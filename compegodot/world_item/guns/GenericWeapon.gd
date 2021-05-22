tool
extends RigidBody
class_name GenericWeapon

# The type of the weapon
export (Global.WEAPON_TYPE) var weapon_type = Global.WEAPON_TYPE.SEMI_AUTOMATIC

# The slot that the weapon use if held by a player
export (Global.WEAPON_SLOT) var weapon_slot = Global.WEAPON_SLOT.PRIMARY

# The nodepath going to the animation player of the gun
export (NodePath) var gun_animation_player_path

# The nodepath going to the AudioStreamPlayer3D for shooting
export (NodePath) var gun_shoot_audio_player

# The nodepath going to the currently used mesh instance
export (NodePath) var gun_mesh_instance

# The shooting animation name in the gun AnimationPlayer
export (String) var anim_shoot_name = "shoot"

# The secondary animation name in the gun AnimationPlayer
export (String) var anim_shoot_secondary_name = "shoot_secondary"

# The base damage inflicted for this gun
export (float) var base_damage = 100.0

# The gun's rounds per second. Use 0 to disable it
export (float) var round_per_second = 1

# The gun's maximum distance toward the target
export (float) var max_distance = 300.0

# Interal reference to the gun animation player
var anim_player: AnimationPlayer

# Interal reference to the gun audi player
var shoot_audio_player: AudioStreamPlayer

# Internal timer reference for rate of fire
var rof_timer: Timer

func _is_animation_player() -> bool:
	var test = get_node(gun_animation_player_path)
	return test and (test is AnimationPlayer)


func _is_shoot_audio_player() -> bool:
	var test = get_node(gun_shoot_audio_player)
	return test and (test is AudioStreamPlayer)


func _is_gun_mesh_instance() -> bool:
	var test = get_node(gun_mesh_instance)
	return test and (test is MeshInstance)


func _get_configuration_warning() -> String:
	if not _is_animation_player():
		return "Set gun_animation_player_path to valid AnimationPlayer"
	if not _is_shoot_audio_player():
		return "Set gun_shoot_audio_player to valid AudioStreamPlayer"
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

		# init rate of fire timer
		rof_timer = Timer.new()
		rof_timer.wait_time = 1.0 / round_per_second
		rof_timer.one_shot = true
		rof_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
		add_child(rof_timer)


func can_shoot() -> bool:
	return rof_timer.is_stopped()


# Call when you want to animate and make a shooting sound
# Will also start the timer for round per minute
func trigger_on() -> void:
	if Global.WEAPON_TYPE.SEMI_AUTOMATIC or Global.WEAPON_TYPE.KNIFE:
		shoot_audio_player.play()
		rof_timer.start()
		anim_player.stop()
		anim_player.play(anim_shoot_name)

func trigger_off() -> void:
	if Global.WEAPON_TYPE.SEMI_AUTOMATIC:
		pass


# TODO add second audio
func second_trigger_on() -> void:
	if Global.WEAPON_TYPE.KNIFE:
		rof_timer.start()
		anim_player.stop()
		anim_player.play(anim_shoot_secondary_name)


func second_trigger_off() -> void:
	if Global.WEAPON_TYPE.KNIFE:
		pass


func set_to_equipped() -> void:
	var gun_mesh: MeshInstance = get_node(gun_mesh_instance)
	gun_mesh.layers = 2

	self.mode = RigidBody.MODE_KINEMATIC
	self.collision_layer = 0
	self.collision_mask = 0


func set_to_world_object() -> void:
	var gun_mesh: MeshInstance = get_node(gun_mesh_instance)
	gun_mesh.layers = 1

	self.mode = RigidBody.MODE_RIGID
	self.collision_layer = 1
	self.collision_mask = 1
