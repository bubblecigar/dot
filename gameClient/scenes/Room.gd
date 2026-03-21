extends Control

const ROOM_LIST_SCENE_PATH := "res://scenes/RoomList.tscn"

@onready var room_id_label: Label = $MarginContainer/Grid/RoomIdCard/MarginContainer/RoomIdLabel
@onready var members_label: Label = $MarginContainer/Grid/MembersCard/MarginContainer/MembersLabel
@onready var back_button: Button = $MarginContainer/Grid/BackCard/MarginContainer/BackButton

func _ready() -> void:
	room_id_label.text = "Room ID: %s" % StateStore.current_room_id
	members_label.text = _build_members_text()
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
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
