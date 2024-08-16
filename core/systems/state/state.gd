@icon("res://assets/editor-icons/circle-dot-filled.svg")
extends Resource
class_name State

## Object for tracking the current state of a [StateMachine]
##
## A [State] represents some state of the application, such as the currently
## focused menu. Together with a [StateMachine], a [State] can be used to listen
## for signals whenever the state of the application changes.
##
## A [State] takes advantage of the fact that Godot resources are globally
## unique. This allows you to load a [State] resource from anywhere in the project
## to subscribe to state changes.

## Emitted whenever a [StateMachine] has set this [State] as the current state.
## The "from" [State] will be populated with the last [State] the [StateMachine]
## was in.
signal state_entered(from: State)
## Emitted whenever a [StateMachine] has left this [State]. The "to" [State] will
## be populated with the new current [State] of the [StateMachine].
signal state_exited(to: State)
## Emitted whenever a [StateMachine] has added this [State] to its state stack.
signal state_added
## Emitted whenever a [StateMachine] has removed this [State] from its state stack.
signal state_removed

## Optional human-readable name for the state
@export var name: String
## DEPRECATED: Use 'set_meta()' or 'get_meta()' instead
@export var data: Dictionary


func _to_string() -> String:
	if not name.is_empty():
		return "<State:{name}>".format({"name": name})
	return "<State:{rid}>".format({"rid": get_rid()})

