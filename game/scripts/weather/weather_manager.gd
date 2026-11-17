class_name WeatherManager extends Node

@export_group("Scenes")
@export var rain_particles: RainSystem
@export var sky_3d: Sky3D
@export var time_of_day: TimeOfDay
@export var sky_dome: SkyDome

@export_group("Resources")
@export var weather_conditions: Dictionary[String, Resource]
@export var environment: Environment

var wind_direction: Vector3 = Vector3(1.0, 0.0, 0.0)
var wind_intensity: float = 1.0

var is_raining: bool = false
var is_storming: bool = false

var current_condition: WeatherCondition

static var instance: WeatherManager
func _init() -> void:
	instance = self


func _ready() -> void:
	environment.fog_density = 0.0


func randomize_weather() -> void:
	var condition : String = weather_conditions.keys().pick_random()
	var rand_wind_direction : Vector3 = Vector3(randf_range(-5.0, 5.0),0.0,randf_range(-5.0, 5.0))
	var rand_wind_intensity : float = randf()
	rpc("load_weather_condition", condition)
	rpc("set_wind", [rand_wind_direction, rand_wind_intensity])


@rpc("any_peer", "call_local")
func load_weather_condition(condition: String) -> void:
	if !weather_conditions.has(condition):
		return

	current_condition = weather_conditions[condition]
	is_raining = current_condition.is_raining
	is_storming = current_condition.is_storming

	environment.fog_density = current_condition.fog_density
	sky_dome.cumulus_coverage = current_condition.cloud_coverage
	environment.fog_sky_affect = current_condition.cloud_coverage
	rain_particles.amount = current_condition.rain_particle_amount
	sky_3d.skydome_energy = current_condition.default_skydome_energy

	sky_3d.sun_energy = current_condition.sun_energy
	sky_3d.moon_energy = 0.15 * current_condition.sun_energy
	sky_3d.cloud_intensity = current_condition.cloud_intensity

	rain_particles.rain_enabled = is_raining
	rain_particles.storm_enabled = is_storming
	rain_particles.lightning.default_skydome_energy = current_condition.default_skydome_energy


@rpc("any_peer", "call_local")
func set_wind(direction: Vector3, intensity: float) -> void:
	wind_direction = direction.normalized()
	wind_intensity = clampf(intensity, 0.0, 1.0)

	# apply wind to rain
	rain_particles.apply_new_wind(wind_intensity, wind_direction)

	# apply wind to clouds
	var wind_angle = atan2(-wind_direction.x, wind_direction.z)
	sky_dome.wind_direction = wind_angle
	sky_dome.wind_speed = wind_intensity * 5.0

	# apply wind to shaders
	RenderingServer.global_shader_parameter_set("sgt_wind_direction", wind_direction)
	RenderingServer.global_shader_parameter_set("sgt_wind_strength", wind_intensity / 2.0)
