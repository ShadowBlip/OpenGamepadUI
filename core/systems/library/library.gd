extends Node
class_name Library
@icon("res://assets/icons/book-open.svg")

# Unique identifier for the library
@export var library_id: String
# Optional store that this library is linked to
@export var store_id: String
# Icon for library provider
@export var library_icon: Texture2D

var _cache_dir: String
var logger := Log.get_logger("Library")

@onready var library_manager: LibraryManager = get_tree().get_first_node_in_group("library_manager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("library")
	_cache_dir = "/".join(["library", library_id])
	logger = Log.get_logger(library_id)


# Returns an array of available library launch items
func get_library_launch_items() -> Array:
	return []
	

# Installs the given library item
func install(item: LibraryItem):
	pass
	

# Uninstalls the given library item
func uninstall(item: LibraryItem):
	pass
