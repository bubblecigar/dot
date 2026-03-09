extends RigidBody2D

@export var radius: float = 60.0
@export var color: Color = Color(1, 1, 1, 1)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.size_changed.connect(_on_viewport_size_changed)

	if global_position == Vector2.ZERO:
		var size := get_viewport_rect().size
		global_position = Vector2(size.x * 0.5, radius + 20.0)

	_update_collision_shape()
	queue_redraw()

func _on_viewport_size_changed() -> void:
	var size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, radius, size.x - radius)
	_update_collision_shape()
	queue_redraw()

func _update_collision_shape() -> void:
	var circle_shape: CircleShape2D
	if collision_shape.shape is CircleShape2D:
		circle_shape = collision_shape.shape as CircleShape2D
	else:
		circle_shape = CircleShape2D.new()
		collision_shape.shape = circle_shape

	circle_shape.radius = radius

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
