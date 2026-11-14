## we are using GodotSteam plugin docs located here : https://godotsteam.com
class_name SteamLobbyManager extends Node2D

## 480 is the default for local testing
## to publish we need a developer account on steamworks ($100 per registered application)
## this is set in the project steam settings
static var app_id : int = 0
static var is_online : bool = true

## Current User Specific information
static var current_user_id : int = 0
static var current_user_username : String = ""
static var owns_game : bool = true

## Lobby specific information
static var lobby_id : int = 0
# steam invites / join via friend on steam.
static var invite_lobby_id : int = 0

static var instance : SteamLobbyManager

func _init() -> void:
	SteamLobbyManager.instance = self

func _ready() -> void:
	var initialize_response: Dictionary = Steam.get_steam_init_result()
	print("Did Steam initialize?: %s " % initialize_response)
	
	var status : Steam.SteamAPIInitResult = initialize_response['status']
	if status != Steam.STEAM_API_INIT_RESULT_OK:
		printerr("Failed to initialize Steam, shutting down: %s" % initialize_response)
		_close_game()
		return
	
	SteamLobbyManager.app_id = Steam.getAppID()
	SteamLobbyManager.is_online = Steam.loggedOn()
	SteamLobbyManager.current_user_id = Steam.getSteamID()
	SteamLobbyManager.current_user_username = Steam.getPersonaName()
	SteamLobbyManager.owns_game = Steam.isSubscribed()
	
	#ignore while in development
	if Engine.is_editor_hint():
		owns_game = true
	if not owns_game:
		printerr("User does not own this game")
		_close_game()
		return
	
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)

func _close_game() -> void:
	get_tree().quit()

func _on_lobby_created(connect: int, lobby_id: int) -> void:
	pass

func _on_lobby_joined(lobby: int, permissions: int, locked: bool, response: int) -> void:
	pass

func _process(_delta: float) -> void:
	Steam.run_callbacks()
