@tool
extends Node
class_name FocusSetter

# The node to try and discover the focusable node.
@export var target: Node

# Signal on our parent to connect to
var on_signal: String
var logger := Log.get_logger("FocusSetter", Log.LEVEL.INFO)


func _ready() -> void:
	notify_property_list_changed()
	get_parent().connect(on_signal, _on_signal)


# Fires when the given signal is emitted, recursively look through all children
# of the target node for a Control node with FOCUS_ALL. When we find one, call
# grab focus on the node.
func _on_signal():
	if not target:
		logger.debug("No focus target specified")
		return

	# If the target has 'focus_node' defined, use that.
	if target.get("focus_node"):
		target.focus_node.grab_focus.call_deferred()
		return

	# Otherwise, discover the first focusable node
	var focus_node := _find_focusable([target])
	if not focus_node:
		logger.debug("Unable to find a control node with FOCUS_ALL")
		return
	focus_node.grab_focus.call_deferred()


# Recursively searches the given node children for a focusable node.
func _find_focusable(nodes: Array[Node]) -> Control:
	if nodes.size() == 0:
		return null

	for node in nodes:
		logger.debug("Considering node: " + node.name)
		if node is Control and node.focus_mode == Control.FOCUS_ALL:
			if node.visible:
				return node as Control
		var focusable := _find_focusable(node.get_children())
		if focusable:
			return focusable

	return null


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
