extends Node3D

@export var weather_manager: WeatherManager

func _ready() -> void:
	Steam.setAchievement("ACH_WIN_ONE_GAME")
	Steam.setAchievement("ACH_TRAVEL_FAR_ACCUM")
	Steam.setAchievement("ACH_TRAVEL_FAR_SINGLE")
	Steam.setAchievement("ACH_WIN_100_GAMES")
	Steam.setAchievement("NEW_ACHIEVEMENT_0_4")

	weather_manager.randomize_weather.call_deferred()


func _process(_delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		#----DEBUG SECTION----
		if not OS.is_debug_build():
			return
		if Input.is_action_just_pressed("randomize_weather"):
			weather_manager.randomize_weather()
		elif Input.is_action_just_pressed("force_storm"):
			weather_manager.load_weather_condition("storm")
		elif Input.is_action_just_pressed("time_forward"):
			weather_manager.time_of_day.current_time += 1
		elif Input.is_action_just_pressed("time_backward"):
			weather_manager.time_of_day.current_time -= 1
