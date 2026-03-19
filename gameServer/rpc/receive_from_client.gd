extends Node

const AuthApiClient := preload("res://../shared/auth_api_client.gd")

var _authenticated_peers: Dictionary = {}
var _pending_auth_peers: Dictionary = {}

@rpc("any_peer", "call_remote", "reliable")
func submit_button_states(states: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not is_peer_authenticated(peer_id):
		print("Rejected button states from unauthenticated peer %d" % peer_id)
		return
	print("Received button states from client:", states)

@rpc("any_peer", "call_remote", "reliable")
func authenticate(auth_data: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	print("Received auth data from peer %d: %s" % [peer_id, auth_data])
	if _pending_auth_peers.has(peer_id):
		return

	var token := str(auth_data.get("token", "")).strip_edges()
	if token.is_empty():
		await _reject_peer(peer_id, "missing_token")
		return

	_pending_auth_peers[peer_id] = true
	var validation_result := await AuthApiClient.validate_token(token)
	_pending_auth_peers.erase(peer_id)

	if not bool(validation_result.get("ok", false)):
		await _reject_peer(peer_id, str(validation_result.get("error", "invalid_token")))
		return

	var validated_username := str(validation_result.get("username", "")).strip_edges()
	if validated_username.is_empty():
		await _reject_peer(peer_id, "missing_username")
		return

	_authenticated_peers[peer_id] = validated_username
	ClientRpc.rpc_id(peer_id, "auth_result", {
		"ok": true,
		"username": validated_username,
	})
	print("Peer %d authenticated as %s" % [peer_id, validated_username])

@rpc("any_peer", "call_remote", "reliable")
func notify_circle_moved() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not is_peer_authenticated(peer_id):
		print("Rejected circle movement from unauthenticated peer %d" % peer_id)
		return
	print("hello")

func is_peer_authenticated(peer_id: int) -> bool:
	return _authenticated_peers.has(peer_id)

func clear_peer_auth(peer_id: int) -> void:
	_authenticated_peers.erase(peer_id)
	_pending_auth_peers.erase(peer_id)

func _reject_peer(peer_id: int, error: String) -> void:
	clear_peer_auth(peer_id)
	ClientRpc.rpc_id(peer_id, "auth_result", {
		"ok": false,
		"error": error,
	})
	print("Rejected peer %d: %s" % [peer_id, error])
	await get_tree().process_frame
	var peer := multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer:
		(peer as ENetMultiplayerPeer).disconnect_peer(peer_id)
