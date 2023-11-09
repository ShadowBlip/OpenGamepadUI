@tool
@icon("res://assets/editor-icons/twotone-toggle-off.svg")
extends BoxContainer
class_name Toggle

signal button_down
signal button_up
signal pressed
signal toggled(pressed: bool)

@export_category("Label Settings")
@export var text: String = "Setting"
@export var separator_visible: bool = false
@export var show_label := true:
	set(v):
		show_label = v
		if label:
			label.visible = v
		notify_property_list_changed()
@export var description: String = "":
	set(v):
		description = v
		if description_label:
			description_label.text = v
			description_label.visible = v != ""

@export_category("Toggle Settings")
@export var button_pressed := false:
	get:
		if check_button:
			return check_button.button_pressed
		return button_pressed
	set(v):
		button_pressed = v
		if check_button:
			check_button.button_pressed = v
		notify_property_list_changed()

@export var disabled := false:
	set(v):
		disabled = v
		if check_button:
			check_button.disabled = v
		notify_property_list_changed()

@onready var label := $%Label as Label
@onready var description_label := $%DescriptionLabel as Label
@onready var check_button := $%CheckButton as CheckButton
@onready var hsep := $HSeparator as HSeparator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_grab_focus)
	
	label.text = text
	description_label.text = description
	description_label.visible = description != ""
	hsep.visible = separator_visible
	check_button.button_pressed = button_pressed
	check_button.disabled = disabled
	check_button.focus_neighbor_bottom = focus_neighbor_bottom
	check_button.focus_neighbor_left = focus_neighbor_left
	check_button.focus_neighbor_right = focus_neighbor_right
	check_button.focus_neighbor_top = focus_neighbor_top
	check_button.focus_previous = focus_previous
	check_button.focus_next = focus_next

	# Wire up the button signals
	var on_button_down := func():
		button_down.emit()
	check_button.button_down.connect(on_button_down)
	var on_button_up := func():
		button_up.emit()
	check_button.button_up.connect(on_button_up)
	var on_pressed := func():
		pressed.emit()
	check_button.pressed.connect(on_pressed)
	var on_toggled := func(changed: bool):
		toggled.emit(changed)
	check_button.toggled.connect(on_toggled)

	# Set color based on theme
	theme_changed.connect(_on_theme_changed)
	_on_theme_changed()


func _on_theme_changed() -> void:
	check_button.modulate = get_theme_color("color", "Toggle")


# Override focus grabbing to grab the child
func _grab_focus() -> void:
	check_button.grab_focus()


# Override certain properties and pass them to child objects
func _set(property: StringName, value: Variant) -> bool:
	if not check_button:
		return false
	if property.begins_with("focus"):
		check_button.set(property, value)
		return false
	return false
