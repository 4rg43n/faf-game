class_name FishSystem extends Node

enum EFishStateFlags {
	Dead = 0,
	Passive = 1,
	Detected = 2,
}

class FishInfo:
	var flags: EFishStateFlags
	var node: RigidBody3D
	var targetDir: Vector3
	# TODO: Maybe this will be exported
	var detectRange = 5

# Idk if this should be just for the evil fish or for all of them

# All fishes, maybe alive, maybe not
@export var maxFishes: int
@export var baseFish: PackedScene
@export var world: WorldBackBone
@export var spawnAreaRadius: float
@export var fishAttackRadius: float
@export var spawnFrequency: float

var fishes: Array[FishInfo]
var fishesToRecycle: Queue
var spawners: Array[Node3D]
var spawnTimer: float = 0
var rayDirections: Array[Vector3] = []

func _ready() -> void:
	assert(self.world != null, "Can't execute fish system without a world!")
	self.spawners = self.world.evil_fish_spawners
	self.fishesToRecycle = Queue.new(self.maxFishes)
	for i in range(self.maxFishes):
		var fish := FishInfo.new()
		fish.flags = EFishStateFlags.Dead
		fish.node = baseFish.instantiate() as Node3D
		fish.node.visible = false
		fish.node.gravity_scale = 0
		self.add_child(fish.node)
		self.fishesToRecycle.enqueue(i)
		self.fishes.append(fish)

	_generate_directions(300, self.rayDirections)

	self.spawnTimer = 0




func nearest_player(position: Vector3) -> Node3D:
	return null

func _generate_directions(numDirections: int, arrayToFill: Array[Vector3]) -> void:
	const GOLDEN_RATIO := (1.0 + sqrt(5.0)) / 2.0
	const angleIncrement := PI * 2.0 * GOLDEN_RATIO
	for i in range(numDirections):
		var t := float(i) / numDirections
		var inclination := acos(1.0 - 2.0 * t)
		var azimuth := angleIncrement * i

		var result := Vector3()
		result.x = sin(inclination) * cos(azimuth)
		result.y = sin(inclination) * sin(azimuth)
		result.z = cos(inclination)
		arrayToFill.append(result)


func _create_sphere_query(pos: Vector3, radius: float) -> PhysicsShapeQueryParameters3D:
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	query.shape = sphere
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_bodies = true
	query.transform.origin = pos
	return query


# Thx Sebastian Lague
func _fish_find_unobstructed_direction(fish: FishInfo) -> Vector3:
	var bestDir := fish.node.linear_velocity
	var furthestUnobstructedDst := 0.0
	for rayDir in self.rayDirections:
		var dir := fish.node.global_transform * (rayDir)
		DebugDraw3d.draw_sphere(fish.node.global_position, Quaternion.IDENTITY, 5)
		# Sphere cast
		var sphereQuery := _create_sphere_query(fish.node.global_position, 5)
		var space := self.world.get_world_3d()
		var results : Dictionary = space.intersect_shape(sphereQuery)

		if results == null or results.is_empty():
			return dir
		
		var point : Vector3 = results["point"]
		var diff := point - fish.node.global_position
		var distance := diff.length()

		if distance > furthestUnobstructedDst:
			bestDir = dir
			furthestUnobstructedDst = distance
	return bestDir


func spawn_fish_subsystem():
	if self.spawnTimer > 0:
		return
	self.spawnTimer = self.spawnFrequency
	for spawner in self.spawners:
		# DebugDraw3D.draw_sphere(spawner.global_position, Quaternion.IDENTITY, self.spawnAreaRadius)
		var fishIdx : int = self.fishesToRecycle.dequeue()
		var fish := self.fishes[fishIdx]
		fish.node.visible = true
		# TODO: Randomize around the radius
		fish.node.global_position = spawner.global_position
		fish.flags = EFishStateFlags.Passive
		fish.targetDir = Vector3.LEFT
	pass

func _fish_movement(delta, fish: FishInfo):
	pass

func fish_update(_delta: float, fish: FishInfo) -> void:
	# Detect the player
	if fish.flags == EFishStateFlags.Passive:
		# Go wander around
		fish.node.linear_velocity = fish.targetDir
		var player := nearest_player(fish.node.global_position)
		if (player == null):
			return

		fish.flags |= EFishStateFlags.Detected
		# TODO: Move this to the physics update
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

func _physics_process(delta: float) -> void:
	# var cntr = -1
	for fish in self.fishes:
		# cntr += 1
		if fish.flags == EFishStateFlags.Dead:
			continue

		_fish_movement(delta, fish)

		pass
	pass
	

func _process(delta: float) -> void:
	self.spawnTimer -= delta
	spawn_fish_subsystem()

	# var cntr = -1
	for fish in self.fishes:
		# cntr += 1
		if fish.flags == EFishStateFlags.Dead:
			continue

		# What do we need our fish to do? basically just move around, detect the player and follow her
		fish_update(delta, fish)

		pass
	pass
