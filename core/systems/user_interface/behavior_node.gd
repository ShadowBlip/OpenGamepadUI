@tool
@icon("res://assets/editor-icons/fluent--brain-circuit-24-filled.svg")
extends Node
class_name BehaviorNode

## Base class for defining signal-based behavior
##
## A [BehaviorNode] is a node that follows a signaling pattern. These nodes can
## be added as a child of any node and can be configured to listen for and react
## to signals from its parent. This can allow developers to attach behaviors
## to nodes in the scene tree from the editor in a compositional way.


## The signal to connect to on this behavior's parent node. This behavior will
## execute whenever this signal is fired.
var on_signal: String:
	set(v):
		on_signal = v
		if Engine.is_editor_hint():
			update_configuration_warnings()

func _init() -> void:
	ready.connect(_on_ready)


## Automatically connect to the configured parent signal on ready
func _on_ready() -> void:
	notify_property_list_changed()
	# Don't run in the editor
	if Engine.is_editor_hint():
		return
	if on_signal != "":
		get_parent().connect(on_signal, _on_signal)


## Invoked whenever the configured parent signal fires. This should be overridden
## in a child class.
func _on_signal(arg1: Variant = null, arg2: Variant = null, arg3: Variant = null, arg4: Variant = null):
	pass


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
	properties.append(
			{
				"name": "on_signal",
				"type": TYPE_STRING,
				"usage": property_usage,  # See above assignment.
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(parent_signals)
			}
	)

	return properties


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if on_signal.is_empty():
		warnings.append("No parent signal selected!")
	return warnings
