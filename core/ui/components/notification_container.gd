@tool
extends PanelContainer
class_name NotificationContainer

@export var icon_texture: Texture2D = preload("res://icon.svg"):
	set(value):
		icon_texture = value
		if icon:
			icon.texture = value
		notify_property_list_changed()
@export var icon_size: Vector2 = Vector2(64, 64):
	set(value):
		icon_size = value
		if icon:
			icon.custom_minimum_size = value
		notify_property_list_changed()
@export_multiline var text: String = "":
	set(value):
		text = value
		if label:
			label.text = value
		notify_property_list_changed()
@export var label_settings: LabelSettings:
	set(value):
		label_settings = value
		if label:
			label.label_settings = value
		notify_property_list_changed()

@onready var icon := $%Icon as TextureRect
@onready var label := $%Label as Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon.texture = icon_texture
	icon.custom_minimum_size = icon_size
	label.text = text
	label.label_settings = label_settings
