class_name RainSystem extends GPUParticles3D

@export_group("Scenes")
@export var rain_sound: AudioStreamPlayer
@export var mist_particles: GPUParticles3D
@export var lightning: Node3D
@export var debug_label: Label
@export var recalculate_audio_timer: Timer
@export var indoor_raycasts_array: Array[RayCast3D]
@export_group("Flags")
@export var rain_sound_mute: bool = false
@export var rain_enabled: bool = false:
	set(value):
		rain_enabled = value
		change_rain()
@export var storm_enabled: bool = false:
	set(value):
		storm_enabled = value
		lightning.is_storming = value
		change_rain()

static var instance: RainSystem
var mist_process_material: ParticleProcessMaterial
var rain_sync: AudioStreamSynchronized

var amount_indoors: float = 0.0

enum RainSounds{
		Rain,
		HeavyRain,
		Storm
	}

func _init() -> void:
	instance = self

func _ready() -> void:
	mist_process_material = mist_particles.process_material
	rain_sync = rain_sound.get_stream()
	recalculate_audio_timer.timeout.connect(recalculate_audio)
	visible = true


func _physics_process(_delta: float) -> void:
	if not GameManager.instance.player:
		return
	calculate_amount_indoors()
	global_position = GameManager.instance.player.global_position


func apply_new_wind(wind_intensity: float, wind_direction: Vector3) -> void:
	var tilt: float = lerpf(0.1, 0.6, wind_intensity * 5.0)
	var rain_dir: Vector3 = Vector3(
		wind_direction.x * tilt, -1.0, wind_direction.z * tilt
		).normalized()

	process_material.direction = rain_dir

	mist_process_material.direction = rain_dir

	mist_process_material.initial_velocity_min = wind_intensity * 5.0


func change_rain_sound(stream_index: int) -> void:
	var total_streams: int = rain_sync.get_stream_count()
	for i in range(total_streams):
		var target_volume: float = -60.0
		if i == stream_index:
			target_volume = 0.0
		rain_sync.set_sync_stream_volume(i, target_volume)


func change_rain() -> void:
	var current_condition: WeatherCondition = WeatherManager.instance.current_condition
	var current_condition_name: String = current_condition.condition_name

	mist_particles.emitting = current_condition.enable_mist

	if current_condition_name == "Rain":
		change_rain_sound(RainSounds.Rain)
	elif current_condition_name == "Heavy Rain":
		change_rain_sound(RainSounds.HeavyRain)
	elif current_condition_name == "Storm":
		change_rain_sound(RainSounds.Storm)
	else:
		change_rain_sound(RainSounds.Rain)

	emitting = rain_enabled

	if rain_sound_mute:
		rain_sound.playing = false
	else:
		rain_sound.playing = rain_enabled


func calculate_amount_indoors() -> float:
	amount_indoors = 0.0
	var add_amount: float = 1.0 / indoor_raycasts_array.size()
	for raycast: RayCast3D in indoor_raycasts_array:
		if raycast.is_colliding():
			amount_indoors += add_amount
	debug_label.text = "Indoor Amount: " + str(amount_indoors * 100) + "%"
	return amount_indoors


func recalculate_audio() -> void:
	var low_pass: AudioEffectLowPassFilter = AudioServer.get_bus_effect(1, 0)

	var target_cutoff: float = 20500.0

	if amount_indoors > 0.3:
		var new_tween: Tween = get_tree().create_tween()
		target_cutoff = (18500.0 * (1.0 - amount_indoors)) + 2000.0

		new_tween.tween_property(low_pass, "cutoff_hz", target_cutoff, 0.1)
