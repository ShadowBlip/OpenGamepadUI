# https://www.reddit.com/r/godot/comments/vodp2a/comment/iegv4fs/?utm_source=reddit&utm_medium=web2x&context=3
# The state machine takes advantage of the fact that resources are globally unique.
# This allows you to load a state machine resource from anywhere to subscribe to
# state changes.
@icon("res://assets/icons/log-in.svg")
extends Resource
class_name StateMachine

signal state_changed(from: StateMachineState, to: StateMachineState)

@export var starting_state: StateMachineState = StateMachineState.new()
@export var logger_name := "StateMachine"
var _state_stack: Array[StateMachineState] = []
var logger := Log.get_logger(logger_name)


func _init() -> void:
	state_changed.connect(_on_state_changed)


# Emit state changes on the state itself and log state changes
func _on_state_changed(from: StateMachineState, to: StateMachineState) -> void:
	var from_str = "<null>"
	var to_str = "<null>"
	if from != null:
		from_str = from.name
		from.state_exited.emit()
	if to != null:
		to_str = to.name
		to.state_entered.emit()
	logger.info("Switched from state {0} to {1}".format([from_str, to_str]))


# Returns the current state at the end of the state stack
func current_state() -> StateMachineState:
	var length = len(_state_stack)
	if length == 0:
		return null
	return _state_stack[length-1]


# Set state will set the entire state stack to the given array of states
func set_state(stack: Array) -> void:
	var cur := current_state()
	_state_stack = stack
	state_changed.emit(cur, stack[-1])


# Push state will push the given state to the top of the state stack. 
func push_state(state: StateMachineState) -> void:
	var cur := current_state()
	_push_unique(state)
	state_changed.emit(cur, state)


# Pushes the given state to the front of the stack
func push_state_front(state: StateMachineState) -> void:
	var cur = current_state()
	_state_stack.push_front(state)
	state_changed.emit(cur, current_state())


# Pop state will remove the last state from the stack and return it.
func pop_state() -> StateMachineState:
	var popped = _state_stack.pop_back()
	var cur = current_state()
	state_changed.emit(popped, cur)
	return popped


# Replaces the current state at the end of the stack with the given state
func replace_state(state: StateMachineState) -> void:
	var popped := _state_stack.pop_back()
	_push_unique(state)
	state_changed.emit(popped, state)


# Removes all instances of the given state from the stack
func remove_state(state: StateMachineState, data: Dictionary = {}) -> void:
	var cur := current_state()
	var new_state_stack := []
	for i in range(0, len(_state_stack)):
		var s := _state_stack[i]
		if state != s:
			new_state_stack.push_back(s)
	_state_stack = new_state_stack
	state_changed.emit(cur, current_state(), data)


# Returns the length of the state stack
func stack_length() -> int:
	return len(_state_stack)


# Returns true if the given state exists anywhere in the state stack
func has_state(state: StateMachineState) -> bool:
	if _state_stack.find(state) != -1:
		return true
	return false


func _push_unique(state: StateMachineState) -> void:
	var i = _state_stack.find(state)
	if i >= 0:
		_state_stack.remove_at(i)
	_state_stack.push_back(state)

