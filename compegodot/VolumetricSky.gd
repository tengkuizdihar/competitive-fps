extends Spatial
class_name VolumetricSky

var delta_total = 0
var sky_viewport: Viewport
var sky_sprite: Sprite

func _ready():
	# Readying the sky viewport
	sky_viewport = preload('res://world_item/VolumetricSkyViewport.tscn').instance()
	add_child(sky_viewport)

	sky_sprite = sky_viewport.get_child(0)
	sky_sprite.material.set("shader_param/COVERAGE", 0.5)
	sky_sprite.material.set("shader_param/ABSORPTION", 1.031)
	sky_sprite.material.set("shader_param/THICKNESS", 30)
	sky_sprite.material.set("shader_param/STEPS", 100)

	# Readying the environment for the currently used camera
	var camera = get_viewport().get_camera()
	camera.environment = preload('res://default_env.tres') as Environment
	camera.environment.background_sky.set_panorama(sky_viewport.get_texture())

func _physics_process(delta):
	delta_total += delta
	sky_sprite.material.set('shader_param/iTime', delta_total / 10)
	sky_sprite.material.set('shader_param/iFrame', Engine.get_physics_frames())
