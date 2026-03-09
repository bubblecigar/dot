extends Control

const NODE_BUTTON_SIZE := Vector2(180, 36)
const HORIZONTAL_GAP := 220.0
const VERTICAL_GAP := 110.0
const TOP_MARGIN := 40.0

@onready var graph_edges: Control = $GraphEdges
@onready var graph_nodes: Control = $GraphNodes

func _ready() -> void:
	AbilityStore.ability_tree_changed.connect(_refresh_ability_tree_menu)
	resized.connect(_refresh_ability_tree_menu)
	_refresh_ability_tree_menu.call_deferred()

func _refresh_ability_tree_menu() -> void:
	for child in graph_edges.get_children():
		child.queue_free()
	for child in graph_nodes.get_children():
		child.queue_free()

	var tree: Dictionary = AbilityStore.get_ability_tree()
	if tree.is_empty():
		_add_graph_message("Ability tree is empty")
		return

	var layout_root := "root"
	if not tree.has(layout_root):
		layout_root = _get_fallback_focus(tree)
	var node_positions := _calculate_node_positions(tree, layout_root)
	_draw_graph_edges(tree, node_positions)
	_draw_graph_nodes(tree, node_positions)

func _get_fallback_focus(tree: Dictionary) -> String:
	for ability_id_variant in tree.keys():
		return String(ability_id_variant)
	return ""

func _calculate_node_positions(tree: Dictionary, center_id: String) -> Dictionary:
	var positions := {}
	if center_id == "" or not tree.has(center_id):
		return positions

	var subtree_widths := {}
	_compute_subtree_width(tree, center_id, subtree_widths, {})

	var root_units := float(subtree_widths.get(center_id, 1))
	var x_start := 0.0
	var tree_pixel_width := root_units * HORIZONTAL_GAP
	if tree_pixel_width < size.x:
		x_start = (size.x - tree_pixel_width) * 0.5 / HORIZONTAL_GAP

	_assign_tree_positions(tree, center_id, 0, x_start, positions, subtree_widths, {})

	return positions

func _compute_subtree_width(
	tree: Dictionary,
	ability_id: String,
	subtree_widths: Dictionary,
	visited: Dictionary
) -> int:
	if visited.has(ability_id):
		return 1
	visited[ability_id] = true

	if not tree.has(ability_id):
		return 1

	var node_data: Dictionary = tree[ability_id]
	var child_ids: Array[String] = []
	for child_variant in node_data.get("children", PackedStringArray()):
		var child_id := String(child_variant)
		if tree.has(child_id):
			child_ids.append(child_id)
	child_ids.sort()

	if child_ids.is_empty():
		subtree_widths[ability_id] = 1
		return 1

	var total_width := 0
	for child_id in child_ids:
		total_width += _compute_subtree_width(tree, child_id, subtree_widths, visited.duplicate())

	var width := maxi(total_width, 1)
	subtree_widths[ability_id] = width
	return width

func _assign_tree_positions(
	tree: Dictionary,
	ability_id: String,
	depth: int,
	x_start_units: float,
	positions: Dictionary,
	subtree_widths: Dictionary,
	visited: Dictionary
) -> void:
	if visited.has(ability_id):
		return
	visited[ability_id] = true

	if not tree.has(ability_id):
		return

	var node_width_units := float(subtree_widths.get(ability_id, 1))
	var x_center_units := x_start_units + node_width_units * 0.5
	var x := x_center_units * HORIZONTAL_GAP
	var y := TOP_MARGIN + float(depth) * VERTICAL_GAP
	positions[ability_id] = Vector2(x, y)

	var node_data: Dictionary = tree[ability_id]
	var child_ids: Array[String] = []
	for child_variant in node_data.get("children", PackedStringArray()):
		var child_id := String(child_variant)
		if tree.has(child_id):
			child_ids.append(child_id)
	child_ids.sort()

	var child_x_start := x_start_units
	for child_id in child_ids:
		_assign_tree_positions(
			tree,
			child_id,
			depth + 1,
			child_x_start,
			positions,
			subtree_widths,
			visited.duplicate()
		)
		child_x_start += float(subtree_widths.get(child_id, 1))

func _draw_graph_edges(tree: Dictionary, positions: Dictionary) -> void:
	for ability_id_variant in tree.keys():
		var parent_id := String(ability_id_variant)
		if not positions.has(parent_id):
			continue

		var parent_pos: Vector2 = positions[parent_id]
		var node_data: Dictionary = tree[parent_id]
		for child_variant in node_data.get("children", PackedStringArray()):
			var child_id := String(child_variant)
			if not positions.has(child_id):
				continue

			var child_pos: Vector2 = positions[child_id]
			var line := Line2D.new()
			line.width = 2.0
			line.default_color = Color(0.78, 0.78, 0.82, 0.85)
			line.add_point(parent_pos)
			line.add_point(child_pos)
			graph_edges.add_child(line)

func _draw_graph_nodes(tree: Dictionary, positions: Dictionary) -> void:
	for ability_id_variant in positions.keys():
		var ability_id := String(ability_id_variant)
		if not tree.has(ability_id):
			continue

		var node_data: Dictionary = tree[ability_id]
		var ability_name := String(node_data.get("name", ability_id))
		var unlocked_prefix := "[x]" if AbilityStore.is_unlocked(ability_id) else "[ ]"

		var button := Button.new()
		button.text = "%s %s" % [unlocked_prefix, ability_name]
		button.custom_minimum_size = NODE_BUTTON_SIZE
		button.size = NODE_BUTTON_SIZE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = AbilityStore.has_expanded(ability_id)
		button.position = (positions[ability_id] as Vector2) - (NODE_BUTTON_SIZE * 0.5)

		if not button.disabled:
			button.pressed.connect(_on_ability_node_pressed.bind(ability_id))

		graph_nodes.add_child(button)

func _add_graph_message(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(12, 12)
	graph_nodes.add_child(label)

func _on_ability_node_pressed(ability_id: String) -> void:
	AbilityStore.add_random_children(ability_id)
