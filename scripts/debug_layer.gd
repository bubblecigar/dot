extends CanvasLayer

@onready var debug_label: Label = $DebugLabel

func _process(_delta: float) -> void:
	var snapshot := StateStore.get_debug_snapshot()
	var keys := snapshot.keys()
	keys.sort()

	var lines: PackedStringArray = ["StateStore"]
	for key in keys:
		lines.append("%s: %s" % [key, var_to_str(snapshot[key])])

	debug_label.text = "\n".join(lines)
