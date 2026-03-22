extends Control

const ROW_KEYS := ["row_1", "row_2", "row_3"]
const PHASE_PICK_PLUS := 1
const PHASE_PICK_MINUS := 2
const GAME_PHASE_CHARACTER_SETUP := "character_setup"
const GAME_PHASE_ROUND_PICK := "round_pick"

@onready var title_label: Label = $MarginContainer/Layout/HeaderCard/MarginContainer/HeaderLayout/TitleLabel
@onready var hint_label: Label = $MarginContainer/Layout/HeaderCard/MarginContainer/HeaderLayout/HintLabel
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
var _pick_rows: Dictionary = {}
var _phase: int = PHASE_PICK_PLUS
var _submit_pending: bool = false
var _pick_submit_pending: bool = false

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
	_pick_rows = {
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
	if not ClientRpc.game_state_updated_received.is_connected(_on_game_state_updated_received):
		ClientRpc.game_state_updated_received.connect(_on_game_state_updated_received)
	_apply_state_from_game_state()
	_refresh_view()

func _exit_tree() -> void:
	if ClientRpc.game_state_updated_received.is_connected(_on_game_state_updated_received):
		ClientRpc.game_state_updated_received.disconnect(_on_game_state_updated_received)

func _on_slot_pressed(row_key: String, column_index: int) -> void:
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		var row_pick_values: Array = _pick_rows[row_key]
		for index in range(row_pick_values.size()):
			row_pick_values[index] = 1 if index == column_index else 0
		_pick_rows[row_key] = row_pick_values
		_refresh_view()
		return

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
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		if not _is_valid_round_pick():
			return
		_pick_submit_pending = true
		ServerRpc.submit_round_pick(_build_pick_payload())
		summary_label.text = "Submitting round pick to the server..."
		_refresh_view()
		return

	if _phase == PHASE_PICK_PLUS:
		if not _is_phase_one_complete():
			return
		_phase = PHASE_PICK_MINUS
		_refresh_view()
		return

	if not _is_valid_setup():
		return
	_submit_pending = true
	ServerRpc.submit_character_setup(_build_payload())
	summary_label.text = "Submitted. Waiting for other players..."
	_refresh_view()

func _refresh_view() -> void:
	var interaction_locked := _is_interaction_locked()
	title_label.text = _build_title_text()
	hint_label.text = _build_hint_text()
	for row_key in ROW_KEYS:
		var buttons: Array = _row_buttons[row_key]
		var row_values: Array = _pick_rows[row_key] if _get_game_phase() == GAME_PHASE_ROUND_PICK else _rows[row_key]
		for index in range(buttons.size()):
			var button := buttons[index] as Button
			var value := int(row_values[index])
			button.text = _format_value(value)
			button.disabled = interaction_locked or _is_button_disabled(value)

	phase_label.text = _build_phase_text()
	remaining_label.text = _build_remaining_text()
	submit_button.text = _build_submit_text()
	submit_button.disabled = _is_submit_disabled()
	if submit_button.disabled:
		summary_label.text = _build_summary_hint()

func _is_valid_setup() -> bool:
	for row_key in ROW_KEYS:
		var row_values: Array = _rows[row_key]
		var sorted_values: Array = row_values.duplicate()
		sorted_values.sort()
		if sorted_values != [-1, 0, 1]:
			return false
	return true

func _is_valid_round_pick() -> bool:
	for row_key in ROW_KEYS:
		var row_values: Array = _pick_rows[row_key]
		var total := 0
		for value_variant in row_values:
			total += int(value_variant)
		if total != 1:
			return false
	return true

func _build_payload() -> Dictionary:
	return {
		"row_1": (_rows["row_1"] as Array).duplicate(),
		"row_2": (_rows["row_2"] as Array).duplicate(),
		"row_3": (_rows["row_3"] as Array).duplicate(),
	}

func _build_pick_payload() -> Dictionary:
	return {
		"row_1": (_pick_rows["row_1"] as Array).duplicate(),
		"row_2": (_pick_rows["row_2"] as Array).duplicate(),
		"row_3": (_pick_rows["row_3"] as Array).duplicate(),
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
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		return false
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
	if _submit_pending:
		return true
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		if _pick_submit_pending or _has_current_player_submitted_pick():
			return true
		return not _is_valid_round_pick()
	if _is_setup_locked():
		return true
	if _phase == PHASE_PICK_PLUS:
		return not _is_phase_one_complete()
	return not _is_valid_setup()

func _build_submit_text() -> String:
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		if _pick_submit_pending:
			return "Submitting..."
		if _has_current_player_submitted_pick():
			return "Submitted"
		return "Confirm Round Pick"
	if _submit_pending:
		return "Submitting..."
	if _has_current_player_submitted_setup():
		return "Submitted"
	if _phase == PHASE_PICK_PLUS:
		return "Continue to Phase 2"
	return "Confirm Setup"

func _build_phase_text() -> String:
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		if _has_current_player_submitted_pick():
			return "Round Pick submitted"
		return "Round Pick: choose one cell per row"
	if _has_current_player_submitted_setup():
		return "Character setup submitted"
	if _phase == PHASE_PICK_PLUS:
		return "Phase 1: choose the +1 slot in each row, then submit"
	return "Phase 2: choose the -1 slot from the two remaining cells"

func _build_summary_hint() -> String:
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		if _pick_submit_pending:
			return "Submitting your round pick to the server..."
		if _has_current_player_submitted_pick():
			return "Waiting for the other players to submit their round picks."
		return "Pick one cell in each row for this round."
	if _submit_pending:
		return "Submitting your character setup to the server..."
	if _has_current_player_submitted_setup():
		return "Waiting for the other players to submit their character setups."
	if _phase == PHASE_PICK_PLUS:
		return "Phase 1: each row needs one +1 selection before you continue."
	return "Phase 2: the +1 cells are locked. Pick one -1 from the two remaining cells in each row."

func _build_remaining_text() -> String:
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		if _has_current_player_submitted_pick():
			return _build_pick_submission_status_text()
		return _build_round_pick_status_text()
	if _has_current_player_submitted_setup():
		return _build_submission_status_text()

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

func _build_submission_status_text() -> String:
	var lines: PackedStringArray = ["Submissions:"]
	for player_variant in _get_players():
		var player := player_variant as Dictionary
		var status := "submitted" if bool(player.get("has_submitted_setup", false)) else "waiting"
		lines.append("- %s: %s" % [str(player.get("username", "")), status])
	return "\n".join(lines)

func _build_round_pick_status_text() -> String:
	var parts: PackedStringArray = []
	for row_key in ROW_KEYS:
		var row_values: Array = _pick_rows[row_key]
		var selected_index := _find_value_index(row_values, 1)
		if selected_index >= 0:
			parts.append("%s: picked slot %d" % [_format_row_name(row_key), selected_index + 1])
		else:
			parts.append("%s: choose one slot" % _format_row_name(row_key))
	return "\n".join(parts)

func _build_pick_submission_status_text() -> String:
	var lines: PackedStringArray = ["Round Pick Submissions:"]
	for player_variant in _get_players():
		var player := player_variant as Dictionary
		var status := "submitted" if bool(player.get("has_submitted_pick", false)) else "waiting"
		lines.append("- %s: %s" % [str(player.get("username", "")), status])
	return "\n".join(lines)

func _on_game_state_updated_received(_state: Dictionary) -> void:
	print(
		"Game scene state update user=%s game_phase=%s setup_submitted=%s pick_submitted=%s"
		% [
			AuthManager.auth_username,
			_get_game_phase(),
			str(_has_current_player_submitted_setup()),
			str(_has_current_player_submitted_pick()),
		]
	)
	_submit_pending = false
	_pick_submit_pending = false
	_apply_state_from_game_state()
	_refresh_view()

func _apply_state_from_game_state() -> void:
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		_phase = PHASE_PICK_PLUS
		var pick_matrix: Dictionary = _get_current_player_pick_matrix()
		for row_key in ROW_KEYS:
			var row_values_variant: Variant = pick_matrix.get(row_key, [0, 0, 0])
			if row_values_variant is Array:
				_pick_rows[row_key] = (row_values_variant as Array).duplicate()
		return

	var setup := _get_current_player_setup()
	if setup.is_empty():
		return

	for row_key in ROW_KEYS:
		var row_values_variant: Variant = setup.get(row_key, [0, 0, 0])
		if row_values_variant is Array:
			_rows[row_key] = (row_values_variant as Array).duplicate()

	if _is_valid_setup():
		_phase = PHASE_PICK_MINUS
	else:
		_phase = PHASE_PICK_PLUS

func _get_players() -> Array:
	return SessionFlowManager.game_state.get("players", [])

func _get_game_phase() -> String:
	return str(SessionFlowManager.game_state.get("game_phase", GAME_PHASE_CHARACTER_SETUP)).strip_edges()

func _get_current_player() -> Dictionary:
	var current_username := AuthManager.auth_username.strip_edges()
	for player_variant in _get_players():
		var player := player_variant as Dictionary
		if str(player.get("username", "")).strip_edges() == current_username:
			return player
	return {}

func _get_current_player_setup() -> Dictionary:
	return (_get_current_player().get("character_setup", {}) as Dictionary).duplicate(true)

func _get_current_player_pick_matrix() -> Dictionary:
	return (_get_current_player().get("pick_matrix", {}) as Dictionary).duplicate(true)

func _has_current_player_submitted_setup() -> bool:
	return bool(_get_current_player().get("has_submitted_setup", false))

func _has_current_player_submitted_pick() -> bool:
	return bool(_get_current_player().get("has_submitted_pick", false))

func _is_setup_locked() -> bool:
	return _get_game_phase() == GAME_PHASE_ROUND_PICK or _has_current_player_submitted_setup()

func _is_interaction_locked() -> bool:
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		return _pick_submit_pending or _has_current_player_submitted_pick()
	return _is_setup_locked()

func _build_title_text() -> String:
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		return "Pick Your Round Actions"
	return "Build Your Character"

func _build_hint_text() -> String:
	if _get_game_phase() == GAME_PHASE_ROUND_PICK:
		return "Choose exactly one cell in each row. This round-pick matrix is separate from your character setup."
	return "First choose the +1 cell in each row, then choose the -1 cell from the two remaining spots."
