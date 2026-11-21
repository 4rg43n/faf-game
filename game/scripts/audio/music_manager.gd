class_name MusicManager extends Node

@export var music_player: AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_player.play()
