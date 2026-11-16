class_name PlayerMetadata extends Node3D

@export var peer_id : int
@export var steam_id : int
@export var player_controller : PlayerController

func init(in_peer_id : int, in_steam_id : int, in_spawn_location : Node3D) -> void:
	print("spawning in a new client for peer ", String.num_int64(in_peer_id))
	peer_id = in_peer_id
	steam_id = in_steam_id
	player_controller.position = in_spawn_location.position
