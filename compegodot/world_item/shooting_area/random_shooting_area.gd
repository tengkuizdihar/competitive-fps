tool
extends Area

# Target that's going to be randomly spawned in the level
export (PackedScene) var target_scene
var collision_area: CollisionShape

# This variable will be used for pool of objects to be used
var alive_targets = [] # node => is_being_used

func _get_configuration_warning() -> String:
	for i in get_children():
		if i is CollisionShape and i.shape is BoxShape:
			return ""
	return "Must have a CollisionShape with BoxShape for area of randomness."


func _ready() -> void:
	if not Engine.editor_hint:
		for i in get_children():
			if i is CollisionShape and i.shape is BoxShape:
				collision_area = i
				break

		__spawn_target(collision_area.global_transform.origin)

		Util.handle_err(Score.connect("score_changed", self, "_on_score_score_changed"))
		Util.handle_err(Score.connect("mode_changed", self, "_on_score_mode_changed"))
		Util.handle_err(State.connect("state_player_reloaded", self, "_on_state_player_reloaded"))

func _physics_process(delta):
	if not Engine.editor_hint:
		if Score.mode == Score.Mode.RANDOM_SINGLE and State.get_state("shooting_target_movement_mode") == Global.SHOOTING_TARGET_MOVEMENT_MODE.MOVING:
			for t in alive_targets:
				if is_instance_valid(t):
					t.move_target(delta)


func _on_Target_dead(target) -> void:
	# NOTE: To avoid being killed again after spawning because now bullets have penetration
	#       which could kill the newly spawned shooting target if it's close enough
	yield(get_tree(), "physics_frame")
	Pool.deactivate_node(Pool.SHOOTING_TARGET_KEY, target)
	alive_targets.erase(target)
	Score.add_score()

	match Score.mode:
		Score.Mode.RANDOM_SINGLE:
			__spawn_target()
		Score.Mode.SPRAY_SINGLE:
			__spawn_target(collision_area.global_transform.origin)
		_:
			printerr("Score Mode isn't recognized by ShootingArea!")


func _on_score_score_changed(score: int) -> void:
	if score == 0:
		for i in get_children():
			if i != collision_area:
				i.queue_free()

		__clear_all_targets()
		__spawn_target(collision_area.global_transform.origin)


func _on_score_mode_changed(_mode: int) -> void:
	__clear_all_targets()
	Score.reset_score()


func _on_state_player_reloaded(_reload_frame: int):
	if Score.mode == Score.Mode.SPRAY_SINGLE and Score.score > 0:
		__clear_all_targets()
		Score.reset_score()
		__spawn_target(collision_area.global_transform.origin)


func __clear_all_targets() -> void:
	for i in alive_targets:
		Pool.deactivate_node(Pool.SHOOTING_TARGET_KEY, i)

	alive_targets.clear()

func __spawn_target(target_origin: Vector3 = Vector3.INF, health: float = 1.0) -> void:
	var new_target = Pool.activate_node(Pool.SHOOTING_TARGET_KEY)
	new_target.is_score_count_after_death = false
	new_target.is_free_after_death = false
	alive_targets.push_back(new_target)

	new_target._on_state_shooting_target_size(State.get_state("shooting_target_size"))

	# Because call deferred is called in activate_node, we need this.
	# I know, it's not ideal, but it's all we've got for now...
	yield(get_tree(), "idle_frame")

	if target_origin == Vector3.INF:
		new_target.global_transform.origin = __get_random_points_inside_area()
	else:
		new_target.global_transform.origin = target_origin

	var interface = Util.get_interface(new_target, IHealth) as IHealth
	interface.set_health(health)

	Util.validated_connect(interface, "dead", self, "_on_Target_dead", [new_target])


func __get_random_points_inside_area() -> Vector3:
	var shape = collision_area.shape as BoxShape
	var extents = shape.extents
	var collision_area_glob_trans = collision_area.global_transform
	randomize()
	var random_in_box = Vector3(rand_range(-extents.x, extents.x), rand_range(-extents.y, extents.y), rand_range(-extents.z, extents.z))

	return collision_area_glob_trans.xform(random_in_box)
