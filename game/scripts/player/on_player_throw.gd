class_name ThrowBug extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_released() and event.is_action("Throw"):
		var peer_id : int = multiplayer.get_unique_id()
		var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
		#TODO implement zachy poo
		## remove from active or decrement count and then if we are at zero and go back to empty hand via spawner remove child
		var child_obj : RigidBody3D = player.get_active_item()
		#TODO we also need to get the spawnable scene string from the object - will be needed in set active as well
		var item_resource_scene_path : String = "?"
		if child_obj == null:
			return
		_throw_on_server.rpc_id(1, peer_id, item_resource_scene_path)

#runs on server - we retake authority away from player as it is now in the shared world.
@rpc("reliable", "any_peer", "call_local")
func _throw_on_server(peer_id : int, item_resource_scene_path : String) -> void:
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	var scene : PackedScene = load(item_resource_scene_path)
	if scene == null:
		printerr("couldnt find scene from path %s" % item_resource_scene_path)
		return
	var child_obj : RigidBody3D = scene.instantiate()
	InteractableItemSpawner.instance.add_child(child_obj)
	var force : Vector3 = 2500 * (player.player_controller.visuals.global_transform.basis.z) + 200 * Vector3.UP
	child_obj.apply_force(force)
