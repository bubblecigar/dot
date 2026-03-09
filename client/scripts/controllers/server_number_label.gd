extends Label

func _ready() -> void:
	text = "Waiting for server number..."
	ClientRpc.random_number_received.connect(_on_random_number_received)

func _on_random_number_received(value: int) -> void:
	text = str(value)
