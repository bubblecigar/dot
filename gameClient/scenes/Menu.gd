extends Control

@onready var cards_row: HBoxContainer = $Layout/CardsRow
@onready var selected_label: Label = $Layout/SelectedLabel

var _offered_cards: PackedInt32Array = PackedInt32Array()

func _ready() -> void:
	AbilityStore.selected_cards_changed.connect(_refresh_selected_label)
	_refresh_selected_label()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_menu_visible():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_U:
			_generate_cards()
			get_viewport().set_input_as_handled()

func _generate_cards() -> void:
	_offered_cards.clear()
	for i in range(3):
		_offered_cards.append(randi_range(1, 99))
	_render_cards()

func _render_cards() -> void:
	for child in cards_row.get_children():
		child.queue_free()

	for i in range(_offered_cards.size()):
		var card_value := int(_offered_cards[i])
		var button := Button.new()
		button.custom_minimum_size = Vector2(140, 200)
		button.text = str(card_value)
		button.pressed.connect(_on_card_pressed.bind(i))
		cards_row.add_child(button)

func _on_card_pressed(card_index: int) -> void:
	if card_index < 0 or card_index >= _offered_cards.size():
		return

	var value := int(_offered_cards[card_index])
	AbilityStore.add_selected_card(value)
	_offered_cards.clear()
	_render_cards()

func _refresh_selected_label() -> void:
	var picked := AbilityStore.get_selected_cards()
	selected_label.text = "Selected: %s" % [var_to_str(picked)]

func _is_menu_visible() -> bool:
	var node: Node = self
	while node != null:
		if node is CanvasLayer:
			return (node as CanvasLayer).visible
		node = node.get_parent()
	return false
