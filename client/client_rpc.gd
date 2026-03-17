extends Node

signal random_number_received(value: int)

@rpc("authority", "call_remote", "reliable")
func broadcast_random_number(value: int) -> void:
	random_number_received.emit(value)
