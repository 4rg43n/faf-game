extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	if GameManager.instance.player:
		text = str(abs(GameManager.instance.player.velocity.length())) + "m/s"
