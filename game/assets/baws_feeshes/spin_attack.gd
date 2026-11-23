class_name SpinAttackState extends WaitForAnimationToFinish

@export var hit_boxes : Array[Area3D] = []

## Called once, when state is initialized.
func _setup() -> void:
	super._setup()
	for area : Area3D in hit_boxes:
		area.monitorable = false
		area.monitoring = false

## Called when state is entered.
func _enter() -> void:
	super._enter()
	for area : Area3D in hit_boxes:
		area.monitorable = true
		area.monitoring = true

## Called when state is exited.
func _exit() -> void:
	super._exit()
	for area : Area3D in hit_boxes:
		area.monitorable = false
		area.monitoring = false

## Called each frame when this state is active.
func _update(delta: float) -> void:
	super._update(delta)
	dispatch("&search_for_ammo")
