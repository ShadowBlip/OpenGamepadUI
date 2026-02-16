@icon("res://assets/editor-icons/radix-icons--component-1.svg")
extends Resource
class_name ComponentsMap


enum Type {
	Button,
}

@export_category("Components")
@export var button: PackedScene


## Build a UI component of the given type
func build(component_type: Type) -> Control:
	match component_type:
		Type.Button:
			return button.instantiate()
	return null


## Returns the default user interface
static func default() -> ComponentsMap:
	var components := load("res://core/ui/etoile_ui/etoile_components.tres") as ComponentsMap
	return components
