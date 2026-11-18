class_name InventorySystem extends MarginContainer

@export var main_inventory: GridContainer
@export var hotbar: HBoxContainer

@onready var main: Main = Main.instance
@onready var game_manager: GameManager = GameManager.instance

var player_data : PlayerMetadata = null
var drag_icon : Sprite2D = Sprite2D.new()
var hovered_slot: InventoryButton = null
var old_slot: InventoryButton = null

static var instance: InventorySystem

func _init() -> void:
	instance = self


func _ready() -> void:
	main_inventory.visibility_changed.connect(_on_main_inventory_visibility_changed)
	game_manager.player_synced.connect(_on_player_synced)

func _process(_delta: float) -> void:
	if drag_icon.texture:
		drag_icon.position = get_global_mouse_position()


func button_pressed(button: InventoryButton):
	if button.stored_item and button.icon:
		# I'm lazy fuck you this works just fine
		if not main.get_children().has(drag_icon):
			main.add_child(drag_icon)
		old_slot = button
		drag_icon.texture = button.icon
		var drag_icon_size = drag_icon.texture.get_size()
		drag_icon.scale = Vector2(50/drag_icon_size.x, 50/drag_icon_size.y)


func button_released():
	if hovered_slot and old_slot and old_slot.stored_item:
		# fuck you this code works don't complain I know it's ass
		var old_item : Item = old_slot.stored_item
		var main_slots : Array = main_inventory.get_children()
		var hotbar_slots : Array = hotbar.get_children()
		if main_slots.has(old_slot):
			player_data.main_inventory.set(main_slots.find(old_slot), hovered_slot.stored_item)
		elif hotbar_slots.has(old_slot):
			player_data.hotbar.set(hotbar_slots.find(old_slot), hovered_slot.stored_item)
		if not hovered_slot or main_slots.has(hovered_slot):
			player_data.main_inventory.set(main_slots.find(hovered_slot), old_item)
			print(player_data.main_inventory)
		elif not hovered_slot or hotbar_slots.has(hovered_slot):
			player_data.hotbar.set(hotbar_slots.find(hovered_slot), old_item)
			print(player_data.hotbar)
		old_slot.stored_item = hovered_slot.stored_item
		hovered_slot.stored_item = old_item

	drag_icon.texture = null


func button_hovered(button: InventoryButton):
	hovered_slot = button


func button_unhovered():
	hovered_slot = null


func reset():
	old_slot = null
	drag_icon.texture = null
	hovered_slot = null


func _on_main_inventory_visibility_changed():
	reset()


func _on_player_synced():
	player_data = game_manager.player_data
	game_manager.player_data.hotbar_updated.connect(_on_hotbar_updated)
	game_manager.player_data.main_inventory_updated.connect(_on_main_inventory_updated)


func _on_hotbar_updated():
	var index : int = -1
	for item: Item in player_data.hotbar:
		index += 1
		var inventory_slot : InventoryButton = hotbar.get_child(index)
		inventory_slot.stored_item = item if item else null


func _on_main_inventory_updated():
	var index : int = -1
	for item: Item in player_data.main_inventory:
		index += 1
		var inventory_slot : InventoryButton = main_inventory.get_child(index)
		inventory_slot.stored_item = item if item else null
