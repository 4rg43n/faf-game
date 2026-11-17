class_name DigBait extends FleeingBait

func generate_flee_direction() -> void:
	flee_direction.x = randf_range(-1, 1)
	flee_direction.y = -randf() * 1000 # heavily scew it to dig down
	flee_direction.z = randf_range(-1, 1)
	flee_direction = flee_direction.normalized()
	var rand_sample_index : int = randi_range(0, speed_curve.point_count)
	speed = speed_curve.sample_baked(rand_sample_index) * max_speed
