class_name HandableSpawner extends MultiplayerSpawner

var hand_socket : BoneAttachment3D

func _ready() -> void:
	child_entered_tree.connect(_on_child_enter_tree)
	child_exiting_tree.connect(_on_child_exit_tree)
	hand_socket = get_node_or_null(spawn_path)

#called from the player (client) trying to pickup an item.
func pickup_item(child_obj : Node3D) -> void:
	if not child_obj.has("item_resource"):
		return
	var item_resource : Item = child_obj.get("item_resource")
	var peer_id : int = multiplayer.get_unique_id()
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	if not player.add_item_if_possible(item_resource):
		print("Inventory full, cannot hold anymore items.")
		return
	print("LETS FUCKING GOOOO: " + str(player.main_inventory) + "\n" + str(player.hotbar))
	#delete it it is tracked in our inventory system.
	if player.current_equipment != CustomEnums.Equipment_Type.EMPTY_HAND:
		child_obj.queue_free()
		return
	player.current_equipment = CustomEnums.Equipment_Type.THROWABLE_OBJ
	child_obj.reparent(hand_socket)

#grabs items!
#asumes we already set_multiplayer_authority to the player that is picking up the item
func _on_child_enter_tree(child_obj : Node3D) -> void:
	if not is_multiplayer_authority():
		return
	child_obj.position = Vector3(0,0,0)
	child_obj.process_mode = ProcessMode.PROCESS_MODE_DISABLED


##throws items! - returns auth to host server
func _on_child_exit_tree(child_obj : Node3D) -> void:
	if not is_multiplayer_authority():
		return
	var peer_id : int = child_obj.get_multiplayer_authority()
	child_obj.set_multiplayer_authority(1)
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	player.current_equipment = CustomEnums.Equipment_Type.EMPTY_HAND
	child_obj.process_mode = Node.PROCESS_MODE_ALWAYS
