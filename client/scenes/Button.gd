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
	_update_color()

func _on_button_pressed():
	button_state = !button_state
	_update_color()
	print("%s pressed, state: %s" % [name, button_state])

func _update_color():
	if button_state:
		modulate = Color(0.3, 0.7, 1) # blue
	else:
		modulate = Color(1, 1, 1) # default
