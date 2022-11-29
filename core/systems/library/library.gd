extends Node
class_name Library
@icon("res://assets/icons/book-open.svg")

# Unique identifier for the library
@export var library_id: String
# Optional store that this library is linked to
@export var store_id: String
# Icon for library provider
@export var library_icon: Texture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("library")


# Returns an array of available library launch items
func get_library_launch_items() -> Array:
	return []
	

# Installs the given library item
func install(item: LibraryItem):
	pass
	

# Uninstalls the given library item
func uninstall(item: LibraryItem):
	pass
