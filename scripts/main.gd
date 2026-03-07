extends Node2D

@export var radius: float = 60.0
@export var color: Color = Color(1, 1, 1, 1)

func _ready() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.size_changed.connect(_on_viewport_size_changed)
	queue_redraw()

func _on_viewport_size_changed() -> void:
	queue_redraw()

func _draw() -> void:
	var center := get_viewport_rect().size * 0.5
	draw_circle(center, radius, color)
