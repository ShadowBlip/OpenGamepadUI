@tool
extends VBoxContainer
class_name TabLabel

@export var text := "Tab":
	set(v):
		text = v
		if label:
			label.text = v
@export var selected := false:
	set(v):
		selected = v
		if separator:
			separator.visible = v

@onready var label := $%SubsectionLabel
@onready var separator := $%HSeparator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = text
	separator.visible = selected
