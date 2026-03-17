extends Node

const SAVE_PATH := "user://state_store.cfg"

var circle_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	_load_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()

func set_circle_position(pos: Vector2) -> void:
	circle_position = pos

func get_circle_position(default_position: Vector2) -> Vector2:
	if circle_position == Vector2.ZERO:
		return default_position
	return circle_position

func get_debug_snapshot() -> Dictionary:
	var snapshot := {}
	for property in get_property_list():
		var usage := int(property.get("usage", 0))
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue

		var name := String(property.get("name", ""))
		if name.begins_with("_"):
			continue

		snapshot[name] = get(name)
	return snapshot

func save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("circle", "x", circle_position.x)
	config.set_value("circle", "y", circle_position.y)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return

	var x := float(config.get_value("circle", "x", 0.0))
	var y := float(config.get_value("circle", "y", 0.0))
	circle_position = Vector2(x, y)
