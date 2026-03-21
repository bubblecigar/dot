extends RefCounted

const PHASE_WAITING := "waiting"

static func create_from_room(room: Dictionary) -> Dictionary:
	return _build_state({}, room)

static func sync_from_room(state: Dictionary, room: Dictionary) -> Dictionary:
	return _build_state(state, room)

static func _build_state(existing_state: Dictionary, room: Dictionary) -> Dictionary:
	var next_state := existing_state.duplicate(true)
	var room_id := str(room.get("id", "")).strip_edges()
	var owner_username := str(room.get("owner_username", "")).strip_edges()
	var members: Array = room.get("members", [])

	next_state["room_id"] = room_id
	next_state["owner_username"] = owner_username
	next_state["phase"] = str(existing_state.get("phase", PHASE_WAITING))
	next_state["round"] = int(existing_state.get("round", 1))
	next_state["turn"] = int(existing_state.get("turn", 0))
	next_state["players"] = _build_players(existing_state.get("players", []), members)
	return next_state

static func _build_players(existing_players_variant: Variant, members: Array) -> Array:
	var existing_players: Array = existing_players_variant if existing_players_variant is Array else []
	var existing_by_username := {}
	for player_variant in existing_players:
		var player := player_variant as Dictionary
		var username := str(player.get("username", "")).strip_edges()
		if username.is_empty():
			continue
		existing_by_username[username] = player

	var players: Array = []
	for member_variant in members:
		var username := str(member_variant).strip_edges()
		if username.is_empty():
			continue

		var existing_player: Dictionary = existing_by_username.get(username, {})
		players.append({
			"username": username,
			"is_connected": true,
			"is_ready": bool(existing_player.get("is_ready", false)),
		})
	return players
