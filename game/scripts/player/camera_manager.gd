class_name CameraManager extends Node3D

@export var player: PlayerController
@export var spring_arm_pivot: Node3D
@export var spring_arm: SpringArm3D
@export var mouse_sensitivity: float = 0.005
@export var min_zoom_distance: float = 2.0
@export var max_zoom_distance: float = 25.0
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/2
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = PI/4

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if not Input.mouse_mode == Input.MouseMode.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		spring_arm_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm_pivot.rotation.y = wrapf(spring_arm_pivot.rotation.y, 0.0, TAU)

		spring_arm_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm_pivot.rotation.x = clamp(spring_arm_pivot.rotation.x, min_vertical_angle, max_vertical_angle)

	elif event.is_action_pressed("wheel_up"):
		if spring_arm.spring_length < min_zoom_distance:
			player.active_camera = player.first_person_cam
		else:
			spring_arm.spring_length -= 1
	elif event.is_action_pressed("wheel_down"):
		spring_arm.spring_length += 1
		spring_arm.spring_length = clamp(spring_arm.spring_length, min_zoom_distance, max_zoom_distance)
		if spring_arm.spring_length > min_zoom_distance:
			player.active_camera = player.third_person_cam
