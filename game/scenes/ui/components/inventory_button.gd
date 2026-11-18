extends Button

@onready var inventory_system: InventorySystem = InventorySystem.instance

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed():
	inventory_system.button_pressed(self)
