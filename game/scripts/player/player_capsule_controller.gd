class_name PlayerController extends CharacterBody3D

@export var first_person_cam : Camera3D
@export var third_person_cam : Camera3D

@export var camera: Camera3D
@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 6.0
var owned_by_current_client : bool = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	direction = direction.rotated(Vector3.UP, camera.global_rotation.y)

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func make_current_player() -> void:
	owned_by_current_client = true
	camera.make_current()
	print("this client is the owner!")
