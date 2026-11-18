class_name InventorySystem extends Control

@export var main_inventory: GridContainer
@export var hotbar: HBoxContainer

@onready var main: Main = Main.instance

var drag_icon : Sprite2D = Sprite2D.new()

static var instance: InventorySystem

func _init() -> void:
	instance = self


func _process(_delta: float) -> void:
	if not main_inventory.visible:
		drag_icon.texture = null
	if drag_icon.texture:
		drag_icon.position = get_global_mouse_position()


func button_pressed(button: Button):
	if button.icon:
		# I'm lazy fuck you this works just fine
		if not main.get_children().has(drag_icon):
			main.add_child(drag_icon)
		drag_icon.texture = button.icon
		var drag_icon_size = drag_icon.texture.get_size()
		drag_icon.scale = Vector2(50/drag_icon_size.x, 50/drag_icon_size.y)
