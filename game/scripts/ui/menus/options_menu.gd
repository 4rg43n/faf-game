extends CenterContainer

@export var unstuck_button: Button
@export var world: WorldBackBone


func _ready() -> void:
	unstuck_button.pressed.connect(_on_unstuck_button_pressed)


func _on_lobby_button_pressed() -> void:
	LobbyManager.instance.leave_lobby()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_unstuck_button_pressed() -> void:
	GameManager.instance.player.global_position = world.spawn_location.global_position
