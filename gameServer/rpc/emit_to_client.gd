extends Node

@rpc("authority", "call_remote", "reliable")
func broadcast_random_number(value: int) -> void:
	if multiplayer.multiplayer_peer == null:
		return

	rpc("broadcast_random_number", value)

@rpc("authority", "call_remote", "reliable")
func auth_result(result: Dictionary) -> void:
	if multiplayer.multiplayer_peer == null:
		return

	rpc("auth_result", result)

@rpc("authority", "call_remote", "reliable")
func room_list(rooms: Array) -> void:
	if multiplayer.multiplayer_peer == null:
		return

	rpc("room_list", rooms)

@rpc("authority", "call_remote", "reliable")
func room_joined(room: Dictionary) -> void:
	if multiplayer.multiplayer_peer == null:
		return

	rpc("room_joined", room)

@rpc("authority", "call_remote", "reliable")
func room_updated(room: Dictionary) -> void:
	if multiplayer.multiplayer_peer == null:
		return

	rpc("room_updated", room)
