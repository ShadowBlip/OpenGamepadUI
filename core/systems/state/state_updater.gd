@tool
@icon("res://assets/editor-icons/transition-right.svg")
extends Node
class_name StateUpdater

## Update the state of a state machine when a signal fires
##
## The [StateUpdater] can be added as a child to any node that exposes signals.
## Upon entering the scene tree, the [StateUpdater] connects to a given signal
## on its parent, and will update the configured state machine's state to the
## given state, allowing menus to react to state changes (e.g. changing menus)

const in_game := preload("res://assets/state/states/in_game.tres")

## Possible state actions to take
enum ACTION {
	PUSH, ## Pushes the state on top of the state stack
	POP, ## Removes the state at the top of the state stack
	REPLACE, ## Replaces the state at the top of the state stack
	SET, ## Removes all states and sets the given state
}

## The state machine instance to use for managing state changes
@export var state_machine: StateMachine
## Signal on our parent to connect to. When this signal fires, the [StateUpdater] 
## will change the state machine to the given state.
var on_signal: String
## The state to change to when the given signal is emitted.
@export var state: State
## Whether to push, pop, replace, or set the state when the signal has fired.
@export var action: ACTION = ACTION.PUSH


func _ready() -> void:
	notify_property_list_changed()
	get_parent().connect(on_signal, _on_signal)


func _on_signal(metakey: String = "", metadata: Variant = null):
	# Switch to the given state
	var sm := state_machine as StateMachine
	if metakey != "":
		state.set_meta(metakey, metadata)

	# Manage the state based on the given action
	match action:
		ACTION.PUSH:
			sm.push_state(state)
		ACTION.POP:
			sm.pop_state()
		ACTION.REPLACE:
			sm.replace_state(state)
		ACTION.SET:
			var states := [state] as Array[State]
			# Never get rid of the in-game state if it's running
			if sm.has_state(in_game):
				states.push_front(in_game)
			sm.set_state(states)


# Customize editor properties that we expose. Here we dynamically look up
# the parent node's signals so we can display them in a list.
func _get_property_list():
	# By default, `on_signal` is not visible in the editor.
	var property_usage := PROPERTY_USAGE_NO_EDITOR

	var parent_signals := []
	if get_parent() != null:
		property_usage = PROPERTY_USAGE_DEFAULT
		for sig in get_parent().get_signal_list():
			parent_signals.push_back(sig["name"])

	var properties := []
	(
		properties
		. append(
			{
				"name": "on_signal",
				"type": TYPE_STRING,
				"usage": property_usage,  # See above assignment.
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(parent_signals)
			}
		)
	)

	return properties
