
@tool
extends EditorScript

func _run() -> void:
	var source = load(
        "res://assets/animations/quaternius/AnimationLibrary_Godot_Standard.glb"
	)

	var scene = source.instantiate()
	var player = scene.get_node("AnimationPlayer")

	var original = player.get_animation_library("")
	var library = AnimationLibrary.new()

	for animation_name in original.get_animation_list():
		var animation = original.get_animation(animation_name)
		library.add_animation(animation_name, animation.duplicate(true))

	var path = "res://assets/animations/quaternius/humanoid_animations.tres"

	var error = ResourceSaver.save(library, path)

	if error == OK:
		print("Saved ", library.get_animation_list().size(), " animations.")
	else:
		push_error("Failed to save animation library: ", error)

	scene.free()
