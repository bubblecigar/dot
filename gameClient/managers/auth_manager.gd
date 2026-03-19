extends Node

const NetworkConfig := preload("res://../shared/network_config.gd")
const AuthApiClient := preload("res://../shared/auth_api_client.gd")
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
	if action == "register":
		return await AuthApiClient.register(email, password)
	return await AuthApiClient.login(email, password)

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
