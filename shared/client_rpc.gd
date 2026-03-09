extends Node

const SERVER_PEER_ID := 1

func send_circle_moved() -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	rpc_id(SERVER_PEER_ID, "notify_circle_moved")

@rpc("any_peer", "call_remote", "reliable")
func notify_circle_moved() -> void:
	if not multiplayer.is_server():
		return
	print("hello")
