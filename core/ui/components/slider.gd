@tool
@icon("res://assets/editor-icons/slider.svg")
extends VBoxContainer
class_name ValueSlider

signal drag_ended(value_changed: bool)
signal drag_started()
signal changed()
signal value_changed(value: float)

@export var text: String = "Setting"
@export var show_label := true:
	set(v):
		show_label = v
		if hbox:
			hbox.visible = v
		notify_property_list_changed()

@export var value: float = 0:
	set(v):
		value = v
		if label_value:
			label_value.text = str(v)
		if slider:
			slider.value = v
		value_changed.emit(v)
		notify_property_list_changed()

@export var max_value: float = 100:
	set(v):
		max_value = v
		if slider:
			slider.max_value = v
		notify_property_list_changed()

@export var min_value: float = 0:
	set(v):
		min_value = v
		if slider:
			slider.min_value = v
		notify_property_list_changed()

@export var step: float = 1:
	set(v):
		step = v
		if slider:
			slider.step = v
		notify_property_list_changed()

@export var editable: bool = true:
	set(v):
		editable = v
		if slider:
			slider.editable = v
		notify_property_list_changed()

@export var tick_count := 0
@export var separator_visible: bool = false

@onready var label := $%Label as Label
@onready var label_value := $%LabelValue as Label
@onready var slider := $%HSlider as HSlider
@onready var hbox := $HBoxContainer as HBoxContainer
@onready var hsep := $HSeparator as HSeparator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_grab_focus)
	label.text = text
	label_value.text = str(slider.value)
	hsep.visible = separator_visible
	slider.value_changed.connect(_on_value_changed)
	slider.value = value
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.tick_count = tick_count
	slider.editable = editable
	slider.focus_neighbor_bottom = focus_neighbor_bottom
	slider.focus_neighbor_left = focus_neighbor_left
	slider.focus_neighbor_right = focus_neighbor_right
	slider.focus_neighbor_top = focus_neighbor_top
	slider.focus_previous = focus_previous
	slider.focus_next = focus_next
	
	# Wire up all slider signals
	var on_drag_ended := func(changed: bool):
		drag_ended.emit(changed)
	slider.drag_ended.connect(on_drag_ended)
	var on_drag_started := func():
		drag_started.emit()
	slider.drag_ended.connect(on_drag_started)
	var on_changed := func():
		changed.emit()
	slider.changed.connect(on_changed)

	# Set color based on theme
	theme_changed.connect(_on_theme_changed)
	_on_theme_changed()


func _on_theme_changed() -> void:
	slider.modulate = get_theme_color("color", "Slider")


func _on_value_changed(v: float) -> void:
	value = v


# Override focus grabbing to grab the slider
func _grab_focus() -> void:
	slider.grab_focus()


# Override certain properties and pass them to child objects
func _set(property: StringName, value: Variant) -> bool:
	if not slider:
		return false
	if property.begins_with("focus"):
		slider.set(property, value)
		return false
	return false
