class_name ThrowBug extends Node

@export var new_parent : Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_released() and event.is_action("Throw"):
		_on_player_attempt_throw.rpc_id(1, multiplayer.get_unique_id())

@rpc("reliable", "any_peer", "call_local")
func _on_player_attempt_throw(peer_id : int) -> void:
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	if player.current_equipment == CustomEnums.Equipment_Type.EMPTY_HAND:
		return
	if player.player_controller.left_hand_socket.get_child_count() != 0:
		player.current_equipment = CustomEnums.Equipment_Type.EMPTY_HAND
		_throw_held_item_from_peer.rpc(player.peer_id, true)

@rpc("reliable", "any_peer",  "call_local")
func _throw_held_item_from_peer(peer_id : int, left_hand : bool = true) -> void:
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	var child_obj : RigidBody3D
	if left_hand:
		child_obj = player.player_controller.left_hand_socket.get_child(0)
	else:
		child_obj = player.player_controller.right_hand_socket.get_child(0)
	child_obj.process_mode = Node.PROCESS_MODE_ALWAYS
	if multiplayer.get_unique_id() == 1:
		var force : Vector3 = 1000 * (-player.global_transform.basis.z) + 200 * Vector3.UP
		child_obj.apply_force(force)
	child_obj.reparent(new_parent)
	child_obj.set_multiplayer_authority(1)
