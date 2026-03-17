extends RigidBody2D

@export var radius: float = 60.0
@export var color: Color = Color(1, 1, 1, 1)
@export var move_speed: float = 320.0
@export var jump_velocity: float = 700.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var floor_ray: RayCast2D = $FloorRay

func _ready() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.size_changed.connect(_on_viewport_size_changed)

	if global_position == Vector2.ZERO:
		var size := get_viewport_rect().size
		global_position = Vector2(size.x * 0.5, radius + 20.0)

	_update_collision_shape()
	_update_floor_ray()
	queue_redraw()

func _on_viewport_size_changed() -> void:
	var size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, radius, size.x - radius)
	_update_collision_shape()
	_update_floor_ray()
	queue_redraw()

func _update_collision_shape() -> void:
	var circle_shape: CircleShape2D
	if collision_shape.shape is CircleShape2D:
		circle_shape = collision_shape.shape as CircleShape2D
	else:
		circle_shape = CircleShape2D.new()
		collision_shape.shape = circle_shape

	circle_shape.radius = radius

func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	linear_velocity.x = direction * move_speed

	if Input.is_action_just_pressed("ui_up"):
		linear_velocity.y = -jump_velocity

	_clamp_to_viewport()

func _update_floor_ray() -> void:
	floor_ray.target_position = Vector2(0.0, radius + 8.0)

func _is_grounded() -> bool:
	return floor_ray.is_colliding()

func _clamp_to_viewport() -> void:
	var size := get_viewport_rect().size
	var min_pos := Vector2(radius, radius)
	var max_pos := Vector2(size.x - radius, size.y - radius)
	var clamped_pos := global_position.clamp(min_pos, max_pos)

	if clamped_pos.x != global_position.x and signf(linear_velocity.x) == signf(global_position.x - clamped_pos.x):
		linear_velocity.x = 0.0
	if clamped_pos.y != global_position.y and signf(linear_velocity.y) == signf(global_position.y - clamped_pos.y):
		linear_velocity.y = 0.0

	global_position = clamped_pos

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
