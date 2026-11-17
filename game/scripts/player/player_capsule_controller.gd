class_name PlayerController extends CharacterBody3D

signal active_camera_changed(camera: Camera3D)

@onready var visuals: Node3D = $Visuals
@export var turn_speed: float = 10.0

@export var debug_scene_play:bool=false

@export var first_person_cam : Camera3D
@export var third_person_cam : Camera3D
@export var third_person_pivot : Node3D

@export var active_camera: Camera3D:
	set(camera):
		if camera == active_camera:
			return
		active_camera = camera
		make_current_player()

@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 6.0

var owned_by_current_client : bool = false

var regular_speed: float = SPEED
var dev_speed: float = 50.0

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	# DEV TOOLS
	if OS.is_debug_build():
		if Input.is_action_pressed("shift"):
			SPEED = dev_speed
		else:
			SPEED = regular_speed

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.WWWWWWWWWWWWWWWWWW
	var input_dir : Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction : Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	direction = direction.rotated(Vector3.UP, third_person_cam.global_rotation.y)

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Face the movement direction (Godot's forward is -Z)
		var target_yaw := atan2(direction.x, direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func make_current_player() -> void:
	if not is_node_ready():
		await ready
	if not debug_scene_play:
		var parent_peer_id : int = get_parent().get("peer_id")
		var current_peer_id : int = multiplayer.get_unique_id()
		if current_peer_id != parent_peer_id:
			return
	owned_by_current_client = true
	active_camera.make_current()
	active_camera_changed.emit(active_camera)
	active_camera.make_current()
