extends Control

const ROOM_LIST_SCENE_PATH := "res://scenes/RoomList.tscn"

@onready var room_id_label: Label = $MarginContainer/Grid/RoomIdCard/MarginContainer/RoomIdLabel
@onready var members_label: Label = $MarginContainer/Grid/MembersCard/MarginContainer/MembersLabel
@onready var back_button: Button = $MarginContainer/Grid/BackCard/MarginContainer/BackButton

func _ready() -> void:
	room_id_label.text = "Room ID: %s" % StateStore.current_room_id
	members_label.text = _build_members_text()
	back_button.pressed.connect(_on_back_pressed)
	if not ClientRpc.game_state_updated_received.is_connected(_on_game_state_updated_received):
		ClientRpc.game_state_updated_received.connect(_on_game_state_updated_received)

func _exit_tree() -> void:
	if ClientRpc.game_state_updated_received.is_connected(_on_game_state_updated_received):
		ClientRpc.game_state_updated_received.disconnect(_on_game_state_updated_received)

func _on_back_pressed() -> void:
	ServerRpc.leave_room(StateStore.current_room_id)
	StateStore.clear_room_data()
	StateStore.clear_game_state()
	SceneManager.change_scene(ROOM_LIST_SCENE_PATH, true)

func _build_members_text() -> String:
	var players: Array = _get_players()
	if players.is_empty():
		return "Members:\n- No members"

	var lines: PackedStringArray = ["Members:"]
	for player_variant in players:
		var player := player_variant as Dictionary
		lines.append("- %s" % str(player.get("username", "")))
	return "\n".join(lines)

func _on_game_state_updated_received(state: Dictionary) -> void:
	var room_id := str(state.get("room_id", "")).strip_edges()
	if room_id != StateStore.current_room_id:
		return
	members_label.text = _build_members_text()

func _get_players() -> Array:
	var state := StateStore.game_state
	var players: Array = state.get("players", [])
	return players
