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
		var btn = ButtonScene.instantiate()
		btn.name = "Button%d" % i
		btn.text = "Button %d" % i
		btn.size_flags_horizontal = 3
		btn.size_flags_vertical = 3
		button_states[btn.name] = false
		btn.pressed.connect(func(): _on_button_pressed(btn))
		grid.add_child(btn)

func _on_button_pressed(btn):
	var name = btn.name
	button_states[name] = !button_states[name]
	# Optional: print state for debugging
	print(button_states)
