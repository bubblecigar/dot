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
