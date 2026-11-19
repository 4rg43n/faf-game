@tool
class_name InventoryButton extends Button

@export var count_label: Label
@export var stored_item: Item:
	set(value):
		stored_item = value
		if stored_item:
			icon = stored_item.icon
			if stored_item.count > 1:
				count_label.text = str(stored_item.count)
			else:
				count_label.text = ""
		else:
			icon = null
			count_label.text = ""

@onready var inventory_system: InventorySystem = InventorySystem.instance

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_down.connect(_on_pressed)
	button_up.connect(_on_released)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_pressed():
	inventory_system.button_pressed(self)


func _on_released():
	inventory_system.button_released()


func _on_mouse_entered():
	inventory_system.button_hovered(self)


func _on_mouse_exited():
	inventory_system.button_unhovered()
