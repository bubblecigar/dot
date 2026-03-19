extends Node2D

const LOGIN_SCENE := "res://scenes/Login.tscn"
const AUTHENTICATED_SCENE := "res://scenes/StagePicker.tscn"

@onready var gameplay_root: Node2D = $GameplayRoot

func _ready() -> void:
	SceneManager.initialize(gameplay_root)
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
	if StateStore.auth_status == "authenticated":
		return AUTHENTICATED_SCENE
	return LOGIN_SCENE
