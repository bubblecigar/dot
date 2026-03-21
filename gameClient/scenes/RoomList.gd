extends Control

@onready var create_room_button: Button = $MarginContainer/Grid/CreateRoomCard/MarginContainer/CreateRoomButton
@onready var refresh_button: Button = $MarginContainer/Grid/RefreshCard/MarginContainer/RefreshButton
@onready var logout_button: Button = $MarginContainer/Grid/LogoutCard/MarginContainer/LogoutButton
@onready var rooms_container: VBoxContainer = $MarginContainer/Grid/RoomsCard/MarginContainer/RoomsContainer
@onready var status_label: Label = $MarginContainer/Grid/StatusCard/MarginContainer/StatusLabel

func _ready() -> void:
	create_room_button.pressed.connect(_on_create_room_pressed)
	refresh_button.pressed.connect(_request_room_list)
	logout_button.pressed.connect(_on_logout_pressed)
	if not ClientRpc.room_list_received.is_connected(_on_room_list_received):
		ClientRpc.room_list_received.connect(_on_room_list_received)
	_render_room_list([])
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

func _on_logout_pressed() -> void:
	status_label.text = "Logging out..."
	AuthManager.logout()

func _on_room_list_received(rooms: Array) -> void:
	_render_room_list(rooms)
	status_label.text = "Rooms loaded: %d" % rooms.size()

func _render_room_list(rooms: Array) -> void:
	for child in rooms_container.get_children():
		child.queue_free()

	if rooms.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No rooms yet"
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rooms_container.add_child(empty_label)
		return

	for room_variant in rooms:
		var room := room_variant as Dictionary
		var room_id := str(room.get("id", "unknown"))
		var owner := str(room.get("owner_username", "unknown"))
		var room_button := Button.new()
		room_button.custom_minimum_size = Vector2(0, 56)
		room_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		room_button.text = "%s (owner: %s)" % [room_id, owner]
		room_button.pressed.connect(_on_room_pressed.bind(room_id))
		rooms_container.add_child(room_button)

func _on_room_pressed(room_id: String) -> void:
	status_label.text = "Joining %s..." % room_id
	ServerRpc.join_room(room_id)
