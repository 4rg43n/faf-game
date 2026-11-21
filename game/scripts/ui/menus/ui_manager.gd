class_name UI extends Control

@export var lobby_manager: LobbyManager
@export var options_menu: CenterContainer
@export var inventory: InventorySystem
@export var game_manager: GameManager
@export var chaos_tracker: VBoxContainer
@export var speed_tracker: Label
@export var fps_tracker: Label
@export var credits: Control

static var instance: UI

func _init() -> void:
	instance = self

func _ready() -> void:
	lobby_manager.visibility_changed.connect(_on_lobby_manager_visibility_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not LobbyManager.instance.is_visible_in_tree():
		if Input.is_action_just_pressed("esc_key"):
			if inventory.inventory_container.visible:
				inventory.inventory_container.hide()
				inventory.background.visible = !inventory.background.visible
				inventory.shop_container.visible = false
				if inventory.inventory_container.visible:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				else:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				return
			options_menu.visible = !options_menu.visible
			if options_menu.visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				game_manager.paused = true
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				game_manager.paused = false
		elif Input.is_action_just_pressed("inventory"):
			inventory.inventory_container.visible = !inventory.inventory_container.visible
			inventory.background.visible = !inventory.background.visible
			inventory.shop_container.visible = false
			if inventory.inventory_container.visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# ----HOTBAR KEYS----
		if Input.is_action_just_pressed("hotbar_0"):
			inventory.active_slot = 0
		elif Input.is_action_just_pressed("hotbar_1"):
			inventory.active_slot = 1
		elif Input.is_action_just_pressed("hotbar_2"):
			inventory.active_slot = 2
		elif Input.is_action_just_pressed("hotbar_3"):
			inventory.active_slot = 3
		elif Input.is_action_just_pressed("hotbar_4"):
			inventory.active_slot = 4
		elif Input.is_action_just_pressed("hotbar_5"):
			inventory.active_slot = 5
		elif Input.is_action_just_pressed("hotbar_6"):
			inventory.active_slot = 6
		elif Input.is_action_just_pressed("hotbar_7"):
			inventory.active_slot = 7
		elif Input.is_action_just_pressed("hotbar_8"):
			inventory.active_slot = 8


func _on_lobby_manager_visibility_changed():
	inventory.visible = not lobby_manager.visible
	chaos_tracker.visible = not chaos_tracker.visible


func show_shop():
	inventory.inventory_container.visible = true
	inventory.background.visible = true
	inventory.shop_container.visible = true
	speed_tracker.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func hide_all_ui():
	inventory.inventory_container.visible = false
	inventory.background.visible = false
	inventory.shop_container.visible = false
	inventory.hotbar_container.visible = false
	speed_tracker.visible = false
	chaos_tracker.visible = false
	options_menu.visible = false
	fps_tracker.visible = false
	game_manager.player.hide_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
