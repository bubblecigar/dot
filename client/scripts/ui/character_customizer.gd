extends Control


# Lookup for button states
var button_states := {}

func _ready():
	var grid = $MarginContainer/Grid
	# Remove all children from the grid
	for child in grid.get_children():
		child.queue_free()
	var ButtonScene = preload("res://client/scenes/Button.tscn")
	for i in range(1, 10):
		var label = "Button %d" % i
		var name = "Button%d" % i
		var state = false
		var btn = ButtonScene.instantiate()
		btn.button_label = label
		btn.button_state = state
		btn.name = name
		btn.text = label
		btn.size_flags_horizontal = 3
		btn.size_flags_vertical = 3
		button_states[btn.name] = state
		btn.pressed.connect(func(): _on_button_pressed(btn))
		grid.add_child(btn)

func _on_button_pressed(btn):
	var name = btn.name
	button_states[name] = !button_states[name]
	# Optional: print state for debugging
	print(button_states)
