class_name DriveBy extends LimboState

func _setup() -> void:
	pass

func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update(delta: float) -> void:
	var current_fire_target : Node3D = blackboard.get_var(&"current_fire_target")
	if current_fire_target == null:
		current_fire_target = OctoRockBehavior.instance.find_closest_player()
		if current_fire_target == null:
			current_fire_target = OctoRockBehavior.instance.fire_direction
		blackboard.set_var(&"current_fire_target", current_fire_target)
	#in reality we would slowly rotate then take time to fire all rounds
	OctoRockBehavior.instance.look_at(current_fire_target.global_position)
	var current_ammo : Array = blackboard.get_var(&"current_ammo")
	for ammo in current_ammo:
		if ammo is PlayerMetadata:
			var player_controller := (ammo as PlayerMetadata).player_controller
			player_controller.spit_out()
		else:
			var rigid_body := ammo as RigidBody3D
			rigid_body.visible = true
			rigid_body.process_mode = Node.PROCESS_MODE_INHERIT
			var force : Vector3 = 2500 * (OctoRockBehavior.instance.global_transform.basis.z) + 200 * Vector3.UP
			rigid_body.apply_force(force)
	blackboard.set_var(&"current_ammo", [])
	##we need to uh shoot them ehre like when we throw sheeet
	##calculate how hard and at want direction we need to throw to hit da player at this distance

	dispatch(LimboState.EVENT_FINISHED)
