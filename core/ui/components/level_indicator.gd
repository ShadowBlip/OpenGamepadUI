@tool
extends Control
class_name LevelIndicator

@export var icon_texture: Texture2D
@export var value: float = 50:
	set(v):
		value = v
		if progress_bar:
			progress_bar.value = v
		notify_property_list_changed()

@onready var icon := $%Icon
@onready var progress_bar := $%ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	icon.texture = icon_texture
	progress_bar.value = value
