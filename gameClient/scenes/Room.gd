extends Control

const ROOM_LIST_SCENE_PATH := "res://scenes/RoomList.tscn"

@onready var room_id_label: Label = $MarginContainer/Grid/RoomIdCard/MarginContainer/RoomIdLabel
@onready var phase_label: Label = $MarginContainer/Grid/PhaseCard/MarginContainer/PhaseLabel
@onready var members_label: Label = $MarginContainer/Grid/MembersCard/MarginContainer/MembersLabel
@onready var ready_button: Button = $MarginContainer/Grid/ReadyCard/MarginContainer/ReadyButton
@onready var back_button: Button = $MarginContainer/Grid/BackCard/MarginContainer/BackButton

func _ready() -> void:
	_refresh_view()
	ready_button.pressed.connect(_on_ready_pressed)
	back_button.pressed.connect(_on_back_pressed)
	if not ClientRpc.game_state_updated_received.is_connected(_on_game_state_updated_received):
		ClientRpc.game_state_updated_received.connect(_on_game_state_updated_received)

func _exit_tree() -> void:
	if ClientRpc.game_state_updated_received.is_connected(_on_game_state_updated_received):
		ClientRpc.game_state_updated_received.disconnect(_on_game_state_updated_received)

func _on_back_pressed() -> void:
	ServerRpc.leave_room(_get_room_id())

func _on_ready_pressed() -> void:
	ServerRpc.set_player_ready(not _is_current_player_ready())

func _build_members_text() -> String:
	var players: Array = _get_players()
	if players.is_empty():
		return "Members:\n- No members"

	var lines: PackedStringArray = ["Members:"]
	for player_variant in players:
		var player := player_variant as Dictionary
		var ready_status := "ready" if bool(player.get("is_ready", false)) else "waiting"
		var connection_state := str(player.get("connection_state", "connected")).strip_edges()
		lines.append("- %s (%s, %s)" % [str(player.get("username", "")), ready_status, connection_state])
	return "\n".join(lines)

func _on_game_state_updated_received(state: Dictionary) -> void:
	var room_id := str(state.get("room_id", "")).strip_edges()
	if room_id != _get_room_id():
		return
	_refresh_view()

func _get_players() -> Array:
	var state := SessionFlowManager.game_state
	var players: Array = state.get("players", [])
	return players

func _get_room_id() -> String:
	return str(SessionFlowManager.game_state.get("room_id", "")).strip_edges()

func _get_phase() -> String:
	var phase := str(SessionFlowManager.game_state.get("phase", "waiting")).strip_edges()
	var countdown := int(SessionFlowManager.game_state.get("transition_countdown", 0))
	if phase == "all_ready" and countdown > 0:
		return "%s (%d)" % [phase, countdown]
	return phase

func _is_current_player_ready() -> bool:
	var current_username := AuthManager.auth_username.strip_edges()
	if current_username.is_empty():
		return false

	for player_variant in _get_players():
		var player := player_variant as Dictionary
		if str(player.get("username", "")).strip_edges() == current_username:
			return bool(player.get("is_ready", false))

	return false

func _refresh_view() -> void:
	room_id_label.text = "Room ID: %s" % _get_room_id()
	phase_label.text = "Phase: %s" % _get_phase()
	members_label.text = _build_members_text()
	ready_button.text = "Unready" if _is_current_player_ready() else "Ready"
