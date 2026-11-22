# spawns at 33% cahos in the water and walks up beach - he should ignore the water.
class_name OctoRockBehavior extends Node3D

static var instance : OctoRockBehavior

@export var root_hsm : LimboHSM
@export var spin_attack_state : LimboState
@export var out_of_ammo : LimboHSM
@export var get_in_range_of_target : LimboState
@export var vaccum_in_ammo : LimboState
@export var shoot_your_shot : LimboState

@export var hurt_boxes : Array[Area3D]
@export var hit_boxes : Array[Area3D]
@export var sucking_boxes : Array[Area3D]
@export var mesh : MeshInstance3D

@export var spin_timmer : Timer
@export var swallow_cam : Camera3D
@export var swallow_anchor : BoneAttachment3D
@export var fire_direction : Node3D

@export var aggro_area : Area3D

@export_group("blackboard")
@export var current_suckage_target : Node3D = null
@export var current_ammo : Array[Node3D] = []  :
	set(new_value):
		var old_size := current_ammo.size()
		var new_size := new_value.size()
		if old_size == 0 and new_size != 0:
			_on_capture_ammo.call_deferred()
		current_ammo = new_value
@export var current_hp : float = 100
@export var current_player_target : Node3D = null

#player that dealt damage, flat damage we intend to deal, if we hit a weakpoint
func _on_hit_by_player(peer_id : int, damage : float, critical_damage : bool, _area_hit : Area3D) -> void:
	damage *= 1 if not critical_damage else 1.5
	current_hp -= damage
	if not spin_timmer.is_stopped():
		return
	spin_timmer.start(3)


func find_closest_ammo() -> Node3D:
	var all_possible_targets := aggro_area.get_overlapping_bodies()
	var best_target : Node3D = null
	var best_dist : float = INF
	for body in all_possible_targets:
		var target : Node3D = body.owner
		if target in current_ammo:
			continue
		var dist := global_position.distance_squared_to(target.global_position)
		if dist < best_dist:
			best_dist = dist
			best_target = target
	return best_target


func find_closest_player() -> Node3D:
	var all_possible_targets := PlayerSpawner.instance.get_children()
	var best_target : Node3D = null
	var best_dist : float = INF
	for body in all_possible_targets:
		var target : Node3D = body.owner
		if target in current_ammo:
			continue
		var dist := global_position.distance_squared_to(target.global_position)
		if dist < best_dist:
			best_dist = dist
			best_target = target
	return best_target


func _init() -> void:
	aggro_area.monitorable = false
	OctoRockBehavior.instance = self


#will run current limbo state (leaf) every tick until a transition tells it to leave
#can also use behavior trees inside a state machine to handle more complex behavior (starts top down every tick)
func _ready() -> void:
	root_hsm.initialize(self)
	root_hsm.set_active(true)
	root_hsm.initial_state = out_of_ammo
	#what event causes a transition from this state to another specified state, guard returns false = no transition
	root_hsm.add_transition(root_hsm.ANYSTATE, spin_attack_state, &"start_spin_attack", _can_spin_attack_guard)
	root_hsm.add_transition(spin_attack_state, out_of_ammo, LimboState.EVENT_FINISHED, _needs_ammo)
	root_hsm.add_transition(spin_attack_state, shoot_your_shot, LimboState.EVENT_FINISHED, _has_ammo_to_shoot)
	root_hsm.add_transition(root_hsm.ANYSTATE, shoot_your_shot, &"shoot_da_stuff", _has_ammo_to_shoot)
	out_of_ammo.add_transition(get_in_range_of_target, vaccum_in_ammo, LimboState.EVENT_FINISHED, _has_target_in_area)
	out_of_ammo.add_transition(vaccum_in_ammo, get_in_range_of_target, LimboState.EVENT_FINISHED, _not_has_target_in_area)
	#events that call dispatch / transitions
	spin_timmer.timeout.connect(_on_countdown_timer_completed)


##internal events start at the leaf that dispatched them and bubble up to root instead.
##how external events are emitted - starts at active leaf and bubbles up - same as calling inside active leaf
##if root is not active dispatch will not fire - uset set_active
func _on_countdown_timer_completed() -> void:
	root_hsm.dispatch(&"start_spin_attack")

func _can_spin_attack_guard() -> bool:
	return spin_timmer.is_stopped()

func _needs_ammo() -> bool:
	return current_ammo.is_empty()

func _has_ammo_to_shoot() -> bool:
	return not current_ammo.is_empty()

func _not_has_target_in_area() -> bool:
	if _has_ammo_to_shoot():
		return false
	return not _has_target_in_area()

func _has_target_in_area() -> bool:
	if _has_ammo_to_shoot():
		return false
	var has_valid_target : bool = false
	var all_bodies : Array = []
	for area : Area3D in sucking_boxes:
		all_bodies.append_array(area.get_overlapping_bodies())
	for body in all_bodies:
		if body.owner is PlayerMetadata:
			has_valid_target = true
			break
		elif body.owner is RigidBody3D:
			has_valid_target = true
			break
	return has_valid_target

func _on_capture_ammo() -> void:
	root_hsm.dispatch(&"shoot_da_stuff")

#respond to an event without a transition
"""
func _setup() -> void:
    add_event_handler("movement_started", _on_movement_started)

func _on_movement_started(cargo = null) -> bool:
    # Handle the "movement_started" event here.
    # `cargo` can be passed with the event when calling `dispatch()`.
    # It's quite handy when you need to pass some data to the event handler.
    return true
"""
