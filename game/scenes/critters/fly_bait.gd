class_name FlyAwaiyBait extends FleeingBait

var grounded : bool = true
var ground_timer : float = 0

func generate_flee_direction() -> void:
	if not is_multiplayer_authority():
		return
	flee_direction.x = randf_range(-1, 1)
	flee_direction.y = 1
	flee_direction.z = randf_range(-1, 1)
	flee_direction = flee_direction.normalized()
	var rand_sample_index : int = randi_range(0, speed_curve.point_count)
	speed = speed_curve.sample_baked(rand_sample_index) * max_speed

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if ground_timer > 2.5 and position.y <= 5:
		gravity_scale = 0.01
		apply_force(flee_direction * 1000 * speed * delta)

	if position.y <= 1:
		ground_timer += delta
	else:
		ground_timer = 0
		gravity_scale = 1
