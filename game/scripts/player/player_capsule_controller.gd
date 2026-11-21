class_name PlayerController extends CharacterBody3D

signal active_camera_changed(camera: Camera3D)

#region Exports
@export_group("Nodes")
@export var first_person_cam : Camera3D
@export var third_person_cam : Camera3D
@export var third_person_pivot : Node3D
@export var player_metadata : PlayerMetadata
@export var visuals: Node3D
@export var animation_tree: AnimationTree
@export var animation_player: AnimationPlayer
@export var interact_label: Label
@export var fishing_label: Label
@export var super_jump_label: Label
@export var super_jump_bar: ProgressBar
@export var active_camera: Camera3D:
	set(camera):
		if camera == active_camera:
			return
		active_camera = camera
		make_current_player()
# TODO(Nef): I really hate how we have to do this, ask me for my pseudo-comp lookup idea later
@export var shapeColl: CollisionShape3D

@export_group("Hands")
@export var left_hand_socket : BoneAttachment3D
@export var right_hand_socket : BoneAttachment3D
@export var left_hand_spawner : HandableSpawner
@export var right_hand_spawner : HandableSpawner
@export var LEFT_HANDED : bool = true

@export_group("Misc Settings")
@export var turn_speed: float = 10.0
@export var INTERACT_RAYCAST_LENGTH: float

@export_group("Animation Settings")
#####################################################################
# animation junk for jumping
@onready var animation_state:AnimationNodeStateMachinePlayback=\
	animation_tree.get("parameters/Locomotion/playback")
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

####################################################################
# spell junk
@onready var animation_state_attacks:AnimationNodeStateMachinePlayback=\
	animation_tree.get("parameters/Attacks/playback")
@export var spell_shoot_time_scale:float=1
####################################################################
# punches
@export var punch_light_speed_scale:float = 2
@export var punch_heavy_speed_scale:float = 2
####################################################################

@export_group("Movement Settings")
@export var walk_speed: float = 7.0
@export var run_speed: float = 8.5
@export var ground_accel: float = 14.0
@export var ground_decel: float = 10.0
@export var ground_friction: float = 6.0
@export var jump_velocity: float = 5.0
@export var max_jump_velocity: float = 9.0
@export var super_jump_charge_rate: float = 8.0
@export var air_cap := 0.85
@export var air_accel := 800.0
@export var air_move_speed := 500.0
#endregion Exports

const ASSUMED_MASS = 60.0

# ----Sound----
var sound_player := AudioStreamPlayer.new()
var reverb_effect = AudioServer.get_bus_effect(2, 0)  # Adjust index as necessary
var JumpSounds = [preload("res://assets/sfx/main-char/jump-1.wav"), preload("res://assets/sfx/main-char/jump-2.wav"), preload("res://assets/sfx/main-char/jump-3.wav")]

# ----Misc----
var can_move : bool = true
var owned_by_current_client : bool = false

# ----Movement----
var input_dir : Vector2
var wish_dir : Vector3
var move_speed: float = walk_speed
var cur_ground_decel : float = ground_decel
var cur_ground_friction : float = ground_friction

var current_jump_velocity : float = jump_velocity
var available_jumps : int = 1
var max_available_jumps : int = 1
var available_wall_jumps : int = 1
var max_available_wall_jumps : int = 1
var max_slide_time : float = 0.75
var time_sliding : float = 0.0

var ui_hidden : bool = false

# ----DEV SETTINGS----
var dev_speed: float = 50.0
var debug_scene_play : bool = false

func _ready():
	add_child(sound_player)
	active_camera = third_person_cam

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	handle_move_input(delta)

	handle_interaction()

	handle_fire1()
	handle_fire2()
	handle_fire3()

	move_and_slide()

	handle_animation(delta)

	update_locomotion()

	if ui_hidden:
		interact_label.visible = false
		fishing_label.visible = false
		super_jump_label.visible = false
		super_jump_bar.visible = false

	#print(animation_state)
	#print(animation_state.get_current_node())

func update_locomotion()->void:
	# get our speed
	var horizontal_speed:=Vector2(
		velocity.x,
		velocity.z).length()

	# set the blend	value
	var blend:=clampf(horizontal_speed/move_speed,
		0.0,
		1.0)

	# set the blend
	animation_tree.set("parameters/Locomotion/Locomotion/blend_position",
		blend);

func make_current_player() -> void:
	if not is_node_ready():
		await ready
	if not debug_scene_play:
		var parent_peer_id : int = player_metadata.peer_id
		var current_peer_id : int = multiplayer.get_unique_id()
		if current_peer_id != parent_peer_id:
			return
	owned_by_current_client = true
	active_camera.make_current()
	active_camera_changed.emit(active_camera)

func is_moving()->bool:
	var test_input = Input.get_vector("move_left", "move_right", "move_up", "move_down") # poll again because 'can_move' interferes

	if test_input.length()>0.1:
		return true
	else:
		return false

func handle_fire1()->void:
	if Input.is_action_just_pressed("fire1"):
		animation_tree.set("parameters/Attacks/Punch_Light/TimeScale/scale", punch_light_speed_scale)
		animation_state_attacks.start("Punch_Light")
		animation_tree.set(
			"parameters/UpperBodyAttack/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)

func handle_fire2()->void:
	if Input.is_action_just_pressed("fire2"):
		animation_tree.set("parameters/Attacks/Punch_Light/TimeScale/scale", punch_heavy_speed_scale)
		animation_state_attacks.start("Punch_Heavy")
		animation_tree.set(
			"parameters/UpperBodyAttack/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)

func handle_fire3()->void:
	if Input.is_action_just_pressed("fire3"):
		animation_tree.set("parameters/Attacks/Spell_Shoot/TimeScale/scale", spell_shoot_time_scale)
		animation_state_attacks.start("Spell_Shoot")
		animation_tree.set(
			"parameters/UpperBodyAttack/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func clip_velocity(normal: Vector3, overbounce : float) -> void:
	var backoff : float = velocity.dot(normal) * overbounce

	if backoff >= 0: return

	var change := normal * backoff
	velocity -= change

	var adjust := velocity.dot(normal)
	if adjust < 0.0:
		velocity -= normal * adjust


func is_surface_too_steep(normal: Vector3) -> bool:
	var max_slope_ang_dot = Vector3(0, 1, 0).rotated(Vector3(1.0, 0, 0), floor_max_angle).dot(Vector3(0, 1, 0))
	return normal.dot(Vector3(0, 1, 0)) < max_slope_ang_dot


func _handle_air_physics(delta: float) -> void:
	var cur_speed_in_wish_dir = velocity.dot(wish_dir)
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		velocity += accel_speed * wish_dir

	if is_on_wall():
		if is_surface_too_steep(get_wall_normal()):
			motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		clip_velocity(get_wall_normal(), 1) # Allows surfing

func _handle_ground_physics(delta: float) -> void:
	var cur_speed_in_wish_dir = velocity.dot(wish_dir)
	var add_speed_till_cap = move_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * move_speed
		accel_speed = min(accel_speed, add_speed_till_cap)
		velocity += accel_speed * wish_dir

	var control = max(velocity.length(), cur_ground_decel)
	var drop = control * cur_ground_friction * delta
	var new_speed = max(velocity.length() - drop, 0.0)
	if velocity.length() > 0:
		new_speed /= velocity.length()
	velocity *= new_speed


func handle_move_input(delta: float) -> void:
	if GameManager.instance.paused:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		return

	var jump_percent = current_jump_velocity - jump_velocity
	if jump_percent == 0:
		super_jump_bar.value = 0
	else:
		super_jump_bar.value = (current_jump_velocity - jump_velocity) / (max_jump_velocity - jump_velocity) * 100

	if is_on_floor():
		available_jumps = max_available_jumps
		available_wall_jumps = max_available_wall_jumps
		if Input.is_action_pressed("ctrl"):
			current_jump_velocity = clampf(current_jump_velocity + super_jump_charge_rate * delta, jump_velocity, max_jump_velocity)
			if velocity.length() > walk_speed/2 and time_sliding < max_slide_time:
				cur_ground_decel = ground_decel / 10
				cur_ground_friction = ground_friction / 10
				time_sliding += delta
			else:
				cur_ground_decel = ground_decel
				cur_ground_friction = ground_friction
		else:
			current_jump_velocity = jump_velocity
			cur_ground_decel = ground_decel
			cur_ground_friction = ground_friction
			time_sliding = 0

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_wall_only() and available_wall_jumps > 0:
			available_wall_jumps -= 1
			velocity.y = current_jump_velocity
			if(randi() % 10 < 9):
				reverb_effect.room_size = RainSystem.instance.amount_indoors / 2
				sound_player.stream = JumpSounds.pick_random()
				sound_player.play()
		elif available_jumps > 0:
			velocity.y = current_jump_velocity
			landing_requested=false
			animation_state.travel("Jump_Start")
			if not is_on_floor():
				available_jumps -= 1
			if(randi() % 10 < 9):
				reverb_effect.room_size = RainSystem.instance.amount_indoors / 2
				sound_player.stream = JumpSounds.pick_random()
				sound_player.play()
		current_jump_velocity = jump_velocity

	if Input.is_action_pressed("shift"):
		move_speed = run_speed
	else:
		move_speed = walk_speed

	# DEV TOOLS
	if OS.is_debug_build() and debug_scene_play:
		check_dev_inputs()

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
			interact_label.text = "Press E to interact"
			if Input.is_key_pressed(KEY_E):
				hit.on_interact(player_metadata.peer_id)
	else:
		interact_label.text = "";


func check_dev_inputs():
	if Input.is_action_pressed("shift"):
		move_speed = dev_speed
	else:
		move_speed = walk_speed


func handle_animation(delta: float):
	var grounded := is_on_floor()
	animation_tree.set("parameters/Locomotion/Jump_Start/TimeScale/scale", jump_start_time_scale)
	animation_tree.set("parameters/Locomotion/Jump_Land/TimeScale/scale", jump_end_time_scale)

	# Detect landing after being airborne
	if grounded and not was_on_floor:
		if not landing_requested:
			landing_timer=0.0
			animation_tree.set("parameters/Locomotion/conditions/landing_done", false)
			animation_state.travel("Jump_Land")
			landing_requested=true

	# check for out of jump
	# Note: This has to be done because AnimationTree does not support multiple transitions
	if grounded and animation_state.get_current_node()=="Jump_Land":
		landing_timer+=delta

		var moving:=input_dir.length()>0.1
		var finished:=landing_timer>=landing_duration-0.05 # account for xfade

		animation_tree.set("parameters/Locomotion/conditions/landing_done",
		moving or finished)


	# Reset for next jump
	if grounded and animation_state.get_current_node()=="Locomotion":
		landing_requested=false

	was_on_floor=grounded


func hide_ui():
	ui_hidden = true
