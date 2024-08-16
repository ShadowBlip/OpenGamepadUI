@icon("res://assets/editor-icons/state-machine.svg")
extends Resource
class_name StateMachine

## Manages the current [State] for some part of the application.
##
## A [StateMachine] is responsible for managing an arbitrary number of [State]
## objects. The [StateMachine] keeps a "stack" of states that can be set, pushed,
## popped, removed, or cleared, and will fire signals for each kind of change.
## This can allow the application to update and respond to different states of
## the [StateMachine].
##
## Only one [State] is considered the "current" state in a [StateMachine]: the
## last state in the stack. A [State] will fire the "entered" signal whenever it
## becomes the "current" state, and fires the "exited" signal whenever it leaves
## the "current" state.
##
## The [StateMachine] takes advantage of the fact that Godot resources are globally
## unique. This allows you to load a [StateMachine] resource from anywhere in the
## project to subscribe to state changes.

## Emitted whenever this [StateMachine] has changed states
signal state_changed(from: State, to: State)

@export var logger_name := "StateMachine"
@export var minimum_states: int = 1

var _state_stack: Array[State] = []
var logger := Log.get_logger(logger_name)


func _init() -> void:
	state_changed.connect(_on_state_changed)


## Emit state changes on the state itself and log state changes
func _on_state_changed(from: State, to: State) -> void:
	var from_str = "<null>"
	var to_str = "<null>"
	if from != null:
		from_str = from.name
	if to != null:
		to_str = to.name
	if logger.get_name() != logger_name:
		logger = Log.get_logger(logger_name)
	logger.info("Switched from state {0} to {1}".format([from_str, to_str]))
	var state_names := PackedStringArray()
	for state in _state_stack:
		state_names.append(state.name)
	logger.info("Stack: " + "-> ".join(state_names))


## Returns the current state at the end of the state stack
func current_state() -> State:
	var length = len(_state_stack)
	if length == 0:
		return null
	return _state_stack[length-1]


## Set state will set the entire state stack to the given array of states
func set_state(new_stack: Array[State]) -> void:
	if null in new_stack:
		logger.warn("Invalid NULL state pushed.")
		return
	var states_added: Array[State] = []
	var states_removed: Array[State] = []
	for state: State in new_stack:
		if not has_state(state):
			states_added.push_back(state)
	for state: State in _state_stack:
		if not state in new_stack:
			states_removed.push_back(state)
	var last_current := current_state()
	_state_stack = new_stack
	var new_current := current_state()
	if last_current != new_current:
		if last_current:
			last_current.state_exited.emit(new_current)
		if new_current:
			new_current.state_entered.emit(last_current)
		state_changed.emit(last_current, new_current)
	for state: State in states_removed:
		state.state_removed.emit()
	for state: State in states_added:
		state.state_added.emit()


## Push state will push the given state to the top of the state stack.
func push_state(state: State) -> void:
	if state == null:
		logger.warn("Invalid NULL state pushed.")
		return
	var current := current_state()
	if state == current:
		return
	var is_new := not has_state(state)
	_push_unique(state)
	if is_new:
		state.state_added.emit()
	if current:
		current.state_exited.emit(state)
	state.state_entered.emit(current)
	state_changed.emit(current, state)


## Pushes the given state to the front of the stack
func push_state_front(state: State) -> void:
	if state == null:
		logger.warn("Invalid NULL state pushed.")
		return
	var is_new := not has_state(state)
	var last_current := current_state()
	_push_front_unique(state)
	var new_current := current_state()
	if is_new:
		state.state_added.emit()
	if last_current != new_current:
		if last_current:
			last_current.state_exited.emit(new_current)
		if new_current:
			new_current.state_entered.emit(last_current)
		state_changed.emit(last_current, new_current)


## Pop state will remove the last state from the stack and return it.
func pop_state() -> State:
	if self.stack_length() > minimum_states:
		var popped := _state_stack.pop_back() as State
		var current := current_state()
		if popped:
			popped.state_exited.emit(current)
			popped.state_removed.emit()
		if current:
			current.state_entered.emit(popped)
		state_changed.emit(popped, current)
		return popped
	return current_state()


## Replaces the current state at the end of the stack with the given state
func replace_state(state: State) -> void:
	if state == null:
		logger.warn("Invalid NULL state pushed.")
		return
	var current := current_state()
	if state == current:
		return
	var is_new := not has_state(state)
	var popped := _state_stack.pop_back() as State
	_push_unique(state)
	if is_new:
		state.state_added.emit()
	if popped:
		popped.state_exited.emit(state)
		popped.state_removed.emit()
	state.state_entered.emit(popped)
	state_changed.emit(popped, state)


## Removes all instances of the given state from the stack
func remove_state(state: State) -> void:
	if not state:
		return
	if not has_state(state):
		return
	var last_current := current_state()
	var new_state_stack: Array[State] = []
	for existing_state: State in _state_stack:
		if state == existing_state:
			continue
		new_state_stack.push_back(existing_state)
	_state_stack = new_state_stack
	if last_current == state:
		state.state_exited.emit(current_state())
	state.state_removed.emit()
	var new_current := current_state()
	if last_current != new_current:
		if new_current:
			new_current.state_entered.emit(last_current)
		state_changed.emit(last_current, new_current)


## Removes all states
func clear_states() -> void:
	var current := current_state()
	if current:
		current.state_exited.emit(null)
	for state: State in _state_stack:
		state.state_removed.emit()
	_state_stack.clear()
	state_changed.emit(current, null)


## Returns the length of the state stack
func stack_length() -> int:
	return len(_state_stack)


## Returns the current state stack
func stack() -> Array[State]:
	return _state_stack.duplicate()


## Returns true if the given state exists anywhere in the state stack
func has_state(state: State) -> bool:
	if _state_stack.find(state) != -1:
		return true
	return false


func _push_unique(state: State) -> void:
	var i := _state_stack.find(state)
	if i >= 0:
		_state_stack.remove_at(i)
	_state_stack.push_back(state)


func _push_front_unique(state: State) -> void:
	var i := _state_stack.find(state)
	if i >= 0:
		_state_stack.remove_at(i)
	_state_stack.push_front(state)
