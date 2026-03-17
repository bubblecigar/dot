extends Control

@export var stage_one_path: String = "res://scenes/CharacterCustomizer.tscn"
@export var stage_two_path: String = "res://scenes/Gameplay.tscn"

@onready var layout: VBoxContainer = $Layout
@onready var stage_one_button: Button = $Layout/StageOneButton
@onready var stage_two_button: Button = $Layout/StageTwoButton
@onready var status_label: Label = $Layout/StatusLabel

func _ready() -> void:
	stage_one_button.pressed.connect(_on_stage_pressed.bind(stage_one_path))
	stage_two_button.pressed.connect(_on_stage_pressed.bind(stage_two_path))
	SceneManager.scene_change_failed.connect(_on_scene_change_failed)
	var viewport := get_viewport()
	if viewport:
		viewport.size_changed.connect(_update_layout_rect)
	_update_layout_rect.call_deferred()

func _on_stage_pressed(scene_path: String) -> void:
	status_label.text = "Loading: %s" % scene_path
	SceneManager.change_scene(scene_path, true)

func _on_scene_change_failed(path: String, reason: String) -> void:
	status_label.text = "Failed: %s (%s)" % [path, reason]

func _update_layout_rect() -> void:
	var viewport_size := get_viewport_rect().size
	var content_size := layout.get_combined_minimum_size()

	var target_width := clampf(content_size.x + 48.0, 280.0, viewport_size.x * 0.92)
	var target_height := clampf(content_size.y + 32.0, 180.0, viewport_size.y * 0.92)

	layout.size = Vector2(target_width, target_height)
	layout.position = (viewport_size - layout.size) * 0.5
