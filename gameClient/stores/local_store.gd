extends Node

const SAVE_PATH := "user://local_store.cfg"

var saved_login_email: String = ""
var saved_login_password: String = ""

func _ready() -> void:
	_load_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()

func set_saved_login_credentials(email: String, password: String) -> void:
	saved_login_email = email
	saved_login_password = password
	save_state()

func save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("login", "email", saved_login_email)
	config.set_value("login", "password", saved_login_password)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return

	saved_login_email = str(config.get_value("login", "email", ""))
	saved_login_password = str(config.get_value("login", "password", ""))
