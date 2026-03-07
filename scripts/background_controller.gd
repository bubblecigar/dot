extends Node2D

@export var color: Color = Color(1, 0, 0, 1)

func _ready() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.size_changed.connect(_on_viewport_size_changed)
	queue_redraw()

func _on_viewport_size_changed() -> void:
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), color, true)
