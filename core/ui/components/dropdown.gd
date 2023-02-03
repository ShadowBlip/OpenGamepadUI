@tool
extends BoxContainer

signal item_focused(index: int)
signal item_selected(index: int)

@export_category("Label Settings")
@export var title: String = "Setting":
	set(v):
		title = v
		if label:
			label.text = v
			label.visible = v != ""
@export var description: String = "Description":
	set(v):
		description = v
		if description_label:
			description_label.text = v
			description_label.visible = v != ""

@onready var label := $%Label as Label
@onready var description_label := $%DescriptionLabel as Label
@onready var option_button := $%OptionButton as OptionButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Override focus grabbing to grab the node
func grab_focus() -> void:
	option_button.grab_focus()
