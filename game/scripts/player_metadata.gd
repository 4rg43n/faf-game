class_name PlayerMetadata extends Node3D

signal main_inventory_updated()
signal hotbar_updated()

@export var peer_id : int
@export var steam_id : int
@export var player_controller : PlayerController
@export var current_equipment : CustomEnums.Equipment_Type = CustomEnums.Equipment_Type.EMPTY_HAND
@export var main_inventory : Array[Item]:
	set(value):
		main_inventory = value
		main_inventory_updated.emit()
@export var hotbar : Array[Item]:
	set(value):
		hotbar = value
		hotbar_updated.emit()

const MAX_INVENTORY_SIZE : int = 50
const MAX_HOTBAR_SIZE : int = 9

func init(in_peer_id : int, in_steam_id : int, in_spawn_location : Node3D) -> void:
	print("spawning in a new client for peer ", String.num_int64(in_peer_id))
	peer_id = in_peer_id
	steam_id = in_steam_id
	player_controller.position = in_spawn_location.position


func add_item_if_possible(new_item: Item) -> bool:
	if not new_item:
		printerr("Tried to add null item to inventory")
		return false
	var free_slot : int = -1
	var index : int = -1
	for hotbar_item: Item in hotbar:
		index += 1
		if hotbar_item == null:
			if free_slot == -1:
				free_slot = index
			continue
		if hotbar_item.id == new_item.id and hotbar_item.count + new_item.count < hotbar_item.max_count:
			hotbar_item.count += new_item.count if new_item.count > 0 else 1
			hotbar_updated.emit()
			return true
	if free_slot >= 0:
		hotbar.set(free_slot, new_item)
		hotbar_updated.emit()
		return true
	index = -1
	for item: Item in main_inventory:
		index += 1
		if item == null:
			free_slot = index
			continue
		if item.id == new_item.id and item.count + new_item.count < item.max_count:
			item.count += new_item.count if new_item.count > 0 else 1
			main_inventory_updated.emit()
			return true
	if free_slot >= 0:
		main_inventory[free_slot] = new_item
		main_inventory_updated.emit()
		return true
	return false
