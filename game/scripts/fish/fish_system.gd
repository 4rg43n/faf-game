class_name FishSystem extends Node

enum EFishStateFlags {
	Dead = 0,
	Passive = 1,
	Detected = 2,
}

class FishInfo:
	var flags: EFishStateFlags
	var node: RigidBody3D
	var targetVel: Vector3
	# TODO: Maybe this will be exported
	var detectRange = 5

class FishUpdateRes:
	var avoidanceDirection: Vector3

const FISH_COLL_LAYER := 2

# Idk if this should be just for the evil fish or for all of them

# All fishes, maybe alive, maybe not
@export var maxFishes: int
@export var baseFish: PackedScene
@export var world: WorldBackBone
@export var spawnAreaRadius: float
@export var fishAttackRadius: float
@export var spawnFrequency: float
@export var fishSeparation: float
@export var fishCoherence: float
@export var fishSteerForce: float
@export var fishMaxSpeed: float
@export var fishAlignment: float
@export var fishBoundsRadius: float
@export var fishAvoidCollisionWeight: float

var fishes: Array[FishInfo]
var fishesToRecycle: Queue
var spawners: Array[Node3D]
var spawnTimer: float = 0
var rayDirections: Array[Vector3] = []
var avgFlockHeading: Vector3 # This is one frame off so we can calculate it post-
var avgAvoidance: Vector3

func _ready() -> void:
	self.avgFlockHeading = Vector3.LEFT
	self.avgAvoidance = Vector3.DOWN # idk
	assert(self.world != null, "Can't execute fish system without a world!")
	self.spawners = self.world.evil_fish_spawners
	self.fishesToRecycle = Queue.new(self.maxFishes)
	for i in range(self.maxFishes):
		var fish := FishInfo.new()
		fish.flags = EFishStateFlags.Dead
		fish.node = baseFish.instantiate() as Node3D
		fish.node.visible = false
		fish.node.gravity_scale = 0
		fish.node.add_to_group("fish")
		fish.node.collision_layer = 0
		fish.node.collision_mask = 0
		self.add_child(fish.node)
		self.fishesToRecycle.enqueue(i)
		self.fishes.append(fish)

	_generate_directions(300, self.rayDirections)

	self.spawnTimer = 0


func get_flockmate_positions(fish: FishInfo, perceptionRadius: float) -> Array[Vector3]:
	var flockmates: Array[Vector3] = []
	var spaceState := self.world.get_world_3d().direct_space_state
	var query := _create_sphere_query(fish.node.global_position, perceptionRadius)
	var results := spaceState.intersect_shape(query, self.maxFishes)
	for result in results:
		var collider: Node = result["collider"]
		if collider == fish.node or not collider.is_in_group("fish"):
			continue
		flockmates.append(collider.global_position)
	return flockmates


func nearest_player(_position: Vector3) -> Node3D:
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


func _create_sphere_query(pos: Vector3, radius: float, offset: Vector3 = Vector3.ZERO) -> PhysicsShapeQueryParameters3D:
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	query.shape = sphere
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_bodies = true
	query.transform.origin = pos + offset
	return query


# Thx Sebastian Lague
func _fish_find_unobstructed_direction(fish: FishInfo) -> Vector3:
	var bestDir := fish.node.linear_velocity
	var furthestUnobstructedDst := 0.0
	for rayDir in self.rayDirections:
		var dir := fish.node.global_transform.basis * (rayDir)
		DebugDraw3d.draw_sphere(fish.node.global_position, Quaternion.IDENTITY, 5)
		# Sphere cast
		var sphereQuery := _create_sphere_query(fish.node.global_position, 5)
		var space := self.world.get_world_3d().direct_space_state
		var results : Array[Dictionary] = space.intersect_shape(sphereQuery, 1)

		if results == null or results.is_empty():
			return dir
		
		var point : Vector3 = results[0]["position"]
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
		fish.node.collision_layer = FISH_COLL_LAYER
		fish.node.collision_mask = 1
		fish.node.visible = true
		# TODO: Randomize around the radius
		fish.node.global_position = spawner.global_position
		fish.flags = EFishStateFlags.Passive
		fish.targetVel = Vector3.LEFT
	pass

func _fish_movement(_delta: float, fish: FishInfo):
	fish.node.linear_velocity = fish.targetVel

func _steer_towards(vector: Vector3, fish: FishInfo) -> Vector3:
	var v : Vector3 = vector.normalized() * self.fishMaxSpeed - fish.node.linear_velocity
	return v.limit_length(self.fishSteerForce)

func _is_heading_for_collision(pos: Vector3, fwd: Vector3) -> bool:
	var query := _create_sphere_query(pos, self.fishBoundsRadius, fwd)
	var space := self.world.get_world_3d().direct_space_state
	var results : Array[Dictionary] = space.intersect_shape(query, 1)
	return results != null && !results.is_empty()


func fish_update(delta: float, fish: FishInfo) -> FishUpdateRes:
	var updateInfo := FishUpdateRes.new()
	# Fly around
	var acceleration := Vector3.ZERO
	# Detect all other flockmates
	var flockMates := get_flockmate_positions(fish, 2)
	var centre := Vector3.ZERO
	for pos in flockMates:
		centre += pos

	if (!flockMates.is_empty()):
		centre /= flockMates.size()
	var offsetToFlockmatesCentre := (centre - fish.node.global_position)

	var alignmentForce := _steer_towards(self.avgFlockHeading, fish) * self.fishAlignment
	var cohesionForce := _steer_towards(offsetToFlockmatesCentre, fish) * self.fishCoherence
	var separationForce := _steer_towards(self.avgAvoidance, fish) * self.fishSeparation

	acceleration += alignmentForce
	acceleration += cohesionForce
	acceleration += separationForce

	# Collision detection
	if _is_heading_for_collision(fish.node.global_position, -fish.node.global_basis.z):
		var unobstructedDir := _fish_find_unobstructed_direction(fish)
		var collisionAvoidForce := _steer_towards(unobstructedDir, fish) * self.fishAvoidCollisionWeight
		updateInfo.avoidanceDirection = collisionAvoidForce
		acceleration += collisionAvoidForce

	fish.targetVel += acceleration * delta

	# Detect the player
	if fish.flags == EFishStateFlags.Passive:
		var player := nearest_player(fish.node.global_position)
		if (player == null):
			return updateInfo

		fish.flags |= EFishStateFlags.Detected
		# TODO: Move this to the physics update
		return updateInfo
	if (fish.flags & EFishStateFlags.Detected) != 0:
		var player := nearest_player(fish.node.global_position)
		# We can't detect a player, we should turn off our aggressive flags
		if (player == null):
			fish.flags = (int(fish.flags) & ~int(EFishStateFlags.Detected)) as EFishStateFlags
			return updateInfo

		var toPlayerV : Vector3 = player.global_position - fish.node.global_position
		var playerDisSqr = toPlayerV.length_squared()
		if playerDisSqr < (self.fishAttackRadius * self.fishAttackRadius):
			pass

		return updateInfo
	return updateInfo

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
	var localAvgHeading := Vector3.ZERO
	var localAvgAvoidance := Vector3.ZERO

	var aliveFish := 0
	# var cntr = -1
	for fish in self.fishes:
		# cntr += 1
		if fish.flags == EFishStateFlags.Dead:
			continue

		# What do we need our fish to do? basically just move around, detect the player and follow her
		var updateInfo := fish_update(delta, fish)
		localAvgAvoidance += updateInfo.avoidanceDirection
		aliveFish += 1
		localAvgHeading += fish.node.linear_velocity
		pass

	if aliveFish != 0:
		self.avgFlockHeading = localAvgHeading / aliveFish
		self.avgAvoidance = localAvgAvoidance / aliveFish

