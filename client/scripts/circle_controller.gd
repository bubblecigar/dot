extends Node2D

@export var radius: float = 60.0
@export var color: Color = Color(1, 1, 1, 1)
@export var speed: float = 300.0

var circle_position: Vector2 = Vector2.ZERO
var _was_moving: bool = false

func _ready() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.size_changed.connect(_on_viewport_size_changed)
	circle_position = StateStore.get_circle_position(get_viewport_rect().size * 0.5)
	circle_position = _clamp_to_viewport(circle_position)
	StateStore.set_circle_position(circle_position)
	queue_redraw()

func _exit_tree() -> void:
	StateStore.save_state()

func _on_viewport_size_changed() -> void:
	circle_position = _clamp_to_viewport(circle_position)
	queue_redraw()

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var is_moving := direction != Vector2.ZERO
	if is_moving and not _was_moving:
		_notify_server_circle_moved()

	if is_moving:
		circle_position += direction * speed * delta
		circle_position = _clamp_to_viewport(circle_position)
		StateStore.set_circle_position(circle_position)
		StateStore.save_state()
		queue_redraw()

	_was_moving = is_moving

func _notify_server_circle_moved() -> void:
	ClientRpc.send_circle_moved()

func _clamp_to_viewport(pos: Vector2) -> Vector2:
	var size := get_viewport_rect().size
	pos.x = clampf(pos.x, radius, size.x - radius)
	pos.y = clampf(pos.y, radius, size.y - radius)
	return pos

func _draw() -> void:
	draw_circle(circle_position, radius, color)
