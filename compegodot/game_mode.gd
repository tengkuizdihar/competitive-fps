extends Node

const player_scene = preload("res://player/Player.tscn")
const player_group_names = [Global.SPAWN_TYPE_GROUP.UNIVERSAL, Global.SPAWN_TYPE_GROUP.TEAM_1, Global.SPAWN_TYPE_GROUP.TEAM_2]

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
		_:
			print_stack()
			printerr("Game Mode Doesn't Exist")


###########################################################
# GAME MODE SECTION
#
# gmd => Game Mode DEFAULT
# glc => Game Mode LONG_COMPETITIVE
# gsc => Game Mode SHORT_COMPETITIVE
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