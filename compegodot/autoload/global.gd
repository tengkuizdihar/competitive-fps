extends Node


###########################################################
# GLOBALLY USED FUNCTIONS
# Any function that need to be applied globally
###########################################################

func _ready():
	Util.handle_err(get_tree().connect("node_added", self, "_on_tree_node_added"))


func _on_tree_node_added(node: Node) -> void:
	if node is Light:
		make_light_available_every_layer(node)


func make_light_available_every_layer(node: Light) -> void:
	node.layers = MAX_INT


###########################################################
# GLOBALLY USED CONSTANTS
# Anything that's copy by value and could be a constant
###########################################################

const PHI = 1.61803399
const MATERIAL_GROUP_PREFIX = "MATERIAL__"
const MAX_INT = 9223372036854775807


###########################################################
# GLOBALLY USED ENUM + CLASSES
# Basically enums, but with values other than an integer
###########################################################

class GROUP:
	const LEVEL = "LEVEL"
	const DECAL_BULLET = "DECAL_BULLET"


class SPAWN_TYPE_GROUP:
	const UNIVERSAL = "SPAWN_TYPE_GROUP__UNIVERSAL"
	const TEAM_1 = "SPAWN_TYPE_GROUP__TEAM_1"
	const TEAM_2 = "SPAWN_TYPE_GROUP__TEAM_2"


# The values inside of MATERIAL should be added to physical bodies
class MATERIAL:
	const GENERIC = "MATERIAL__GENERIC"
	const WOOD = "MATERIAL__WOOD"
	const GLASS = "MATERIAL__GLASS"

###########################################################
# GLOBALLY USED ENUMS
# Enums that are used... Globally...
###########################################################

enum GAME_MODE {
	# The player will be spawned in immediately to a universal spawn point
	# and will be respawned in that spawn point when they die.
	DEFAULT = 1,

	# A competitive mode that's taking the default amount of rounds to win
	LONG_COMPETITIVE,

	# A competitive mode that's taking a shorter amount of rounds to win
	SHORT_COMPETITIVE
}

enum WEAPON_TYPE {
	AUTOMATIC,
	SEMI_AUTOMATIC,
	SNIPER_SEMI_AUTOMATIC,
	KNIFE,
	FRAG_GRENADE,
	FLASH_GRENADE
}

enum WEAPON_SLOT {
	PRIMARY,
	SECONDARY,
	MELEE,
	UTILITY
}

enum RENDER_LAYERS {
	WORLD = 1,
	PLAYER = 2
}

enum PHYSICS_LAYERS {
	WORLD = 1,
	TEAM_1 = 2,
	TEAM_2 = 4,
	GUN = 8,
	MISC_CLIP = 16 # For physics object that's supposed to influence others but are not player related.
}

enum WEAPON_ZOOM_MODE {
	DEFAULT,
	SNIPER_ZOOMED_1,
	SNIPER_ZOOMED_2
}

enum SHOOTING_TARGET_MOVEMENT_MODE {
	STATIC,
	MOVING,
}


###########################################################
# GLOBALLY USED FUNCTIONS
# Most of the time to map enum with their respective values
###########################################################

func get_material_penetration_coefficient(node: Node) -> float:
	var value = get_material_groups(node)
	return match_material_penetration_coeficient(value)


func get_material_groups(node: Node):
	var result = Util.get_groups_with_prefix(node, MATERIAL_GROUP_PREFIX)

	# NOTE: I'm using this ugly code because the engine will get mad if I use .front() on an empty array
	if result.size() > 0:
		return result.front()
	else:
		return null


func match_material_penetration_coeficient(surface_id) -> float:
	match surface_id:
		MATERIAL.GENERIC:
			return 300.0
		MATERIAL.WOOD:
			return 100.0
		MATERIAL.GLASS:
			return 10.0
		_:
			return 300.0
