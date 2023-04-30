@tool
@icon("res://assets/editor-icons/center-focus-strong-sharp.svg")
extends Node
class_name FocusGroupSetter

@export_category("Focus")
## The focus group to grab focus on when the given signal is emitted
@export var target: FocusGroup

# Signal on our parent to connect to
var on_signal: String
var logger := Log.get_logger("FocusGroupSetter", Log.LEVEL.DEBUG)


func _ready() -> void:
	notify_property_list_changed()
	get_parent().connect(on_signal, _on_signal)


# Fires when the given signal is emitted, recursively look through all children
# of the target node for a Control node with FOCUS_ALL. When we find one, call
# grab focus on the node.
func _on_signal():
	if not target:
		logger.warn("No focus group target specified")
		return

	target.grab_focus()


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
