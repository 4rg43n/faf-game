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


const FISH_COLL_LAYER := 2

# Idk if this should be just for the evil fish or for all of them

# All fishes, maybe alive, maybe not
@export var maxFishes: int
@export var baseFish: PackedScene
@export var world: WorldBackBone
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
var spawners: Array[FishSpawner]
var rayDirections: Array[Vector3] = []
var avgFlockHeading: Vector3

func _ready() -> void:
	self.avgFlockHeading = Vector3.LEFT
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



func get_flockmate_positions(fish: FishInfo, perceptionRadius: float) -> Array[Vector3]:
	var flockmates: Array[Vector3] = []
	var spaceState := self.world.get_world_3d().direct_space_state
	var query := _create_sphere_query(fish.node.global_position, perceptionRadius)
	query.collision_mask = FISH_COLL_LAYER
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
	query.collision_mask = 0xFFFFFFFF & ~(FISH_COLL_LAYER)
	query.collide_with_bodies = true
	query.transform.origin = pos + offset
	return query


# Thx Sebastian Lague
func _fish_find_unobstructed_direction(fish: FishInfo) -> Vector3:
	var bestDir := fish.node.linear_velocity
	var furthestUnobstructedDst := 0.0
	for rayDir in self.rayDirections:
		var dir := fish.node.global_transform.basis * (rayDir)
		var sphereQuery := _create_sphere_query(fish.node.global_position, self.fishBoundsRadius, dir)
		var space := self.world.get_world_3d().direct_space_state
		var results : Array[Dictionary] = space.intersect_shape(sphereQuery, 1)

		if results == null or results.is_empty():
			bestDir = dir
			break
		
		var point : Vector3 = (results[0]["collider"] as Node3D).global_position
		var diff := point - fish.node.global_position
		var distance := diff.length()

		if distance > furthestUnobstructedDst:
			bestDir = dir
			furthestUnobstructedDst = distance
	return bestDir


func _spawn_fish_at(pos: Vector3, radius: float):
	var spawnPos := Vector3(
		randf_range(pos.x - radius, pos.x + radius),
		randf_range(pos.y - radius, pos.y + radius),
		randf_range(pos.z - radius, pos.z + radius)
	)

	var fishIdx : int = self.fishesToRecycle.dequeue()
	var fish := self.fishes[fishIdx]
	fish.node.collision_layer = FISH_COLL_LAYER
	fish.node.collision_mask = 1
	fish.node.visible = true
	# TODO: Randomize around the radius
	fish.node.global_position = spawnPos
	fish.flags = EFishStateFlags.Passive
	fish.targetVel = Vector3.LEFT


func spawn_fish_subsystem(delta: float):
	for spawner in self.spawners:
		if !spawner._initialized:
			continue

		spawner.spawnTimer -= delta

		if spawner.spawnTimer > 0:
			continue


		spawner.spawnTimer = spawner.spawnFrequency
		DebugDraw3D.draw_sphere(spawner.global_position, spawner.spawnRadius, Color.GREEN)
		var fishToSpawn := randi_range(spawner.minFishesPerSpawn, spawner.maxFishesPerSpawn)
		fishToSpawn = clampi(fishToSpawn, 0, self.fishesToRecycle._length)
		for i in range(fishToSpawn):
			_spawn_fish_at(spawner.global_position, spawner.spawnRadius)


func _fish_movement(_delta: float, fish: FishInfo):
	fish.node.linear_velocity = fish.targetVel
	DebugDraw3D.draw_line(fish.node.global_position, fish.node.global_position + fish.node.linear_velocity, Color.LIGHT_BLUE)

func _steer_towards(vector: Vector3, fish: FishInfo) -> Vector3:
	var v : Vector3 = vector.normalized() * self.fishMaxSpeed - fish.node.linear_velocity
	return v.limit_length(self.fishSteerForce)

func _is_heading_for_collision(pos: Vector3, fwd: Vector3) -> bool:
	var query := _create_sphere_query(pos, self.fishBoundsRadius, fwd)
	var space := self.world.get_world_3d().direct_space_state
	var results : Array[Dictionary] = space.intersect_shape(query, 5)
	var collided := results != null && !results.is_empty()
	if collided:
		DebugDraw3D.draw_sphere(pos, self.fishBoundsRadius, Color.RED)
		return true
	DebugDraw3D.draw_sphere(pos, self.fishBoundsRadius, Color.CADET_BLUE)
	return false


func fish_update(delta: float, fish: FishInfo) -> void:
	var acceleration := Vector3.ZERO
	var flockMates := get_flockmate_positions(fish, 2)
	var centre := Vector3.ZERO
	for pos in flockMates:
		centre += pos

	if (!flockMates.is_empty()):
		centre /= flockMates.size()
	else:
		centre = fish.node.global_position
	var offsetToFlockmatesCentre := (centre - fish.node.global_position)

	var separationOffset := Vector3.ZERO
	for pos in flockMates:
		separationOffset += (fish.node.global_position - pos).normalized()

	var alignmentForce := _steer_towards(self.avgFlockHeading, fish) * self.fishAlignment
	var cohesionForce := _steer_towards(offsetToFlockmatesCentre, fish) * self.fishCoherence
	var separationForce := _steer_towards(separationOffset, fish) * self.fishSeparation

	DebugDraw3D.draw_line(fish.node.global_position, fish.node.global_position + alignmentForce, Color.YELLOW)
	DebugDraw3D.draw_line(fish.node.global_position, fish.node.global_position + cohesionForce, Color.CHOCOLATE)
	DebugDraw3D.draw_line(fish.node.global_position, fish.node.global_position + separationForce, Color.SALMON)

	acceleration += alignmentForce
	acceleration += cohesionForce
	acceleration += separationForce

	# Collision detection
	if _is_heading_for_collision(fish.node.global_position, -fish.node.global_basis.z):
		var unobstructedDir := _fish_find_unobstructed_direction(fish)
		var collisionAvoidForce := _steer_towards(unobstructedDir, fish) * self.fishAvoidCollisionWeight
		acceleration += collisionAvoidForce

	fish.targetVel += acceleration * delta
	fish.targetVel = fish.targetVel.limit_length(self.fishMaxSpeed)

	# Detect the player
	if fish.flags == EFishStateFlags.Passive:
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

func _physics_process(delta: float) -> void:
	var localAvgHeading := Vector3.ZERO
	var aliveFish := 0
	for fish in self.fishes:
		if fish.flags == EFishStateFlags.Dead:
			continue
		fish_update(delta, fish)
		_fish_movement(delta, fish)
		aliveFish += 1
		localAvgHeading += fish.node.linear_velocity
		pass
	if aliveFish != 0:
		self.avgFlockHeading = localAvgHeading / aliveFish
	pass
	

func _process(delta: float) -> void:
	spawn_fish_subsystem(delta)
