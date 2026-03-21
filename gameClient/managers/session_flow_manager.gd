extends Node

const LOGIN_SCENE_PATH := "res://scenes/Login.tscn"
const ROOM_LIST_SCENE_PATH := "res://scenes/RoomList.tscn"
const ROOM_SCENE_PATH := "res://scenes/Room.tscn"
const GAME_SCENE_PATH := "res://scenes/Game.tscn"

var game_state: Dictionary = {}
var _logout_requested: bool = false
var _logout_disconnect_requested: bool = false

func _ready() -> void:
	if not AuthManager.authenticated.is_connected(_on_authenticated):
		AuthManager.authenticated.connect(_on_authenticated)
	if not ClientRpc.game_state_updated_received.is_connected(_on_game_state_updated_received):
		ClientRpc.game_state_updated_received.connect(_on_game_state_updated_received)
	if not AuthManager.game_server_disconnected.is_connected(_on_game_server_disconnected):
		AuthManager.game_server_disconnected.connect(_on_game_server_disconnected)
	if not AuthManager.session_invalidated.is_connected(_on_session_invalidated):
		AuthManager.session_invalidated.connect(_on_session_invalidated)

func logout() -> void:
	if _logout_requested:
		return

	_logout_requested = true
	_logout_disconnect_requested = false

	var peer := multiplayer.multiplayer_peer
	if peer == null:
		_finalize_local_logout()
		return

	var room_id := _get_current_room_id()
	if not room_id.is_empty():
		ServerRpc.leave_room(room_id)
		return

	_request_server_logout()

func _on_game_state_updated_received(state: Dictionary) -> void:
	set_game_state(state)
	_route_from_game_state(state)

func _on_game_server_disconnected() -> void:
	if _logout_requested:
		_finalize_local_logout()

func _on_authenticated(_username: String) -> void:
	if not _get_current_room_id().is_empty():
		return

	var current_scene := SceneManager.get_current_scene()
	if current_scene != null and current_scene.scene_file_path == LOGIN_SCENE_PATH:
		SceneManager.change_scene(ROOM_LIST_SCENE_PATH, true)

func _get_current_room_id() -> String:
	return str(game_state.get("room_id", "")).strip_edges()

func _route_from_game_state(state: Dictionary) -> void:
	var room_id := str(state.get("room_id", "")).strip_edges()
	var phase := str(state.get("phase", "")).strip_edges()
	var current_scene := SceneManager.get_current_scene()
	if room_id.is_empty():
		if _logout_requested:
			_request_server_logout()
			return
		if current_scene != null and (
			current_scene.scene_file_path == ROOM_SCENE_PATH
			or current_scene.scene_file_path == GAME_SCENE_PATH
		) and AuthManager.auth_status == "authenticated":
			SceneManager.change_scene(ROOM_LIST_SCENE_PATH, true)
		return

	if phase == "playing":
		if current_scene != null and current_scene.scene_file_path == GAME_SCENE_PATH:
			return
		SceneManager.change_scene(GAME_SCENE_PATH, true)
		return

	if current_scene != null and current_scene.scene_file_path == ROOM_SCENE_PATH:
		return

	SceneManager.change_scene(ROOM_SCENE_PATH, true)

func _request_server_logout() -> void:
	if _logout_disconnect_requested:
		return
	_logout_disconnect_requested = true
	AuthManager.prepare_for_logout_disconnect()
	ServerRpc.logout()

func _finalize_local_logout() -> void:
	_logout_requested = false
	_logout_disconnect_requested = false
	AuthManager.clear_auth_data()
	clear_game_state()
	SceneManager.change_scene(LOGIN_SCENE_PATH, false)

func _on_session_invalidated(_message: String) -> void:
	_logout_requested = false
	_logout_disconnect_requested = false
	clear_game_state()
	SceneManager.change_scene(LOGIN_SCENE_PATH, false)

func set_game_state(state: Dictionary) -> void:
	game_state = state.duplicate(true)

func clear_game_state() -> void:
	game_state = {}

func get_debug_snapshot() -> Dictionary:
	return {
		"game_state": game_state.duplicate(true),
	}
