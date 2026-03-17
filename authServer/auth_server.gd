extends Node

const USER_DB_PATH := "user://auth_users.cfg"

var _server := TCPServer.new()
var _clients: Array[Dictionary] = []
var _sessions: Dictionary = {}

func start(port: int) -> int:
	randomize()
	var err := _server.listen(port)
	if err != OK:
		return err

	print("Auth server started on port %d" % port)
	return OK

func _process(_delta: float) -> void:
	_accept_pending_clients()
	_poll_clients()

func _accept_pending_clients() -> void:
	while _server.is_connection_available():
		var peer := _server.take_connection()
		print("Auth client connected")
		_clients.append({
			"peer": peer,
			"buffer": "",
		})

func _poll_clients() -> void:
	for i in range(_clients.size() - 1, -1, -1):
		var client: Dictionary = _clients[i]
		var peer: StreamPeerTCP = client["peer"]
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("Auth client disconnected")
			_clients.remove_at(i)
			continue

		var bytes_available := peer.get_available_bytes()
		if bytes_available <= 0:
			continue

		client["buffer"] += peer.get_utf8_string(bytes_available)
		_clients[i] = client
		_process_client_buffer(i)

func _process_client_buffer(client_index: int) -> void:
	var client: Dictionary = _clients[client_index]
	var buffer: String = client["buffer"]
	var peer: StreamPeerTCP = client["peer"]

	while true:
		var newline_index := buffer.find("\n")
		if newline_index == -1:
			break

		var raw_line := buffer.substr(0, newline_index).strip_edges()
		buffer = buffer.substr(newline_index + 1)
		if raw_line.is_empty():
			continue

		var response := _handle_request(raw_line)
		_send_response(peer, response)

	client["buffer"] = buffer
	_clients[client_index] = client

func _handle_request(raw_line: String) -> Dictionary:
	var parsed = JSON.parse_string(raw_line)
	if typeof(parsed) != TYPE_DICTIONARY:
		print("Auth request rejected: invalid_json")
		return {
			"ok": false,
			"error": "invalid_json",
		}

	var payload: Dictionary = parsed
	var action := str(payload.get("action", ""))
	var username := str(payload.get("username", "")).strip_edges()
	var password := str(payload.get("password", ""))
	print("Auth request: action=%s username=%s" % [action, username])

	match action:
		"register":
			return _register_user(username, password)
		"login":
			return _login_user(username, password)
		"validate":
			return _validate_token(str(payload.get("token", "")))
		_:
			print("Auth request rejected: unsupported_action action=%s username=%s" % [action, username])
			return {
				"ok": false,
				"error": "unsupported_action",
			}

func _register_user(username: String, password: String) -> Dictionary:
	var validation_error := _validate_credentials(username, password)
	if not validation_error.is_empty():
		print("Auth register failed: username=%s error=%s" % [username, validation_error])
		return {
			"ok": false,
			"error": validation_error,
		}

	var db := _load_user_db()
	if db.has_section_key("users", username):
		print("Auth register failed: username=%s error=user_exists" % username)
		return {
			"ok": false,
			"error": "user_exists",
		}

	db.set_value("users", username, password.sha256_text())
	var err := db.save(USER_DB_PATH)
	if err != OK:
		print("Auth register failed: username=%s error=save_failed" % username)
		return {
			"ok": false,
			"error": "save_failed",
		}

	print("Auth register success: username=%s" % username)
	return {
		"ok": true,
		"message": "registered",
	}

func _login_user(username: String, password: String) -> Dictionary:
	var validation_error := _validate_credentials(username, password)
	if not validation_error.is_empty():
		print("Auth login failed: username=%s error=%s" % [username, validation_error])
		return {
			"ok": false,
			"error": validation_error,
		}

	var db := _load_user_db()
	if not db.has_section_key("users", username):
		print("Auth login failed: username=%s error=invalid_credentials" % username)
		return {
			"ok": false,
			"error": "invalid_credentials",
		}

	var password_hash := str(db.get_value("users", username, ""))
	if password_hash != password.sha256_text():
		print("Auth login failed: username=%s error=invalid_credentials" % username)
		return {
			"ok": false,
			"error": "invalid_credentials",
		}

	var token := _create_token(username)
	_sessions[token] = username
	print("Auth login success: username=%s" % username)
	return {
		"ok": true,
		"message": "logged_in",
		"token": token,
		"username": username,
	}

func _validate_token(token: String) -> Dictionary:
	if token.is_empty() or not _sessions.has(token):
		print("Auth validate failed: invalid_token")
		return {
			"ok": false,
			"error": "invalid_token",
		}

	print("Auth validate success: username=%s" % str(_sessions[token]))
	return {
		"ok": true,
		"username": str(_sessions[token]),
	}

func _validate_credentials(username: String, password: String) -> String:
	if username.is_empty():
		return "missing_username"
	if password.is_empty():
		return "missing_password"
	if username.length() < 3:
		return "username_too_short"
	if password.length() < 6:
		return "password_too_short"
	return ""

func _load_user_db() -> ConfigFile:
	var db := ConfigFile.new()
	db.load(USER_DB_PATH)
	return db

func _create_token(username: String) -> String:
	var entropy := "%s:%s:%s" % [
		username,
		Time.get_unix_time_from_system(),
		randi(),
	]
	return entropy.sha256_text()

func _send_response(peer: StreamPeerTCP, payload: Dictionary) -> void:
	var packet := JSON.stringify(payload) + "\n"
	peer.put_data(packet.to_utf8_buffer())
