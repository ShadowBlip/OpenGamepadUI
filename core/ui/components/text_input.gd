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
	get:
		if line_edit:
			return line_edit.text
		return ""
	set(v):
		text = v
		if line_edit and line_edit.text != v:
			line_edit.text = v
@export var placeholder_text: String:
	set(v):
		placeholder_text = v
		if line_edit and line_edit.placeholder_text != v:
			line_edit.placeholder_text = v
@export var editable := true:
	set(v):
		editable = v
		if line_edit:
			line_edit.editable = v
@export var secret := false:
	set(v):
		secret = v
		if line_edit:
			line_edit.secret = v

@onready var label := $%Label as Label
@onready var description_label := $%DescriptionLabel as Label
@onready var line_edit := $%LineEdit as LineEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_grab_focus)
	label.text = title
	description_label.text = description
	line_edit.text = text
	line_edit.placeholder_text = placeholder_text
	line_edit.editable = editable
	line_edit.secret = secret

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
		text = v
		text_changed.emit(v)
	line_edit.text_changed.connect(on_text_changed)
	var on_text_submitted := func(v: String):
		text_submitted.emit(v)
	line_edit.text_change_rejected.connect(on_text_submitted)
	var on_focus_exited := func():
		focus_exited.emit()
	line_edit.focus_exited.connect(on_focus_exited)
	var on_focus_entered := func():
		focus_entered.emit()
	line_edit.focus_entered.connect(on_focus_entered)
	


# Override focus grabbing to grab the node
func _grab_focus() -> void:
	line_edit.grab_focus()
