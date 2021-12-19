extends Node

###########################################################
# GLOBALLY USED CONSTANTS
# Anything that's copy by value and could be a constant
###########################################################

const PHI = 1.61803399
const MATERIAL_GROUP_PREFIX = "MATERIAL__"

###########################################################
# GLOBALLY USED ENUM + CLASSES
# Basically enums, but with values other than an integer
###########################################################

class GROUP:
	const LEVEL = "LEVEL"
	const DECAL_BULLET = "DECAL_BULLET"


# The values inside of MATERIAL should be added to physical bodies
class MATERIAL:
	const GENERIC = "MATERIAL__GENERIC"
	const WOOD = "MATERIAL__WOOD"
	const GLASS = "MATERIAL__GLASS"

###########################################################
# GLOBALLY USED ENUMS
# Enums that are used... Globally...
###########################################################

enum WEAPON_TYPE {
	AUTOMATIC,
	SEMI_AUTOMATIC,
	SNIPER_SEMI_AUTOMATIC,
	KNIFE
}

enum WEAPON_SLOT {
	PRIMARY,
	SECONDARY,
	MELEE
}

enum RENDER_LAYERS {
	WORLD = 1,
	PLAYER = 2
}

enum PHYSICS_LAYERS {
	WORLD = 1,
	TEAM_1 = 2,
	TEAM_2 = 4,
	GUN = 8
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
			return 100.0
		MATERIAL.WOOD:
			return 10.0
		MATERIAL.GLASS:
			return 5.0
		_:
			return 100.0
