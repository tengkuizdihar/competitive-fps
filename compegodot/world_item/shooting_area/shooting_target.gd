extends KinematicBody

var direction = Vector3.ZERO
var speed = 1.0

onready var i_health = $IHealth
onready var health_label = $HealthLabel

export (bool) var is_free_after_death = true
export (bool) var is_score_count_after_death = true

func _ready() -> void:
	Util.handle_err(i_health.connect("dead", self, "_on_ShootingTarget_dead"))
	Util.handle_err(i_health.connect("health_changed", self, "_on_IHealth_health_changed"))

	_on_state_shooting_target_size(State.get_state("shooting_target_size"))
	set_health_text(i_health.current_health)

	# Inititalize direction of the target
	randomize()
	direction = (global_transform.basis.x * rand_range(-1,1) + global_transform.basis.y * rand_range(-1,1)).normalized()
	speed = rand_range(5, 20)

func move_target(delta):
	direction.z = 0
	direction = direction.normalized()

	var collision_info = move_and_collide(direction * speed * delta)
	if collision_info:
		direction = direction.bounce(collision_info.normal).normalized()


func add_hit_count() -> void:
	Score.add_score()


func set_health_text(health: float):
	if health <= 0.0:
		return
	elif health == 1.0:
		health_label.text = ""
	else:
		health_label.text = str(health)


func _on_ShootingTarget_dead() -> void:
	if is_score_count_after_death:
		add_hit_count()

	if is_free_after_death:
		queue_free()


func _on_state_shooting_target_size(state: float):
	scale = Vector3.ONE * state


func _on_IHealth_health_changed(health: float, _armor: float):
	set_health_text(health)
