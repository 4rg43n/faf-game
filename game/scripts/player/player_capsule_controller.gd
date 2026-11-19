class_name PlayerController extends CharacterBody3D

signal active_camera_changed(camera: Camera3D)

@export_group("Dev Flags")
@export var debug_scene_play:bool=false

@export_group("Nodes")
@export var first_person_cam : Camera3D
@export var third_person_cam : Camera3D
@export var third_person_pivot : Node3D
@export var visuals: Node3D
@export var animation_tree:AnimationTree
@export  var animation_player:AnimationPlayer
@export var interact_label: Label
@export var player_metadata : PlayerMetadata
@export var active_camera: Camera3D:
	set(camera):
		if camera == active_camera:
			return
		active_camera = camera
		make_current_player()
@export var shapeColl: CollisionShape3D
@export var left_hand_socket : BoneAttachment3D
@export var right_hand_socket : BoneAttachment3D

@export_group("Visual Settings")
@export var turn_speed: float = 10.0
@export var jump_start_time_scale:float = 1.5
@export var jump_end_time_scale:float = 3.0

# animation junk for jumping
@onready var animation_state:AnimationNodeStateMachinePlayback=\
	animation_tree.get("parameters/playback")
var was_on_floor:bool = true
var landing_requested:bool=false
@onready var landing_animation:Animation=\
	animation_player.get_animation("humanoid_animations/Jump_Land")
@onready var landing_duration: float = landing_animation.length / maxf(jump_end_time_scale, 0.001)
var landing_timer:float = 0.0

@export_group("")
@export var INTERACT_RAYCAST_LENGTH: float
@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 6.0

# TODO(Nef): I really hate how we have to do this, ask me for my pseudo-comp lookup idea later

const ASSUMED_MASS = 60.0

var owned_by_current_client : bool = false

var input_dir : Vector2

# ----DEV SETTINGS----
var regular_speed: float = SPEED
var dev_speed: float = 50.0

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# DEV TOOLS
	if OS.is_debug_build():
		check_dev_inputs()

	handle_move_input(delta)

	handle_interaction()

	move_and_slide()

	handle_animation(delta)

	update_locomotion()

func update_locomotion()->void:
	# get our speed
	var horizontal_speed:=Vector2(
		velocity.x,
		velocity.z).length()

	# set the blend	value
	var blend:=clampf(horizontal_speed/SPEED,
		0.0,
		1.0)

	# set the blend
	animation_tree.set("parameters/Locomotion/blend_position",
		blend);

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


func handle_move_input(delta: float) -> void:
	if GameManager.instance.paused:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		return

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		landing_requested=false
		animation_state.travel("Jump_Start")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction : Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	direction = direction.rotated(Vector3.UP, active_camera.global_rotation.y)

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Face the movement direction (Godot's forward is -Z)
		var target_yaw := atan2(direction.x, direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)


func handle_interaction():
	# INTERACT WITH ITEMS
	var space_state = get_world_3d().direct_space_state
	# use global coordinates, not local to node
	var interact_look_direction = -third_person_cam.global_transform.basis.z
	var query = PhysicsRayQueryParameters3D.create( third_person_cam.global_position,
	third_person_cam.global_position + interact_look_direction * INTERACT_RAYCAST_LENGTH)
	query.collision_mask = 4;
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	if result:
		interact_label.text = "She could interact but she has no method..." + result.collider.name
		var hit = result.collider
		if hit.has_method("on_interact"):
			interact_label.text = "press E to interact"
			if Input.is_key_pressed(KEY_E):
				hit.on_interact(player_metadata.peer_id)
	else:
		interact_label.text = "";


func check_dev_inputs():
	if Input.is_action_pressed("shift"):
		SPEED = dev_speed
	else:
		SPEED = regular_speed


func handle_animation(delta: float):
	var grounded := is_on_floor()
	animation_tree.set("parameters/Jump_Start/TimeScale/scale", jump_start_time_scale)
	animation_tree.set("parameters/Jump_Land/TimeScale/scale", jump_end_time_scale)

	# Detect landing after being airborne
	if grounded and not was_on_floor:
		if not landing_requested:
			landing_timer=0.0
			animation_tree.set("parameters/conditions/landing_done", false)
			animation_state.travel("Jump_Land")
			landing_requested=true
			animation_state.travel("Jump_Land")

	# check for out of jump
	# Note: This has to be done because AnimationTree does not support multiple transitions
	if grounded and animation_state.get_current_node()=="Jump_Land":
		landing_timer+=delta

		var moving:=input_dir.length()>0.1
		var finished:=landing_timer>=landing_duration-0.05 # account for xfade

		animation_tree.set("parameters/conditions/landing_done",
		moving or finished)


	# Reset for next jump
	if grounded and animation_state.get_current_node()=="Locomotion":
		landing_requested=false

	was_on_floor=grounded

	#var playback: AnimationNodeStateMachinePlayback = \
		#$AnimationTree.get("parameters/playback")

	#print(playback.get_current_node())
