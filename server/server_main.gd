extends Node

const DEFAULT_SERVER_PORT := 7000
const DEFAULT_MAX_CLIENTS := 32

func _ready() -> void:
	var port := _get_int_arg("--port", DEFAULT_SERVER_PORT)
	var max_clients := _get_int_arg("--max-clients", DEFAULT_MAX_CLIENTS)

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
