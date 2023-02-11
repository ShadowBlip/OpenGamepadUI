@tool
extends VBoxContainer

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
@export_category("Value Settings")
@export var text: String = "Value":
	set(v):
		text = v
		if value_label:
			value_label.text = v

@onready var label := $%Label as Label
@onready var description_label := $%DescriptionLabel as Label
@onready var value_label := $%LabelValue as Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = title
	description_label.text = description
	description_label.visible = description != ""
	value_label.text = text
