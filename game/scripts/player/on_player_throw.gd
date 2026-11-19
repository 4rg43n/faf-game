class_name ThrowBug extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_released() and event.is_action("Throw"):
		_on_player_attempt_throw.rpc_id(1, multiplayer.get_unique_id())

#runs on server - we retake authority away from player as it is now in the shared world.
@rpc("reliable", "any_peer", "call_local")
func _on_player_attempt_throw(peer_id : int) -> void:
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	var child_obj : RigidBody3D = player.get_active_item()
	if child_obj == null:
		return
	child_obj.reparent(InteractableItemSpawner.instance)
	var force : Vector3 = 2500 * (player.player_controller.visuals.global_transform.basis.z) + 200 * Vector3.UP
	child_obj.apply_force(force)
