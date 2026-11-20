class_name ThrowBug extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_released() and event.is_action("Throw"):
		var peer_id : int = multiplayer.get_unique_id()
		var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
		var active_item = player.hotbar[InventorySystem.instance.active_slot]
		if not active_item:
			return
		if not active_item.equipment_type == CustomEnums.Equipment_Type.THROWABLE_OBJ:
			return
		var item : Item = player.decrement_active_item()
		if item == null:
			return
		_throw_on_server.rpc_id(1, peer_id, item.item_scene.resource_path)

#runs on server - we retake authority away from player as it is now in the shared world.
@rpc("reliable", "any_peer", "call_local")
func _throw_on_server(peer_id : int, item_resource_scene_path : NodePath) -> void:
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	var scene : PackedScene = load(item_resource_scene_path)
	if scene == null:
		printerr("couldnt find scene from path %s" % item_resource_scene_path)
		return
	var child_obj : RigidBody3D = scene.instantiate()
	child_obj.set_multiplayer_authority(1)
	InteractableItemSpawner.instance.add_child(child_obj, true)
	if player.player_controller.LEFT_HANDED:
		child_obj.global_position = player.player_controller.left_hand_socket.global_position
		child_obj.global_basis = player.player_controller.left_hand_socket.global_basis
	else:
		child_obj.global_position = player.player_controller.right_hand_socket.global_position
		child_obj.global_basis = player.player_controller.right_hand_socket.global_basis
	var force : Vector3 = 2500 * (player.player_controller.visuals.global_transform.basis.z) + 200 * Vector3.UP
	child_obj.apply_force(force)
