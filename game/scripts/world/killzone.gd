extends Area3D

@export var starting_world: WorldBackBone

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D):
	body.global_position = starting_world.spawn_location.global_position
