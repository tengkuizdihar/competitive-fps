tool
extends Area

# Target that's going to be randomly spawned in the level
export (PackedScene) var target_scene
var collision_area: CollisionShape
var alive_targets = []

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
	alive_targets.erase(target)

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

		__spawn_target(collision_area.global_transform.origin)


func _on_score_mode_changed(_mode: int) -> void:
	Score.reset_score()


func _on_state_player_reloaded(_reload_frame: int):
	if Score.mode == Score.Mode.SPRAY_SINGLE and Score.score > 0:
		Score.reset_score()
		__spawn_target(collision_area.global_transform.origin)


func __spawn_target(target_origin: Vector3 = Vector3.INF, health: float = 1.0) -> void:
	var new_target = target_scene.instance() as Node
	add_child(new_target)
	alive_targets.push_back(new_target)

	if target_origin == Vector3.INF:
		new_target.global_transform.origin = __get_random_points_inside_area()
	else:
		new_target.global_transform.origin = target_origin

	var interface = Util.get_interface(new_target, IHealth) as IHealth
	interface.set_health(health)
	interface.connect("dead", self, "_on_Target_dead", [new_target])


func __get_random_points_inside_area() -> Vector3:
	var shape = collision_area.shape as BoxShape
	var extents = shape.extents
	var collision_area_glob_trans = collision_area.global_transform
	randomize()
	var random_in_box = Vector3(rand_range(-extents.x, extents.x), rand_range(-extents.y, extents.y), rand_range(-extents.z, extents.z))

	return collision_area_glob_trans.xform(random_in_box)