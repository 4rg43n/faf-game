class_name LobbySearchScreen extends Window

static var instance : LobbySearchScreen

@export var show_filters_button : Button
@export var refresh_query_search : Button
@export var close_button : Button

@export var lobby_filter_popup : LobbySearchFilters

@export var lobby_container : VBoxContainer
@export var LOBBY_ENTRY_SCENE : PackedScene

func _init() -> void:
	LobbySearchScreen.instance = self

func _ready() -> void:
	show_filters_button.pressed.connect(show_filters)
	refresh_query_search.pressed.connect(refresh_filters)
	close_button.pressed.connect(close_window)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	visibility_changed.connect(on_visibility_changed)

func on_visibility_changed() -> void:
	#clear existing lobbies
	for child : LobbySearchEntry in lobby_container:
		lobby_container.remove_child(child)
		child.queue_free()
	lobby_filter_popup.hide()

func close_window() -> void:
	hide()

func show_filters() -> void:
	LobbySearchFilters.instance.popup_centered()

func refresh_filters() -> void:
	add_lobby_filters()
	Steam.requestLobbyList()

func add_lobby_filters() -> void:
	Steam.addRequestLobbyListDistanceFilter(LobbySearchFilters.instance.search_distance_options.selected as Steam.LobbyDistanceFilter)
	Steam.addRequestLobbyListFilterSlotsAvailable(int(LobbySearchFilters.instance.open_player_slots_spin_box.value))
	Steam.addRequestLobbyListResultCountFilter(int(LobbySearchFilters.instance.max_query_size_spin_box.value))
	
	if not LobbySearchFilters.instance.lobby_name_line_edit.text.is_empty():
		Steam.addRequestLobbyListStringFilter("lobby_name", LobbySearchFilters.instance.lobby_name_line_edit.text, Steam.LobbyComparison.LOBBY_COMPARISON_EQUAL)
	
	#specific lobby data / tags the user wants to match with
	var data_sets : PackedStringArray = LobbySearchFilters.instance.lobby_data_line_edit.text.split(",", false)
	for key_value_pair : String in data_sets:
		var pair : PackedStringArray = key_value_pair.split(":", false, 1)
		if pair.size() != 2:
			continue
		if pair[0].length() > Steam.MAX_LOBBY_KEY_LENGTH:
			printerr("Invalid term passed, too long: %s" % key_value_pair)
			continue
		Steam.addRequestLobbyListStringFilter(pair[0], pair[1], Steam.LobbyComparison.LOBBY_COMPARISON_EQUAL)

func _on_lobby_match_list(lobbies: Array) -> void:
	#clear existing lobbies
	for child : LobbySearchEntry in lobby_container:
		lobby_container.remove_child(child)
		child.queue_free()
	
	if lobbies.is_empty():
		return

	for current_lobby_id : int in lobbies:
		var new_lobby_obj : LobbySearchEntry = LOBBY_ENTRY_SCENE.instantiate()
		new_lobby_obj.initalize_from_loby_object(current_lobby_id)
		new_lobby_obj.joining_lobby.connect(LobbyManager.instance._join_lobby_through_ui)
		lobby_container.call_deferred("add_child", new_lobby_obj)
