class_name Bobber extends RigidBody3D

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@export var label_3d: Label3D

signal fish_bit_bobber(caught: bool)

var near_ground : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_bobber_hit)
	label_3d.visible = false


func hit_water():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	set_deferred("freeze", true)
	
	start_fish_delay_timer()

## TODO[Ethan]: Should just move this label into living on the player so we 
## don't have to worry about setting a position
func notify_hook(start_location : Vector3):
	label_3d.visible = true
	label_3d.global_position = start_location # set to where the bobber is at
	label_3d.global_position.y += 3
	await get_tree().create_timer(1).timeout
	label_3d.visible = false


func start_fish_delay_timer():
	await get_tree().create_timer(randf_range(4, 12)).timeout
	# await get_tree().create_timer(randf_range(4, 12)).timeout
	# label_3d.visible = true
	# label_3d.global_position = self.global_position # set to where the bobber is at
	# label_3d.global_position.y += 2
	
	fish_bit_bobber.emit(true)
	await get_tree().create_timer(1).timeout
	fish_bit_bobber.emit(false)
	# label_3d.visible = false
	
	# await get_tree().create_timer(5).timeout
	# start_fish_delay_timer()
	
	# TODO[Ethan] - replace with tween later
	# var tween := create_tween().set_parallel(true)
	# tween.tween_property(label_3d, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# tween.tween_property(label_3d, "global_position:y", label_3d.global_position.y + 1.2, 1).set_ease(Tween.EASE_OUT)
	# tween.tween_property(label_3d, "modulate:a", 0.0, 1 * 0.6).set_delay(1 * 0.4)


func _bobber_hit(_body: Node) -> void:
	print("hit something")
	
	# if near_ground:
		# Close enough to something underneath to stop
		# print("We should stop moving")
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	set_deferred("freeze", true)

"""
func _physics_process(_delta: float) -> void:
	if ray_cast_3d.is_colliding():
		print("Near ground")
		# near_ground = true
		
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		set_deferred("freeze", true)
"""
