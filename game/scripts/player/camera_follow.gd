extends Camera3D

@export var spring_arm_pos: Node3D
@export var lerp_speed: float = 6.0

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		return
	position = lerp(position, spring_arm_pos.position, delta*lerp_speed)
