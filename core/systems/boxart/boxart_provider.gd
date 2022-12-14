extends Node
class_name BoxArtProvider
@icon("res://assets/icons/image.svg")

signal boxart_loaded(texture: Texture2D)

# Unique identifier for the boxart provider
@export var provider_id: String
# Icon for boxart provider
@export var provider_icon: Texture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("boxart_provider")


# To be implemented by a provider
func get_boxart(item: LibraryItem, kind: int) -> Texture2D:
	return null
