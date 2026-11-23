extends Node

@export var dev_container : MarginContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_key"):
			dev_container.visible = not dev_container.visible
