class_name GameManager extends Node

@export var player: CharacterBody3D

static var instance: GameManager
func _init() -> void:
	instance = self
