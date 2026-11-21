extends ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ChaosSystem.instance.chaos_changed.connect(_on_chaos_changed)


func _on_chaos_changed() -> void:
	value = ChaosSystem.instance.current_chaos
