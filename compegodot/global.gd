extends Node

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

class GROUP:
	const LEVEL = "LEVEL"

const PHI = 1.61803399
