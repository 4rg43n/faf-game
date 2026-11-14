class_name DynamicResizeToMatchViewport extends MarginContainer


func _ready() -> void:
	_update_margins()
	get_viewport().size_changed.connect(_update_margins)

func _update_margins() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var dx: int = int(viewport_size.x)
	var dy: int = int(viewport_size.y)

	add_theme_constant_override("margin_left", dx)
	add_theme_constant_override("margin_right", dx)
	add_theme_constant_override("margin_top", dy)
	add_theme_constant_override("margin_bottom", dy)
