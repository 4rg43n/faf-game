class_name LobbyHostGenerator extends PopupPanel

static var instance : LobbyHostGenerator

@export var create_button : Button
@export var cancel_button : Button
@export var max_players_spin_box : SpinBox
@export var lobby_visibility_options : OptionButton
@export var lobby_data_line_edit : LineEdit
@export var lobby_name : LineEdit

func _ready() -> void:
	create_button.pressed.connect(_on_create_pressed)
	create_button.pressed.connect(_on_cancel_pressed)
	Steam.lobby_created.connect(SteamLobbyManager.instance._on_lobby_created)

func _on_create_pressed() -> void:
	var lobby_type: Steam.LobbyType = lobby_visibility_options.selected as Steam.LobbyType
	Steam.createLobby(lobby_type, int(max_players_spin_box.value))

func _on_cancel_pressed() -> void:
	hide()
