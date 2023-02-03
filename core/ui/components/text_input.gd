@tool
extends BoxContainer

signal text_change_rejected(rejected_substring: String)
signal text_changed(new_text: String)
signal text_submitted(new_text: String)

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
@export_category("LineEdit Settings")
@export var text: String:
	set(v):
		text = v
		if line_edit:
			line_edit.text = v
@export var placeholder_text: String:
	set(v):
		placeholder_text = v
		if line_edit:
			line_edit.placeholder_text = v
@export var editable := true:
	set(v):
		editable = v
		if line_edit:
			line_edit.editable = v

@onready var label := $%Label as Label
@onready var description_label := $%DescriptionLabel as Label
@onready var line_edit := $%LineEdit as LineEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = title
	description_label.text = description
	line_edit.text = text
	line_edit.placeholder_text = placeholder_text
	line_edit.editable = editable

	# Hide labels if nothing is specified
	if title == "":
		label.visible = false
	if description == "":
		description_label.visible = false

	# Signals
	var on_text_change_rejected := func(v: String):
		text_change_rejected.emit(v)
	line_edit.text_change_rejected.connect(on_text_change_rejected)
	var on_text_changed := func(v: String):
		text_changed.emit(v)
	line_edit.text_changed.connect(on_text_changed)
	var on_text_submitted := func(v: String):
		text_submitted.emit(v)
	line_edit.text_change_rejected.connect(on_text_submitted)
	


# Override focus grabbing to grab the node
func grab_focus() -> void:
	line_edit.grab_focus()
