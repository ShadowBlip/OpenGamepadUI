@tool
@icon("res://assets/editor-icons/text-field-bold.svg")
extends VBoxContainer
class_name SelectableText

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
@onready var panel := $%PanelContainer as PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = title
	description_label.text = description
	description_label.visible = description != ""
	value_label.text = text

	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	theme_changed.connect(_on_theme_changed)


func _on_theme_changed() -> void:
	# Get the style from the set theme so it can be set on the panel container
	var normal_stylebox := get_theme_stylebox("panel", "SelectableText").duplicate()
	panel.add_theme_stylebox_override("panel", normal_stylebox)


func _on_focus(focused: bool) -> void:
	panel.remove_theme_stylebox_override("panel")
	if focused:
		var focus_stylebox := get_theme_stylebox("panel_focus", "SelectableText").duplicate()
		panel.add_theme_stylebox_override("panel", focus_stylebox)
		return
	var normal_stylebox := get_theme_stylebox("panel", "SelectableText").duplicate()
	panel.add_theme_stylebox_override("panel", normal_stylebox)
