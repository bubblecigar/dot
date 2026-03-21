extends Node

const SharedGameState := preload("res://../shared/game_state.gd")

var _room_game_states: Dictionary = {}

@rpc("any_peer", "call_remote", "reliable")
func submit_button_states(states: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not SessionAuthService.is_peer_authenticated(peer_id):
		print("Rejected button states from unauthenticated peer %d" % peer_id)
		return
	print("Received button states from client:", states)

@rpc("any_peer", "call_remote", "reliable")
func authenticate(auth_data: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	print("Received auth data from peer %d: %s" % [peer_id, auth_data])

	var token := str(auth_data.get("token", "")).strip_edges()
	var result := await SessionAuthService.authenticate_peer(peer_id, token)
	if str(result.get("error", "")) == "auth_in_progress":
		return

	if not bool(result.get("ok", false)):
		await _reject_peer(peer_id, str(result.get("error", "invalid_token")))
		return

	ClientRpc.rpc_id(peer_id, "auth_result", {
		"ok": true,
		"username": str(result.get("username", "")),
	})
	print("Peer %d authenticated as %s" % [peer_id, str(result.get("username", ""))])

@rpc("any_peer", "call_remote", "reliable")
func notify_circle_moved() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not SessionAuthService.is_peer_authenticated(peer_id):
		print("Rejected circle movement from unauthenticated peer %d" % peer_id)
		return
	print("hello")

@rpc("any_peer", "call_remote", "reliable")
func request_room_list() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not SessionAuthService.is_peer_authenticated(peer_id):
		print("Rejected room list request from unauthenticated peer %d" % peer_id)
		return

	var username := SessionAuthService.get_authenticated_username(peer_id)
	var rooms := RoomService.get_rooms()
	print(
		"Room list requested by peer %d (%s): %d rooms"
		% [peer_id, username, rooms.size()]
	)
	ClientRpc.rpc_id(peer_id, "room_list", rooms)

@rpc("any_peer", "call_remote", "reliable")
func create_room() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not SessionAuthService.is_peer_authenticated(peer_id):
		print("Rejected room creation from unauthenticated peer %d" % peer_id)
		return

	var username := SessionAuthService.get_authenticated_username(peer_id)
	var room := RoomService.create_room(peer_id, username)
	print("Room created by peer %d (%s): %s" % [peer_id, username, str(room.get("id", ""))])
	_broadcast_game_state_update(_sync_game_state_for_room(room))
	_broadcast_room_list()

@rpc("any_peer", "call_remote", "reliable")
func join_room(room_id: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not SessionAuthService.is_peer_authenticated(peer_id):
		print("Rejected room join from unauthenticated peer %d" % peer_id)
		return

	var username := SessionAuthService.get_authenticated_username(peer_id)
	var normalized_room_id := room_id.strip_edges()
	var room := RoomService.get_room_by_id(normalized_room_id)
	if room.is_empty():
		print("Rejected room join for peer %d (%s): missing room %s" % [peer_id, username, normalized_room_id])
		return

	print("Peer %d (%s) requested join for room %s" % [peer_id, username, normalized_room_id])
	room = RoomService.add_member_to_room(normalized_room_id, username)
	print("Approved room join for peer %d (%s): %s" % [peer_id, username, normalized_room_id])
	_broadcast_game_state_update(_sync_game_state_for_room(room))
	_broadcast_room_list()

@rpc("any_peer", "call_remote", "reliable")
func leave_room(room_id: String) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not SessionAuthService.is_peer_authenticated(peer_id):
		print("Rejected room leave from unauthenticated peer %d" % peer_id)
		return

	var username := SessionAuthService.get_authenticated_username(peer_id)
	var normalized_room_id := room_id.strip_edges()
	if normalized_room_id.is_empty():
		print("Rejected room leave for peer %d (%s): empty room id" % [peer_id, username])
		return

	var room := RoomService.remove_member_from_room(normalized_room_id, username)
	if room.is_empty():
		print("Rejected room leave for peer %d (%s): missing room %s" % [peer_id, username, normalized_room_id])
		return

	print("Peer %d (%s) left room %s" % [peer_id, username, normalized_room_id])
	ClientRpc.rpc_id(peer_id, "game_state_updated", {})
	_broadcast_game_state_update(_sync_game_state_for_room(room))
	_broadcast_room_list()

@rpc("any_peer", "call_remote", "reliable")
func logout() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not SessionAuthService.is_peer_authenticated(peer_id):
		print("Rejected logout from unauthenticated peer %d" % peer_id)
		return

	var username := SessionAuthService.get_authenticated_username(peer_id)
	print("Peer %d (%s) requested logout" % [peer_id, username])
	await _disconnect_peer(peer_id)

func _reject_peer(peer_id: int, error: String) -> void:
	SessionAuthService.clear_peer_auth(peer_id)
	ClientRpc.rpc_id(peer_id, "auth_result", {
		"ok": false,
		"error": error,
	})
	print("Rejected peer %d: %s" % [peer_id, error])
	await _disconnect_peer(peer_id)

func _disconnect_peer(peer_id: int) -> void:
	await get_tree().process_frame
	var peer := multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer:
		(peer as ENetMultiplayerPeer).disconnect_peer(peer_id)

func _broadcast_room_list() -> void:
	var rooms := RoomService.get_rooms()
	var peer_ids := SessionAuthService.get_authenticated_peer_ids()
	print("Broadcasting room list to %d authenticated peers: %d rooms" % [peer_ids.size(), rooms.size()])
	for peer_id in peer_ids:
		ClientRpc.rpc_id(peer_id, "room_list", rooms)

func _broadcast_game_state_update(state: Dictionary) -> void:
	var room_id := str(state.get("room_id", "")).strip_edges()
	if room_id.is_empty():
		return

	var players: Array = state.get("players", [])
	var member_peer_ids: Array[int] = []
	for peer_id in SessionAuthService.get_authenticated_peer_ids():
		var username := SessionAuthService.get_authenticated_username(peer_id)
		for player_variant in players:
			var player := player_variant as Dictionary
			if str(player.get("username", "")).strip_edges() != username:
				continue
			member_peer_ids.append(peer_id)
			break

	print("Broadcasting game state for %s to %d peers" % [room_id, member_peer_ids.size()])
	for peer_id in member_peer_ids:
		ClientRpc.rpc_id(peer_id, "game_state_updated", state)

func _sync_game_state_for_room(room: Dictionary) -> Dictionary:
	var room_id := str(room.get("id", "")).strip_edges()
	if room_id.is_empty():
		return {}

	var current_state: Dictionary = _room_game_states.get(room_id, {})
	var next_state: Dictionary
	if current_state.is_empty():
		next_state = SharedGameState.create_from_room(room)
	else:
		next_state = SharedGameState.sync_from_room(current_state, room)
	_room_game_states[room_id] = next_state
	return next_state.duplicate(true)
