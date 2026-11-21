@tool
class_name InventorySystem extends MarginContainer

@export var main_inventory: GridContainer
@export var background: Panel
@export var inventory_container: PanelContainer
@export var shop_container: PanelContainer
@export var shop_inventory: GridContainer
@export var hotbar: HBoxContainer
@export var money_label: Label
@export var active_slot: int:
	set(value):
		if value > 8 or value < 0: # We only have 9 hotbar slots 0-8
			printerr("Tried to set active slot to invalid index")
			return
		var old_value = active_slot
		active_slot = value
		_on_active_slot_changed(active_slot, old_value)

@export_group("Stylebox Resources")
@export var normal_stylebox: StyleBox
@export var pressed_stylebox: StyleBox
@export var hover_stylebox: StyleBox

@onready var main: Main = Main.instance
@onready var game_manager: GameManager = GameManager.instance

signal on_active_slot_changed(old_slot : int)

var player_data : PlayerMetadata = null
var drag_icon : Sprite2D = Sprite2D.new()
var hovered_slot: InventoryButton = null
var old_slot: InventoryButton = null

static var instance: InventorySystem

func _init() -> void:
	instance = self


func _ready() -> void:
	inventory_container.visibility_changed.connect(_on_main_inventory_visibility_changed)
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
	else:
		reset()


func button_released():
	if hovered_slot == old_slot:
		reset()
		return
	if hovered_slot and old_slot and old_slot.stored_item:
		# fuck you this code works don't complain I know it's ass
		var old_item : Item = old_slot.stored_item
		var main_slots : Array = main_inventory.get_children()
		var hotbar_slots : Array = hotbar.get_children()

		var old_main_idx : int = main_slots.find(old_slot)
		var old_hotbar_idx : int = hotbar_slots.find(old_slot)
		var hovered_main_idx : int = main_slots.find(hovered_slot)
		var hovered_hotbar_idx : int = hotbar_slots.find(hovered_slot)

		var player_items : Array = [old_main_idx, old_hotbar_idx, hovered_main_idx, hovered_hotbar_idx]\
			.filter(func(v): return v >= 0)

		if not player_items.size(): # Trying to move items around in the shop
			reset()
			return
		if not player_items.size() >= 2:
			_handle_shop_interaction(
				old_item,
				main_slots if old_main_idx >= 0 else hotbar_slots,
				main_slots if hovered_main_idx >= 0 else hotbar_slots)
			_on_main_inventory_updated()
			_on_hotbar_updated()
			reset()
			return

		if hovered_slot.stored_item and old_item.id == hovered_slot.stored_item.id:
			player_data.merge_items(old_item, hovered_slot.stored_item)

		if old_main_idx >= 0:
			player_data.main_inventory.set(old_main_idx, hovered_slot.stored_item)
		elif old_hotbar_idx >= 0:
			player_data.hotbar.set(old_hotbar_idx, hovered_slot.stored_item)
		if not hovered_slot or hovered_main_idx >= 0:
			player_data.main_inventory.set(hovered_main_idx, old_item)
			print(player_data.main_inventory)
		elif not hovered_slot or hovered_hotbar_idx >= 0:
			player_data.hotbar.set(hovered_hotbar_idx, old_item)
			print(player_data.hotbar)
		_on_hotbar_updated()
		_on_main_inventory_updated()

	reset()


func button_hovered(button: InventoryButton):
	hovered_slot = button


func button_unhovered():
	hovered_slot = null


func stored_item_set(button: InventoryButton) -> void:
	var button_slot = hotbar.get_children().find(button)
	if not active_slot == button_slot:
		return
	player_data.set_active_item(-1)


func reset() -> void:
	old_slot = null
	drag_icon.texture = null
	hovered_slot = null


func _on_main_inventory_visibility_changed() -> void:
	reset()


func _on_player_synced() -> void:
	player_data = game_manager.player_data
	player_data.hotbar_updated.connect(_on_hotbar_updated)
	player_data.main_inventory_updated.connect(_on_main_inventory_updated)
	player_data.money_updated.connect(_on_money_updated)
	_on_hotbar_updated()
	_on_main_inventory_updated()
	_on_shop_inventory_updated()
	_on_money_updated()
	call_deferred("@active_slot_setter", 0) # FUCK OFF this is so stupid


func _on_hotbar_updated() -> void:
	var index : int = -1
	for item: Item in player_data.hotbar:
		index += 1
		var inventory_slot : InventoryButton = hotbar.get_child(index)
		inventory_slot.stored_item = item if item else null


func _on_main_inventory_updated() -> void:
	var index : int = -1
	for item: Item in player_data.main_inventory:
		index += 1
		var inventory_slot : InventoryButton = main_inventory.get_child(index)
		inventory_slot.stored_item = item if item else null


func _on_shop_inventory_updated() -> void:
	var index : int = -1
	for item: Item in Shop.instance.main_inventory:
		index += 1
		var inventory_slot : InventoryButton = shop_inventory.get_child(index)
		inventory_slot.stored_item = item if item else null


func _on_active_slot_changed(slot: int, in_old_slot : int) -> void:
	if not hotbar:
		return # go fuck yourself godot
	var hotbar_buttons : Array = hotbar.get_children()
	for button: InventoryButton in hotbar_buttons:
		button.add_theme_stylebox_override("normal", normal_stylebox)
	var hotbar_button: InventoryButton = hotbar.get_children()[slot]
	hotbar_button.add_theme_stylebox_override("normal", hover_stylebox)
	on_active_slot_changed.emit(in_old_slot)


func _on_money_updated() -> void:
	money_label.text = "Money: " + str(player_data.money)


func _handle_shop_interaction(old_item: Item, old_inventory: Array[Node], new_inventory: Array[Node]) -> void:
	if old_item.unsellable:
		print("Item is unable to be sold")
		return
	var old_slot_idx : int = old_inventory.find(old_slot)
	if old_slot_idx >= 0: # We're selling
		player_data.money += old_item.sell_value * old_item.count
		if old_inventory == main_inventory.get_children():
			player_data.main_inventory.set(old_slot_idx, null)
		elif new_inventory == hotbar.get_children():
			player_data.hotbar.set(old_slot_idx, null)
	elif new_inventory.has(hovered_slot): # We're buying
		var shop_inventory_slots = shop_inventory.get_children()
		old_slot_idx = shop_inventory_slots.find(old_slot)
		var new_slot_idx : int = new_inventory.find(hovered_slot)
		if not player_data.money > old_item.sell_value:
			print("You're too poor bitch")
			return
		var new_stored_item = new_inventory[new_slot_idx].stored_item
		var old_stored_item = shop_inventory_slots[old_slot_idx].stored_item
		if old_stored_item == null:
			print("old index: ", old_slot_idx)
			print(old_inventory[old_slot_idx].stored_item)
		elif new_stored_item != null:
			if new_stored_item.id == old_stored_item.id:
				if new_stored_item.count < new_stored_item.max_count:
					new_stored_item.count += 1
					player_data.money -= old_item.sell_value
			else:
				print("Tried to buy item in non-empty slot: ", new_inventory[new_slot_idx].stored_item)
			return
		player_data.money -= old_item.sell_value
		var new_item : Item = old_item.duplicate()
		new_item.count = 1
		if new_inventory == main_inventory.get_children():
			player_data.main_inventory.set(new_slot_idx, new_item)
		elif new_inventory == hotbar.get_children():
			player_data.hotbar.set(new_slot_idx, new_item)
