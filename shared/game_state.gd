extends RefCounted

const PHASE_WAITING := "waiting"
const PHASE_ALL_READY := "all_ready"
const PHASE_PLAYING := "playing"

static func create_from_room(room: Dictionary) -> Dictionary:
	return _build_state({}, room)

static func sync_from_room(state: Dictionary, room: Dictionary) -> Dictionary:
	return _build_state(state, room)

static func set_player_ready(state: Dictionary, username: String, is_ready: bool) -> Dictionary:
	var next_state := state.duplicate(true)
	var normalized_username := username.strip_edges()
	var players: Array = next_state.get("players", [])
	var updated_players: Array = []

	for player_variant in players:
		var player := player_variant as Dictionary
		var next_player := player.duplicate(true)
		if str(next_player.get("username", "")).strip_edges() == normalized_username:
			next_player["is_ready"] = is_ready
		updated_players.append(next_player)

	next_state["players"] = updated_players
	next_state["phase"] = _resolve_phase(updated_players)
	return next_state

static func set_player_connection_state(state: Dictionary, username: String, is_connected: bool) -> Dictionary:
	var next_state := state.duplicate(true)
	var normalized_username := username.strip_edges()
	var current_phase := str(next_state.get("phase", PHASE_WAITING)).strip_edges()
	var players: Array = next_state.get("players", [])
	var updated_players: Array = []

	for player_variant in players:
		var player := player_variant as Dictionary
		var next_player := player.duplicate(true)
		if str(next_player.get("username", "")).strip_edges() == normalized_username:
			next_player["is_connected"] = is_connected
			next_player["connection_state"] = "connected" if is_connected else "disconnected"
		updated_players.append(next_player)

	next_state["players"] = updated_players
	if current_phase == PHASE_PLAYING:
		next_state["phase"] = PHASE_PLAYING
		return next_state

	next_state["phase"] = _resolve_phase(updated_players)
	if str(next_state.get("phase", PHASE_WAITING)) != PHASE_ALL_READY:
		next_state["transition_countdown"] = 0
	return next_state

static func set_phase(state: Dictionary, phase: String) -> Dictionary:
	var next_state := state.duplicate(true)
	next_state["phase"] = phase
	return next_state

static func set_transition_countdown(state: Dictionary, countdown_seconds: int) -> Dictionary:
	var next_state := state.duplicate(true)
	next_state["transition_countdown"] = countdown_seconds
	return next_state

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
	next_state["transition_countdown"] = int(existing_state.get("transition_countdown", 0))
	var players := _build_players(existing_state.get("players", []), members)
	next_state["players"] = players
	next_state["phase"] = _resolve_phase(players)
	if str(next_state.get("phase", PHASE_WAITING)) != PHASE_ALL_READY:
		next_state["transition_countdown"] = 0
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
		var is_connected := bool(existing_player.get("is_connected", true))
		players.append({
			"username": username,
			"is_connected": is_connected,
			"connection_state": "connected" if is_connected else "disconnected",
			"is_ready": bool(existing_player.get("is_ready", false)),
		})
	return players

static func _resolve_phase(players: Array) -> String:
	if players.is_empty():
		return PHASE_WAITING

	for player_variant in players:
		var player := player_variant as Dictionary
		if not bool(player.get("is_ready", false)):
			return PHASE_WAITING

	return PHASE_ALL_READY
