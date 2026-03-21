extends Node2D

const LOGIN_SCENE := "res://scenes/Login.tscn"
const ROOM_LIST_SCENE := "res://scenes/RoomList.tscn"
const ROOM_SCENE := "res://scenes/Room.tscn"
const GAME_SCENE := "res://scenes/Game.tscn"

@onready var scene_root: CanvasLayer = $SceneRoot

func _ready() -> void:
	SceneManager.initialize(scene_root)
	SceneManager.change_scene(_get_initial_scene(), false)

func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			get_tree().quit()
			return

		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
				SceneManager.change_scene(_get_initial_scene(), false)
				get_viewport().set_input_as_handled()

func _get_initial_scene() -> String:
	if AuthManager.auth_status == "authenticated":
		if not str(SessionFlowManager.game_state.get("room_id", "")).strip_edges().is_empty():
			if str(SessionFlowManager.game_state.get("phase", "")).strip_edges() == "playing":
				return GAME_SCENE
			return ROOM_SCENE
		return ROOM_LIST_SCENE
	return LOGIN_SCENE
