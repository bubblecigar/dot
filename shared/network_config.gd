extends RefCounted

const CONFIG_PATH_CANDIDATES := [
	"res://shared/host.config",
	"res://../shared/host.config",
]
const DEFAULT_SERVER_HOST := "127.0.0.1"
const DEFAULT_SERVER_PORT := 7000
const DEFAULT_AUTH_PORT := 7001
const DEFAULT_MAX_CLIENTS := 32

static func _get_config_path() -> String:
	for path in CONFIG_PATH_CANDIDATES:
		if FileAccess.file_exists(path):
			return path
	return ""

static func _load_config() -> ConfigFile:
	var config := ConfigFile.new()
	var config_path := _get_config_path()
	if config_path.is_empty():
		return ConfigFile.new()
	var err := config.load(config_path)
	if err != OK:
		return ConfigFile.new()
	return config

static func get_server_host() -> String:
	var config := _load_config()
	return str(config.get_value("server", "host", DEFAULT_SERVER_HOST))

static func get_server_port() -> int:
	var config := _load_config()
	return int(config.get_value("server", "port", DEFAULT_SERVER_PORT))

static func get_auth_port() -> int:
	var config := _load_config()
	return int(config.get_value("server", "auth_port", DEFAULT_AUTH_PORT))

static func get_max_clients() -> int:
	var config := _load_config()
	return int(config.get_value("server", "max_clients", DEFAULT_MAX_CLIENTS))
