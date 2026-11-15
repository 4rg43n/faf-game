class_name GameManager extends Node

@export var player: CharacterBody3D
@export var sky_3d: Sky3D

static var instance: GameManager
func _init() -> void:
	instance = self
