extends Node

const AuthApiClient := preload("res://../shared/auth_api_client.gd")

var _authenticated_peers: Dictionary = {}
var _pending_auth_peers: Dictionary = {}

func authenticate_peer(peer_id: int, token: String) -> Dictionary:
	if _pending_auth_peers.has(peer_id):
		return {
			"ok": false,
			"error": "auth_in_progress",
		}

	if token.is_empty():
		clear_peer_auth(peer_id)
		return {
			"ok": false,
			"error": "missing_token",
		}

	_pending_auth_peers[peer_id] = true
	var validation_result := await AuthApiClient.validate_token(token)
	_pending_auth_peers.erase(peer_id)

	if not bool(validation_result.get("ok", false)):
		clear_peer_auth(peer_id)
		return {
			"ok": false,
			"error": str(validation_result.get("error", "invalid_token")),
		}

	var username := str(validation_result.get("username", "")).strip_edges()
	if username.is_empty():
		clear_peer_auth(peer_id)
		return {
			"ok": false,
			"error": "missing_username",
		}

	_authenticated_peers[peer_id] = username
	return {
		"ok": true,
		"username": username,
	}

func is_peer_authenticated(peer_id: int) -> bool:
	return _authenticated_peers.has(peer_id)

func get_authenticated_username(peer_id: int) -> String:
	return str(_authenticated_peers.get(peer_id, ""))

func clear_peer_auth(peer_id: int) -> void:
	_authenticated_peers.erase(peer_id)
	_pending_auth_peers.erase(peer_id)
