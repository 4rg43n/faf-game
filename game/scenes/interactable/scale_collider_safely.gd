@tool
class_name ScaleColliderSafely extends Area3D

func _enter_tree() -> void:
	set_notify_transform(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		var new_scalar : Vector3 = scale
		scale = Vector3.ONE

		var children_colliders := get_children()
		for collider : CollisionShape3D in children_colliders:
			if collider.shape is BoxShape3D:
				var box : BoxShape3D = collider.shape
				box.size *= new_scalar
				collider.position *= new_scalar
			elif collider.shape is ConvexPolygonShape3D:
				var polygon : ConvexPolygonShape3D = collider.shape
				if collider is Node3DConvexShapeColliderBuilder:
					var node_builder : Node3DConvexShapeColliderBuilder = collider
					var children_verts := node_builder.get_children()
					for vert : Node3D in children_verts:
						vert.position *= new_scalar
					var points : PackedVector3Array = polygon.points
					for i in points.size():
						points[i] *= new_scalar
					polygon.points = points
					collider.position *= new_scalar
