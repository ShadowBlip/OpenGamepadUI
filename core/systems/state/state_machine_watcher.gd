@tool
@icon("res://assets/editor-icons/visible.svg")
extends Node
class_name StateMachineWatcher

## Fires signals based on [StateMachine] changes
##
## The [StateMachineWatcher] fires signals based changes to the given
## [StateMachine]. This enables other nodes to react to state changes.

## Emitted when the configured [StateMachine] changes states
signal state_changed(to: State, from: State)
## Emitted when the configured [StateMachine] no longer has any [State] objects
## in its stack
signal emptied

## Fire signals when this state machine changes
@export var state_machine: StateMachine:
	set(v):
		state_machine = v
		if Engine.is_editor_hint():
			update_configuration_warnings()


func _ready() -> void:
	if not state_machine:
		return
	if Engine.is_editor_hint():
		return
	var on_changed := func(from: State, to: State):
		state_changed.emit(from, to)
	state_machine.state_changed.connect(on_changed)
	var on_emptied := func():
		emptied.emit()
	state_machine.emptied.connect(on_emptied)


func _get_configuration_warnings() -> PackedStringArray:
	if not state_machine:
		return ["No state machine configured!"]
	return []
