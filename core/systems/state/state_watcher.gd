@icon("res://assets/editor-icons/visible.svg")
extends Node
class_name StateWatcher

## Fires signals based on [State] changes to a [StateMachine]
##
## The [StateWatcher] fires signals based on the current [State] of a 
## [StateMachine]. This enables other nodes to react to state changes.

signal state_entered
signal state_exited
signal state_removed

## Fire signals when this state is switched to
@export var state: State


func _ready() -> void:
	assert(state != null)
	var on_entered := func(from: State):
		state_entered.emit()
	state.state_entered.connect(on_entered)
	var on_exited := func(to: State):
		state_exited.emit()
	state.state_exited.connect(on_exited)
	var on_removed := func():
		state_removed.emit()
	state.state_removed.connect(on_removed)
