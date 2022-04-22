tool
extends GenericWeapon
class_name Grenade

export (float) var nade_fuse_time = 2.0
export (PackedScene) var explosion_scene = null # TODO: probably create another child class for FragGrenade?
export (PackedScene) var explosion_sound_scene = null # TODO: probably create another child class for FragGrenade?
export (NodePath) var influence_area_path = null

var influence_area = null
var influence_area_range = 0

func _get_configuration_warning():
	var parent_config_warning = ._get_configuration_warning()
	if parent_config_warning != "":
		return parent_config_warning

	if not _is_influence_area():
		return "Set influence_area_path to valid Area"
	return ""


func _ready():
	if !Engine.editor_hint:
		Util.handle_err(anim_player.connect("animation_finished", self, "_on_AnimationPlayer_animation_finished"))

		# INIT Influence Area
		influence_area = get_node(influence_area_path)
		influence_area_range = ((influence_area.get_child(0)).shape as SphereShape).radius


func _active_grenade_routine():
	if weapon_type == Global.WEAPON_TYPE.FRAG_GRENADE:
		yield(get_tree().create_timer(nade_fuse_time), "timeout")

		var explosion_sound = explosion_sound_scene.instance()
		Util.add_to_world(explosion_sound)
		explosion_sound.global_transform.origin = global_transform.origin
		explosion_sound.play()

		var ray_results = _get_ray_results_of_frag_influenced_objects()
		for r in ray_results:
			_apply_damage(r)
			_apply_impulse(r)

		var explosion_effect_size = 20
		var explosion_effect_node = explosion_scene.instance()
		var translate_then_scale_xform = Transform().scaled(Vector3.ONE * explosion_effect_size)
		translate_then_scale_xform.origin = global_transform.origin

		explosion_effect_node.global_transform = translate_then_scale_xform
		explosion_effect_node.emitting = true
		Util.add_to_world(explosion_effect_node)

		queue_free()
	if weapon_type == Global.WEAPON_TYPE.FLASH_GRENADE:
		yield(get_tree().create_timer(nade_fuse_time), "timeout")

		var explosion_sound = explosion_sound_scene.instance()
		Util.add_to_world(explosion_sound)
		explosion_sound.global_transform.origin = global_transform.origin
		explosion_sound.play()

		var ray_results = _get_ray_results_of_flash_influenced_players()
		for r in ray_results:
			_apply_flashbang(r)

		queue_free()

# Will give an array of ray_result back
func _get_ray_results_of_frag_influenced_objects() -> Array:
	var overlapping_bodies = influence_area.get_overlapping_bodies()
	var result = []

	# For rays
	var space_state = get_world().direct_space_state
	var from = global_transform.origin
	var shootable_collision_mask = Global.PHYSICS_LAYERS.WORLD | Global.PHYSICS_LAYERS.GUN | Global.PHYSICS_LAYERS.TEAM_1 | Global.PHYSICS_LAYERS.TEAM_2

	# Filtering overlapping bodies
	# TODO-BUG #77: Grenade can't damage player if it's inside the player
	for i in overlapping_bodies:
		# 1. Check whether grenade has line of sight to object
		var to = i.global_transform.origin
		var ray_result = space_state.intersect_ray(from, to, [self], shootable_collision_mask)
		var colliding = ray_result.get("collider")

		# 2. Add to result if it does pass the check
		if colliding and colliding == i and (colliding is RigidBody or "i_health" in i or "i_interact" in i):
			result.append(ray_result)

	return result


# Will give an array of ray_result back
func _get_ray_results_of_flash_influenced_players() -> Array:
	var overlapping_bodies = get_tree().get_nodes_in_group(Global.SPAWN_TYPE_GROUP.TEAM_1)
	overlapping_bodies.append_array(get_tree().get_nodes_in_group(Global.SPAWN_TYPE_GROUP.TEAM_2))
	overlapping_bodies.append_array(get_tree().get_nodes_in_group(Global.SPAWN_TYPE_GROUP.UNIVERSAL))

	var result = []

	# For rays
	var space_state = get_world().direct_space_state
	var from = global_transform.origin
	var flashable_collision_mask = Global.PHYSICS_LAYERS.TEAM_1 | Global.PHYSICS_LAYERS.TEAM_2 | Global.PHYSICS_LAYERS.WORLD

	# Filtering overlapping bodies
	# TODO-BUG #77: Grenade can't flash player if it's inside the player
	for i in overlapping_bodies:
		# 1. Check whether grenade has line of sight to object
		var to = i.global_transform.origin
		var ray_result = space_state.intersect_ray(from, to, [self], flashable_collision_mask)
		var colliding = ray_result.get("collider")

		# 2. Add to result if it does pass the check
		if colliding and colliding == i and ("i_flash" in i):
			result.append(ray_result)

	return result


# apply damage based on distance linearly instead of squared because screw physics
func _apply_damage(ray_result: Dictionary):
	var collider = ray_result.get("collider")
	var position = ray_result.get("position", Vector3())

	if collider and "i_health" in collider:
		# Math stuff for area of influence modifier (the farther the smaller the damage)
		var distance = global_transform.origin.distance_to(position)
		var influence_range_ratio = (influence_area_range - distance) / influence_area_range
		var modifier = max(influence_range_ratio, 0)
		var modified_damage = -base_damage * modifier

		collider.i_health.change_health_and_armor(modified_damage)


func _apply_impulse(ray_result: Dictionary):
	var collider = ray_result.get("collider")
	var position = ray_result.get("position", Vector3())

	if collider is RigidBody:
		# Math stuff for area of influence modifier (the farther the smaller the damage)
		var distance = global_transform.origin.distance_to(position)
		var influence_range_ratio = (influence_area_range - distance) / influence_area_range
		var modifier = max(influence_range_ratio, 0)
		var imp_direction = (position - global_transform.origin).normalized()
		var modified_impulse_power = imp_direction * modifier * 25

		collider.apply_impulse(position - collider.global_transform.origin, modified_impulse_power)


func _apply_flashbang(ray_result: Dictionary):
	var collider = ray_result.get("collider")

	if "i_flash" in collider: # TODO: create i_flash and apply to player
		collider.i_flash.flash(self.global_transform.origin)


func _is_influence_area() -> bool:
	var test = get_node(influence_area_path)
	return test and (test is Area)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == anim_shoot_name or anim_name == anim_shoot_secondary_name:
		influence_area.monitoring = true

		# Cache it for a second
		var p = player
		var camera = p.camera

		# Set to world
		p.remove_weapon(weapon_slot)
		self.collision_layer = 0
		self.collision_mask = Global.PHYSICS_LAYERS.WORLD
		self.global_transform.origin = p.pivot.global_transform.origin
		self.add_collision_exception_with(p)

		# Throw it from the front of the player
		global_transform.origin = camera.global_transform.origin
		global_rotate(Vector3(rand_range(-1, 1), rand_range(-1, 1), rand_range(-1, 1)).normalized(), PI * rand_range(0, 2))

		# Throwing power based on animation name (because it determine between first and secondary shot)
		var throwing_power = 18
		if anim_name == anim_shoot_secondary_name:
			throwing_power = 7

		# Add force to the gun
		apply_central_impulse(-camera.global_transform.basis.z * throwing_power + (p.desired_movement_velocity))
		apply_torque_impulse(Vector3(rand_range(-1, 1), rand_range(-1, 1), rand_range(-1, 1)).normalized() * 0.10)

		# Depends on the types of grenade
		_active_grenade_routine()
