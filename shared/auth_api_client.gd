extends RefCounted

class_name AuthApiClient

const NETWORK_CONFIG_PATH_CANDIDATES := [
	"res://shared/network_config.gd",
	"res://../shared/network_config.gd",
]
const AUTH_CONNECT_TIMEOUT_MS := 3000
const AUTH_RESPONSE_TIMEOUT_MS := 3000

static func _get_network_config():
	for path in NETWORK_CONFIG_PATH_CANDIDATES:
		if ResourceLoader.exists(path):
			return load(path)
	push_error("Unable to locate network_config.gd")
	return null

static func login(email: String, password: String) -> Dictionary:
	return await send_request({
		"action": "login",
		"email": email,
		"password": password,
	})

static func register(email: String, password: String) -> Dictionary:
	return await send_request({
		"action": "register",
		"email": email,
		"password": password,
	})

static func validate_token(token: String) -> Dictionary:
	return await send_request({
		"action": "validate",
		"token": token,
	})

static func send_request(payload: Dictionary) -> Dictionary:
	var network_config = _get_network_config()
	if network_config == null:
		return {
			"ok": false,
			"error": "missing_network_config",
		}

	var host := _get_string_arg("--auth-host", network_config.get_server_host())
	var auth_port := _get_int_arg("--auth-port", network_config.get_auth_port())
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

	var response := await _send_request(auth_peer, payload)
	auth_peer.disconnect_from_host()
	return response

static func _send_request(auth_peer: StreamPeerTCP, payload: Dictionary) -> Dictionary:
	var packet := JSON.stringify(payload) + "\n"
	var err := auth_peer.put_data(packet.to_utf8_buffer())
	if err != OK:
		return {
			"ok": false,
			"error": "auth_send_failed_%d" % err,
		}

	return await _read_response(auth_peer)

static func _read_response(auth_peer: StreamPeerTCP) -> Dictionary:
	var response_buffer := ""
	var deadline := Time.get_ticks_msec() + AUTH_RESPONSE_TIMEOUT_MS
	var tree := Engine.get_main_loop() as SceneTree
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

		await tree.process_frame

	return {
		"ok": false,
		"error": "auth_response_timeout",
	}

static func _wait_for_tcp_status(auth_peer: StreamPeerTCP, target_status: int, timeout_ms: int) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	var tree := Engine.get_main_loop() as SceneTree
	while Time.get_ticks_msec() < deadline:
		auth_peer.poll()
		var status := auth_peer.get_status()
		if status == target_status:
			return true
		if status == StreamPeerTCP.STATUS_ERROR:
			return false
		await tree.process_frame
	return false

static func _get_string_arg(flag: String, default_value: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(flag + "="):
			return arg.get_slice("=", 1)
	return default_value

static func _get_int_arg(flag: String, default_value: int) -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(flag + "="):
			return int(arg.get_slice("=", 1))
	return default_value
