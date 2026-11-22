class_name PlayerSpawner extends MultiplayerSpawner

static var instance : PlayerSpawner

func _init() -> void:
	PlayerSpawner.instance = self
