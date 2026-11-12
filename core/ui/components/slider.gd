@tool
@icon("res://assets/editor-icons/slider.svg")
extends VBoxContainer
class_name ValueSlider

signal drag_ended(value_changed: bool)
signal drag_started()
signal changed()
signal value_changed(value: float)

@export var text: String = "Setting":
	set(v):
		text = v
		if not label:
			return
		label.text = text
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
			label_value.text = _get_value_str()
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

@export var show_decimal: bool = false:
	set(v):
		show_decimal = v
		value = value
		notify_property_list_changed()

@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		if not icon:
			return
		icon.texture = v
		slider_icon.texture = v
		icon.visible = icon_texture != null
		slider_icon.visible = not show_label and icon_texture != null

@export var slider_icon_texture: Texture2D:
	set(v):
		slider_icon_texture = v
		if not slider_icon:
			return
		slider_icon.texture = slider_icon_texture
		slider_icon.visible = slider_icon_texture != null

@export var tick_count := 0:
	set(v):
		tick_count = v
		if not slider:
			return
		slider.tick_count = v
@export var separator_visible: bool = false:
	set(v):
		separator_visible = v
		if not hsep:
			return
		hsep.visible = v

@onready var label := $%Label as Label
@onready var label_value := $%LabelValue as Label
@onready var slider := $%HSlider as HSlider
@onready var hbox := $HBoxContainer as HBoxContainer
@onready var hsep := $HSeparator as HSeparator
@onready var icon := %Icon as TextureRect
@onready var slider_icon := %SliderIcon as TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_grab_focus)
	text = text
	show_label = show_label
	separator_visible = separator_visible
	value = value
	min_value = min_value
	max_value = max_value
	step = step
	tick_count = tick_count
	editable = editable
	slider.focus_neighbor_bottom = focus_neighbor_bottom
	slider.focus_neighbor_left = focus_neighbor_left
	slider.focus_neighbor_right = focus_neighbor_right
	slider.focus_neighbor_top = focus_neighbor_top
	slider.focus_previous = focus_previous
	slider.focus_next = focus_next
	slider.value_changed.connect(_on_value_changed)

	# Wire up all slider signals
	var on_drag_ended := func(changed_value: bool):
		drag_ended.emit(changed_value)
	slider.drag_ended.connect(on_drag_ended)
	var on_drag_started := func():
		drag_started.emit()
	slider.drag_ended.connect(on_drag_started)
	var on_changed := func():
		label_value.text = _get_value_str()
		changed.emit()
	slider.changed.connect(on_changed)

	# Set color based on theme
	theme_changed.connect(_on_theme_changed)

	# Find the parent theme and update if required
	var effective_theme := ThemeUtils.get_effective_theme(self)
	if effective_theme:
		_on_theme_changed()


func _on_theme_changed() -> void:
	slider.modulate = get_theme_color("color", "Slider")


func _on_value_changed(v: float) -> void:
	value = v


# Override focus grabbing to grab the slider
func _grab_focus() -> void:
	slider.grab_focus()


# Get the current value as a string
func _get_value_str() -> String:
	if show_decimal:
		return str(slider.value)
	else:
		return str(int(slider.value))


# Override certain properties and pass them to child objects
func _set(property: StringName, prop_value: Variant) -> bool:
	if not slider:
		return false
	if property.begins_with("focus"):
		slider.set(property, prop_value)
		return false
	return false
