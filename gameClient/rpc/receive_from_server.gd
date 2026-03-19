extends Node

signal random_number_received(value: int)
signal auth_result_received(result: Dictionary)

var _pending_auth_result: Dictionary = {}

@rpc("authority", "call_remote", "reliable")
func broadcast_random_number(value: int) -> void:
	random_number_received.emit(value)

@rpc("authority", "call_remote", "reliable")
func auth_result(result: Dictionary) -> void:
	_pending_auth_result = result
	auth_result_received.emit(result)

func consume_auth_result() -> Dictionary:
	var result := _pending_auth_result
	_pending_auth_result = {}
	return result
