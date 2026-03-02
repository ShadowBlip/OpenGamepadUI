@icon("res://assets/editor-icons/slider.svg")
@tool
extends Component
class_name ComponentSlider

signal drag_ended(value_changed: bool)
signal drag_started()
signal changed()
signal value_changed(value: float)

@export var text: String:
	set(v):
		text = v
		_set_implementation_property("text", v)
@export var description: String:
	set(v):
		description = v
		_set_implementation_property("description", v)
@export var value: float = 0:
	set(v):
		value = v
		_set_implementation_property("value", v)
@export var value_unit: String:
	set(v):
		value_unit = v
		_set_implementation_property("value_unit", v)
@export var max_value: float = 100:
	set(v):
		max_value = v
		_set_implementation_property("max_value", v)
@export var min_value: float = 0:
	set(v):
		min_value = v
		_set_implementation_property("min_value", v)
@export var step: float = 1:
	set(v):
		step = v
		_set_implementation_property("step", v)
@export var editable: bool = true:
	set(v):
		editable = v
		_set_implementation_property("editable", v)
@export var show_label: bool = true:
	set(v):
		show_label = v
		_set_implementation_property("show_label", v)
@export var show_decimal: bool = false:
	set(v):
		show_decimal = v
		_set_implementation_property("show_decimal", v)
@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		_set_implementation_property("icon_texture", v)
@export var tick_count := 0:
	set(v):
		tick_count = v
		_set_implementation_property("tick_count", v)


func _ready() -> void:
	var components := get_component_map()
	if Engine.is_editor_hint():
		components = load("res://core/ui/etoile_ui/etoile_components.tres")
	else:
		assert(components != null, "Unable to detect user interface to build component")
	implementation = components.build(ComponentsMap.Type.Slider)
	_connect_implementation_signal("drag_ended", _on_drag_ended)
	_connect_implementation_signal("drag_started", _on_drag_started)
	_connect_implementation_signal("changed", _on_changed)
	_connect_implementation_signal("value_changed", _on_value_changed)
	text = text
	description = description
	value = value
	value_unit = value_unit
	max_value = max_value
	min_value = min_value
	step = step
	editable = editable
	show_label = show_label
	show_decimal = show_decimal
	icon_texture = icon_texture
	tick_count = tick_count
	add_child(implementation)


func _on_drag_ended(v: bool) -> void:
	drag_ended.emit(v)


func _on_drag_started() -> void:
	drag_started.emit()


func _on_changed() -> void:
	changed.emit()


func _on_value_changed(v: float) -> void:
	value_changed.emit(v)
