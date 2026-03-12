extends Button

@export var button_state: bool = false
@export var button_label: String = ""

func _init(label: String = "", state: bool = false, name: String = ""):
	button_label = label
	button_state = state
	if label != "":
		text = label
	if name != "":
		self.name = name
