extends Node

var auth_status: String = "unauthenticated"
var auth_username: String = ""
var auth_token: String = ""
var available_rooms: Array = []
var current_room_id: String = ""
var game_state: Dictionary = {}

func get_debug_snapshot() -> Dictionary:
	var snapshot := {}
	for property in get_property_list():
		var usage := int(property.get("usage", 0))
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue

		var name := String(property.get("name", ""))
		if name.begins_with("_"):
			continue

		snapshot[name] = get(name)
	return snapshot

func set_auth_data(status: String, username: String, token: String) -> void:
	auth_status = status
	auth_username = username
	auth_token = token

func clear_auth_data() -> void:
	set_auth_data("unauthenticated", "", "")

func set_available_rooms(rooms: Array) -> void:
	available_rooms = rooms.duplicate(true)

func clear_available_rooms() -> void:
	available_rooms = []

func set_current_room_id(room_id: String) -> void:
	current_room_id = room_id.strip_edges()

func clear_room_data() -> void:
	set_current_room_id("")

func set_game_state(state: Dictionary) -> void:
	game_state = state.duplicate(true)

func clear_game_state() -> void:
	game_state = {}
