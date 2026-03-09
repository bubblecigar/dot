extends Node

const NetworkConfig := preload("res://shared/network_config.gd")

func _ready() -> void:
	var port := _get_int_arg("--port", NetworkConfig.get_server_port())
	var max_clients := _get_int_arg("--max-clients", NetworkConfig.get_max_clients())

	var server := preload("res://server/enet_server.gd").new()
	add_child(server)
	var err := server.start(port, max_clients)
	if err != OK:
		push_error("Failed to start ENet server (error %d)." % err)
		get_tree().quit(1)

func _get_int_arg(flag: String, default_value: int) -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(flag + "="):
			return int(arg.get_slice("=", 1))
	return default_value
