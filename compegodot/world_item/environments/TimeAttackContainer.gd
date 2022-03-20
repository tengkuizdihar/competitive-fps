tool
extends Spatial
class_name TimeAttackContainer

const TIME_ELAPSED_TEXT_FORMAT = "TIME ELAPSED:\n%.1f"


var time_attack_label_3d = null
var time_attack_elapsed = 0.0
var update_text_interval = null
var is_time_attack_ongoing = false

var list_of_target_transforms = []
var target_container = null

var target_count = 0
var target_count_killed = 0

var reset_time_attack_button = null
var player_respawn_location = null

export (PackedScene) var target_scene # Must implement i_health and Spatial/Node3D
export (NodePath) var target_positions_container_path = null
export (NodePath) var time_attack_label_3d_path = null
export (NodePath) var reset_time_attack_button_path = null
export (NodePath) var player_respawn_location_path = null


func _get_configuration_warning() -> String:
	if not target_positions_container_path:
		return "Target Container Path must be set!"
	if not time_attack_label_3d_path:
		return "Time Attack Label 3D Path must be set!"
	if not reset_time_attack_button_path:
		return "Reset Time Attack Button Path must be set!"
	if not player_respawn_location_path:
		return "Player Respawn Location Path must be set!"
	return ""


# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.editor_hint:
		# Initialize Player Respawn When Resetting Time Attack
		player_respawn_location = get_node(player_respawn_location_path)

		# Initialize target_positions
		target_container = get_node(target_positions_container_path)

		target_count = target_container.get_children().size()
		respawn_targets(true)

		# Initialize 3D Label
		time_attack_label_3d = get_node(time_attack_label_3d_path)
		set_text_ready()

		# Initialize Reset Button
		reset_time_attack_button = get_node(reset_time_attack_button_path)
		reset_time_attack_button.i_interact.connect("interacted", self, "reset_time_attack")

		# Initialize some kind of mechanism to limit the 3D label update
		# This will make sure that 3D label is not updated every frame, because that's very expensive process
		update_text_interval = Timer.new()
		add_child(update_text_interval)
		Util.handle_err(update_text_interval.connect("timeout", self, "_on_update_text_interval_timeout"))
		update_text_interval.wait_time = 0.1
		update_text_interval.one_shot = false
		update_text_interval.start() # DEBUG: only for debug, this timer should only start when the time attack starts.


func _process(delta):
	if not Engine.editor_hint:
		update_time_elapsed_time(delta)


func reset_time_attack(player: Spatial):
	is_time_attack_ongoing = false
	target_count_killed = 0
	reset_time_elapsed_time()
	respawn_targets(false)

	# TODO: interacted need to pass the interactor
	respawn_player(player)



func update_time_elapsed_time(delta: float):
	if is_time_attack_ongoing:
		time_attack_elapsed += delta


func reset_time_elapsed_time():
	time_attack_elapsed = 0.0


func set_text_ready():
	time_attack_label_3d.text = "READY TO GO!"


func set_text_elapsed_time():
	time_attack_label_3d.text = TIME_ELAPSED_TEXT_FORMAT % time_attack_elapsed # DEBUG: use time attack timer


func respawn_targets(init_only: bool):
	var targets = target_container.get_children()
	for t in targets:
		if init_only:
			list_of_target_transforms.append(t.get_global_transform())
		t.queue_free()

	# initialize targets
	for gtrans in list_of_target_transforms:
		var new_target = target_scene.instance() as Spatial
		target_container.add_child(new_target)

		new_target.global_transform = gtrans
		new_target.i_health.connect("dead", self, "_on_target_dead", [new_target])
		new_target.i_health.set_health(1)


func respawn_player(player: Spatial):
	print(player_respawn_location.global_transform)
	player.global_transform = player_respawn_location.global_transform


func _on_update_text_interval_timeout():
	set_text_elapsed_time()


func _on_target_dead(_target: Spatial):
	target_count_killed += 1

	if not is_time_attack_ongoing:
		is_time_attack_ongoing = true
	if target_count == target_count_killed and target_count != 0:
		is_time_attack_ongoing = false
