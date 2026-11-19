class_name PlayerMetadata extends Node3D

signal main_inventory_updated()
signal hotbar_updated()

@export var peer_id : int
@export var steam_id : int
@export var player_controller : PlayerController
@export var current_equipment : CustomEnums.Equipment_Type = CustomEnums.Equipment_Type.EMPTY_HAND
@export var main_inventory : Array[Item]
@export var hotbar : Array[Item]

const MAX_INVENTORY_SIZE : int = 50
const MAX_HOTBAR_SIZE : int = 9

func init(in_peer_id : int, in_steam_id : int, in_spawn_location : Node3D) -> void:
	print("spawning in a new client for peer ", String.num_int64(in_peer_id))
	peer_id = in_peer_id
	steam_id = in_steam_id
	player_controller.position = in_spawn_location.position
	InventorySystem.instance.on_active_slot_changed.connect(set_active_item)


func add_item_if_possible(new_item: Item) -> bool:
	if not new_item:
		printerr("Tried to add null item to inventory")
		return false
	new_item = new_item.duplicate()
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


func merge_items(first_item: Item, second_item: Item):
	print("Attemping to merge items...")
	var first_idx : int = hotbar.find(first_item)
	if not first_idx >= 0:
		first_idx = main_inventory.find(first_item)
		if not first_idx >= 0:
			printerr("Tried to merge null items")
			return
	var second_idx : int = hotbar.find(second_item)
	var is_second_main_item : bool = false
	if not second_idx >= 0:
		second_idx = main_inventory.find(second_item)
		if not second_idx >= 0:
			printerr("Tried to merge null items")
			return
		is_second_main_item = true

	var total_count = first_item.count + second_item.count
	first_item.count = wrapi(total_count, 0, first_item.max_count)
	total_count -= first_item.count
	if total_count <= 0:
		if is_second_main_item:
			main_inventory.set(second_idx, null)
		else:
			hotbar.set(second_idx, null)
	else:
		second_item.count = total_count
	hotbar_updated.emit()
	main_inventory_updated.emit()
	return

func decrement_active_item() -> Item:
	var item : Item = null
	if hotbar[InventorySystem.instance.active_slot] == null:
		return item
	item = hotbar[InventorySystem.instance.active_slot]
	var current_hotbar_item : Item = hotbar[InventorySystem.instance.active_slot]
	current_hotbar_item.count -= 1

	if current_hotbar_item.count <= 0:
		item_removed_from_hotbar(current_hotbar_item, InventorySystem.instance.active_slot)
	hotbar_updated.emit()
	return item

## should be called when we scroll to new slot or when we pick up a new item into the active slot.
func set_active_item(old_slot : int) -> void:
	if not hotbar[old_slot] == null:
		var old_active_item : Item = hotbar[old_slot]
		var old_item_obj : Node3D = get_node_or_null(old_active_item.hotbar_item_path)
		if not old_item_obj == null:
			old_item_obj.visible = false

	if hotbar[InventorySystem.instance.active_slot] == null:
		current_equipment = CustomEnums.Equipment_Type.EMPTY_HAND
		return
	var new_active_item : Item = hotbar[InventorySystem.instance.active_slot]
	var new_item_obj : Node3D = get_node_or_null(new_active_item.hotbar_item_path)
	if new_item_obj == null:
		var scene : PackedScene = new_active_item.item_scene
		if scene != null:
			new_item_obj = scene.instantiate()
			if player_controller.LEFT_HANDED:
				player_controller.left_hand_socket.add_child(new_item_obj, true)
			else:
				player_controller.right_hand_socket.add_child(new_item_obj, true)
			new_active_item.hotbar_item_path = new_item_obj.get_path()
	new_item_obj.visible = true
	current_equipment = CustomEnums.Equipment_Type.THROWABLE_OBJ

func item_removed_from_hotbar(item : Item, old_hotbar_index : int) -> void:
	var old_item_obj : Node3D = get_node_or_null(item.hotbar_item_path)
	item.hotbar_item_path = ""
	if old_item_obj != null:
		if player_controller.LEFT_HANDED:
			player_controller.left_hand_socket.remove_child(old_item_obj)
		else:
			player_controller.right_hand_socket.remove_child(old_item_obj)
	hotbar.set(old_hotbar_index, null)
	current_equipment = CustomEnums.Equipment_Type.EMPTY_HAND
	hotbar_updated.emit()

func pickup_item(child_obj : Node3D) -> void:
	if player_controller.LEFT_HANDED:
		player_controller.left_hand_spawner.pickup_item(child_obj)
	else:
		player_controller.right_hand_spawner.pickup_item(child_obj)
