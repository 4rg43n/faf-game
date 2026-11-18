class_name FleeingBait extends RigidBody3D

## basically the timer - they spawn randomly inside a bug pickup minigame and once they leave the area they despawn.
@export var speed_curve : Curve
@export var max_speed : float
@export var speed : float = 1

## ground direction (no flying) - we can allow flying in the flying class that extends this one.
@export var flee_direction : Vector3

func _ready() -> void:
	if not is_multiplayer_authority():
		return
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
	if not is_multiplayer_authority():
		return
	if not is_node_ready():
		await ready
	var up_dir: Vector3 = Vector3.UP
	var target_dir = state.linear_velocity.normalized()
	if target_dir.is_zero_approx():
		return
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
	if not is_multiplayer_authority():
		return
	apply_force(flee_direction * speed * delta)

func _enter_tree() -> void:
	if not is_multiplayer_authority():
		return
	if get_parent() is BoneAttachment3D:
		process_mode = ProcessMode.PROCESS_MODE_DISABLED

func on_interact(peer_id : int) -> void:
	on_pickup.rpc_id(1, peer_id)

@rpc("any_peer", "call_local", "reliable")
func on_pickup(peer_id : int) -> void:
	var player : PlayerMetadata = LobbyManager.instance.get_player_from_peer_id(peer_id)
	if player.current_equipment != CustomEnums.Equipment_Type.EMPTY_HAND:
		print("hand not empty")
		return
	player.current_equipment = CustomEnums.Equipment_Type.THROWABLE_OBJ
	_pickup_held_item_from_peer.rpc(peer_id, true)

@rpc("reliable", "any_peer", "call_local")
func _pickup_held_item_from_peer(peer_id : int, left_hand : bool = true) -> void:
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	var child_obj : RigidBody3D
	if left_hand:
		child_obj = player.player_controller.left_hand_socket.get_child(0)
	else:
		child_obj = player.player_controller.right_hand_socket.get_child(1)
	reparent(player.player_controller.left_hand_socket)
	position = Vector3(0,0,0)
	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	set_multiplayer_authority(peer_id)
