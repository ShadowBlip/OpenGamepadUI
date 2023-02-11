@tool
extends VBoxContainer

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
		if texture_rect and theme:
			texture_rect.modulate = theme.get_color(v, "Status")

@onready var label := $%Label as Label
@onready var description_label := $%DescriptionLabel as Label
@onready var texture_rect := $%TextureRect as TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = title
	description_label.text = description
	description_label.visible = description != ""
	texture_rect.texture = status_texture_map[status]
	texture_rect.modulate = theme.get_color(color, "Status")
