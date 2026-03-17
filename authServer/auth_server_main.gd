extends Node

const NetworkConfig := preload("res://../shared/network_config.gd")

func _ready() -> void:
	var auth_port := _get_int_arg("--auth-port", NetworkConfig.get_auth_port())

	var auth_server := preload("res://auth_server.gd").new()
	add_child(auth_server)
	var err := auth_server.start(auth_port)
	if err != OK:
		push_error("Failed to start auth server (error %d)." % err)
		get_tree().quit(1)

func _get_int_arg(flag: String, default_value: int) -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(flag + "="):
			return int(arg.get_slice("=", 1))
	return default_value
