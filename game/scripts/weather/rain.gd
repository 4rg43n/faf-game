class_name RainSystem extends GPUParticles3D


func _physics_process(_delta: float) -> void:
	global_position = GameManager.instance.player.global_position
