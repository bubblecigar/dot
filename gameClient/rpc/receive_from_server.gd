extends Node

signal random_number_received(value: int)
signal auth_result_received(result: Dictionary)
signal room_list_received(rooms: Array)
signal room_joined_received(room: Dictionary)
signal room_updated_received(room: Dictionary)
signal game_state_updated_received(state: Dictionary)

@rpc("authority", "call_remote", "reliable")
func broadcast_random_number(value: int) -> void:
	random_number_received.emit(value)

@rpc("authority", "call_remote", "reliable")
func auth_result(result: Dictionary) -> void:
	auth_result_received.emit(result)

@rpc("authority", "call_remote", "reliable")
func room_list(rooms: Array) -> void:
	room_list_received.emit(rooms)

@rpc("authority", "call_remote", "reliable")
func room_joined(room: Dictionary) -> void:
	room_joined_received.emit(room)

@rpc("authority", "call_remote", "reliable")
func room_updated(room: Dictionary) -> void:
	room_updated_received.emit(room)

@rpc("authority", "call_remote", "reliable")
func game_state_updated(state: Dictionary) -> void:
	game_state_updated_received.emit(state)
