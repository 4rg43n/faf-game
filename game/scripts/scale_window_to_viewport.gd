class_name ExtendWindowToViewport extends Window

func _ready() -> void:
	get_tree().root.size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()

func _fit_to_viewport() -> void:
	var root_viewport : Viewport = get_tree().root
	
	position = root_viewport.position
	size = root_viewport.size
