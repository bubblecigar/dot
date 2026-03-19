extends Node

const SAVE_PATH := "user://local_store.cfg"

var circle_position: Vector2 = Vector2.ZERO
var saved_login_email: String = ""
var saved_login_password: String = ""

func _ready() -> void:
	_load_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()

func set_circle_position(pos: Vector2) -> void:
	circle_position = pos
	save_state()

func get_circle_position(default_position: Vector2) -> Vector2:
	if circle_position == Vector2.ZERO:
		return default_position
	return circle_position

func set_saved_login_credentials(email: String, password: String) -> void:
	saved_login_email = email
	saved_login_password = password
	save_state()

func save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("circle", "x", circle_position.x)
	config.set_value("circle", "y", circle_position.y)
	config.set_value("login", "email", saved_login_email)
	config.set_value("login", "password", saved_login_password)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return

	var x := float(config.get_value("circle", "x", 0.0))
	var y := float(config.get_value("circle", "y", 0.0))
	circle_position = Vector2(x, y)
	saved_login_email = str(config.get_value("login", "email", ""))
	saved_login_password = str(config.get_value("login", "password", ""))
