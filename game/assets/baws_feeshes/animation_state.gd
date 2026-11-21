extends LimboHSM

@export var animation_player: AnimationPlayer
@export var animation_name: StringName

## Called once, when state is initialized.
func _setup() -> void:
	pass

## Called when state is entered.
func _enter() -> void:
	animation_player.play(animation_name)

## Called when state is exited.
func _exit() -> void:
	pass

## Called each frame when this state is active.
func _update(_delta: float) -> void:
	if not animation_player.is_playing() or animation_player.assigned_animation != animation_name:
		dispatch(EVENT_FINISHED)
