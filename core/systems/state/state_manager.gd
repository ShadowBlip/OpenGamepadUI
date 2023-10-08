# StateManager is responsible for managing the states for different components.
# It is implemented as a state machine with a stack of states that you can
# push to and pop.
@icon("res://assets/icons/log-in.svg")
extends Node
class_name StateManager

enum STATE {
	NONE,
	HOME,
	MAIN_MENU,
	QUICK_BAR_MENU,
	LIBRARY,
	STORE,
	IN_GAME,
	IN_GAME_MENU,
	GAME_LAUNCHER,
	SETTINGS,
	OSK,
	QUICK_BAR_BUTTON_SUBMENU,
}

const StateMap = {
	STATE.NONE: "",
	STATE.HOME: "home",
	STATE.MAIN_MENU: "main_menu",
	STATE.QUICK_BAR_MENU: "quick_bar_menu",
	STATE.LIBRARY: "library",
	STATE.STORE: "store",
	STATE.IN_GAME: "in-game",
	STATE.IN_GAME_MENU: "in-game_menu",
	STATE.GAME_LAUNCHER: "game_launcher_menu",
	STATE.SETTINGS: "settings_menu",
	STATE.OSK: "osk",
	STATE.QUICK_BAR_BUTTON_SUBMENU: "quick_bar_button_submenu",
}

signal state_changed(from: int, to: int, data: Dictionary)

@export var starting_state: STATE = STATE.HOME
var _state_stack: Array = [STATE.NONE]
var logger := Log.get_logger("StateManager")


func _ready() -> void:
	state_changed.connect(_on_state_changed)
	push_state(starting_state)


func _on_state_changed(from: int, to: int, _data: Dictionary) -> void:
	# Always switch to home if we end up with no state
	if to == STATE.NONE:
		push_state(starting_state)
	var from_str = StateManager.StateMap[from]
	var to_str = StateManager.StateMap[from]
	logger.info("Switched from state {0} to {1}".format([from_str, to_str]))


# Set state will set the entire state stack to the given array of states
func set_state(stack: Array, data: Dictionary = {}):
	var cur = current_state()
	_state_stack = stack
	state_changed.emit(cur, stack[-1], data)


# Push state will push the given state to the top of the state stack. You can
# optionally pass 'unique' to allow/disallow duplicate states in the stack.
func push_state(state: int, unique: bool = true, data: Dictionary = {}):
	var cur = current_state()
	if unique:
		_push_unique(state)
	else:
		_state_stack.push_back(state)
	state_changed.emit(cur, state, data)
	

# Pushes the given state to the front of the stack
func push_state_front(state: int, data: Dictionary = {}):
	var cur = current_state()
	_state_stack.push_front(state)
	state_changed.emit(cur, current_state(), data)


# Pop state will remove the last state from the stack and return it.
func pop_state(data: Dictionary = {}) -> int:
	var popped = _state_stack.pop_back()
	var cur = current_state()
	state_changed.emit(popped, cur, data)
	return popped
	
	
# Replaces the current state at the end of the stack with the given state
func replace_state(state: int, unique: bool = true, data: Dictionary = {}):
	var popped = _state_stack.pop_back()
	if unique:
		_push_unique(state)
	else:
		_state_stack.push_back(state)
	state_changed.emit(popped, state, data)


# Removes all instances of the given state from the stack
func remove_state(state: int, data: Dictionary = {}):
	var cur = current_state()
	var new_state_stack = []
	for i in range(0, len(_state_stack)):
		var s = _state_stack[i]
		if state != s:
			new_state_stack.push_back(s)
	_state_stack = new_state_stack
	state_changed.emit(cur, current_state(), data)


# Returns the current state at the end of the state stack
func current_state() -> int:
	var length = len(_state_stack)
	if length == 0:
		return STATE.NONE
	return _state_stack[len(_state_stack)-1]


# Returns the length of the state stack
func stack_length() -> int:
	return len(_state_stack)


# Returns true if the given state exists anywhere in the state stack
func has_state(state: int) -> bool:
	if _state_stack.find(state) != -1:
		return true
	return false


func _push_unique(state: int):
	var i = _state_stack.find(state)
	if i >= 0:
		_state_stack.remove_at(i)
	_state_stack.push_back(state)
	
