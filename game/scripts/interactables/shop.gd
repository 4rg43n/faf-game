class_name Shop extends InteractableObject

@export var main_inventory : Array[Item]

static var instance: Shop

func _init() -> void:
	instance = self


@rpc("any_peer", "reliable", "call_local")
func on_interact(activating_peer_id : int) -> void:
	if not is_multiplayer_authority():
		on_interact.rpc_id(activating_peer_id, activating_peer_id)
		return
	UI.instance.show_shop()
