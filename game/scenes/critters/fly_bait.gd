class_name FlyAwaiyBait extends FleeingBait

func generate_flee_direction() -> void:
	flee_direction.x = randf_range(-1, 1)
	flee_direction.y = randf()
	flee_direction.z = randf_range(-1, 1)
	flee_direction = flee_direction.normalized()
	var rand_sample_index : int = randi_range(0, speed_curve.point_count)
	speed = speed_curve.sample_baked(rand_sample_index) * max_speed

func _physics_process(delta: float) -> void:
	apply_force(flee_direction * speed * delta)
