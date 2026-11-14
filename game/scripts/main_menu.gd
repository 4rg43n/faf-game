class_name LobbyMainMenu extends Node2D

@export var game_world : PackedScene

## we are using GodotSteam plugin docs located here : https://godotsteam.com

## 480 is the default for local testing
## to publish we need a developer account on steamworks ($100 per registered application)
## this is set in the project steam settings
static var app_id : int = 0
static var is_online : bool = true
static var current_user_id : int = 0
static var current_user_username : String = ""

static var owns_game : bool = true

func _init() -> void:
	pass

func _ready() -> void:
	var initialize_response: Dictionary = Steam.get_steam_init_result()
	print("Did Steam initialize?: %s " % initialize_response)
	
	var status : Steam.SteamAPIInitResult = initialize_response['status']
	if status != Steam.STEAM_API_INIT_RESULT_OK:
		printerr("Failed to initialize Steam, shutting down: %s" % initialize_response)
		_close_game()
		return
	
	LobbyMainMenu.app_id = Steam.getAppID()
	LobbyMainMenu.is_online = Steam.loggedOn()
	LobbyMainMenu.current_user_id = Steam.getSteamID()
	LobbyMainMenu.current_user_username = Steam.getPersonaName()
	LobbyMainMenu.owns_game = Steam.isSubscribed()
	
	#ignore while in development
	if Engine.is_editor_hint():
		owns_game = true
	if not owns_game:
		printerr("User does not own this game")
		_close_game()
		return

func _close_game() -> void:
	get_tree().quit()

#region steam multiplayer
func start_loby() -> void:
	pass

func join_game() ->void:
	pass
#endregion steam multiplayer

func _process(_delta: float) -> void:
	Steam.run_callbacks()
