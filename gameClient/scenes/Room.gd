extends Control

const ROOM_LIST_SCENE_PATH := "res://scenes/RoomList.tscn"

@onready var room_id_label: Label = $MarginContainer/Grid/RoomIdCard/MarginContainer/RoomIdLabel
@onready var back_button: Button = $MarginContainer/Grid/BackCard/MarginContainer/BackButton

func _ready() -> void:
	room_id_label.text = "Room ID: %s" % StateStore.current_room_id
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	StateStore.set_current_room_id("")
	SceneManager.change_scene(ROOM_LIST_SCENE_PATH, true)
