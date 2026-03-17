extends Node2D

const NetworkConfig := preload("res://../shared/network_config.gd")
const INITIAL_SCENE := "res://scenes/StagePicker.tscn"
const MOCK_AUTH_USERNAME := "mock_user"
const MOCK_AUTH_PASSWORD := "mock_password"
const AUTH_CONNECT_TIMEOUT_MS := 3000
const AUTH_RESPONSE_TIMEOUT_MS := 3000

@onready var gameplay_root: Node2D = $GameplayRoot

func _ready() -> void:
	SceneManager.initialize(gameplay_root)
	SceneManager.change_scene(INITIAL_SCENE, false)

	var auth_result := await _authenticate_with_auth_server()
	if not bool(auth_result.get("ok", false)):
		var error_message := str(auth_result.get("error", "auth_failed"))
		StateStore.set_auth_data("failed", "", "")
		push_warning("Authentication failed: %s" % error_message)
		return

	StateStore.set_auth_data(
		"authenticated",
		str(auth_result.get("username", "")),
		str(auth_result.get("token", "")),
	)
	_connect_to_server()

func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			get_tree().quit()
			return

		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
				SceneManager.change_scene(INITIAL_SCENE, false)
				get_viewport().set_input_as_handled()


func _connect_to_server() -> void:
	var host := _get_string_arg("--server-host", NetworkConfig.get_server_host())
	var port := _get_int_arg("--server-port", NetworkConfig.get_server_port())

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	if err != OK:
		push_warning("Failed to connect to ENet server %s:%d (error %d)." % [host, port, err])
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_connected_to_server() -> void:
	print("Connected to ENet server")

func _on_connection_failed() -> void:
	push_warning("Connection to ENet server failed")

func _on_server_disconnected() -> void:
	print("Disconnected from ENet server")

func _authenticate_with_auth_server() -> Dictionary:
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
		return {
			"ok": false,
			"error": "auth_connect_timeout",
		}

	var login_response := await _send_auth_request(auth_peer, {
		"action": "login",
		"username": MOCK_AUTH_USERNAME,
		"password": MOCK_AUTH_PASSWORD,
	})
	if bool(login_response.get("ok", false)):
		auth_peer.disconnect_from_host()
		return login_response

	if str(login_response.get("error", "")) != "invalid_credentials":
		auth_peer.disconnect_from_host()
		return login_response

	var register_response := await _send_auth_request(auth_peer, {
		"action": "register",
		"username": MOCK_AUTH_USERNAME,
		"password": MOCK_AUTH_PASSWORD,
	})
	if not bool(register_response.get("ok", false)):
		auth_peer.disconnect_from_host()
		return register_response

	var retry_login_response := await _send_auth_request(auth_peer, {
		"action": "login",
		"username": MOCK_AUTH_USERNAME,
		"password": MOCK_AUTH_PASSWORD,
	})
	auth_peer.disconnect_from_host()
	return retry_login_response

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
