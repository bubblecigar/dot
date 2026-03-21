extends Node

const NetworkConfig := preload("res://shared/network_config.gd")
const AuthApiClient := preload("res://shared/auth_api_client.gd")
const GAME_CONNECT_TIMEOUT_MS := 3000
const GAME_AUTH_TIMEOUT_MS := 3000

signal authenticated(username: String)
signal authentication_failed(message: String)
signal game_server_disconnected()
signal game_server_reconnect_started()
signal game_server_reconnected()
signal session_invalidated(message: String)

var auth_status: String = "unauthenticated"
var auth_username: String = ""
var auth_token: String = ""
var _is_busy: bool = false
var _pending_game_auth_result: Dictionary = {}
var _logout_disconnect_expected: bool = false
var _reconnect_in_progress: bool = false

const RECONNECT_RETRY_DELAY_SEC := 2.0

func _ready() -> void:
	if not ClientRpc.auth_result_received.is_connected(_on_game_server_auth_result):
		ClientRpc.auth_result_received.connect(_on_game_server_auth_result)
	_log_client_network_config()
	call_deferred("_restore_saved_session")

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
	_set_auth_data("authenticating", "", "")

	var auth_result := await _authenticate_with_auth_server(action, email, password)
	if not bool(auth_result.get("ok", false)):
		var auth_error := str(auth_result.get("error", "auth_failed"))
		_set_auth_data("failed", "", "")
		authentication_failed.emit(auth_error)
		_is_busy = false
		return auth_result

	_set_auth_data(
		"authenticating",
		str(auth_result.get("username", "")),
		str(auth_result.get("token", "")),
	)

	var connect_result := await _connect_to_game_server()
	if not bool(connect_result.get("ok", false)):
		var connect_error := str(connect_result.get("error", "game_connect_failed"))
		_set_auth_data("failed", auth_username, auth_token)
		authentication_failed.emit(connect_error)
		_is_busy = false
		return connect_result

	_set_auth_data(
		"authenticated",
		str(connect_result.get("username", auth_username)),
		auth_token,
	)
	LocalStore.set_saved_auth_session(auth_username, auth_token)
	_logout_disconnect_expected = false
	authenticated.emit(auth_username)
	_is_busy = false
	return {
		"ok": true,
		"username": auth_username,
		"token": auth_token,
	}

func _authenticate_with_auth_server(action: String, email: String, password: String) -> Dictionary:
	if action == "register":
		return await AuthApiClient.register(email, password)
	return await AuthApiClient.login(email, password)

func _connect_to_game_server() -> Dictionary:
	var host := _get_string_arg("--server-host", NetworkConfig.get_public_game_host())
	var port := _get_int_arg("--server-port", NetworkConfig.get_server_port())
	print(
		"Game client connecting to game server env=%s config=%s host=%s port=%d"
		% [
			NetworkConfig.get_config_env_name(),
			NetworkConfig.get_active_config_path(),
			host,
			port,
		]
	)

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
			_pending_game_auth_result = {}
			ServerRpc.authenticate({
				"token": auth_token,
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
	multiplayer.multiplayer_peer = null
	game_server_disconnected.emit()
	if _should_auto_reconnect():
		call_deferred("_run_reconnect_loop")

func _wait_for_game_server_auth_result() -> Dictionary:
	var deadline := Time.get_ticks_msec() + GAME_AUTH_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		var result := _pending_game_auth_result
		if not result.is_empty():
			_pending_game_auth_result = {}
			if not bool(result.get("ok", false)):
				multiplayer.multiplayer_peer = null
			return result
		await get_tree().process_frame

	multiplayer.multiplayer_peer = null
	return {
		"ok": false,
		"error": "game_auth_timeout",
	}

func _on_game_server_auth_result(result: Dictionary) -> void:
	_pending_game_auth_result = result

func prepare_for_logout_disconnect() -> void:
	_logout_disconnect_expected = true

func clear_auth_data() -> void:
	_logout_disconnect_expected = false
	_reconnect_in_progress = false
	LocalStore.clear_saved_auth_session()
	_set_auth_data("unauthenticated", "", "")

func _set_auth_data(status: String, username: String, token: String) -> void:
	auth_status = status
	auth_username = username
	auth_token = token

func _restore_saved_session() -> void:
	if _is_busy:
		return
	if not auth_token.is_empty():
		return

	var saved_token := LocalStore.saved_auth_token.strip_edges()
	if saved_token.is_empty():
		return

	_is_busy = true
	_set_auth_data(
		"authenticating",
		LocalStore.saved_auth_username.strip_edges(),
		saved_token,
	)

	var connect_result := await _connect_to_game_server()
	if not bool(connect_result.get("ok", false)):
		_is_busy = false
		if _is_fatal_reconnect_error(str(connect_result.get("error", ""))):
			clear_auth_data()
		else:
			_set_auth_data("unauthenticated", "", "")
		return

	_set_auth_data(
		"authenticated",
		str(connect_result.get("username", auth_username)),
		auth_token,
	)
	LocalStore.set_saved_auth_session(auth_username, auth_token)
	_logout_disconnect_expected = false
	_is_busy = false
	authenticated.emit(auth_username)

func _run_reconnect_loop() -> void:
	if _reconnect_in_progress:
		return
	if not _should_auto_reconnect():
		return

	_reconnect_in_progress = true
	game_server_reconnect_started.emit()

	while _should_auto_reconnect():
		var reconnect_result := await _connect_to_game_server()
		if bool(reconnect_result.get("ok", false)):
			_set_auth_data(
				"authenticated",
				str(reconnect_result.get("username", auth_username)),
				auth_token,
			)
			_logout_disconnect_expected = false
			_reconnect_in_progress = false
			game_server_reconnected.emit()
			return

		var error := str(reconnect_result.get("error", "game_reconnect_failed"))
		if _is_fatal_reconnect_error(error):
			_reconnect_in_progress = false
			clear_auth_data()
			session_invalidated.emit(error)
			return

		await get_tree().create_timer(RECONNECT_RETRY_DELAY_SEC).timeout

	_reconnect_in_progress = false

func _should_auto_reconnect() -> bool:
	return (
		not _logout_disconnect_expected
		and auth_status == "authenticated"
		and not auth_token.is_empty()
	)

func _is_fatal_reconnect_error(error: String) -> bool:
	return (
		error == "missing_token"
		or error == "invalid_token"
		or error == "missing_username"
	)

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

func _log_client_network_config() -> void:
	print(
		"Game client config env=%s config=%s auth_host=%s auth_port=%d game_host=%s game_port=%d"
		% [
			NetworkConfig.get_config_env_name(),
			NetworkConfig.get_active_config_path(),
			_get_string_arg("--auth-host", NetworkConfig.get_public_auth_host()),
			_get_int_arg("--auth-port", NetworkConfig.get_auth_port()),
			_get_string_arg("--server-host", NetworkConfig.get_public_game_host()),
			_get_int_arg("--server-port", NetworkConfig.get_server_port()),
		]
	)
