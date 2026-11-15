class_name LightningController extends Node3D

signal lightning_strike

@export var lightning: Node3D
@export var thunder_audio: AudioStreamPlayer3D
@export var lightning_directional_light: DirectionalLight3D

@export var lightning_min_distance: float = 25.0
@export var lightning_max_distance: float = 500.0

var sky_3d: Sky3D

var is_storming: bool = false
var is_flashing: bool = false

var default_skydome_energy: float = 1.0

func _ready() -> void:
	visible = is_flashing

	lightning_strike.connect(play_thunder)

func _physics_process(_delta: float) -> void:
	if is_storming:
		if !is_flashing and !thunder_audio.playing:
			if randf() < 1.0 / 60.0:
				start_lightning()


func start_lightning() -> void:
	pass


func play_thunder() -> void:
	pass
