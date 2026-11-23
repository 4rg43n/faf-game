@tool
##meant solely for use in editor.
class_name Node3DConvexShapeColliderBuilder extends CollisionShape3D

@export var rebuild_shape: bool = false:
	set(value):
		if value:
			generate_convex_shape()

func generate_convex_shape() -> void:
	var points := PackedVector3Array()

	for child in get_children():
		points.append(child.position)

	# A 3D convex hull requires at least 4 non-coplanar points
	if points.size() < 4:
		push_warning("ConvexPolygonShape3D needs at least 4 non-coplanar points.")
		return

	var convex_shape := ConvexPolygonShape3D.new()
	convex_shape.points = points
	shape = convex_shape
