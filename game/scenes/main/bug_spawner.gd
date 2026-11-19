#bugs or anything we can pickup put in inventory and throw.
class_name InteractableItemSpawner  extends MultiplayerSpawner

static var instance : InteractableItemSpawner = null

func _init() -> void:
	InteractableItemSpawner.instance = self
