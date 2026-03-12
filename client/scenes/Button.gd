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

func _ready():
	pressed.connect(_on_button_pressed)

func _on_button_pressed():
	button_state = !button_state
	print("%s pressed, state: %s" % [name, button_state])
