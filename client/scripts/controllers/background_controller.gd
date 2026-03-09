extends Node2D

@export var color: Color = Color(0.83, 0.83, 0.83, 1)
@export var ground_color: Color = Color(0.30, 0.32, 0.36, 1)
@export var ground_height: float = 80.0

@onready var floor_body: StaticBody2D = $Floor
@onready var floor_collision: CollisionShape2D = $Floor/CollisionShape2D

func _ready() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.size_changed.connect(_on_viewport_size_changed)
	_update_floor()
	queue_redraw()

func _on_viewport_size_changed() -> void:
	_update_floor()
	queue_redraw()

func _update_floor() -> void:
	var size := get_viewport_rect().size
	floor_body.position = Vector2(size.x * 0.5, size.y - ground_height * 0.5)

	var rect_shape: RectangleShape2D
	if floor_collision.shape is RectangleShape2D:
		rect_shape = floor_collision.shape as RectangleShape2D
	else:
		rect_shape = RectangleShape2D.new()
		floor_collision.shape = rect_shape

	rect_shape.size = Vector2(size.x, ground_height)

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), color, true)
	draw_rect(Rect2(0.0, size.y - ground_height, size.x, ground_height), ground_color, true)
