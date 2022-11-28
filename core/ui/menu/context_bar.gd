extends Control

@onready var state_mgr: StateManager = get_node("/root/Main/StateManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_mgr.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	var stack = []
	for state in state_mgr._state_stack:
		stack.push_back(StateManager.StateMap[state])
	var state_stack = "-> ".join(stack)
	$MarginContainer/HBoxContainer/DebugLabel.text = state_stack



func _on_state_changed(from: int, to: int, _data: Dictionary):
	var stack = []
	for state in state_mgr._state_stack:
		stack.push_back(StateManager.StateMap[state])
	var state_stack = "-> ".join(stack)
	print(state_stack)
