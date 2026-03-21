extends Node

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
	ClientRpc.rpc_id(peer_id, "room_joined", room)
	print("Sent room_joined to peer %d for %s" % [peer_id, str(room.get("id", ""))])
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
	ClientRpc.rpc_id(peer_id, "room_joined", room)
	print("Approved room join for peer %d (%s): %s" % [peer_id, username, normalized_room_id])

func _reject_peer(peer_id: int, error: String) -> void:
	SessionAuthService.clear_peer_auth(peer_id)
	ClientRpc.rpc_id(peer_id, "auth_result", {
		"ok": false,
		"error": error,
	})
	print("Rejected peer %d: %s" % [peer_id, error])
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
