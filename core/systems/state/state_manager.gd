extends Node
class_name StateManager

enum State {
	NONE,
	HOME,
	MAIN_MENU,
	QUICK_ACCESS_MENU,
	LIBRARY,
	IN_GAME,
	IN_GAME_MENU,
}

const StateMap = {
	State.NONE: "",
	State.HOME: "home",
	State.MAIN_MENU: "main_menu",
	State.QUICK_ACCESS_MENU: "quick_access_menu",
	State.LIBRARY: "library",
	State.IN_GAME: "in-game",
	State.IN_GAME_MENU: "in-game_menu",
}

signal state_changed(from: State, to: State)

@export var starting_state: State = State.HOME
var _state_stack: Array = [State.NONE]

func _ready() -> void:
	state_changed.connect(_on_state_changed)
	push_state(starting_state)

func _on_state_changed(from: int, to: int) -> void:
	# Always switch to home if we end up with no state
	if to == State.NONE:
		push_state(starting_state)

func set_state(stack: Array):
	var cur = current_state()
	_state_stack = stack
	state_changed.emit(cur, stack[-1])

func push_state(state: int, unique: bool = true):
	var cur = current_state()
	if unique:
		_push_unique(state)
	else:
		_state_stack.push_back(state)
	state_changed.emit(cur, state)
	
func pop_state() -> int:
	var popped = _state_stack.pop_back()
	var cur = current_state()
	state_changed.emit(popped, cur)
	return popped
	
# Replaces the current state with the given state
func replace_state(state: int, unique: bool = true):
	var popped = _state_stack.pop_back()
	if unique:
		_push_unique(state)
	else:
		_state_stack.push_back(state)
	state_changed.emit(popped, state)

# Removes all instances of the given state from the stack
func remove_state(state: int):
	var cur = current_state()
	var new_state_stack = []
	for i in range(0, len(_state_stack)):
		var s = _state_stack[i]
		if state != s:
			new_state_stack.push_back(s)
	_state_stack = new_state_stack
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
	
func _push_unique(state: int):
	var i = _state_stack.find(state)
	if i >= 0:
		_state_stack.remove_at(i)
	_state_stack.push_back(state)
	
