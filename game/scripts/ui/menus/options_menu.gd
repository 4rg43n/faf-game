extends CenterContainer


func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_lobby_button_pressed() -> void:
	LobbyManager.instance.leave_lobby()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")




func _on_quit_button_pressed() -> void:
	get_tree().quit()
