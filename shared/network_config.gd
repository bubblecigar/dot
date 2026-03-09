extends RefCounted

const CONFIG_PATH := "res://shared/host.config"
const DEFAULT_SERVER_HOST := "127.0.0.1"
const DEFAULT_SERVER_PORT := 7000
const DEFAULT_MAX_CLIENTS := 32

static func _load_config() -> ConfigFile:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err != OK:
		return ConfigFile.new()
	return config

static func get_server_host() -> String:
	var config := _load_config()
	return str(config.get_value("server", "host", DEFAULT_SERVER_HOST))

static func get_server_port() -> int:
	var config := _load_config()
	return int(config.get_value("server", "port", DEFAULT_SERVER_PORT))

static func get_max_clients() -> int:
	var config := _load_config()
	return int(config.get_value("server", "max_clients", DEFAULT_MAX_CLIENTS))
