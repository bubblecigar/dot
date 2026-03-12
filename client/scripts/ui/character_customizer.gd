extends Control




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
		grid.add_child(btn)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		var grid = $MarginContainer/Grid
		var status = {}
		for btn in grid.get_children():
			status[btn.name] = btn.button_state
		print("Button states:", status)
		var ClientRpc = get_node_or_null("/root/ClientRpc")
		if ClientRpc:
			ClientRpc.submit_button_states.rpc(status)
		else:
			print("[ERROR] /root/ClientRpc not found. Button states not sent to server.")

