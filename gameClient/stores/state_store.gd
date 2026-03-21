extends Node

var game_state: Dictionary = {}

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

func set_game_state(state: Dictionary) -> void:
	game_state = state.duplicate(true)

func clear_game_state() -> void:
	game_state = {}
