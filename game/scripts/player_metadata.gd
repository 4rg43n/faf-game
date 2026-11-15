class_name PlayerMetadata extends Node3D

@export var peer_id : int
@export var steam_id : int
@export var camera : Camera3D
@export var player_controller : PlayerController

func init(in_peer_id : int, in_steam_id : int) -> void:
	peer_id = in_peer_id
	steam_id = in_steam_id

	if multiplayer.get_unique_id() == peer_id:
		camera.make_current()
		print("this client is the owner!")
