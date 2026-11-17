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
	player.current_equipment = CustomEnums.Equipment_Type.EMPTY_HAND
	if player.player_controller.left_hand_socket.get_child_count() != 0:
		var child_obj = player.player_controller.left_hand_socket.get_child(0)
		child_obj.process_mode = Node.PROCESS_MODE_ALWAYS
		if child_obj is RigidBody3D:
			var rigid_body := (child_obj as RigidBody3D)
			var force : Vector3 = 1000 * (-player.global_transform.basis.z) + 200 * Vector3.UP
			rigid_body.apply_force(force)
		child_obj.reparent(new_parent)
