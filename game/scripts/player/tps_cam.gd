extends Camera3D

@export var player:PlayerController

@export var cam_sensitivity:=0.005
@export var invert_look:=-1


func _unhandled_input(event: InputEvent) -> void:
	if not player.active_camera == self:
		return
	if event is InputEventMouseMotion:
		# event.relative = how far the mouse moved this event, in pixels

		# yaw affects the player
		var deltax:float= -event.relative.x * cam_sensitivity
		var yaw:float=rotation_degrees.y + deltax
		player.rotate_y(yaw * cam_sensitivity)

		# camera pitch
		var deltay:float= event.relative.y * cam_sensitivity
		var pitch:float=clamp(rotation_degrees.x + invert_look*deltay, -80,80)
		rotation_degrees.x=pitch
