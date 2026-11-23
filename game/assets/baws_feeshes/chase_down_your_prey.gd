class_name GoSuckethUpYourTarget extends LimboState

@export var close_enough : float = 5

func _setup() -> void:
	pass

func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update(delta: float) -> void:
	var current_suck_target : Node3D = blackboard.get_var(&"current_suck_target")
	if current_suck_target == null:
		current_suck_target = OctoRockBehavior.instance.find_closest_ammo()
		if current_suck_target == null:
			return
		blackboard.set_var(&"current_suck_target", current_suck_target)
	var target_location := current_suck_target.global_position
	var dir := (OctoRockBehavior.instance.global_position - target_location).normalized()
	var aabb := OctoRockBehavior.instance.mesh.get_aabb()
	target_location += dir * maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	##TODO implement navpath dont just teleport!
	OctoRockBehavior.instance.global_position = target_location
	OctoRockBehavior.instance.look_at(current_suck_target.global_position)

	if target_location.distance_squared_to(OctoRockBehavior.instance.global_position) <= close_enough:
		dispatch(LimboState.EVENT_FINISHED)
