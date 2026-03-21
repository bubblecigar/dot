extends Node

const SAVE_PATH := "user://local_store.cfg"

var saved_login_email: String = ""
var saved_login_password: String = ""
var saved_auth_username: String = ""
var saved_auth_token: String = ""

func _ready() -> void:
	_load_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()

func set_saved_login_credentials(email: String, password: String) -> void:
	saved_login_email = email
	saved_login_password = password
	save_state()

func set_saved_auth_session(username: String, token: String) -> void:
	saved_auth_username = username
	saved_auth_token = token
	save_state()

func clear_saved_auth_session() -> void:
	saved_auth_username = ""
	saved_auth_token = ""
	save_state()

func save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("login", "email", saved_login_email)
	config.set_value("login", "password", saved_login_password)
	config.set_value("auth", "username", saved_auth_username)
	config.set_value("auth", "token", saved_auth_token)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return

	saved_login_email = str(config.get_value("login", "email", ""))
	saved_login_password = str(config.get_value("login", "password", ""))
	saved_auth_username = str(config.get_value("auth", "username", ""))
	saved_auth_token = str(config.get_value("auth", "token", ""))
