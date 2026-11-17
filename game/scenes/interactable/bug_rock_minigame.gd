class_name BugRockMiniGame extends InteractableObject

@export var pivot : Node3D
@export var minigame_camera : Camera3D
@export var bug_spawner : MultiplayerSpawner
@export var bug_spawn_area : CollisionShape3D

## LUT table
@export_range(5, 35) var num_bug_range : int
## give % chance of each bug we can spawn and their scene
@export var LUT_bugs : LUTPercentile

func on_interact(player_metadata : PlayerMetadata) -> void:
	#TODO lerp this + play sound + character animation
	pivot.rotation_degrees.z = 60
	player_metadata.player_controller.active_camera = minigame_camera
	#TODO have this callback come from elsewhere
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
		newest_bug.position = shape.to_global(local_point)
		bug_spawner.add_child(newest_bug)
