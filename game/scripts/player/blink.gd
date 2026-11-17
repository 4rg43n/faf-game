extends MeshInstance3D

@export var blink_shape_name:String="eyes.closed"

@export var min_blink_interval:float = 2.0
@export var max_blink_interval:float=3.0

@export var min_close_duration:float = 0.06
@export var max_close_duration:float=0.12

@export var min_open_duration:float=0.10
@export var max_open_duration:float=0.18

var blink_index:int=-1

func _ready() -> void:
	blink_index=find_blend_shape_by_name(blink_shape_name)
	
	if blink_index==-1:
		push_error("Blink blend shape not found: "+blink_shape_name)
		return
	
	print_rich("[Color=yellow]Starting blink loop")
	blink_loop()
	
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


func set_blink_weight(weight: float) -> void:
	set_blend_shape_value(blink_index, weight)
