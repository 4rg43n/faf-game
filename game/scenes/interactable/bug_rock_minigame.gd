class_name BugRockMiniGame extends InteractableObject

@export var pivot : Node3D
@export var minigame_camera : Camera3D
@export var bug_spawner : MultiplayerSpawner
@export var bug_spawn_area : CollisionShape3D

## LUT table
@export_range(5, 35) var num_bug_range : int
## give % chance of each bug we can spawn and their scene
@export var LUT_bugs : LUTPercentile
var active_player : PlayerMetadata = null
var original_camera : Camera3D = null

#TODO remove when simone implements interactions proppper
@export var interaction_area : Area3D
var player_in_area : bool = false

func _ready() -> void:
	var area : Area3D = bug_spawn_area.get_parent()
	area.body_exited.connect(_on_bug_leave_area)
	bug_spawner.child_exiting_tree.connect(mini_game_over)

	interaction_area.body_entered.connect(_on_player_interact)
	interaction_area.body_exited.connect(_on_player_leave)

func _on_player_interact(body : Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	player_in_area = true

func _on_player_leave(body : Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	if player_in_area and active_player != null:
		active_player.player_controller.active_camera = original_camera
	player_in_area = false

#TODO remove when simone implements interactions proppper
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_released() and event.keycode == KEY_E and player_in_area:
		var player_metadata : PlayerMetadata = LobbyManager.instance.get_current_player(multiplayer.get_unique_id())
		on_interact(player_metadata)

func on_interact(player_metadata : PlayerMetadata) -> void:
	if active_player != null:
		return
	active_player = player_metadata
	pivot.rotation_degrees.z = 60
	original_camera = player_metadata.player_controller.active_camera
	player_metadata.player_controller.active_camera = minigame_camera
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
		newest_bug.set_multiplayer_authority(active_player.peer_id)
		bug_spawner.add_child(newest_bug)

func _on_bug_leave_area(body : Node3D) -> void:
	if not body.is_in_group("Bait"):
		return
	bug_spawner.remove_child(body)
	body.queue_free()

func mini_game_over(node) -> void:
	print("losing a bug ", node.name)
	if bug_spawner.get_child_count() > 1:
		return
	print("game over!")
	pivot.rotation_degrees.z = 0
	if active_player != null:
		active_player.player_controller.active_camera = original_camera
	original_camera = null
	active_player = null
