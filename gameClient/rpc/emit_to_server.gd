extends Node

const SERVER_PEER_ID := 1

@rpc("any_peer", "call_remote", "reliable")
func submit_button_states(states: Dictionary) -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	rpc_id(SERVER_PEER_ID, "submit_button_states", states)

@rpc("any_peer", "call_remote", "reliable")
func authenticate(auth_data: Dictionary) -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	rpc_id(SERVER_PEER_ID, "authenticate", auth_data)

@rpc("any_peer", "call_remote", "reliable")
func notify_circle_moved() -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	rpc_id(SERVER_PEER_ID, "notify_circle_moved")

@rpc("any_peer", "call_remote", "reliable")
func request_room_list() -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	rpc_id(SERVER_PEER_ID, "request_room_list")

@rpc("any_peer", "call_remote", "reliable")
func create_room() -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	rpc_id(SERVER_PEER_ID, "create_room")

@rpc("any_peer", "call_remote", "reliable")
func join_room(room_id: String) -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	rpc_id(SERVER_PEER_ID, "join_room", room_id)

@rpc("any_peer", "call_remote", "reliable")
func leave_room(room_id: String) -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	rpc_id(SERVER_PEER_ID, "leave_room", room_id)
