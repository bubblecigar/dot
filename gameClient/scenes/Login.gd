extends Control

const NEXT_SCENE_PATH := "res://scenes/RoomList.tscn"
static var _init_login_consumed: bool = false

@onready var email_input: LineEdit = $MarginContainer/Grid/EmailCard/MarginContainer/Layout/EmailInput
@onready var password_input: LineEdit = $MarginContainer/Grid/PasswordCard/MarginContainer/Layout/PasswordInput
@onready var login_button: Button = $MarginContainer/Grid/LoginCard/MarginContainer/LoginButton
@onready var register_button: Button = $MarginContainer/Grid/RegisterCard/MarginContainer/RegisterButton
@onready var status_label: Label = $MarginContainer/Grid/StatusCard/MarginContainer/StatusLabel

func _ready() -> void:
	if AuthManager.auth_status == "authenticated":
		SceneManager.change_scene(NEXT_SCENE_PATH, false)
		return

	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	email_input.text_submitted.connect(_on_email_submitted)
	password_input.text_submitted.connect(_on_password_submitted)
	email_input.text_changed.connect(_on_credentials_changed)
	password_input.text_changed.connect(_on_credentials_changed)
	status_label.text = "Enter your email and password."

	if _has_init_credentials() and not _init_login_consumed:
		_init_login_consumed = true
		email_input.text = _get_init_email()
		password_input.text = _get_init_password()
		status_label.text = "Auto logging in..."
		call_deferred("_submit_login", false)
		return

	email_input.text = LocalStore.saved_login_email
	password_input.text = LocalStore.saved_login_password

func _on_email_submitted(_text: String) -> void:
	password_input.grab_focus()

func _on_password_submitted(_text: String) -> void:
	_submit_login(false)

func _on_login_pressed() -> void:
	_submit_login(false)

func _on_register_pressed() -> void:
	_submit_login(true)

func _submit_login(should_register: bool) -> void:
	var email := email_input.text.strip_edges()
	var password := password_input.text
	if email.is_empty():
		status_label.text = "Email is required."
		email_input.grab_focus()
		return
	if password.is_empty():
		status_label.text = "Password is required."
		password_input.grab_focus()
		return

	if not _has_init_credentials():
		LocalStore.set_saved_login_credentials(email, password)
	_set_inputs_disabled(true)
	status_label.text = "Registering..." if should_register else "Logging in..."

	var result: Dictionary
	if should_register:
		result = await AuthManager.register(email, password)
	else:
		result = await AuthManager.login(email, password)

	_set_inputs_disabled(false)
	if bool(result.get("ok", false)):
		status_label.text = "Connected as %s" % str(result.get("username", email))
		SceneManager.change_scene(NEXT_SCENE_PATH, true)
		return

	status_label.text = "Auth failed: %s" % str(result.get("error", "unknown_error"))

func _set_inputs_disabled(disabled: bool) -> void:
	email_input.editable = not disabled
	password_input.editable = not disabled
	login_button.disabled = disabled
	register_button.disabled = disabled

func _on_credentials_changed(_value: String) -> void:
	if _has_init_credentials():
		return
	LocalStore.set_saved_login_credentials(email_input.text.strip_edges(), password_input.text)

func _has_init_credentials() -> bool:
	return not _get_init_email().is_empty() and not _get_init_password().is_empty()

func _get_init_email() -> String:
	var username := _get_cmdline_arg("--init-username")
	if not username.is_empty():
		return username
	return _get_cmdline_arg("--init-email")

func _get_init_password() -> String:
	return _get_cmdline_arg("--init-password")

func _get_cmdline_arg(flag: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(flag + "="):
			return arg.get_slice("=", 1).strip_edges()
	return ""
