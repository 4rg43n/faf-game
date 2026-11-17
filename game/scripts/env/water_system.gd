class_name WaterSystem

extends Node

@export
var gravityFactor : float
@export
var waterDensity: float
@export
var drag: float

# We need a way to setup our boundaries, we can take the AABB of a given 3D node
@export
var oceanAreas: Array[Area3D]

@export
var oceanColor: Color
@export
var oceanResolution: float

@export
var oceanShader: Shader

var objectsInWater: Array[Node3D]


# We probably need to find all bodies that enter the water and then apply an upwards force to them

# F = (p)Vg

func _ready() -> void:
	var cntr := 0
	for area in self.oceanAreas:
		area.monitoring = true
		area.body_entered.connect(_on_body_enters_ocean)
		area.body_exited.connect(_on_body_exits_ocean)
		_create_water_plane(cntr)
		cntr += 1

func _on_body_enters_ocean(area: Node3D):
	print("Entered ", area.name)
	self.objectsInWater.append(area)

func _on_body_exits_ocean(area: Node3D):
	print("Exited")
	self.objectsInWater.erase(area)


func ocean_process(oceanIdx: int, delta: float) -> void:
	for obj in self.objectsInWater:
		var aabb : AABB
		var velocity : Vector3
		var mass : float = 1
		if obj is PlayerController:
			var character := obj as PlayerController
			# Curse you Godot
			aabb = character.shapeColl.shape.get_debug_mesh().get_aabb()
			velocity = character.velocity
		elif obj is BuoyantBody:
			var body := obj as BuoyantBody
			aabb = body.mesh.get_aabb()
			velocity = body.rig.linear_velocity
			mass = body.rig.mass
		else:
			# Skip to next iter
			continue

		var vol := aabb.get_volume()
		var submerged := get_submerged(oceanIdx, obj.global_transform.origin.y, aabb.size.y)
		var forceToApply := _get_bouyancy_force(vol, submerged) * delta
		var totalForceToAdd = Vector3(0, forceToApply, 0)
		if velocity.y > 0:
			totalForceToAdd.y -= self.drag * submerged * delta * mass
		else:
			totalForceToAdd.y += self.drag * submerged * delta * mass

		# This is dumb, but we could probably either do a fat struct or a common base class to avoid this
		if obj is PlayerController:
			var character := obj as PlayerController
			# Curse you Godot
			character.velocity += totalForceToAdd
		elif obj is BuoyantBody:
			# Bouyant bodies need some more work
			var body := obj as BuoyantBody
			body.rig.linear_velocity += totalForceToAdd


func _physics_process(delta: float) -> void:
	for i in range(len(self.oceanAreas)):
		ocean_process(i, delta)


func _get_ocean_shape(oceanIdx: int) -> CollisionShape3D:
	assert(self.oceanAreas[oceanIdx].get_child_count() > 0, "The ocean area must have children")
	return self.oceanAreas[oceanIdx].get_child(0) as CollisionShape3D


func _create_water_plane(oceanIdx: int) -> void:
	var shapeNode := _get_ocean_shape(oceanIdx)
	var box := shapeNode.shape as BoxShape3D
	var size := box.size

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(oceanColor)

	var halfWidth := size.x * 0.5
	var halfDepth := size.z * 0.5
	# Cast to ints bc things get wacky if we don't
	var widthVertCount := maxi(1, int(ceil(size.x * oceanResolution)))
	var depthVertCount := maxi(1, int(ceil(size.z * oceanResolution)))

	const defaultTangent := Plane(1, 0, 0, -1)
	for x in range(widthVertCount + 1):
		for z in range(depthVertCount + 1):
			var u := float(x) / widthVertCount
			var v := float(z) / depthVertCount
			st.set_uv(Vector2(u, v))
			st.set_tangent(defaultTangent)
			st.add_vertex(Vector3(u * size.x - halfWidth, 0.0, v * size.z - halfDepth))

	var rowWidth := depthVertCount + 1
	for x in widthVertCount:
		for z in depthVertCount:
			var index := x * rowWidth + z
			st.add_index(index)
			st.add_index(index + 1)
			st.add_index(index + rowWidth + 1)
			st.add_index(index)
			st.add_index(index + rowWidth + 1)
			st.add_index(index + rowWidth)

	st.generate_normals()

	var plane := MeshInstance3D.new()
	plane.mesh = st.commit()

	plane.transform = shapeNode.transform * Transform3D(Basis(), Vector3(0, size.y * 0.5, 0))
	plane.rotate_z(deg_to_rad(180))
	oceanAreas[oceanIdx].add_child(plane)
	assert(self.oceanShader != null, "Ocean shader needs to be set to continue!")
	var mat := ShaderMaterial.new()
	mat.shader = self.oceanShader
	plane.material_override = mat

func get_submerged(oceanIdx: int, posY: float, sizeY: float) -> float:
	var charBottom: float = posY
	var oceanTop : float = self.oceanAreas[oceanIdx].global_position.y
	# Diff them to see if we're in or out of it and by how much
	return clampf((oceanTop - charBottom) / sizeY, 0.0, 1.0)


func _get_bouyancy_force(solidVolume: float, submerged: float) -> float :
	# Find out how much water we're displacing as a function
	# of the volume of the object and its position relative
	# to the top of the surface
	# TODO: This should be read from the current spike of the ocean's surface
	var displacedVolume : float = solidVolume * submerged
	return self.waterDensity * displacedVolume * self.gravityFactor
	
