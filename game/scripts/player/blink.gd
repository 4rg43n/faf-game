extends MeshInstance3D

@export var blink_shape_name:String="eyes.closed"

@export var min_blink_interval:float = 2.0
@export var max_blink_interval:float=4.0

@export var min_close_duration:float = 0.06
@export var max_close_duration:float=0.12

@export var min_open_duration:float=0.10
@export var max_open_duration:float=0.18

var blink_index:int=-1

@export var look_left:String="look.l"
@export var look_right:String="look.r"
@export var look_up:String="look.u"
@export var look_down:String="look.d"

var horiz_look_max:float=0.5
var vert_look_max:float=0.5
var look_left_index:int=-1
var look_right_index:int=-1
var look_up_index:int=-1
var look_down_index:int=-1

@export var min_wander_interval:float = 1.0
@export var max_wander_interval:float=3.0


func _ready() -> void:
	blink_index=find_blend_shape_by_name(blink_shape_name)
	
	look_left_index=find_blind_shape_by_name(look_left)
	look_right_index=find_blind_shape_by_name(look_right)
	look_up_index=find_blind_shape_by_name(look_up)
	look_down_index=find_blind_shape_by_name(look_down)
	
	if blink_index==-1:
		push_error("Blink blend shape not found: "+blink_shape_name)
		return
	
	if look_left_index==-1:
		push_error("Look left blend shape not found: "+look_left)
	if look_right_index==-1:
		push_error("Look right blend shape not found: "+look_right)
	if look_up_index==-1:
		push_error("Look up blend shape not found: "+look_up)
	if look_down_index==-1:
		push_error("Look down blend shape not found: "+look_down)
	
	blink_loop()
	eye_wander_loop()
	
func find_blind_shape_by_name(shape_name:String)->int:
	for i in range(mesh.get_blend_shape_count()):
		if mesh.get_blend_shape_name(i)==shape_name:
			return i
	
	return -1

func blink_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(
			randf_range(min_blink_interval, max_blink_interval)
			).timeout

		if not is_inside_tree():
			return

		var close_duration := randf_range(
			min_close_duration,
			max_close_duration
			)

		var open_duration := randf_range(
			min_open_duration,
			max_open_duration
			)

		var tween := create_tween()

		tween.tween_method(
			set_blink_weight,
			0.0,
			1.0,
			close_duration
			)

		tween.tween_method(
			set_blink_weight,
			1.0,
			0.0,
			open_duration
			)

		await tween.finished

func eye_wander_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(
			randf_range(min_wander_interval, max_wander_interval)
			).timeout
		
		var weightx:float = randf_range(-horiz_look_max, horiz_look_max)
		var weighty:float = randf_range(-vert_look_max, vert_look_max)
		
		set_eye_weight(weightx, weighty)

func set_blink_weight(weight: float) -> void:
	set_blend_shape_value(blink_index, weight)

func set_eye_weight(weightx:float, weighty:float)->void:
	var look_left_bs:float=0.0
	var look_right_bs:float=0.0
	var look_up_bs:float=0.0
	var look_down_bs:float=0.0
	
	if weightx<0:
		look_left_bs=weightx
		look_right_bs=0
	else:
		look_right_bs=weightx
		look_left_bs=0
	
	if weighty<0:
		look_down_bs=weighty
		look_up_bs=0
	else:
		look_down_bs=0
		look_up_bs=weighty
	
	set_blend_shape_value(look_left_index, look_left_bs)
	set_blend_shape_value(look_right_index, look_right_bs)
	set_blend_shape_value(look_up_index, look_up_bs)
	set_blend_shape_value(look_down_index, look_down_bs)
