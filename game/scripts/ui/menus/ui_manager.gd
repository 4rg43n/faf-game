extends Control

@export var lobby_manager: LobbyManager
@export var options_menu: CenterContainer
@export var inventory: InventorySystem
@export var game_manager: GameManager

func _ready() -> void:
	lobby_manager.visibility_changed.connect(_on_lobby_manager_visibility_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not LobbyManager.instance.is_visible_in_tree():
		if Input.is_action_just_pressed("esc_key"):
			options_menu.visible = !options_menu.visible
			if options_menu.visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				game_manager.paused = true
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				game_manager.paused = false
		elif Input.is_action_just_pressed("inventory"):
			inventory.main_inventory.visible = !inventory.main_inventory.visible
			if inventory.main_inventory.visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_lobby_manager_visibility_changed():
	inventory.visible = not lobby_manager.visible
