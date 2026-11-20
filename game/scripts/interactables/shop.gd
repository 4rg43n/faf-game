extends InteractableObject


@rpc("any_peer", "reliable", "call_local")
func on_interact(activating_peer_id : int) -> void:
	if not is_multiplayer_authority():
		on_interact.rpc_id(1, activating_peer_id)
		return
	UI.instance
