class_name GameManager extends Node

signal player_synced()

@export var sky_3d: Sky3D

var player: PlayerController
var player_data: PlayerMetadata

var paused: bool = false

static var instance: GameManager
func _init() -> void:
	instance = self


func setup(new_player_data: PlayerMetadata):
	var current_peer_id : int = multiplayer.get_unique_id()
	if current_peer_id != new_player_data.peer_id:
		return
	var new_player = new_player_data.player_controller
	player = new_player
	player_data = new_player_data
	player_synced.emit()
