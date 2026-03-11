extends Control


# Lookup for button states
var button_states := {}

func _ready():
	for i in range(1, 10):
		var btn = $MarginContainer/Grid.get_node("Button%d" % i)
		button_states[btn.name] = false
		btn.pressed.connect(func(): _on_button_pressed(btn))

func _on_button_pressed(btn):
	var name = btn.name
	button_states[name] = !button_states[name]
	# Optional: print state for debugging
	print(button_states)
