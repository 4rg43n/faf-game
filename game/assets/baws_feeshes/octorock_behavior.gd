# spawns at 33% cahos in the water and walks up beach - he should ignore the water.
class_name OctoRockBehavior extends Node3D

@export var root_hsm : LimboHSM
@export var spin_attack_state : LimboState

var spin_timmer : Timer

#track damage per player
func _on_hit_by_player() -> void:
	pass

#will run current limbo state (leaf) every tick until a transition tells it to leave
#can also use behavior trees inside a state machine to handle more complex behavior (starts top down every tick)

func _process(delta: float) -> void:
	root_hsm.initialize(self)
	#what event causes a transition from this state to another specified state, guard returns false = no transition
	root_hsm.add_transition(root_hsm.ANYSTATE, spin_attack_state, &"start_spin_attack", _can_spin_attack_guard)

	spin_timmer.timeout.connect(_on_countdown_timer_completed)


##internal events start at the leaf that dispatched them and bubble up to root instead.
##how external events are emitted - starts at active leaf and bubbles up - same as calling inside active leaf
##if root is not active dispatch will not fire - uset set_active
func _on_countdown_timer_completed() -> void:
	root_hsm.dispatch(&"start_spin_attack")

func _can_spin_attack_guard() -> bool:
	return true


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
