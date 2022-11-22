extends Node
class_name StateManager

enum State {
	NONE,
	HOME,
	IN_GAME,
}

signal state_changed(from: State, to: State)

@export var starting_state: State = State.HOME
var _state_stack: Array = []

func _ready() -> void:
	push_state(starting_state)

func push_state(state: int):
	var cur = current_state()
	_state_stack.push_back(state)
	state_changed.emit(cur, state)
	
func pop_state() -> int:
	var popped = _state_stack.pop_back()
	var cur = current_state()
	state_changed.emit(popped, cur)
	return popped

# Removes all instances of the given state from the stack
func remove_state(state: int):
	var cur = current_state()
	for i in range(0, len(_state_stack)-1):
		var s = _state_stack[i]
		if state != s:
			continue
		_state_stack.remove_at(i)
	if cur == state:
		state_changed.emit(cur, current_state())
	
func current_state() -> int:
	var length = len(_state_stack)
	if length == 0:
		return State.NONE
	return _state_stack[len(_state_stack)-1]
	
func has_state(state: int) -> bool:
	if _state_stack.find(state) != -1:
		return true
	return false
