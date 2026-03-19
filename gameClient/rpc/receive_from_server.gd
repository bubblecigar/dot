extends Node

signal random_number_received(value: int)
signal auth_result_received(result: Dictionary)

@rpc("authority", "call_remote", "reliable")
func broadcast_random_number(value: int) -> void:
	random_number_received.emit(value)

@rpc("authority", "call_remote", "reliable")
func auth_result(result: Dictionary) -> void:
	auth_result_received.emit(result)
