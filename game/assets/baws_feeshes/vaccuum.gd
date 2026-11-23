extends LimboState

@export var sucking_boxes : Array[Area3D]

func _setup() -> void:
	for area : Area3D in sucking_boxes:
		area.monitorable = false
		area.monitoring = false

func _enter() -> void:
	var all_overlapping_bodies : Array[Node3D] = []
	for area : Area3D in sucking_boxes:
		area.monitorable = true
		area.monitoring = true
		area.body_entered.connect(_on_object_enter_area)
		all_overlapping_bodies.append_array(area.get_overlapping_bodies())
	for body in all_overlapping_bodies:
		_on_object_enter_area(body)

func _exit() -> void:
	for area : Area3D in sucking_boxes:
		area.monitorable = false
		area.monitoring = false
		area.body_entered.disconnect(_on_object_enter_area)

func _update(delta: float) -> void:
	pass

func _on_object_enter_area(body : Node3D) -> void:
	var body_owner := body.owner
	if body_owner is RigidBody3D or body_owner is PlayerMetadata:
		if body_owner is PlayerMetadata:
			var player_metadata := body_owner as PlayerMetadata
			player_metadata.player_controller.swallowed()
		else:
			body_owner.process_mode = Node.PROCESS_MODE_DISABLED
			body_owner.visible = false
		var ammo : Array = blackboard.get_var("current_ammo")
		ammo.append(body_owner)
		blackboard.set_var("current_ammo", ammo)
