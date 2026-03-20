extends Node

var _rooms: Array[Dictionary] = []
var _next_room_id: int = 1

func create_room(owner_peer_id: int, owner_username: String) -> Dictionary:
	var room := {
		"id": "room-%04d" % _next_room_id,
		"owner_peer_id": owner_peer_id,
		"owner_username": owner_username,
	}
	_next_room_id += 1
	_rooms.append(room)
	return room.duplicate(true)

func get_rooms() -> Array:
	var rooms: Array = []
	for room in _rooms:
		rooms.append(room.duplicate(true))
	return rooms

func remove_rooms_for_owner(owner_peer_id: int) -> void:
	var removed_room_ids: PackedStringArray = []
	var remaining_rooms: Array[Dictionary] = []
	for room in _rooms:
		if int(room.get("owner_peer_id", -1)) == owner_peer_id:
			removed_room_ids.append(str(room.get("id", "")))
			continue
		remaining_rooms.append(room)
	_rooms = remaining_rooms
	if not removed_room_ids.is_empty():
		print(
			"Removed rooms for peer %d: %s"
			% [owner_peer_id, ", ".join(removed_room_ids)]
		)
