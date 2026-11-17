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
