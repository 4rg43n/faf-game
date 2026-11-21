extends Control

var delay: float = 3.0
var time_elapsed: float = 0.0
var credits_rolling: bool = false
var max_distance: float = -1750.0

func _process(delta: float):
	if not credits_rolling:
		return
	time_elapsed += delta
	if time_elapsed >= delay:
		_roll_credits(delta)

func start_credits():
	visible = true
	credits_rolling = true
	GameManager.instance.player.active_camera = GameManager.instance.lobby_camera
	UI.instance.hide_all_ui()
	WeatherManager.instance.load_weather_condition("clear")
	WeatherManager.instance.disabled = true

func _roll_credits(delta: float):
	if position.y <= max_distance:
		visible = false
		credits_rolling = false
		time_elapsed = 0.0
		UI.instance.options_menu._on_lobby_button_pressed()
		return
	position.y -= 25 * delta
