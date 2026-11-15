extends Node3D

func _ready() -> void:
	Steam.setAchievement("ACH_WIN_ONE_GAME")
	Steam.setAchievement("ACH_TRAVEL_FAR_ACCUM")
	Steam.setAchievement("ACH_TRAVEL_FAR_SINGLE")
	Steam.setAchievement("ACH_WIN_100_GAMES")
	Steam.setAchievement("NEW_ACHIEVEMENT_0_4")


func _process(_delta: float) -> void:
	pass
