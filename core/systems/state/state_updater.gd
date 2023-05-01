@tool
@icon("res://assets/editor-icons/transition-right.svg")
extends Node
class_name StateUpdater

const in_game := preload("res://assets/state/states/in_game.tres")

# Possible state actions to take
enum ACTION {
	PUSH,
	POP,
	REPLACE,
	SET,
}

# State machine resource to use
@export var state_machine: StateMachine
# Signal on our parent to connect to
var on_signal: String
# The state to change to when the given signal is emitted
@export var state: State
@export var action: ACTION = ACTION.PUSH


func _ready() -> void:
	notify_property_list_changed()
	get_parent().connect(on_signal, _on_signal)


func _on_signal():
	# Switch to the given state
	var sm := state_machine as StateMachine

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
