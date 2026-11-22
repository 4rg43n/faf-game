class_name ChaosSystem extends Node

signal chaos_changed()

var current_chaos : float = 100.0:
	set(value):
		current_chaos = clampf(value, 0, 100.0)
		if current_chaos <= 66.0 and not beetle_already_spawned:
			_spawn_beetle_boss()
		if current_chaos <= 33.0 and not octopus_already_spawned:
			_spawn_octopus_boss()
		if current_chaos <= 0.0:
			UI.instance.credits.start_credits()
		chaos_changed.emit()
var max_chaos : float = 100.0
var chaos_pieces : int = 0
var chaos_pieces_needed : int = 1

@export var octopus_spawn_scene : PackedScene
@export var current_world : WorldBackBone
@export var boss_spawner : MultiplayerSpawner

var beetle_already_spawned : bool = false
var octopus_already_spawned : bool = false

static var instance: ChaosSystem

func _init() -> void:
	instance = self


func _spawn_seagull() -> void:
	pass


func _spawn_beetle_boss() -> void:
	beetle_already_spawned = true


func _spawn_octopus_boss() -> void:
	octopus_already_spawned = true
	var octopus : OctoRockBehavior = octopus_spawn_scene.instantiate()
	octopus.global_basis = current_world.octopus_spawn_location.global_basis
	octopus.global_position = current_world.octopus_spawn_location.global_position
	boss_spawner.add_child(octopus, true)


func _decrease_chaos() -> void:
	if boss_spawner.get_child_count() > 0:
		return
	chaos_pieces += 1
	if chaos_pieces >= chaos_pieces_needed:
		chaos_pieces = 0
		current_chaos -= 5.0
