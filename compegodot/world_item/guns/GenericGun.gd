tool
extends Spatial
class_name GenericGun

# The nodepath going to the animation player of the gun
export (NodePath) var gun_animation_player_path

# The nodepath going to the AudioStreamPlayer3D for shooting
export (NodePath) var gun_shoot_audio_player

# The shooting animation name in the gun AnimationPlayer
export (String) var anim_shoot_name = "shoot"

# The base damage inflicted for this gun
export (float) var base_damage = 100.0

# The gun's rounds per second. Use 0 to disable it
export (float) var round_per_second = 1

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


func _get_configuration_warning() -> String:
	if not _is_animation_player():
		return "Set gun_animation_player_path to valid AnimationPlayer"
	if not _is_shoot_audio_player():
		return "Set gun_shoot_audio_player to valid AudioStreamPlayer"

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
func shoot_routine() -> void:
	shoot_audio_player.play()
	rof_timer.start()
	anim_player.stop()
	anim_player.play(anim_shoot_name)
