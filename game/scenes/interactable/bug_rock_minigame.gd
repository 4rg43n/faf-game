class_name BugRockMiniGame extends InteractableObject

@export var pivot : Node3D
@export var minigame_camera : Camera3D
@export var bug_spawner : MultiplayerSpawner
@export var bug_spawn_area : CollisionShape3D
@export var bug_spawn_area_area : Area3D

## LUT table
@export_range(5, 35) var num_bug_range : int
## give % chance of each bug we can spawn and their scene
@export var LUT_bugs : LUTPercentile
var active_player : PlayerMetadata = null
var original_camera : Camera3D = null

@rpc("any_peer", "reliable", "call_local")
func on_interact(activating_peer_id : int) -> void:
	if not is_multiplayer_authority():
		on_interact.rpc_id(1, activating_peer_id)
		return
	if active_player != null:
		return
	var player_metadata : PlayerMetadata = LobbyManager.instance.get_player_from_peer_id(activating_peer_id)
	active_player = player_metadata
	pivot.rotation_degrees.z = 60
	mini_game_start.rpc_id(activating_peer_id)
	on_open_animation_finish()

## spawn all the buggies
func on_open_animation_finish() -> void:
	for i in num_bug_range:
		var bug_scene : PackedScene = LUT_bugs.roll_for_object()
		var newest_bug : FleeingBait = bug_scene.instantiate()
		newest_bug.name = "Bug_%s" % i

		var shape := bug_spawn_area.shape as BoxShape3D
		var half_size := shape.size * 0.5
		var local_point := Vector3(
			randf_range(-half_size.x, half_size.x),
			randf_range(-half_size.y, half_size.y),
			randf_range(-half_size.z, half_size.z)
		)
		newest_bug.position = to_global(local_point)
		newest_bug.set_multiplayer_authority(1)
		bug_spawner.add_child(newest_bug)

#server
@rpc("any_peer", "reliable", "call_local")
func mini_game_start() -> void:
	var player_metadata : PlayerMetadata = LobbyManager.instance.get_player_from_peer_id(multiplayer.get_unique_id())
	active_player = player_metadata
	original_camera = player_metadata.player_controller.active_camera
	player_metadata.player_controller.active_camera = minigame_camera
	mini_game_over()

#client
@rpc("any_peer", "reliable", "call_local")
func mini_game_over() -> void:
	if original_camera != null:
		var player_metadata : PlayerMetadata = LobbyManager.instance.get_player_from_peer_id(multiplayer.get_unique_id())
		player_metadata.player_controller.active_camera = original_camera
	original_camera = null
	active_player = null

@rpc("any_peer", "reliable", "call_local")
func on_animation_end() -> void:
	if original_camera != null:
		active_player.player_controller.active_camera = original_camera
