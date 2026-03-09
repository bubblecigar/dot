extends Control

const NODE_BUTTON_SIZE := Vector2(180, 36)
const LEVEL_RADIUS_STEP := 130.0

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

	var depth_map := _get_graph_depth_map(tree, center_id)
	var center := size * 0.5

	for depth_variant in depth_map.keys():
		var depth := int(depth_variant)
		var ids: Array[String] = []
		for ability_id_variant in depth_map.get(depth, []):
			ids.append(String(ability_id_variant))
		ids.sort()

		if depth == 0:
			positions[center_id] = center
			continue

		var count := ids.size()
		if count == 0:
			continue

		var radius := LEVEL_RADIUS_STEP * depth
		for i in range(count):
			var angle := -PI * 0.5 + (TAU * float(i) / float(count))
			var point := center + Vector2(cos(angle), sin(angle)) * radius
			positions[ids[i]] = point

	return positions

func _get_graph_depth_map(tree: Dictionary, center_id: String) -> Dictionary:
	var adjacency := _build_undirected_adjacency(tree)
	var visited := {center_id: true}
	var queue: Array[Dictionary] = [{"id": center_id, "depth": 0}]
	var depth_map: Dictionary = {0: [center_id]}

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var current_id := String(current["id"])
		var depth := int(current["depth"])

		var neighbors: Array[String] = []
		for neighbor_variant in adjacency.get(current_id, []):
			neighbors.append(String(neighbor_variant))
		for neighbor in neighbors:
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			var next_depth := depth + 1
			if not depth_map.has(next_depth):
				depth_map[next_depth] = []
			(depth_map[next_depth] as Array).append(neighbor)
			queue.append({"id": neighbor, "depth": next_depth})

	return depth_map

func _build_undirected_adjacency(tree: Dictionary) -> Dictionary:
	var adjacency := {}
	for ability_id_variant in tree.keys():
		var ability_id := String(ability_id_variant)
		adjacency[ability_id] = []

	for ability_id_variant in tree.keys():
		var ability_id := String(ability_id_variant)
		var node_data: Dictionary = tree[ability_id]

		for child_variant in node_data.get("children", PackedStringArray()):
			var child_id := String(child_variant)
			if not adjacency.has(child_id):
				adjacency[child_id] = []
			if not (adjacency[ability_id] as Array).has(child_id):
				(adjacency[ability_id] as Array).append(child_id)
			if not (adjacency[child_id] as Array).has(ability_id):
				(adjacency[child_id] as Array).append(ability_id)

		for required_variant in node_data.get("requires", PackedStringArray()):
			var required_id := String(required_variant)
			if not adjacency.has(required_id):
				adjacency[required_id] = []
			if not (adjacency[ability_id] as Array).has(required_id):
				(adjacency[ability_id] as Array).append(required_id)
			if not (adjacency[required_id] as Array).has(ability_id):
				(adjacency[required_id] as Array).append(ability_id)

	return adjacency

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
