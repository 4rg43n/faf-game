class_name Main extends Node

@export var weather_manager: WeatherManager

static var instance: Main = null

func _init() -> void:
	instance = self


func _ready() -> void:
	if weather_manager:
		weather_manager.load_weather_condition.call_deferred("clear")


func _process(_delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		#----DEBUG SECTION----
		if not OS.is_debug_build():
			return
		if Input.is_action_just_pressed("randomize_weather"):
			weather_manager.randomize_weather(false)
		elif Input.is_action_just_pressed("force_storm"):
			weather_manager.load_weather_condition("storm")
		elif Input.is_action_just_pressed("time_forward"):
			weather_manager.time_of_day.current_time += 1
		elif Input.is_action_just_pressed("time_backward"):
			weather_manager.time_of_day.current_time -= 1
