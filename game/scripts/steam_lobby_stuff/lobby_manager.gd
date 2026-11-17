## we are using GodotSteam plugin docs located here : https://godotsteam.com
class_name LobbyManager extends Control

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

static var instance : LobbyManager

@export var host_button : Button
@export var join_button : Button
@export var exit_button : Button

@export var spinning_fish_player : AnimatedImagePlayer
@export var spinning_fish_gif : AnimatedImageTexture

@export var player_spawner : MultiplayerSpawner
@export var starting_world : WorldBackBone

@export var starting_screen_ui : Control

@export var player_scene : PackedScene

var peer : SteamMultiplayerPeer

const already_started_loby_id : String = "already_started_loby_id"
const connect_to_lobby_search_term : String = "+connect_lobby"
#necessary since we are using debug steam game
const magic_tag : String = "my super awesome unique tag name that no one else is using"
const MAGIC_KEY : String = "asdasda23w2ivn17800as9u77v6982nnmv;;aoi8y77ayubhl;"

#we can set player specific lobby values using setLobbyMemberData instead of setLobbyData

func _init() -> void:
	LobbyManager.instance = self

func _ready() -> void:
	var initialize_response: Dictionary = Steam.get_steam_init_result()
	print("Did Steam initialize?: %s " % initialize_response)

	Steam.initRelayNetworkAccess()
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true

	var status : Steam.SteamAPIInitResult = initialize_response['status']
	if status != Steam.STEAM_API_INIT_RESULT_OK:
		printerr("Failed to initialize Steam, shutting down: %s" % initialize_response)
		_close_game()
		return

	LobbyManager.app_id = Steam.getAppID()
	LobbyManager.is_online = Steam.loggedOn()
	LobbyManager.current_user_id = Steam.getSteamID()
	LobbyManager.current_user_username = Steam.getPersonaName()
	LobbyManager.owns_game = Steam.isSubscribed()

	#ignore while in development
	if Engine.is_editor_hint():
		owns_game = true
	if not owns_game:
		printerr("User does not own this game")
		_close_game()
		return

	#spinning_fish_player.load_from_file(spinning_fish_gif.resource_path)
	if not Engine.is_editor_hint():
		spinning_fish_player.play()

	Steam.lobby_joined.connect(LobbyManager.instance._on_lobby_joined)
	Steam.join_requested.connect(_on_join_though_friend)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_data_update.connect(_on_lobby_data_update)

	player_spawner.spawn_function = spawn_player
	#bc host and client are same process we need to cover spawning their client as a special case
	player_spawner.child_entered_tree.connect(_on_player_spawned)

	multiplayer.peer_connected.connect(_on_player_joined)
	multiplayer.peer_disconnected.connect(_on_player_leave)

	host_button.pressed.connect(_open_lobby_host)
	join_button.pressed.connect(_open_lobby_search)
	exit_button.pressed.connect(_close_game)

	_check_command_line_args()

#region runs on client
func _open_lobby_host() -> void:
	LobbyHostScreen.instance.popup()

func _open_lobby_search() -> void:
	LobbySearchScreen.instance.popup()

func _on_lobby_created(connection_status: Steam.Result, in_lobby_id: int) -> void:
	if connection_status != Steam.Result.RESULT_OK:
		printerr("Failed to create a lobby: %s" % connection_status)
		return
	print("Successfully created lobby %s " % String.num_int64(in_lobby_id))
	LobbyManager.instance.lobby_id = in_lobby_id

	spinup_server(in_lobby_id)

	#for display / searching for lobbies
	var requested_lobby_name : String = LobbyHostScreen.instance.lobby_name.text
	requested_lobby_name = requested_lobby_name.strip_edges()
	if not Steam.setLobbyData(in_lobby_id, "name", requested_lobby_name):
		printerr("Failed to set lobby name")

	#specific lobby data / tags the user wants to set.
	var data_sets : PackedStringArray = LobbyHostScreen.instance.lobby_data_search_line_edit.text.split(",", false)
	for key_value_pair : String in data_sets:
		var pair : PackedStringArray = key_value_pair.split(":", false, 1)
		if pair.size() != 2:
			continue
		if not Steam.setLobbyData(in_lobby_id, pair[0], pair[1]):
			printerr("Failed to set lobby %s data [%s : %s]" % [in_lobby_id, pair[0], pair[1]])

	if not Steam.setLobbyData(in_lobby_id, LobbyManager.magic_tag, LobbyManager.MAGIC_KEY):
		printerr("Failed to set lobby %s data [%s : %s]" % [in_lobby_id, LobbyManager.magic_tag, LobbyManager.MAGIC_KEY])

func spinup_server(in_lobby_id : int) -> void:
	print("trying to start server")
	Steam.setLobbyJoinable(in_lobby_id, true)
	# Create the host peer (virtual port 0) and assign to Godot's MultiplayerAPI
	var error := peer.create_host(0)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Hosting Steam P2P lobby: ", LobbyManager.instance.lobby_id)
		LobbyManager.instance.lobby_id = in_lobby_id
		var server_peer_id : int = peer.get_unique_id()
		set_multiplayer_authority(server_peer_id)
		_on_player_joined(server_peer_id)

## if you join a friends game without having the game open yet it will pass the lobby_id via command args
func _check_command_line_args() -> void:
	var command_line_args : Array = OS.get_cmdline_args()
	if command_line_args.is_empty():
		return
	print("Command line args %s " % str(command_line_args))

	var in_lobby_id : int = -1
	var num_args : int = command_line_args.size()
	for i in num_args:
		var arg : String = command_line_args[i]
		if connect_to_lobby_search_term in arg or already_started_loby_id in arg:
			in_lobby_id = int(command_line_args[i+1])

	if in_lobby_id <= 0:
		return

	_join_lobby_through_ui(in_lobby_id)

func _on_join_though_friend(in_lobby_id : int, friend_id : int) -> void:
	var friend_name : String = Steam.getFriendPersonaName(friend_id)
	print("Joining lobby with... %s" % friend_name)
	Steam.joinLobby(in_lobby_id)

func _join_lobby_through_ui(in_lobby_id : int) -> void:
	print("Attempting to join lobby %s from the lobby list" % in_lobby_id)
	Steam.joinLobby(in_lobby_id)
	LobbyManager.instance.invite_lobby_id = in_lobby_id

func _on_lobby_joined(in_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	print("player tried to join lobby")

	#hide UI for host/join
	hide()
	LobbySearchScreen.instance.hide()
	LobbyHostScreen.instance.hide()

	var host_steam_id: int = Steam.getLobbyOwner(in_lobby_id)
	# Only create a client peer if we are not the host
	if host_steam_id != Steam.getSteamID():
		var error := peer.create_client(host_steam_id, 0)
		if error == OK:
			multiplayer.multiplayer_peer = peer
			print("Joined Steam P2P lobby as client.")

	if response == Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("Lobby %s joined successfully" % String.num_int64(in_lobby_id))
		LobbyManager.instance.lobby_id = in_lobby_id
		##TODO Swap to the lobby scene here
		return

	match response:
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST:
			printerr("Failed joining lobby %s, this lobby no longer exists.", in_lobby_id)
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED:
			printerr("Failed joining lobby %s, you don't have permission to join this lobby.", in_lobby_id)
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_FULL:
			printerr("Failed joining lobby %s, the lobby is now full.", in_lobby_id)
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_ERROR:
			printerr("Failed joining lobby %s, something unexpected happened!", in_lobby_id)
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_BANNED:
			printerr("Failed joining lobby %s, you are banned from this lobby.", in_lobby_id)
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_LIMITED:
			printerr("Failed joining lobby %s, you cannot join due to having a limited account.", in_lobby_id)
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED:
			printerr("Failed joining lobby %s, this lobby is locked or disabled.", in_lobby_id)
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN:
			printerr("Failed joining lobby %s, this lobby is community locked.", in_lobby_id)
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU:
			printerr("Failed joining lobby %s, a user in the lobby has blocked you from joining.", in_lobby_id)
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER:
			printerr("Failed joining lobby %s, a user you have blocked is in the lobby.", in_lobby_id)
		Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_RATE_LIMIT_EXCEEDED:
			printerr("Failed joining lobby %s, you have exceeded the rate limit.", in_lobby_id)
		_:
			printerr("Failed joining lobby %s", in_lobby_id)

func toggle_lobby_joinable(can_new_players_join : bool) -> void:
	Steam.setLobbyJoinable(LobbyManager.instance.lobby_id, can_new_players_join)

func open_steam_invite() -> void:
	Steam.activateGameOverlayInviteDialog(LobbyManager.instance.lobby_id)

func leave_lobby() -> void:
	print("player leaving lobby")
	Steam.leaveLobby(LobbyManager.instance.lobby_id)
	LobbyManager.instance.lobby_id = 0
	LobbyManager.instance.invite_lobby_id = 0

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		_close_game()

func _on_player_spawned(new_player : PlayerMetadata) -> void:
	#since p2p server and host client are on same process
	if multiplayer.get_unique_id() == new_player.peer_id:
		print("[_on_player_spawned] we own authority ", new_player.peer_id)
		new_player.player_controller.make_current_player()
	## client
	if not is_multiplayer_authority():
		if multiplayer.get_unique_id() != new_player.peer_id:
			print("[_on_player_spawned] we dont own authority ", new_player.peer_id)
			new_player.process_mode = Node.PROCESS_MODE_DISABLED
			new_player.set_process(false)
			new_player.set_physics_process(false)

func _close_game() -> void:
	get_tree().quit()

## when a player joins / leaves and when they send a message in chat?
func _on_lobby_chat_update(in_lobby_id: int, user_changed_id: int, _making_change_id: int, chat_state: Steam.ChatMemberStateChange) -> void:
	if LobbyManager.instance.lobby_id != in_lobby_id:
		return
	var changed_user: String = Steam.getFriendPersonaName(user_changed_id)
	if chat_state == Steam.ChatMemberStateChange.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s joined the lobby\n" % changed_user)
	else:
		print("%s left the lobby\n" % changed_user)
	update_player_list()

## when a loby's metadata updates
func _on_lobby_data_update(_success: int, in_lobby_id: int, _member_id: int) -> void:
	if LobbyManager.instance.lobby_id != in_lobby_id:
		return
	update_player_list()

##TODO update player list here if we want an in game UI for it
func update_player_list() -> void:
	pass

func _process(_delta: float) -> void:
	Steam.run_callbacks()


## we join the lobby first and then we join via multiplayer peer
#TODO spawn player character (on server) - this does get pinged on clients as well
func _on_player_joined(client_peer_id : int) -> void:
	print("player joined")
	if not is_multiplayer_authority():
		return
	player_spawner.spawn(client_peer_id)


func spawn_player(for_peer_id : int) -> PlayerMetadata:
	print("spawn player ", for_peer_id)
	var new_player : PlayerMetadata = player_scene.instantiate()
	var steam_id : int = Steam.getSteamID()
	new_player.init(for_peer_id, steam_id, starting_world.spawn_location)
	new_player.set_multiplayer_authority(for_peer_id)

	GameManager.instance.setup(new_player)
	new_player.name = str(for_peer_id)

	return new_player

#TODO despawn player character (on server)
#TODO if no players left connected or the host leaves kill the server
func _on_player_leave(client_peer_id : int) -> void:
	var current_children := player_spawner.get_children()
	if client_peer_id == 1:
		for player : PlayerMetadata in current_children:
			player_spawner.remove_child(player)
		show()
	else:
		for player : PlayerMetadata in current_children:
			if player.peer_id == client_peer_id:
				player_spawner.remove_child(player)
				break

func get_current_player(client_peer_id : int) -> PlayerMetadata:
	var current_player : PlayerMetadata = null
	var current_children := player_spawner.get_children()
	for player : PlayerMetadata in current_children:
		if player.peer_id == client_peer_id:
			current_player = player
			break
	return current_player
