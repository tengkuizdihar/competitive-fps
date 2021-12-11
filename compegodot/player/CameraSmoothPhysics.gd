class_name CameraSmoothPhysics
extends Camera

var latest_physics_origin = Vector3.ZERO
var latest_physics_delta = 1.0
var accumulated_delta_render = 0.0

var rotated_angle_horizontal = 0.0
var rotated_angle_vertical = 0.0

const FOV_DEFAULT = 70.0
const FOV_SNIPER_ZOOMED_1 = 40.0
const FOV_SNIPER_ZOOMED_2 = 10.0

export(bool) var tps_view = false
export(float) var tps_distance = 7.0


func _ready():
	Util.handle_err(State.connect("state_player_zoom_mode", self, "_on_state_player_zoom_mode"))


func _physics_process(delta: float) -> void:
	self.latest_physics_delta = delta
	self.latest_physics_origin = get_parent().global_transform.origin
	self.accumulated_delta_render = 0.0


func _process(delta: float) -> void:
	set_as_toplevel(true)
	self.global_transform.basis = get_parent().global_transform.basis

	var current_origin = self.global_transform.origin
	var target_origin = self.latest_physics_origin

	if tps_view:
		target_origin += global_transform.basis.xform(Vector3.BACK * 7.0)

	var ratio = get_ratio(delta)
	var interp_origin = current_origin.linear_interpolate(target_origin, ratio)

	self.global_transform.origin = interp_origin

	self.rotate(-self.global_transform.basis.y, rotated_angle_horizontal)
	self.rotate(self.global_transform.basis.x, rotated_angle_vertical)


func get_ratio(render_delta: float) -> float:
	var ratio = 1.0
	self.accumulated_delta_render += render_delta

	if self.accumulated_delta_render > self.latest_physics_delta:
		ratio = 1.0
	elif self.latest_physics_delta > 0.0:
		ratio = self.accumulated_delta_render / self.latest_physics_delta

	return abs(min(ratio, 1))


func _on_state_player_zoom_mode(value: int):
	match value:
		Global.WEAPON_ZOOM_MODE.DEFAULT:
			fov = FOV_DEFAULT
		Global.WEAPON_ZOOM_MODE.SNIPER_ZOOMED_1:
			fov = FOV_SNIPER_ZOOMED_1
		Global.WEAPON_ZOOM_MODE.SNIPER_ZOOMED_2:
			fov = FOV_SNIPER_ZOOMED_2
		_:
			fov = FOV_DEFAULT
