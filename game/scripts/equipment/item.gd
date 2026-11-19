@tool
class_name Item extends Resource

@export var name : String
@export var id : int
@export var icon : Texture2D
@export var count : int
@export var max_count : int

var item_scene : PackedScene
@export var item_scene_path : String :
	set(new_val):
		item_scene_path = new_val
		item_scene = load(item_scene_path)

var hotbar_item_path : NodePath
