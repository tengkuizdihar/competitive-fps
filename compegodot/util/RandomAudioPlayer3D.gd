extends Spatial
class_name RandomAudioPlayer3D

export (float) var pitch_range = 0.0
export (float) var interval_seconds = 0.0
var interval_timer = null
var audios = [] # {audio: null, default_pitch: 0.0}


func _ready() -> void:
	self.interval_timer = Timer.new()
	self.add_child(self.interval_timer)
	self.interval_timer.one_shot = true

	if interval_seconds <= 0:
		self.interval_timer.wait_time = 0.001
	else:
		self.interval_timer.wait_time = interval_seconds

	for i in self.get_children():
		if i is AudioStreamPlayer3D:
			self.audios.append({
				audio = i,
				default_pitch = i.pitch_scale
			})


func play() -> void:
	var child_index = randi() % self.audios.size()
	var a = self.audios[child_index].audio as AudioStreamPlayer3D
	a.pitch_scale = _range_random(pitch_range) + self.audios[child_index].default_pitch

	a.play()
	self.interval_timer.start()


func stop() -> void:
	self.interval_timer.stop()
	for a in self.get_children():
		a.audio.stop()


# TODO: Refactor to use a variable cache in this class and will be set to false
#       whenever a sound is finished playing. Or maybe use somekind of sempahore.
func is_playing() -> bool:
	var is_at_least_one_playing = false
	for i in audios:
		is_at_least_one_playing = is_at_least_one_playing or i.audio.is_playing()

	return is_at_least_one_playing or !self.interval_timer.is_stopped()


func _range_random(x: float) -> float:
	return rand_range(-x, x)
