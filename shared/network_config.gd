extends RefCounted

const DEFAULT_CONFIG_ENV := "local"
const DEFAULT_EXPORTED_CONFIG_ENV := "prod"
const DEFAULT_BIND_HOST := "0.0.0.0"
const DEFAULT_PUBLIC_GAME_HOST := "127.0.0.1"
const DEFAULT_PUBLIC_AUTH_HOST := "127.0.0.1"
const DEFAULT_AUTH_UPSTREAM_HOST := "127.0.0.1"
const DEFAULT_GAME_PORT := 7000
const DEFAULT_AUTH_PORT := 7001
const DEFAULT_MAX_CLIENTS := 32

static func _get_config_env() -> String:
	var config_env := _get_env_string("CONFIG_ENV").to_lower()
	if config_env.is_empty():
		return _get_default_config_env()
	return config_env

static func _get_default_config_env() -> String:
	if OS.has_feature(DEFAULT_EXPORTED_CONFIG_ENV):
		return DEFAULT_EXPORTED_CONFIG_ENV
	return DEFAULT_CONFIG_ENV

static func _get_config_path_candidates() -> Array[String]:
	var config_env := _get_config_env()
	return [
		"res://shared/%s.config" % config_env,
		"res://../shared/%s.config" % config_env,
	]

static func _get_config_path() -> String:
	for path in _get_config_path_candidates():
		if FileAccess.file_exists(path):
			return path
	return ""

static func get_config_env_name() -> String:
	return _get_config_env()

static func get_active_config_path() -> String:
	return _get_config_path()

static func _load_config() -> ConfigFile:
	var config := ConfigFile.new()
	var config_path := _get_config_path()
	if config_path.is_empty():
		return ConfigFile.new()
	var err := config.load(config_path)
	if err != OK:
		return ConfigFile.new()
	return config

static func _get_env_string(name: String) -> String:
	var value := OS.get_environment(name).strip_edges()
	if value.is_empty():
		return ""
	return value

static func _get_string(section: String, key: String, env_name: String, default_value: String) -> String:
	var env_value := _get_env_string(env_name)
	if not env_value.is_empty():
		return env_value
	var config := _load_config()
	return str(config.get_value(section, key, default_value))

static func _get_int(section: String, key: String, env_name: String, default_value: int) -> int:
	var env_value := _get_env_string(env_name)
	if not env_value.is_empty():
		return int(env_value)
	var config := _load_config()
	return int(config.get_value(section, key, default_value))

static func get_bind_host() -> String:
	return _get_string("server", "bind_host", "BIND_HOST", DEFAULT_BIND_HOST)

static func get_public_game_host() -> String:
	return _get_string("server", "public_game_host", "PUBLIC_GAME_HOST", DEFAULT_PUBLIC_GAME_HOST)

static func get_public_auth_host() -> String:
	return _get_string("server", "public_auth_host", "PUBLIC_AUTH_HOST", DEFAULT_PUBLIC_AUTH_HOST)

static func get_auth_upstream_host() -> String:
	return _get_string("server", "auth_upstream_host", "AUTH_UPSTREAM_HOST", get_public_auth_host())

static func get_server_host() -> String:
	return get_public_game_host()

static func get_server_port() -> int:
	return _get_int("server", "game_port", "GAME_PORT", DEFAULT_GAME_PORT)

static func get_auth_port() -> int:
	return _get_int("server", "auth_port", "AUTH_PORT", DEFAULT_AUTH_PORT)

static func get_max_clients() -> int:
	return _get_int("server", "max_clients", "MAX_CLIENTS", DEFAULT_MAX_CLIENTS)
