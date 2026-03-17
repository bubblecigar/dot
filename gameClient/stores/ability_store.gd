extends Node

signal selected_cards_changed

var selected_cards: PackedInt32Array = PackedInt32Array()

func add_selected_card(value: int) -> void:
	selected_cards.append(value)
	selected_cards_changed.emit()

func get_selected_cards() -> PackedInt32Array:
	return selected_cards.duplicate()

func clear_selected_cards() -> void:
	selected_cards.clear()
	selected_cards_changed.emit()

func get_debug_snapshot() -> Dictionary:
	return {
		"selected_card_count": selected_cards.size(),
		"selected_cards": get_selected_cards(),
	}
