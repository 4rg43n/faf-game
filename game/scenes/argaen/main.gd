extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Steam.setAchievement("ACH_WIN_ONE_GAME")
	Steam.setAchievement("ACH_TRAVEL_FAR_ACCUM")
	Steam.setAchievement("ACH_TRAVEL_FAR_SINGLE")
	Steam.setAchievement("ACH_WIN_100_GAMES")
	Steam.setAchievement("NEW_ACHIEVEMENT_0_4")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
