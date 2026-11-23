extends ProgressBar

# ----UI----
@export var chaos_label : Label

# ----Sound----
@export var audio_player: AudioStreamPlayer
var ui_progess_down = preload("res://audio/sfx/ui_progress_down.mp3")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_player.stream = ui_progess_down;
	ChaosSystem.instance.chaos_changed.connect(_on_chaos_changed)


func _on_chaos_changed() -> void:
	audio_player.play()
	value = ChaosSystem.instance.current_chaos
	chaos_label.text = "Chaos: " + str(snapped(ChaosSystem.instance.current_chaos, 1)) + "%"
