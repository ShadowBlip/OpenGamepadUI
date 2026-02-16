@abstract
@icon("res://assets/editor-icons/icon-park-twotone--figma-component.svg")
extends MarginContainer
class_name Component

## User interface component
##
## Base building block of user interface elements. Plugins should use these components
## in any scenes they provide to ensure consistent look across different user interfaces.

## Child implementation of the component. This should be an instantiated scene defined
## by a specific user interface.
var implementation: Control


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	var on_ready := func() -> void:
		if not implementation:
			return
		focus_mode = implementation.focus_mode
		focus_entered.connect(_on_focus_entered)
	ready.connect(on_ready)


func _on_focus_entered() -> void:
	implementation.grab_focus()


## Connect the given signal function on the child implementation
func _connect_implementation_signal(signal_name: StringName, callable: Callable, flags: int = 0) -> void:
	if not implementation.has_signal(signal_name):
		return
	implementation.connect(signal_name, callable, flags)


## Set the given property value on the child implementation
func _set_implementation_property(property: StringName, value: Variant) -> void:
	if not implementation:
		return
	if not property in implementation:
		return
	@warning_ignore("unsafe_property_access")
	implementation.set(property, value)


## Returns the detected user interface
func get_component_map() -> ComponentsMap:
	var nodes := get_tree().get_nodes_in_group("main")
	var main: Control
	for node in nodes:
		if not "components_map" in node:
			continue
		main = node
	if not main:
		return ComponentsMap.default()
	return main.get("components_map")
