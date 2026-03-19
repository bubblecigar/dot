extends Node

const NetworkConfig := preload("res://../shared/network_config.gd")
const AUTH_CONNECT_TIMEOUT_MS := 3000
const AUTH_RESPONSE_TIMEOUT_MS := 3000

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
	var validation_result := await _validate_token_with_auth_server(token)
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

func _validate_token_with_auth_server(token: String) -> Dictionary:
	var host := _get_string_arg("--auth-host", NetworkConfig.get_server_host())
	var auth_port := _get_int_arg("--auth-port", NetworkConfig.get_auth_port())
	var auth_peer := StreamPeerTCP.new()
	var err := auth_peer.connect_to_host(host, auth_port)
	if err != OK:
		return {
			"ok": false,
			"error": "auth_connect_failed_%d" % err,
		}

	var connected := await _wait_for_tcp_status(
		auth_peer,
		StreamPeerTCP.STATUS_CONNECTED,
		AUTH_CONNECT_TIMEOUT_MS
	)
	if not connected:
		auth_peer.disconnect_from_host()
		return {
			"ok": false,
			"error": "auth_connect_timeout",
		}

	var response := await _send_auth_request(auth_peer, {
		"action": "validate",
		"token": token,
	})
	auth_peer.disconnect_from_host()
	return response

func _send_auth_request(auth_peer: StreamPeerTCP, payload: Dictionary) -> Dictionary:
	var packet := JSON.stringify(payload) + "\n"
	var err := auth_peer.put_data(packet.to_utf8_buffer())
	if err != OK:
		return {
			"ok": false,
			"error": "auth_send_failed_%d" % err,
		}

	return await _read_auth_response(auth_peer)

func _read_auth_response(auth_peer: StreamPeerTCP) -> Dictionary:
	var response_buffer := ""
	var deadline := Time.get_ticks_msec() + AUTH_RESPONSE_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		auth_peer.poll()
		if auth_peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			return {
				"ok": false,
				"error": "auth_disconnected",
			}

		var bytes_available := auth_peer.get_available_bytes()
		if bytes_available > 0:
			response_buffer += auth_peer.get_utf8_string(bytes_available)
			var newline_index := response_buffer.find("\n")
			if newline_index != -1:
				var line := response_buffer.substr(0, newline_index).strip_edges()
				var parsed = JSON.parse_string(line)
				if typeof(parsed) == TYPE_DICTIONARY:
					return parsed
				return {
					"ok": false,
					"error": "auth_invalid_response",
				}

		await get_tree().process_frame

	return {
		"ok": false,
		"error": "auth_response_timeout",
	}

func _wait_for_tcp_status(auth_peer: StreamPeerTCP, target_status: int, timeout_ms: int) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		auth_peer.poll()
		var status := auth_peer.get_status()
		if status == target_status:
			return true
		if status == StreamPeerTCP.STATUS_ERROR:
			return false
		await get_tree().process_frame
	return false

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

func _get_string_arg(flag: String, default_value: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(flag + "="):
			return arg.get_slice("=", 1)
	return default_value

func _get_int_arg(flag: String, default_value: int) -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(flag + "="):
			return int(arg.get_slice("=", 1))
	return default_value
