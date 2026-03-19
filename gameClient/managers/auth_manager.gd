extends Node

const NetworkConfig := preload("res://../shared/network_config.gd")
const AUTH_CONNECT_TIMEOUT_MS := 3000
const AUTH_RESPONSE_TIMEOUT_MS := 3000
const GAME_CONNECT_TIMEOUT_MS := 3000
const GAME_AUTH_TIMEOUT_MS := 3000

signal authenticated(username: String)
signal authentication_failed(message: String)
signal game_server_disconnected()

var _is_busy: bool = false

func login(email: String, password: String) -> Dictionary:
	return await _authenticate_and_connect("login", email, password)

func register(email: String, password: String) -> Dictionary:
	return await _authenticate_and_connect("register", email, password)

func _authenticate_and_connect(action: String, email: String, password: String) -> Dictionary:
	if _is_busy:
		return {
			"ok": false,
			"error": "auth_busy",
		}

	_is_busy = true
	StateStore.set_auth_data("authenticating", "", "")

	var auth_result := await _authenticate_with_auth_server(action, email, password)
	if not bool(auth_result.get("ok", false)):
		var auth_error := str(auth_result.get("error", "auth_failed"))
		StateStore.set_auth_data("failed", "", "")
		authentication_failed.emit(auth_error)
		_is_busy = false
		return auth_result

	StateStore.set_auth_data(
		"authenticating",
		str(auth_result.get("username", "")),
		str(auth_result.get("token", "")),
	)

	var connect_result := await _connect_to_game_server()
	if not bool(connect_result.get("ok", false)):
		var connect_error := str(connect_result.get("error", "game_connect_failed"))
		StateStore.set_auth_data("failed", StateStore.auth_username, StateStore.auth_token)
		authentication_failed.emit(connect_error)
		_is_busy = false
		return connect_result

	StateStore.set_auth_data(
		"authenticated",
		str(connect_result.get("username", StateStore.auth_username)),
		StateStore.auth_token,
	)
	authenticated.emit(StateStore.auth_username)
	_is_busy = false
	return {
		"ok": true,
		"username": StateStore.auth_username,
		"token": StateStore.auth_token,
	}

func _authenticate_with_auth_server(action: String, email: String, password: String) -> Dictionary:
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
		"action": action,
		"email": email,
		"password": password,
	})
	auth_peer.disconnect_from_host()
	return response

func _connect_to_game_server() -> Dictionary:
	var host := _get_string_arg("--server-host", NetworkConfig.get_server_host())
	var port := _get_int_arg("--server-port", NetworkConfig.get_server_port())

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	if err != OK:
		return {
			"ok": false,
			"error": "game_connect_failed_%d" % err,
		}

	multiplayer.multiplayer_peer = peer
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	var deadline := Time.get_ticks_msec() + GAME_CONNECT_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		var status := peer.get_connection_status()
		if status == MultiplayerPeer.CONNECTION_CONNECTED:
			print("Connected to ENet server")
			ClientRpc.consume_auth_result()
			ServerRpc.authenticate({
				"token": StateStore.auth_token,
			})
			return await _wait_for_game_server_auth_result()
		if status == MultiplayerPeer.CONNECTION_DISCONNECTED:
			break
		await get_tree().process_frame

	multiplayer.multiplayer_peer = null
	return {
		"ok": false,
		"error": "game_connect_timeout",
	}

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

func _on_server_disconnected() -> void:
	print("Disconnected from ENet server")
	game_server_disconnected.emit()

func _wait_for_game_server_auth_result() -> Dictionary:
	var deadline := Time.get_ticks_msec() + GAME_AUTH_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		var result := ClientRpc.consume_auth_result()
		if not result.is_empty():
			if not bool(result.get("ok", false)):
				multiplayer.multiplayer_peer = null
			return result
		await get_tree().process_frame

	multiplayer.multiplayer_peer = null
	return {
		"ok": false,
		"error": "game_auth_timeout",
	}

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
