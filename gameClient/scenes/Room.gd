extends Control

const ROOM_LIST_SCENE_PATH := "res://scenes/RoomList.tscn"

@onready var room_id_label: Label = $MarginContainer/Grid/RoomIdCard/MarginContainer/RoomIdLabel
@onready var members_label: Label = $MarginContainer/Grid/MembersCard/MarginContainer/MembersLabel
@onready var back_button: Button = $MarginContainer/Grid/BackCard/MarginContainer/BackButton

func _ready() -> void:
	room_id_label.text = "Room ID: %s" % StateStore.current_room_id
	members_label.text = _build_members_text()
	back_button.pressed.connect(_on_back_pressed)
	if not ClientRpc.room_updated_received.is_connected(_on_room_updated_received):
		ClientRpc.room_updated_received.connect(_on_room_updated_received)

func _exit_tree() -> void:
	if ClientRpc.room_updated_received.is_connected(_on_room_updated_received):
		ClientRpc.room_updated_received.disconnect(_on_room_updated_received)

func _on_back_pressed() -> void:
	ServerRpc.leave_room(StateStore.current_room_id)
	StateStore.set_current_room_id("")
	StateStore.set_current_room_members([])
	SceneManager.change_scene(ROOM_LIST_SCENE_PATH, true)

func _build_members_text() -> String:
	if StateStore.current_room_members.is_empty():
		return "Members:\n- No members"

	var lines: PackedStringArray = ["Members:"]
	for member in StateStore.current_room_members:
		lines.append("- %s" % str(member))
	return "\n".join(lines)

func _on_room_updated_received(room: Dictionary) -> void:
	var room_id := str(room.get("id", "")).strip_edges()
	if room_id != StateStore.current_room_id:
		return
	StateStore.set_current_room_members(room.get("members", []))
	members_label.text = _build_members_text()
