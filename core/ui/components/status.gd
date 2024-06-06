@tool
@icon("res://assets/editor-icons/pajamas--status-active.svg")
extends VBoxContainer
class_name StatusPanel

enum STATUS {
	ACTIVE,
	ALERT,
	CANCELLED,
	CLOSED,
	PAUSED,
}

# Map of statuses to textures to display
var status_texture_map := {
	STATUS.ACTIVE: load("res://assets/ui/icons/status-active.svg"),
	STATUS.ALERT: load("res://assets/ui/icons/status-alert.svg"),
	STATUS.CANCELLED: load("res://assets/ui/icons/status-cancelled.svg"),
	STATUS.CLOSED: load("res://assets/ui/icons/status-closed.svg"),
	STATUS.PAUSED: load("res://assets/ui/icons/status-paused.svg"),
}

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
@export_category("Status Settings")
@export var status: STATUS = STATUS.ACTIVE:
	set(v):
		status = v
		if texture_rect:
			texture_rect.texture = status_texture_map[v]
@export_enum("cyan", "gray", "green", "orange", "pink", "purple", "red", "yellow")
var color: String = "green":
	set(v):
		color = v
		if texture_rect:
			texture_rect.modulate = get_theme_color(v, "Status")

@onready var label := $%Label as Label
@onready var description_label := $%DescriptionLabel as Label
@onready var texture_rect := $%TextureRect as TextureRect
@onready var panel := $%PanelContainer as PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	theme_changed.connect(_on_theme_changed)
	_on_theme_changed()

	label.text = title
	description_label.text = description
	description_label.visible = description != ""
	texture_rect.texture = status_texture_map[status]
	texture_rect.modulate = get_theme_color(color, "Status")


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
