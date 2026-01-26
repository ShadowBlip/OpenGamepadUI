@icon("res://assets/editor-icons/radix-icons--component-1.svg")
@tool
extends Resource
class_name ComponentsMap


enum Type {
	Button,
	Slider,
}

@export_category("Components")
@export var button: PackedScene
@export var slider: PackedScene


## Build a UI component of the given type
func build(component_type: Type) -> Control:
	match component_type:
		Type.Button:
			return button.instantiate()
		Type.Slider:
			return slider.instantiate()
	return null


## Returns the default user interface
static func default() -> ComponentsMap:
	var components := load("res://core/ui/etoile_ui/etoile_components.tres") as ComponentsMap
	return components
