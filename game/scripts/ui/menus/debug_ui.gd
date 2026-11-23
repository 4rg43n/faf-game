extends Node

@export var dev_container : MarginContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and event.keycode == Key.KEY_QUOTELEFT:
			dev_container.visible = not dev_container.visible
