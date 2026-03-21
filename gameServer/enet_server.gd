extends Node

const DEFAULT_TICK_RATE := 20.0
const DEFAULT_PLAYER_SPEED := 220.0
const RANDOM_BROADCAST_INTERVAL := 1.0

var _peer: ENetMultiplayerPeer
var _players: Dictionary = {}
var _tick_accumulator: float = 0.0
var _random_accumulator: float = 0.0

@export var tick_rate: float = DEFAULT_TICK_RATE
@export var player_speed: float = DEFAULT_PLAYER_SPEED

func start(port: int, max_clients: int) -> int:
	randomize()
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, max_clients)
	if err != OK:
		return err

	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("ENet server started on port %d (max clients: %d)" % [port, max_clients])
	return OK

func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null:
		return

	_tick_accumulator += delta
	var tick_step := 1.0 / tick_rate
	while _tick_accumulator >= tick_step:
		_simulate(tick_step)
		_tick_accumulator -= tick_step

	_random_accumulator += delta
	if _random_accumulator >= RANDOM_BROADCAST_INTERVAL:
		_random_accumulator = 0.0
		_broadcast_random_number()

func _simulate(delta: float) -> void:
	for peer_id in _players.keys():
		var player: Dictionary = _players[peer_id]
		var direction: Vector2 = player.get("direction", Vector2.ZERO)
		var position: Vector2 = player.get("position", Vector2.ZERO)
		position += direction * player_speed * delta
		player["position"] = position
		_players[peer_id] = player

	# Placeholder for state replication to clients.
	# You can add authoritative RPC snapshots from here.

func _on_peer_connected(peer_id: int) -> void:
	_players[peer_id] = {
		"position": Vector2.ZERO,
		"direction": Vector2.ZERO,
	}
	print("Peer connected: %d" % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	SessionAuthService.clear_peer_auth(peer_id)
	_players.erase(peer_id)
	print("Peer disconnected: %d (remaining players: %d)" % [peer_id, _players.size()])

func _broadcast_random_number() -> void:
	if _players.is_empty():
		return

	var value := randi_range(1, 100)
	ClientRpc.broadcast_random_number(value)

@rpc("any_peer", "call_local", "unreliable")
func submit_input(direction: Vector2) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	if not SessionAuthService.is_peer_authenticated(peer_id):
		print("Rejected input from unauthenticated peer %d" % peer_id)
		return
	if not _players.has(peer_id):
		return

	var player: Dictionary = _players[peer_id]
	player["direction"] = direction.normalized()
	_players[peer_id] = player
