class_name FleeingBait extends RigidBody3D

## basically the timer - they spawn randomly inside a bug pickup minigame and once they leave the area they despawn.
@export var speed_curve : Curve
@export var max_speed : float
var speed : float = 1

## ground direction (no flying) - we can allow flying in the flying class that extends this one.
var flee_direction : Vector3

func _ready() -> void:
	generate_flee_direction()

func generate_flee_direction() -> void:
	## generate random vector3 then remove verticality
	flee_direction.x = randf_range(-1, 1)
	flee_direction.y = 0
	flee_direction.z = randf_range(-1, 1)
	flee_direction = flee_direction.normalized()
	var rand_sample_index : int = randi_range(0, speed_curve.point_count)
	speed = speed_curve.sample_baked(rand_sample_index) * max_speed

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	state.linear_velocity.x = flee_direction.x * speed
	state.linear_velocity.z = flee_direction.z * speed

	var up_dir: Vector3 = Vector3.UP
	var target_dir = state.linear_velocity
	if abs(target_dir.dot(up_dir)) > 0.999:
		up_dir = Vector3.FORWARD

	var target_basis: Basis = Basis.looking_at(target_dir, up_dir)

	var current_quat: Quaternion = state.transform.basis.get_rotation_quaternion()
	var target_quat: Quaternion = target_basis.get_rotation_quaternion()
	var diff_quat: Quaternion = target_quat * current_quat.inverse()

	if diff_quat.w < 0.0:
		diff_quat = -diff_quat

	var angle: float = diff_quat.get_angle()
	if angle > 0.001:
		var axis: Vector3 = diff_quat.get_axis()
		state.angular_velocity = axis * angle * 10.0
	else:
		state.angular_velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	#apply_force(flee_direction * speed * delta)
	pass
