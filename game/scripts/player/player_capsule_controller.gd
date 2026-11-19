class_name PlayerController extends CharacterBody3D

signal active_camera_changed(camera: Camera3D)

@onready var visuals: Node3D = $Visuals
@onready var animation_tree:AnimationTree = $AnimationTree
@onready var animation_player:AnimationPlayer=$AnimationPlayer

@export var turn_speed: float = 10.0

@export var debug_scene_play:bool=false

@export var first_person_cam : Camera3D
@export var third_person_cam : Camera3D
@export var third_person_pivot : Node3D

var can_move:bool=true

#####################################################################
# animation junk for jumping
@onready var animation_state:AnimationNodeStateMachinePlayback=\
	animation_tree.get("parameters/playback")
var was_on_floor:bool = true
var landing_requested:bool=false
@export var jump_start_time_scale:float = 1.5
@export var jump_end_time_scale:float = 3.0
@onready var landing_animation:Animation=\
	animation_player.get_animation("humanoid_animations/Jump_Land")
#####################################################################
# landing
@onready var landing_duration: float = landing_animation.length / maxf(jump_end_time_scale, 0.001)
var landing_timer:float = 0.0
@export var interact_label: Label
@export var INTERACT_RAYCAST_LENGTH: float
####################################################################
# spell junk
var is_holding_spell:bool=false
var time_holding_spell:float=0.0
@export var spell_enter_time_scale:float=2.0
####################################################################

@export var player_metadata : PlayerMetadata

@export var active_camera: Camera3D:
	set(camera):
		if camera == active_camera:
			return
		active_camera = camera
		make_current_player()

@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 6.0
@export var air_cap := 0.85
@export var air_accel := 800.0
@export var air_move_speed := 500.0

# TODO(Nef): I really hate how we have to do this, ask me for my pseudo-comp lookup idea later
@export var shapeColl: CollisionShape3D
const ASSUMED_MASS = 60.0

@export_group("Hands")
@export var left_hand_socket : BoneAttachment3D
@export var right_hand_socket : BoneAttachment3D
@export var left_hand_spawner : HandableSpawner
@export var right_hand_spawner : HandableSpawner
@export var LEFT_HANDED : bool = true

var owned_by_current_client : bool = false

var input_dir : Vector2
var wish_dir : Vector3

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

	handle_spell(delta)

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

func is_moving()->bool:
	var test_input = Input.get_vector("move_left", "move_right", "move_up", "move_down") # poll again because 'can_move' interferes

	if test_input.length()>0.1:
		return true
	else:
		return false

func handle_spell(delta: float)->void:
	if not is_holding_spell:
		if is_on_floor() and not is_moving() and Input.is_action_just_pressed("spell_down"): # pressed the button
			can_move=false
			is_holding_spell=true
			time_holding_spell=0.0
			animation_tree.set("parameters/Spell_Enter/TimeScale/scale", spell_enter_time_scale)
			animation_state.travel("Spell_Enter")
	else:
		if not is_on_floor() or is_moving(): # we fell, or we tried to move
			cancel_spell()
			animation_state.travel("Locomotion")
		elif Input.is_action_just_released("spell_down") or not is_holding_spell: # released the button. the holding spell check is in case we release control when Spell_Enter is playing
			cancel_spell()
			animation_state.travel("Spell_Shoot")
		else:
			time_holding_spell+=delta


func fire1()->void:
	if Input.is_action_just_pressed("fire1"):
		print_rich("[Color=red]Fire 1")

func fire2()->void:
	if Input.is_action_just_pressed("fire2"):
		print_rich("[Color=red]Fire 2")

func cancel_spell()->void:
	if is_holding_spell:
		can_move=true
		is_holding_spell=false

func _handle_air_physics(delta: float) -> void:
	var cur_speed_in_wish_dir = velocity.dot(wish_dir)
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		velocity += accel_speed * wish_dir


func _handle_ground_physics(delta: float) -> void:
	velocity.x = wish_dir.x * SPEED
	velocity.z = wish_dir.z * SPEED



func handle_move_input(delta: float) -> void:
	if GameManager.instance.paused:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		return

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		cancel_spell() # cancels a spell if we were trying to cast
		velocity.y = JUMP_VELOCITY
		landing_requested=false
		animation_state.travel("Jump_Start")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.

	# stop move input if we can't move. Doing it here lets physics finish up
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	wish_dir = (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	wish_dir = wish_dir.rotated(Vector3.UP, active_camera.global_rotation.y)

	if is_on_floor():
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)

	if wish_dir:
		# ----Animation stuff----
		var target_yaw := atan2(wish_dir.x, wish_dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_yaw, turn_speed * delta)
		# ----Animation stuff----


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
