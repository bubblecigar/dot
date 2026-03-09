extends Control

const NODE_DIAMETER := 34.0
const EDGE_LENGTH := 120.0
const ROOT_SPAN := PI * 0.9
const MIN_SPAN := PI / 9.0
const CANVAS_PADDING := 80.0

@onready var graph_edges: Control = $GraphEdges
@onready var graph_nodes: Control = $GraphNodes

var _node_positions: Dictionary = {}

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
	_sync_saved_positions(tree, layout_root)

	var render_positions := _node_positions.duplicate(true)
	_fit_positions_to_canvas(render_positions)
	_draw_graph_edges(tree, render_positions)
	_draw_graph_nodes(tree, render_positions)

func _get_fallback_focus(tree: Dictionary) -> String:
	for ability_id_variant in tree.keys():
		return String(ability_id_variant)
	return ""

func _calculate_node_positions(tree: Dictionary, root_id: String) -> Dictionary:
	var positions := {}
	if root_id == "" or not tree.has(root_id):
		return positions

	positions[root_id] = Vector2.ZERO
	var subtree_weights := {}
	_compute_subtree_weight(tree, root_id, subtree_weights, {})
	_assign_by_angle(
		tree,
		root_id,
		-PI * 0.5,
		ROOT_SPAN,
		subtree_weights,
		positions,
		{}
	)
	return positions

func _sync_saved_positions(tree: Dictionary, layout_root: String) -> void:
	_prune_saved_positions(tree)

	if _node_positions.is_empty():
		_node_positions = _calculate_node_positions(tree, layout_root)
		return

	_append_missing_positions(tree)

func _prune_saved_positions(tree: Dictionary) -> void:
	var remove_ids: Array[String] = []
	for ability_id_variant in _node_positions.keys():
		var ability_id := String(ability_id_variant)
		if not tree.has(ability_id):
			remove_ids.append(ability_id)

	for ability_id in remove_ids:
		_node_positions.erase(ability_id)

func _append_missing_positions(tree: Dictionary) -> void:
	var pending_ids: Array[String] = []
	for ability_id_variant in tree.keys():
		var ability_id := String(ability_id_variant)
		if not _node_positions.has(ability_id):
			pending_ids.append(ability_id)
	pending_ids.sort()

	var max_passes := maxi(pending_ids.size(), 1)
	for _pass_index in range(max_passes):
		if pending_ids.is_empty():
			return

		var progressed := false
		var next_pending: Array[String] = []
		for ability_id in pending_ids:
			if _try_assign_position(tree, ability_id):
				progressed = true
			else:
				next_pending.append(ability_id)

		pending_ids = next_pending
		if not progressed:
			break

	for ability_id in pending_ids:
		if not _node_positions.has(ability_id):
			_node_positions[ability_id] = Vector2.ZERO

func _try_assign_position(tree: Dictionary, ability_id: String) -> bool:
	if _node_positions.has(ability_id):
		return true
	if not tree.has(ability_id):
		return false

	var parent_id := _get_parent_id(tree, ability_id)
	if parent_id == "":
		_node_positions[ability_id] = Vector2.ZERO
		return true
	if not _node_positions.has(parent_id):
		return false

	var parent_node: Dictionary = tree[parent_id]
	var child_ids: PackedStringArray = parent_node.get("children", PackedStringArray())
	var child_count := maxi(child_ids.size(), 1)
	var child_index := child_ids.find(ability_id)
	if child_index < 0:
		child_index = 0

	var angle := -PI * 0.5
	if child_count > 1:
		angle = -PI * 0.5 + TAU * float(child_index) / float(child_count)

	var parent_pos := _node_positions[parent_id] as Vector2
	var direction := Vector2(cos(angle), sin(angle))
	_node_positions[ability_id] = parent_pos + direction * EDGE_LENGTH
	return true

func _get_parent_id(tree: Dictionary, ability_id: String) -> String:
	if not tree.has(ability_id):
		return ""

	var node_data: Dictionary = tree[ability_id]
	var requires: PackedStringArray = node_data.get("requires", PackedStringArray())
	for required_id in requires:
		if tree.has(required_id):
			return required_id
	return ""

func _fit_positions_to_canvas(positions: Dictionary) -> void:
	if positions.is_empty():
		custom_minimum_size = size
		return

	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF

	for pos_variant in positions.values():
		var pos := pos_variant as Vector2
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)
		min_y = minf(min_y, pos.y)
		max_y = maxf(max_y, pos.y)

	var tree_width := (max_x - min_x) + CANVAS_PADDING * 2.0 + NODE_DIAMETER
	var tree_height := (max_y - min_y) + CANVAS_PADDING * 2.0 + NODE_DIAMETER
	var canvas_size := Vector2(maxf(size.x, tree_width), maxf(size.y, tree_height))
	custom_minimum_size = canvas_size

	var offset := Vector2(
		-min_x + CANVAS_PADDING + NODE_DIAMETER * 0.5,
		-min_y + CANVAS_PADDING + NODE_DIAMETER * 0.5
	)
	var extra := (canvas_size - Vector2(tree_width, tree_height)) * 0.5
	offset += extra

	for ability_id_variant in positions.keys():
		var ability_id := String(ability_id_variant)
		positions[ability_id] = (positions[ability_id] as Vector2) + offset

func _compute_subtree_weight(
	tree: Dictionary,
	ability_id: String,
	subtree_weights: Dictionary,
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
		subtree_weights[ability_id] = 1
		return 1

	var total_weight := 0
	for child_id in child_ids:
		total_weight += _compute_subtree_weight(tree, child_id, subtree_weights, visited.duplicate())

	var weight := maxi(total_weight, 1)
	subtree_weights[ability_id] = weight
	return weight

func _assign_by_angle(
	tree: Dictionary,
	ability_id: String,
	parent_angle: float,
	span: float,
	subtree_weights: Dictionary,
	positions: Dictionary,
	visited: Dictionary
) -> void:
	if visited.has(ability_id):
		return
	visited[ability_id] = true

	if not tree.has(ability_id):
		return

	var node_data: Dictionary = tree[ability_id]
	var child_ids: Array[String] = []
	for child_variant in node_data.get("children", PackedStringArray()):
		var child_id := String(child_variant)
		if tree.has(child_id):
			child_ids.append(child_id)
	child_ids.sort()

	var total_weight := 0.0
	for child_id in child_ids:
		total_weight += float(subtree_weights.get(child_id, 1))
	if total_weight <= 0.0:
		return

	var child_span := maxf(span, MIN_SPAN)
	var angle_cursor := parent_angle - child_span * 0.5
	for child_id in child_ids:
		var child_weight := float(subtree_weights.get(child_id, 1))
		var share := child_span * (child_weight / total_weight)
		var child_angle := angle_cursor + share * 0.5
		var direction := Vector2(cos(child_angle), sin(child_angle))
		positions[child_id] = (positions[ability_id] as Vector2) + direction * EDGE_LENGTH
		_assign_by_angle(
			tree,
			child_id,
			child_angle,
			share * 0.85,
			subtree_weights,
			positions,
			visited.duplicate()
		)
		angle_cursor += share

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
		var is_unlocked := AbilityStore.is_unlocked(ability_id)
		var is_expanded := AbilityStore.has_expanded(ability_id)

		var button := Button.new()
		button.text = ""
		button.tooltip_text = ability_name
		button.custom_minimum_size = Vector2(NODE_DIAMETER, NODE_DIAMETER)
		button.size = Vector2(NODE_DIAMETER, NODE_DIAMETER)
		button.disabled = is_expanded
		button.position = (positions[ability_id] as Vector2) - Vector2(NODE_DIAMETER * 0.5, NODE_DIAMETER * 0.5)
		button.set(
			"theme_override_styles/normal",
			_make_circle_style(Color(0.18, 0.78, 0.40) if is_unlocked else Color(0.34, 0.36, 0.40))
		)
		button.set(
			"theme_override_styles/hover",
			_make_circle_style(Color(0.25, 0.86, 0.50) if is_unlocked else Color(0.44, 0.47, 0.53))
		)
		button.set(
			"theme_override_styles/pressed",
			_make_circle_style(Color(0.12, 0.62, 0.30) if is_unlocked else Color(0.24, 0.26, 0.30))
		)
		button.set("theme_override_styles/disabled", _make_circle_style(Color(0.14, 0.15, 0.17)))

		if not is_expanded:
			button.pressed.connect(_on_ability_node_pressed.bind(ability_id))

		graph_nodes.add_child(button)

func _make_circle_style(fill_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.corner_radius_top_left = int(NODE_DIAMETER * 0.5)
	style.corner_radius_top_right = int(NODE_DIAMETER * 0.5)
	style.corner_radius_bottom_right = int(NODE_DIAMETER * 0.5)
	style.corner_radius_bottom_left = int(NODE_DIAMETER * 0.5)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.95, 0.95, 0.95, 0.9)
	return style

func _add_graph_message(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(12, 12)
	graph_nodes.add_child(label)

func _on_ability_node_pressed(ability_id: String) -> void:
	AbilityStore.add_random_children(ability_id)
