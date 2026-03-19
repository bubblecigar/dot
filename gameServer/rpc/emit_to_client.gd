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
