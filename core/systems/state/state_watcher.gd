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
signal state_added
signal state_refreshed

## Fire signals when this state is switched to
@export var state: State


func _ready() -> void:
	assert(state != null)
	var on_entered := func(_from: State):
		state_entered.emit()
	state.state_entered.connect(on_entered)
	var on_exited := func(_to: State):
		state_exited.emit()
	state.state_exited.connect(on_exited)
	var on_removed := func():
		state_removed.emit()
	state.state_removed.connect(on_removed)
	var on_added := func():
		state_added.emit()
	state.state_added.connect(on_added)
	var on_refresh := func():
		state_refreshed.emit()
	state.refreshed.connect(on_refresh)
