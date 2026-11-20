@tool
class_name Item extends Resource

@export var name : String
@export var id : int
@export var icon : Texture2D
@export var count : int
@export var max_count : int
@export var equipment_type : CustomEnums.Equipment_Type = CustomEnums.Equipment_Type.THROWABLE_OBJ
@export var sell_value : float = 0.0
@export var buy_value : float = 0.0
@export var unsellable : bool = false

var item_scene : PackedScene
@export var item_scene_path : String :
	set(new_val):
		item_scene_path = new_val
		item_scene = load(item_scene_path)

var hotbar_item_path : NodePath
