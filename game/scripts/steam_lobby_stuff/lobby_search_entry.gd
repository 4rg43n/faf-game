class_name LobbySearchEntry extends Panel

var lobby_id : int = 0
var lobby_name : String
var lobby_num_players : int = 0
var lobby_max_players : int = 0

@export var join_button : Button
@export var lobby_name_label : Label
@export var current_num_players_label : Label
@export var max_players_label : Label

signal joining_lobby(out_lobby_id : int)

func initalize_from_loby_object(current_lobby_id : int) -> void:
	name = "Lobby%s" % current_lobby_id
	lobby_id = current_lobby_id
	joining_lobby.connect(on_join_pressed)
	lobby_name = Steam.getLobbyData(lobby_id, "lobby_name")
	lobby_num_players = Steam.getNumLobbyMembers(lobby_id)
	lobby_max_players = Steam.getLobbyMemberLimit(lobby_id)

func _ready() -> void:
	lobby_name_label.text = lobby_name
	current_num_players_label.text = str(lobby_num_players)
	max_players_label.text = str(lobby_max_players)

func on_join_pressed():
	joining_lobby.emit(lobby_id)
