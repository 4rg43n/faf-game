extends Camera3D

@export var player:Node3D=null

@export var follow_offset:=Vector3(0,2.5,1.5)
@export var follow_rot:=Vector3(-16.5,0,0)
@export var cam_sensitivity:=0.5
@export var invert_look:=-1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	#pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position=player.get_global_transform_interpolated()*follow_offset
	rotation.y=player.rotation.y

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# event.relative = how far the mouse moved this event, in pixels

		# yaw affects the player
		var deltax:float= -event.relative.x * cam_sensitivity
		var yaw:float=rotation_degrees.y + deltax
		player.rotation_degrees.y = yaw

		# camera pitch
		var deltay:float= event.relative.y * cam_sensitivity
		var pitch:float=clamp(rotation_degrees.x + invert_look*deltay, -80,80)
		rotation_degrees.x=pitch
