@tool
extends BoxContainer
class_name Dropdown

signal item_focused(index: int)
signal item_selected(index: int)

@export_category("Label Settings")
@export var title: String:
	set(v):
		title = v
		if label:
			label.text = v
			label.visible = v != ""
@export var description: String:
	set(v):
		description = v
		if description_label:
			description_label.text = v
			description_label.visible = v != ""
@export_category("Toggle Settings")
@export var disabled: bool:
	set(v):
		disabled = v
		if option_button:
			option_button.disabled = v
@export var selected: int:
	get:
		if option_button:
			return option_button.selected
		return selected
	set(v):
		selected = v
		if option_button:
			option_button.selected = v

@onready var label := $%Label as Label
@onready var description_label := $%DescriptionLabel as Label
@onready var option_button := $%OptionButton as OptionButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_grab_focus)
	label.text = title
	description_label.text = description
	option_button.disabled = disabled
	option_button.focus_neighbor_bottom = focus_neighbor_bottom
	option_button.focus_neighbor_left = focus_neighbor_left
	option_button.focus_neighbor_right = focus_neighbor_right
	option_button.focus_neighbor_top = focus_neighbor_top
	option_button.focus_previous = focus_previous
	option_button.focus_next = focus_next
	
	# Hide labels if nothing is specified
	if title == "":
		label.visible = false
	if description == "":
		description_label.visible = false
	
	# Wire up the signals 
	var on_item_focused := func(index: int):
		item_focused.emit(index)
	option_button.item_focused.connect(on_item_focused)
	var on_item_selected := func(index: int):
		item_selected.emit(index)
	option_button.item_selected.connect(on_item_selected)


# Override focus grabbing to grab the node
func _grab_focus() -> void:
	option_button.grab_focus()


# Add the given item to the dropdown  
func add_item(text: String, id: int = -1) -> void:
	option_button.add_item(text, id)


func clear() -> void:
	option_button.clear()


func select(idx: int) -> void:
	option_button.select(idx)


func set_option_disabled(idx: int, disabled: bool) -> void:
	option_button.set_item_disabled(idx, disabled)


# Override certain properties and pass them to child objects
func _set(property: StringName, value: Variant) -> bool:
	if not option_button:
		return false
	if property.begins_with("focus"):
		option_button.set(property, value)
		return false
	return false
