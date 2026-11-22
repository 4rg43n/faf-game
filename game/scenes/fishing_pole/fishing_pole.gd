class_name FishingPole extends Node3D

@export var item_resource: Item

@export var bobber: Bobber
@export var fishing_line: MeshInstance3D

@export var fishing_line_start: Marker3D
@export var bobber_marker: Marker3D
@export var bobber_start_position: Marker3D

var bobber_cast: bool = false
var fish_currently_hooked: bool = false


func _ready() -> void:
	bobber.set_physics_process(false)
	fishing_line.hide()
	bobber.fish_bit_bobber.connect(fish_hooked)


func fish_hooked(hooked) -> void:
	fish_currently_hooked = hooked
	if hooked:
		_on_player_hooked_fish.rpc_id(1, multiplayer.get_unique_id())
	else:
		if bobber_cast:
			# Force reel it back in if you missed the time window
			_on_player_attempt_cast.rpc_id(1, multiplayer.get_unique_id())


@rpc("reliable", "any_peer", "call_local")
func _on_player_hooked_fish(peer_id : int) -> void:
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	bobber.notify_hook(player.player_controller.global_position)


func _physics_process(_delta: float) -> void:
	pass
	# _update_fishing_line()


# Trash code
func _update_fishing_line() -> void:
	var center_pos = (fishing_line_start.global_position + bobber.global_position) / 2
	var distance = fishing_line_start.global_position.distance_to(bobber.global_position)

	fishing_line.global_position = center_pos
	fishing_line.mesh.height = distance

	fishing_line.look_at(fishing_line_start.global_position)
	fishing_line.rotation_degrees.x -= 90


func _unhandled_input(event: InputEvent) -> void:
	if event.is_released() and event.is_action("cast"):
		_on_player_attempt_cast.rpc_id(1, multiplayer.get_unique_id())


@rpc("reliable", "any_peer", "call_local")
func _on_player_attempt_cast(peer_id : int) -> void:
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	if bobber_cast:
		if fish_currently_hooked:
			var its_a_fish_scene = preload("res://scenes/critters/rolly_polly_pollie.tscn")
			var fake_fish = its_a_fish_scene.instantiate()
			var fish_resource : Item = fake_fish.get("item_resource")
			player.add_item_if_possible(fish_resource)
			ChaosSystem.instance._decrease_chaos()

		bobber_cast = false

		bobber.freeze = true
		bobber.top_level = false
		bobber.set_physics_process(false)

		bobber.global_position = bobber_start_position.global_position
		return

	bobber_cast = true
	print_rich("[color=yellow][b]Trying to cast bobber!")
	# fishing_line.show()

	# Yeet that bobber
	var force : Vector3 = 1000 * (player.player_controller.visuals.global_transform.basis.z) + 500 * Vector3.UP
	bobber.freeze = false
	bobber.top_level = true
	bobber.set_physics_process(true)
	bobber.apply_force(force)

@rpc("reliable", "call_local", "any_peer")
func remove_from_server_control() -> void:
	if not multiplayer.get_unique_id() == 1:
		remove_from_server_control.rpc_id(1)
		return
	self.queue_free()
