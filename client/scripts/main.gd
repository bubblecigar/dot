extends Node2D

const NetworkConfig := preload("res://shared/network_config.gd")
const INITIAL_SCENE := "res://client/scenes/StagePicker.tscn"

@onready var gameplay_root: Node2D = $GameplayRoot

func _ready() -> void:
	SceneManager.initialize(gameplay_root)
	SceneManager.change_scene(INITIAL_SCENE, false)

	_connect_to_server()

func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			get_tree().quit()
			return

		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
				SceneManager.change_scene(INITIAL_SCENE, false)
				get_viewport().set_input_as_handled()


func _connect_to_server() -> void:
	var host := _get_string_arg("--server-host", NetworkConfig.get_server_host())
	var port := _get_int_arg("--server-port", NetworkConfig.get_server_port())

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	if err != OK:
		push_warning("Failed to connect to ENet server %s:%d (error %d)." % [host, port, err])
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_connected_to_server() -> void:
	print("Connected to ENet server")

func _on_connection_failed() -> void:
	push_warning("Connection to ENet server failed")

func _on_server_disconnected() -> void:
	print("Disconnected from ENet server")

func _get_string_arg(flag: String, default_value: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(flag + "="):
			return arg.get_slice("=", 1)
	return default_value

func _get_int_arg(flag: String, default_value: int) -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(flag + "="):
			return int(arg.get_slice("=", 1))
	return default_value
