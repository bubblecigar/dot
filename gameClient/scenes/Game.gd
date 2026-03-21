extends Control

const ROW_KEYS := ["row_1", "row_2", "row_3"]
const PHASE_PICK_PLUS := 1
const PHASE_PICK_MINUS := 2

@onready var phase_label: Label = $MarginContainer/Layout/HeaderCard/MarginContainer/HeaderLayout/PhaseLabel
@onready var remaining_label: Label = $MarginContainer/Layout/HeaderCard/MarginContainer/HeaderLayout/RemainingLabel
@onready var submit_button: Button = $MarginContainer/Layout/SubmitCard/MarginContainer/SubmitButton
@onready var summary_label: Label = $MarginContainer/Layout/SummaryCard/MarginContainer/SummaryLabel

@onready var row_1_slot_1: Button = $MarginContainer/Layout/RowsCard/MarginContainer/RowsLayout/Row1/Slot1
@onready var row_1_slot_2: Button = $MarginContainer/Layout/RowsCard/MarginContainer/RowsLayout/Row1/Slot2
@onready var row_1_slot_3: Button = $MarginContainer/Layout/RowsCard/MarginContainer/RowsLayout/Row1/Slot3
@onready var row_2_slot_1: Button = $MarginContainer/Layout/RowsCard/MarginContainer/RowsLayout/Row2/Slot1
@onready var row_2_slot_2: Button = $MarginContainer/Layout/RowsCard/MarginContainer/RowsLayout/Row2/Slot2
@onready var row_2_slot_3: Button = $MarginContainer/Layout/RowsCard/MarginContainer/RowsLayout/Row2/Slot3
@onready var row_3_slot_1: Button = $MarginContainer/Layout/RowsCard/MarginContainer/RowsLayout/Row3/Slot1
@onready var row_3_slot_2: Button = $MarginContainer/Layout/RowsCard/MarginContainer/RowsLayout/Row3/Slot2
@onready var row_3_slot_3: Button = $MarginContainer/Layout/RowsCard/MarginContainer/RowsLayout/Row3/Slot3

var _row_buttons: Dictionary = {}
var _rows: Dictionary = {}
var _phase: int = PHASE_PICK_PLUS

func _ready() -> void:
	_row_buttons = {
		"row_1": [row_1_slot_1, row_1_slot_2, row_1_slot_3],
		"row_2": [row_2_slot_1, row_2_slot_2, row_2_slot_3],
		"row_3": [row_3_slot_1, row_3_slot_2, row_3_slot_3],
	}
	_rows = {
		"row_1": [0, 0, 0],
		"row_2": [0, 0, 0],
		"row_3": [0, 0, 0],
	}

	for row_key in ROW_KEYS:
		var buttons: Array = _row_buttons[row_key]
		for index in range(buttons.size()):
			var button := buttons[index] as Button
			button.pressed.connect(_on_slot_pressed.bind(row_key, index))

	submit_button.pressed.connect(_on_submit_pressed)
	_refresh_view()

func _on_slot_pressed(row_key: String, column_index: int) -> void:
	var row_values: Array = _rows[row_key]
	if _phase == PHASE_PICK_PLUS:
		for index in range(row_values.size()):
			row_values[index] = 1 if index == column_index else 0
	elif _phase == PHASE_PICK_MINUS:
		if int(row_values[column_index]) == 1:
			return
		for index in range(row_values.size()):
			if int(row_values[index]) == 1:
				continue
			row_values[index] = -1 if index == column_index else 0
	_rows[row_key] = row_values
	_update_phase()
	_refresh_view()

func _on_submit_pressed() -> void:
	if _phase == PHASE_PICK_PLUS:
		if not _is_phase_one_complete():
			return
		_phase = PHASE_PICK_MINUS
		_refresh_view()
		return

	if not _is_valid_setup():
		return
	summary_label.text = "Ready to submit:\n%s" % JSON.stringify(_build_payload(), "\t")

func _refresh_view() -> void:
	for row_key in ROW_KEYS:
		var buttons: Array = _row_buttons[row_key]
		var row_values: Array = _rows[row_key]
		for index in range(buttons.size()):
			var button := buttons[index] as Button
			var value := int(row_values[index])
			button.text = _format_value(value)
			button.disabled = _is_button_disabled(value)

	phase_label.text = _build_phase_text()
	remaining_label.text = _build_remaining_text()
	submit_button.text = _build_submit_text()
	submit_button.disabled = _is_submit_disabled()
	if submit_button.disabled:
		summary_label.text = _build_summary_hint()

func _build_remaining_text() -> String:
	var parts: PackedStringArray = []
	for row_key in ROW_KEYS:
		var row_values: Array = _rows[row_key]
		if _phase == PHASE_PICK_PLUS:
			var plus_index := _find_value_index(row_values, 1)
			if plus_index >= 0:
				parts.append("%s: +1 locked on slot %d" % [_format_row_name(row_key), plus_index + 1])
			else:
				parts.append("%s: choose one slot for +1" % _format_row_name(row_key))
		else:
			var minus_index := _find_value_index(row_values, -1)
			if minus_index >= 0:
				parts.append("%s: -1 locked on slot %d" % [_format_row_name(row_key), minus_index + 1])
			else:
				parts.append("%s: choose one of the two remaining slots for -1" % _format_row_name(row_key))

	return "\n".join(parts)

func _is_valid_setup() -> bool:
	for row_key in ROW_KEYS:
		var row_values: Array = _rows[row_key]
		var sorted_values: Array = row_values.duplicate()
		sorted_values.sort()
		if sorted_values != [-1, 0, 1]:
			return false
	return true

func _build_payload() -> Dictionary:
	return {
		"row_1": (_rows["row_1"] as Array).duplicate(),
		"row_2": (_rows["row_2"] as Array).duplicate(),
		"row_3": (_rows["row_3"] as Array).duplicate(),
	}

func _format_value(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)

func _format_row_name(row_key: String) -> String:
	return row_key.replace("_", " ").capitalize()

func _update_phase() -> void:
	if _phase == PHASE_PICK_PLUS:
		return

	_phase = PHASE_PICK_MINUS

func _find_value_index(row_values: Array, target: int) -> int:
	for index in range(row_values.size()):
		if int(row_values[index]) == target:
			return index
	return -1

func _is_button_disabled(value: int) -> bool:
	if _phase == PHASE_PICK_PLUS:
		return false
	return value == 1

func _is_phase_one_complete() -> bool:
	for row_key in ROW_KEYS:
		var row_values: Array = _rows[row_key]
		if _find_value_index(row_values, 1) < 0:
			return false
	return true

func _is_submit_disabled() -> bool:
	if _phase == PHASE_PICK_PLUS:
		return not _is_phase_one_complete()
	return not _is_valid_setup()

func _build_submit_text() -> String:
	if _phase == PHASE_PICK_PLUS:
		return "Continue to Phase 2"
	return "Confirm Setup"

func _build_phase_text() -> String:
	if _phase == PHASE_PICK_PLUS:
		return "Phase 1: choose the +1 slot in each row, then submit"
	return "Phase 2: choose the -1 slot from the two remaining cells"

func _build_summary_hint() -> String:
	if _phase == PHASE_PICK_PLUS:
		return "Phase 1: each row needs one +1 selection before you continue."
	return "Phase 2: the +1 cells are locked. Pick one -1 from the two remaining cells in each row."
