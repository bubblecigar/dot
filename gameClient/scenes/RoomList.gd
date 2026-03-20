extends Control

@onready var create_room_button: Button = $MarginContainer/Grid/CreateRoomCard/MarginContainer/CreateRoomButton
@onready var refresh_button: Button = $MarginContainer/Grid/RefreshCard/MarginContainer/RefreshButton
@onready var rooms_label: Label = $MarginContainer/Grid/RoomsCard/MarginContainer/RoomsLabel
@onready var status_label: Label = $MarginContainer/Grid/StatusCard/MarginContainer/StatusLabel

func _ready() -> void:
	create_room_button.pressed.connect(_on_create_room_pressed)
	refresh_button.pressed.connect(_request_room_list)
	if not ClientRpc.room_list_received.is_connected(_on_room_list_received):
		ClientRpc.room_list_received.connect(_on_room_list_received)
	_render_room_list(StateStore.available_rooms)
	status_label.text = "Loading rooms..."
	_request_room_list()

func _exit_tree() -> void:
	if ClientRpc.room_list_received.is_connected(_on_room_list_received):
		ClientRpc.room_list_received.disconnect(_on_room_list_received)

func _on_create_room_pressed() -> void:
	status_label.text = "Creating room..."
	ServerRpc.create_room()

func _request_room_list() -> void:
	status_label.text = "Refreshing rooms..."
	ServerRpc.request_room_list()

func _on_room_list_received(rooms: Array) -> void:
	_render_room_list(rooms)
	status_label.text = "Rooms loaded: %d" % rooms.size()

func _render_room_list(rooms: Array) -> void:
	if rooms.is_empty():
		rooms_label.text = "Rooms:\n- No rooms yet"
		return

	var lines: PackedStringArray = ["Rooms:"]
	for room_variant in rooms:
		var room := room_variant as Dictionary
		var room_id := str(room.get("id", "unknown"))
		var owner := str(room.get("owner_username", "unknown"))
		lines.append("- %s (owner: %s)" % [room_id, owner])
	rooms_label.text = "\n".join(lines)
