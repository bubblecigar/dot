extends Node

signal scene_change_started(path: String)
signal scene_change_progress(path: String, progress: float)
signal scene_changed(path: String)
signal scene_change_failed(path: String, reason: String)

var _container: Node = null
var _current_scene: Node = null
var _loading_path: String = ""
var _is_changing: bool = false

var _transition_layer: CanvasLayer = null
var _transition_rect: ColorRect = null

func initialize(container: Node) -> void:
	_container = container
	if _transition_layer == null:
		_setup_transition_layer()

func get_current_scene() -> Node:
	return _current_scene

func change_scene(path: String, with_transition: bool = true) -> void:
	if _is_changing:
		return
	if _container == null:
		scene_change_failed.emit(path, "SceneManager is not initialized")
		return
	if path.is_empty():
		scene_change_failed.emit(path, "Empty scene path")
		return

	_is_changing = true
	_loading_path = path
	scene_change_started.emit(path)
	_change_scene_async(path, with_transition)

func _change_scene_async(path: String, with_transition: bool) -> void:
	if with_transition:
		await _fade_to_black()

	var request_err := ResourceLoader.load_threaded_request(path)
	if request_err != OK:
		_fail_change(path, "load_threaded_request failed: %d" % request_err)
		return

	while true:
		var progress: Array = []
		var load_status := ResourceLoader.load_threaded_get_status(path, progress)
		if progress.size() > 0:
			scene_change_progress.emit(path, float(progress[0]))

		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail_change(path, "threaded load failed")
			return

		await get_tree().process_frame

	var packed_scene := ResourceLoader.load_threaded_get(path) as PackedScene
	if packed_scene == null:
		_fail_change(path, "loaded resource is not a PackedScene")
		return

	var next_scene := packed_scene.instantiate()
	if next_scene == null:
		_fail_change(path, "instantiate failed")
		return

	if _current_scene != null:
		_current_scene.queue_free()
		_current_scene = null

	_container.add_child(next_scene)
	_current_scene = next_scene

	if with_transition:
		await _fade_from_black()

	_loading_path = ""
	_is_changing = false
	scene_changed.emit(path)

func _fail_change(path: String, reason: String) -> void:
	_loading_path = ""
	_is_changing = false
	scene_change_failed.emit(path, reason)
	if _transition_rect != null:
		_transition_rect.modulate.a = 0.0

func _setup_transition_layer() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 128

	_transition_rect = ColorRect.new()
	_transition_rect.name = "SceneTransition"
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.color = Color.BLACK
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.modulate.a = 0.0

	_transition_layer.add_child(_transition_rect)
	get_tree().root.add_child.call_deferred(_transition_layer)

func _fade_to_black(duration: float = 0.2) -> void:
	if _transition_rect == null:
		return
	var tween := get_tree().create_tween()
	tween.tween_property(_transition_rect, "modulate:a", 1.0, duration)
	await tween.finished

func _fade_from_black(duration: float = 0.2) -> void:
	if _transition_rect == null:
		return
	var tween := get_tree().create_tween()
	tween.tween_property(_transition_rect, "modulate:a", 0.0, duration)
	await tween.finished
