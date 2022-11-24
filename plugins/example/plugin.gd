extends Plugin


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("I'm an example plugin!")
	print("Current state: ", state_manager.current_state())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
