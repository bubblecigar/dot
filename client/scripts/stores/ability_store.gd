extends Node

signal ability_tree_changed
signal ability_unlocked(ability_id: String)

var ability_tree: Dictionary = {}
var unlocked_abilities: Dictionary = {}

func _ready() -> void:
	_set_default_tree()

func _set_default_tree() -> void:
	var default_tree := {
		"root": {
			"name": "Core",
			"requires": PackedStringArray(),
			"children": PackedStringArray(),
		},
	}

	set_ability_tree(default_tree, PackedStringArray(["root"]))

func set_ability_tree(tree: Dictionary, initially_unlocked: PackedStringArray = PackedStringArray()) -> void:
	var normalized_tree := _normalize_tree(tree)
	if normalized_tree.is_empty():
		return

	ability_tree = normalized_tree
	unlocked_abilities.clear()
	for ability_id in initially_unlocked:
		if ability_tree.has(ability_id):
			unlocked_abilities[ability_id] = true

	ability_tree_changed.emit()

func has_ability(ability_id: String) -> bool:
	return ability_tree.has(ability_id)

func is_unlocked(ability_id: String) -> bool:
	return bool(unlocked_abilities.get(ability_id, false))

func can_unlock(ability_id: String) -> bool:
	if not ability_tree.has(ability_id):
		return false
	if is_unlocked(ability_id):
		return false

	var node_data: Dictionary = ability_tree[ability_id]
	var requires: PackedStringArray = node_data.get("requires", PackedStringArray())
	for required_id in requires:
		if not is_unlocked(required_id):
			return false
	return true

func unlock_ability(ability_id: String) -> bool:
	if not can_unlock(ability_id):
		return false

	unlocked_abilities[ability_id] = true
	ability_unlocked.emit(ability_id)
	ability_tree_changed.emit()
	return true

func get_ability_node(ability_id: String) -> Dictionary:
	if not ability_tree.has(ability_id):
		return {}
	return (ability_tree[ability_id] as Dictionary).duplicate(true)

func get_ability_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for ability_id in ability_tree.keys():
		ids.append(String(ability_id))
	return ids

func get_unlocked_ability_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for ability_id in unlocked_abilities.keys():
		ids.append(String(ability_id))
	return ids

func get_ability_tree() -> Dictionary:
	return ability_tree.duplicate(true)

func get_debug_snapshot() -> Dictionary:
	return {
		"ability_count": ability_tree.size(),
		"unlocked_count": unlocked_abilities.size(),
		"unlocked_abilities": get_unlocked_ability_ids(),
	}

func _normalize_tree(tree: Dictionary) -> Dictionary:
	var normalized := {}

	for ability_id_variant in tree.keys():
		var ability_id := String(ability_id_variant)
		var node_data_variant: Variant = tree[ability_id_variant]
		if typeof(node_data_variant) != TYPE_DICTIONARY:
			continue

		var node_data: Dictionary = node_data_variant
		var requires: PackedStringArray = PackedStringArray()
		for required_variant in node_data.get("requires", PackedStringArray()):
			requires.append(String(required_variant))

		var children: PackedStringArray = PackedStringArray()
		for child_variant in node_data.get("children", PackedStringArray()):
			children.append(String(child_variant))

		normalized[ability_id] = {
			"name": String(node_data.get("name", ability_id.capitalize())),
			"requires": requires,
			"children": children,
		}

	return normalized
