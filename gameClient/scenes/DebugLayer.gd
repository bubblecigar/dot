extends CanvasLayer

@onready var debug_label: Label = $DebugLabel
var _latest_random_number: String = "N/A"

func _ready() -> void:
	ClientRpc.random_number_received.connect(_on_random_number_received)

	if not OS.is_debug_build():
		visible = false
		set_process(false)

func _process(_delta: float) -> void:
	var snapshot := SessionFlowManager.get_debug_snapshot()
	var keys := snapshot.keys()
	keys.sort()
	var current_scene := SceneManager.get_current_scene()
	var current_scene_name := "None"
	if current_scene != null:
		current_scene_name = "%s (%s)" % [current_scene.name, current_scene.scene_file_path]

	var lines: PackedStringArray = [
		"SessionFlowManager",
		"server_random_number: %s" % _latest_random_number,
		"current_scene: %s" % current_scene_name,
	]
	for key in keys:
		lines.append("%s: %s" % [key, var_to_str(snapshot[key])])

	debug_label.text = "\n".join(lines)

func _on_random_number_received(value: int) -> void:
	_latest_random_number = str(value)
