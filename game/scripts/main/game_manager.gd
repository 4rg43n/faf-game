class_name GameManager extends Node

@export var player: CharacterBody3D
@export var sky_3d: Sky3D
@export var third_person_cam: Camera3D

var active_camera: Camera3D

static var instance: GameManager
func _init() -> void:
	instance = self


func _process(_delta: float) -> void:
	if not active_camera:
		active_camera = third_person_cam
