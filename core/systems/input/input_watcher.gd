@tool
@icon("res://assets/editor-icons/game-icons--button-finger.svg")
extends Node
class_name InputWatcher

## Fires signals based on configured input events
##
## The [InputWatcher] fires signals based on detected input events.
## This enables other nodes to react to inputs through signals in the editor.

## Emitted when the configured input is pressed
signal input_pressed
## Emitted when the configured input is released
signal input_released

## If true, consumes the event, marking it as handled so no other nodes
## try to handle this input event.
@export var stop_propagation: bool
## Always process inputs or only when parent node is visible
@export_flags("When visible", "When child focused") var process_input_mode: int = 3

## Name of the input action in the InputMap to watch for
var action: String

@onready var logger := Log.get_logger("InputWatcher", Log.LEVEL.INFO)


func _ready() -> void:
	if action.is_empty():
		set_process_input(false)

	if process_input_mode == 0:
		return

	# Only process input if the parent node is visible
	var parent := get_parent()
	if parent is Control:
		var control := parent as Control
		var on_visibility := func():
			set_process_input(control.is_visible_in_tree())
		control.visibility_changed.connect(on_visibility)
		set_process_input(control.is_visible_in_tree())


func _input(event: InputEvent) -> void:
	if not event.is_action(action):
		return

	# Only process input if a child node has focus
	if (process_input_mode & 2):
		var focus_owner := get_viewport().gui_get_focus_owner()
		var parent := get_parent()
		if not parent.is_ancestor_of(focus_owner):
			return

	if event.is_pressed():
		input_pressed.emit()
	elif event.is_released():
		input_released.emit()

	# Stop the event from propagating
	if stop_propagation:
		var parent := get_parent()
		logger.debug("Consuming input event '{action}' for node {n}".format({"action": action, "n": str(parent)}))
		get_viewport().set_input_as_handled()


# Customize editor properties that we expose. Here we dynamically look up
# the input actions from the InputMap.
func _get_property_list():
	# By default, event` is not visible in the editor.
	var property_usage := PROPERTY_USAGE_DEFAULT
	InputMap.load_from_project_settings()
	var actions := InputMap.get_actions()
	var properties := []
	properties.append(
			{
				"name": "action",
				"type": TYPE_STRING,
				"usage": property_usage,  # See above assignment.
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(actions)
			}
	)

	return properties
