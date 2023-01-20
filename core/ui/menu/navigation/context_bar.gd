extends Control

var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var logger := Log.get_logger("ContextBar")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	var stack = []
	for s in state_machine._state_stack:
		var state := s as State
		stack.push_back(state.name)
	var state_stack = "-> ".join(stack)
	$MarginContainer/HBoxContainer/DebugLabel.text = state_stack


func _on_state_changed(from: State, to: State):
	var stack = []
	for s in state_machine._state_stack:
		var state := s as State
		stack.push_back(state.name)
	var state_stack = "-> ".join(stack)
	logger.debug(state_stack)
