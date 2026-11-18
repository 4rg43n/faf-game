class_name InventorySystem extends Control

@export var main_inventory: GridContainer
@export var hotbar: HBoxContainer

@onready var main: Main = Main.instance

var drag_icon : Sprite2D = Sprite2D.new()
var dragging_item : Button = null
var hovered_slot: Button = null

static var instance: InventorySystem

func _init() -> void:
	instance = self


func _ready() -> void:
	main_inventory.visibility_changed.connect(_on_main_inventory_visibility_changed)


func _process(_delta: float) -> void:
	if drag_icon.texture:
		drag_icon.position = get_global_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			reset()


func button_pressed(button: Button):
	if button.icon:
		# I'm lazy fuck you this works just fine
		if not main.get_children().has(drag_icon):
			main.add_child(drag_icon)
		dragging_item = button
		drag_icon.texture = button.icon
		var drag_icon_size = drag_icon.texture.get_size()
		drag_icon.scale = Vector2(50/drag_icon_size.x, 50/drag_icon_size.y)


func button_released():
	if hovered_slot:
		hovered_slot.icon = drag_icon.texture
		dragging_item.icon = null
	drag_icon.texture = null


func button_hovered(button: Button):
	hovered_slot = button


func button_unhovered():
	hovered_slot = null


func reset():
	drag_icon.texture = null
	dragging_item = null
	hovered_slot = null


func _on_main_inventory_visibility_changed():
	reset()
