class_name FishingPole extends Node3D

@export var item_resource: Item

@export var bobber: Bobber
@export var line: MeshInstance3D

@export var fishing_line_start: Marker3D
@export var bobber_marker: Marker3D
@export var bobber_start_position: Marker3D

var bobber_cast: bool = false
var fish_currently_hooked: bool = false


func _ready() -> void:
	bobber.set_physics_process(false)
	bobber.fish_bit_bobber.connect(fish_hooked)


func _process(_delta: float) -> void:
	## Docs: https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/immediatemesh.html
	# Clean up before drawing.
	line.mesh.clear_surfaces()

	# Only draw the line when the bobber is actually out
	if not bobber_cast:
		return

	# Begin draw.
	line.mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	# Draw mesh.
	# line.mesh.surface_add_vertex(fishing_line_start.global_position) # Start
	# line.mesh.surface_add_vertex(bobber_marker.global_position) # End
	# line.mesh.surface_end()

	var start = fishing_line_start.global_position
	var end = bobber_marker.global_position

	var distance = start.distance_to(end)

	# This will still clip into the ground but I think adding sag generally looks better than a strait line
	var total_line_points = clampf(distance, 5.0, 20.0)
	var sag : float = 3
	for t in range(total_line_points):
		var t_percent = t/total_line_points
		var point = start.lerp(end, t_percent)
		var sag_amount = sag * t_percent * (1.0 - t_percent)
		point.y -= sag_amount
		line.mesh.surface_add_vertex(point)
		t += 1
	line.mesh.surface_add_vertex(end)

	# End drawing.
	line.mesh.surface_end()


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



func _unhandled_input(event: InputEvent) -> void:
	if event.is_released() and event.is_action("cast"):
		_on_player_attempt_cast.rpc_id(1, multiplayer.get_unique_id())


@rpc("reliable", "any_peer", "call_local")
func _on_player_attempt_cast(peer_id : int) -> void:
	var player := LobbyManager.instance.get_player_from_peer_id(peer_id)
	if bobber_cast:
		reel_in(player)
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


func reel_in(player : PlayerMetadata) -> void:
	if fish_currently_hooked:
		## TODO, this needs to be replaced with a fish LUT
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

	# In case we reeled in before the fishing timer went off it needs to be cancelled
	# It's kind of trash being set up this way...
	bobber.cancel_fish_delay_timer()

@rpc("reliable", "call_local", "any_peer")
func remove_from_server_control() -> void:
	if not multiplayer.get_unique_id() == 1:
		remove_from_server_control.rpc_id(1)
		return
	self.queue_free()
