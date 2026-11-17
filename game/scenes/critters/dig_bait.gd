class_name DigBait extends FleeingBait

func generate_flee_direction() -> void:
	if not is_multiplayer_authority():
		return
	flee_direction.x = randf_range(-1, 1)
	flee_direction.z = randf_range(-1, 1)
	flee_direction = flee_direction.normalized()
	var rand_sample_index : int = randi_range(0, speed_curve.point_count)
	flee_direction.y = -100
	speed = speed_curve.sample_baked(rand_sample_index) * max_speed
