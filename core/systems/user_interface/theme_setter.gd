@tool
@icon("res://assets/editor-icons/paintbrush-2.svg")
extends Node
class_name ThemeSetter

@export var node_group := "main"
@export var theme: Theme

# Signal on our parent to connect to
var on_signal: String


func _init() -> void:
	ready.connect(_on_ready)


func _on_ready() -> void:
	notify_property_list_changed()
	if on_signal != "":
		get_parent().connect(on_signal, _on_signal)


## Fires when the given signal is emitted.
func _on_signal():
	var node := get_tree().get_first_node_in_group(node_group)
	if not node:
		return
	if not node is Control:
		return
	(node as Control).theme = theme


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
