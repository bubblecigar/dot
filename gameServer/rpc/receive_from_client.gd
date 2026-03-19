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
