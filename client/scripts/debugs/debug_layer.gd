extends CanvasLayer

@onready var debug_label: Label = $DebugLabel
var _latest_random_number: String = "N/A"

func _ready() -> void:
	ClientRpc.random_number_received.connect(_on_random_number_received)

	if not OS.is_debug_build():
		visible = false
		set_process(false)

func _process(_delta: float) -> void:
	var snapshot := StateStore.get_debug_snapshot()
	var keys := snapshot.keys()
	keys.sort()

	var lines: PackedStringArray = [
		"StateStore",
		"server_random_number: %s" % _latest_random_number,
	]
	for key in keys:
		lines.append("%s: %s" % [key, var_to_str(snapshot[key])])

	debug_label.text = "\n".join(lines)

func _on_random_number_received(value: int) -> void:
	_latest_random_number = str(value)
