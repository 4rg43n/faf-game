class_name LightningController extends Node3D

signal lightning_strike

@export var lightning: Node3D
@export var thunder_audio: AudioStreamPlayer3D
@export var lightning_directional_light: DirectionalLight3D

@export var lightning_min_distance: float = 25.0
@export var lightning_max_distance: float = 500.0

var sky_3d: Sky3D

var is_storming: bool = false
var is_flashing: bool = false

var default_skydome_energy: float = 1.0

func _ready() -> void:
	visible = is_flashing

	lightning_strike.connect(play_thunder)

func _physics_process(_delta: float) -> void:
	if is_storming:
		if !is_flashing and !thunder_audio.playing:
			if randf() < 1.0 / 60.0:
				start_lightning()


func start_lightning() -> void:
	if !sky_3d:
		sky_3d = WeatherManager.instance.sky_3d
	rotation_degrees.y = randf_range(0.0, 360.0)
	lightning.position.z = randf_range(lightning_min_distance, lightning_max_distance)

	var distance: float = abs(lightning.position.z)
	var height: float = position.y

	var angle_rad: float = atan2(distance, height)
	lightning_directional_light.rotation_degrees.x = -90.0 - rad_to_deg(angle_rad)

	is_flashing = true
	lightning_strike.emit()

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	flash(true)
	await get_tree().create_timer(randf()/4.0, false).timeout
	flash(false)
	await get_tree().create_timer(randf()/4.0, false).timeout
	flash(true)
	await get_tree().create_timer(randf()/4.0, false).timeout
	flash(false)
	await get_tree().create_timer(3.0, false).timeout
	is_flashing = false


func play_thunder() -> void:
	if not GameManager.instance.player.active_camera:
		return
	var distance: float = GameManager.instance.player.active_camera.global_position.distance_to(global_position)
	var delay_amount: float = distance / (343.0 / 5.0)
	await get_tree().create_timer(delay_amount, false).timeout
	thunder_audio.play()


func flash(toggled_on: bool) -> void:
	if !toggled_on:
		sky_3d.skydome_energy = WeatherManager.instance.current_condition.default_skydome_energy
	else:
		sky_3d.skydome_energy = WeatherManager.instance.current_condition.default_skydome_energy * 4.0
	visible = toggled_on
