class_name FishSystem extends Node

enum EFishStateFlags {
	Dead = 0,
	Passive = 1,
	Detected = 2,
}

class FishInfo:
	var flags: EFishStateFlags
	var node: Node3D
	# TODO: Maybe this will be exported
	var detectRange = 5

# Idk if this should be just for the evil fish or for all of them

# All fishes, maybe alive, maybe not
@export var maxFishes: int
@export var baseFish: PackedScene
@export var spawners: Array[Node3D]
@export var fishDetectRadius: float
@export var fishAttackRadius: float

var fishes: Array[FishInfo]
var fishesToRecycle: Queue

func _ready() -> void:
	self.fishes.resize(maxFishes)
	for fish in self.fishes:
		fish.flags = EFishStateFlags.Dead
		fish.node = baseFish.instantiate() as Node3D
		self.add_child(fish.node)

func nearest_player(position: Vector3) -> Node3D:
	return null

func fish_update(_delta: float, fish: FishInfo) -> void:
	# Detect the player
	if fish.flags == EFishStateFlags.Passive:
		# Go wander around
		var player := nearest_player(fish.node.global_position)
		if (player == null):
			return

		fish.flags |= EFishStateFlags.Detected
		return
	if (fish.flags & EFishStateFlags.Detected) != 0:
		var player := nearest_player(fish.node.global_position)
		# We can't detect a player, we should turn off our aggressive flags
		if (player == null):
			fish.flags = (int(fish.flags) & ~int(EFishStateFlags.Detected)) as EFishStateFlags
			return

		var toPlayerV : Vector3 = player.global_position - fish.node.global_position
		var playerDisSqr = toPlayerV.length_squared()
		if playerDisSqr < (self.fishAttackRadius * self.fishAttackRadius):
			pass

		return
	pass

func _process(delta: float) -> void:
	var cntr = -1
	for fish in self.fishes:
		cntr += 1
		if fish.flags == EFishStateFlags.Dead:
			fishesToRecycle.enqueue(cntr)
			continue

		# What do we need our fish to do? basically just move around, detect the player and follow her
		fish_update(delta, fish)

		pass
	pass



