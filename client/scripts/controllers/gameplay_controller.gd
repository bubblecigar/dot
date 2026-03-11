extends Node2D

const INITIAL_SCENE := "res://client/scenes/StagePicker.tscn"

@onready var menu_layer: CanvasLayer = $Menu

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_TAB:
				menu_layer.visible = not menu_layer.visible
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_R:
				SceneManager.change_scene(INITIAL_SCENE, false)
				get_viewport().set_input_as_handled()
