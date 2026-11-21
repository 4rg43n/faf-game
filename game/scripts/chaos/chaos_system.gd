class_name ChaosSystem extends Node

signal chaos_changed()

var current_chaos : float = 100.0:
	set(value):
		current_chaos = clampf(value, 0, 100.0)
		if current_chaos <= 66.0 and not beetle_already_spawned:
			_spawn_beetle_boss()
		if current_chaos <= 33.0 and not octopus_already_spawned:
			_spawn_octopus_boss()
		chaos_changed.emit()
var max_chaos : float = 100.0
var chaos_pieces : int = 0
var chaos_pieces_needed : int = 1

var beetle_already_spawned : bool = false
var octopus_already_spawned : bool = false

static var instance: ChaosSystem

func _init() -> void:
	instance = self


func _spawn_beetle_boss():
	pass


func _spawn_octopus_boss():
	pass


func _start_end_game_scene():
	pass


func _decrease_chaos():
	chaos_pieces += 1
	if chaos_pieces >= chaos_pieces_needed:
		chaos_pieces = 0
		current_chaos -= 1.0
