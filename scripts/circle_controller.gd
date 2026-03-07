extends Node2D

@export var radius: float = 60.0
@export var color: Color = Color(1, 1, 1, 1)
@export var speed: float = 300.0

const SAVE_PATH := "user://circle_position.cfg"

var circle_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.size_changed.connect(_on_viewport_size_changed)
	circle_position = _load_circle_position(get_viewport_rect().size * 0.5)
	circle_position = _clamp_to_viewport(circle_position)
	queue_redraw()

func _exit_tree() -> void:
	_save_circle_position()

func _on_viewport_size_changed() -> void:
	circle_position = _clamp_to_viewport(circle_position)
	queue_redraw()

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		circle_position += direction * speed * delta
		circle_position = _clamp_to_viewport(circle_position)
		_save_circle_position()
		queue_redraw()

func _load_circle_position(default_position: Vector2) -> Vector2:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return default_position

	var x := float(config.get_value("circle", "x", default_position.x))
	var y := float(config.get_value("circle", "y", default_position.y))
	return Vector2(x, y)

func _save_circle_position() -> void:
	var config := ConfigFile.new()
	config.set_value("circle", "x", circle_position.x)
	config.set_value("circle", "y", circle_position.y)
	config.save(SAVE_PATH)

func _clamp_to_viewport(pos: Vector2) -> Vector2:
	var size := get_viewport_rect().size
	pos.x = clampf(pos.x, radius, size.x - radius)
	pos.y = clampf(pos.y, radius, size.y - radius)
	return pos

func _draw() -> void:
	draw_circle(circle_position, radius, color)
