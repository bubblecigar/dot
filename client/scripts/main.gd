extends Node2D

const NetworkConfig := preload("res://shared/network_config.gd")

@onready var menu_layer: CanvasLayer = $MenuLayer
@onready var menu_content: VBoxContainer = $MenuLayer/MenuPanel/MenuMargin/MenuContent

func _ready() -> void:
	AbilityStore.ability_tree_changed.connect(_refresh_ability_tree_menu)
	_refresh_ability_tree_menu()
	if OS.is_debug_build():
		menu_layer.visible = true

	_connect_to_server()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_TAB:
			menu_layer.visible = not menu_layer.visible
			get_viewport().set_input_as_handled()

func _refresh_ability_tree_menu() -> void:
	for child in menu_content.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "Ability Tree"
	menu_content.add_child(title)

	var tree: Dictionary = AbilityStore.get_ability_tree()
	if tree.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(empty)"
		menu_content.add_child(empty_label)
		return

	var root_ids := _get_root_ids(tree)
	if root_ids.is_empty():
		var invalid_label := Label.new()
		invalid_label.text = "(no root nodes)"
		menu_content.add_child(invalid_label)
		return

	for root_id in root_ids:
		_add_ability_rows(tree, root_id, 0, {})

func _get_root_ids(tree: Dictionary) -> Array[String]:
	var roots: Array[String] = []
	for ability_id_variant in tree.keys():
		var ability_id := String(ability_id_variant)
		var node_data: Dictionary = tree[ability_id]
		var requires: PackedStringArray = node_data.get("requires", PackedStringArray())
		if requires.is_empty():
			roots.append(ability_id)
	roots.sort()
	return roots

func _add_ability_rows(tree: Dictionary, ability_id: String, depth: int, visited: Dictionary) -> void:
	if visited.has(ability_id):
		return
	visited[ability_id] = true

	if not tree.has(ability_id):
		return

	var node_data: Dictionary = tree[ability_id]
	var ability_name := String(node_data.get("name", ability_id))
	var unlocked_prefix := "[x]" if AbilityStore.is_unlocked(ability_id) else "[ ]"

	var line := Button.new()
	line.text = "%s%s %s" % ["  ".repeat(depth), unlocked_prefix, ability_name]
	line.alignment = HORIZONTAL_ALIGNMENT_LEFT
	line.disabled = AbilityStore.has_expanded(ability_id)
	if not line.disabled:
		line.pressed.connect(_on_ability_node_pressed.bind(ability_id))
	menu_content.add_child(line)

	var child_ids: Array[String] = []
	for child_id_variant in node_data.get("children", PackedStringArray()):
		var child_id := String(child_id_variant)
		if tree.has(child_id):
			child_ids.append(child_id)
	child_ids.sort()

	for child_id in child_ids:
		_add_ability_rows(tree, child_id, depth + 1, visited.duplicate())

func _on_ability_node_pressed(ability_id: String) -> void:
	AbilityStore.add_random_children(ability_id)

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
