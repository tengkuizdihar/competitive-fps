extends Node

const player_scene = preload("res://player/player.tscn")
const player_group_names = [Global.SPAWN_TYPE_GROUP.UNIVERSAL, Global.SPAWN_TYPE_GROUP.TEAM_1, Global.SPAWN_TYPE_GROUP.TEAM_2]
const player_weapon_no_recoil_infinite = preload("res://world_item/guns/infinite_semi_auto_pistol.tscn")

var registered_player = {}

func _ready():
	Util.handle_err(get_tree().connect("node_added", self, "_on_tree_node_added"))

###########################################################
# GAME MODE GENERAL
###########################################################

func handle_added_player(player: Node):
	registered_player[player] = null

	# Connect i health when dead and add the player themselves as binding value
	if "i_health" in player:
		player.i_health.connect("dead", self, "_on_player_ihealth_dead", [player])


func handle_new_level(level: Node):
	var game_mode = State.get_state("game_mode")

	match game_mode:
		Global.GAME_MODE.DEFAULT:
			gmd_handle_new_level(level)
		Global.GAME_MODE.AIM_TRAINING:
			gmat_handle_new_level(level)
		_:
			print_stack()
			printerr("Game Mode Doesn't Exist")


###########################################################
# GAME MODE SECTION
#
# gmd  => Game Mode DEFAULT
# glc  => Game Mode LONG_COMPETITIVE
# gsc  => Game Mode SHORT_COMPETITIVE
# gmat => Game Mode AIM_TRAINING
###########################################################


func gmd_handle_new_level(_level):
	# Resurrect Them
	# TODO: only work for single player
	var universal_spawn_point = get_tree().get_nodes_in_group(Global.SPAWN_TYPE_GROUP.UNIVERSAL).pop_front()
	var new_player = player_scene.instance()
	new_player.global_transform = universal_spawn_point.global_transform

	# Add To World
	# Consequently, will be handled by handle_added_player automagically in _on_tree_node_added
	Util.add_to_world(new_player)


func gmd_handle_player_dead(player):
	# Kill The Player
	registered_player.erase(player)
	player.queue_free()

	# Resurrect Them
	# TODO: only work for single player
	var universal_spawn_point = get_tree().get_nodes_in_group(Global.SPAWN_TYPE_GROUP.UNIVERSAL).pop_front()
	var new_player = player_scene.instance()
	new_player.global_transform = universal_spawn_point.global_transform

	# Add To World
	# Consequently, will be handled by handle_added_player automagically in _on_tree_node_added
	Util.add_to_world(new_player)


func gmat_handle_new_level(_level):
	# Resurrect Them
	# TODO: only work for single player
	var universal_spawn_point = get_tree().get_nodes_in_group(Global.SPAWN_TYPE_GROUP.UNIVERSAL).pop_front()
	var new_player = player_scene.instance()
	new_player.global_transform = universal_spawn_point.global_transform

	# Add To World
	# Consequently, will be handled by handle_added_player automagically in _on_tree_node_added
	Util.add_to_world(new_player)

	# give player gun with infinite ammo and no recoil
	var aiming_weapon = player_weapon_no_recoil_infinite.instance()
	Util.add_to_world(aiming_weapon)
	new_player.replace_weapon_and_free_existing(aiming_weapon)
	new_player._switch_weapon_routine(aiming_weapon.weapon_slot)

	# disable player movement input (aiming is still enabled) and processing
	new_player.disable_movement = true

	# disable player throwing guns (using "g")
	new_player.disable_weapon_drop = true


###########################################################
# SIGNAL HANLDER
###########################################################

func _on_tree_node_added(node: Node) -> void:
	if Util.is_in_either_group(node, player_group_names):
		yield(node, "ready") # Node must be ready before processing
		handle_added_player(node)
	if node.is_in_group(Global.GROUP.LEVEL):
		yield(node, "ready")
		handle_new_level(node)


func _on_player_ihealth_dead(player):
	var game_mode = State.get_state("game_mode")

	match game_mode:
		Global.GAME_MODE.DEFAULT:
			gmd_handle_player_dead(player)
		_:
			print_stack()
			printerr("Game Mode Doesn't Exist")
