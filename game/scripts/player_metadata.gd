class_name PlayerMetadata extends Node3D

@export var peer_id : int
@export var steam_id : int
@export var player_controller : PlayerController

var spawn_location : Node3D = null

func init(in_peer_id : int, in_steam_id : int, in_spawn_location : Node3D) -> void:
	print("spawning in a new client for peer ", String.num_int64(in_peer_id))
	peer_id = in_peer_id
	steam_id = in_steam_id
	spawn_location = in_spawn_location

func _enter_tree() -> void:
	var was_authority : bool = is_multiplayer_authority()
	set_multiplayer_authority(multiplayer.get_unique_id())
	print("was auth %s but now is %s" % [was_authority, is_multiplayer_authority()])

	if not is_multiplayer_authority():
		print("[_enter_tree] we dont own authority ", peer_id)
		process_mode = Node.PROCESS_MODE_DISABLED
		set_process(false)
		set_physics_process(false)
	else:
		print("[_enter_tree] we own authority ", peer_id)
