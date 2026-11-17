extends Control

@export var options_menu: Control

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not LobbyManager.instance.is_visible_in_tree():
		if Input.is_action_just_pressed("esc_key"):
			options_menu.visible = !options_menu.visible
			
