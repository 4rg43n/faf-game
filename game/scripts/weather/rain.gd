class_name RainSystem extends GPUParticles3D

@export var rain_sound: AudioStreamPlayer
@export var mist_particles: GPUParticles3D
@export var rain_sound_mute: bool = false
@export var rain_enabled: bool = false:
	set(value):
		rain_enabled = value
		change_rain()
@export var storm_enabled: bool = false:
	set(value):
		storm_enabled = value
		#lighning.is_storming = value
		change_rain()

var mist_process_material: ParticleProcessMaterial
var rain_sync: AudioStreamSynchronized

enum RainSounds{
		Rain,
		HeavyRain,
		Storm
	}

func _ready() -> void:
	mist_process_material = mist_particles.process_material
	rain_sync = rain_sound.get_stream()


func _physics_process(_delta: float) -> void:
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
