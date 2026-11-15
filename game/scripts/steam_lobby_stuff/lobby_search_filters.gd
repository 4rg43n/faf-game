class_name LobbySearchFilters extends Window

static var instance : LobbySearchFilters

@export var cancel_button : Button
@export var search_distance_options : OptionButton
@export var open_player_slots_spin_box : SpinBox
@export var max_query_size_spin_box : SpinBox
@export var lobby_data_search_line_edit : LineEdit
@export var lobby_name_line_edit : LineEdit

func _init() -> void:
	LobbySearchFilters.instance = self

func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)

func _on_cancel_pressed() -> void:
	hide()
