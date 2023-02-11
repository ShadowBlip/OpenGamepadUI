@icon("res://assets/icons/book-open.svg")
extends Node
class_name Library

signal install_completed(item: LibraryItem)
signal update_completed(item: LibraryItem)

# Unique identifier for the library
@export var library_id: String
# Optional store that this library is linked to
@export var store_id: String
# Icon for library provider
@export var library_icon: Texture2D
@export var logger_name := library_id
@export var log_level: Log.LEVEL = Log.LEVEL.INFO

@onready var _cache_dir := "/".join(["library", library_id])
@onready var logger := Log.get_logger(logger_name, log_level)


func _init() -> void:
	add_to_group("library")
	ready.connect(LibraryManager.register_library.bind(self))


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Returns an array of available library launch items
func get_library_launch_items() -> Array[LibraryLaunchItem]:
	return []


# Installs the given library item
func install(item: LibraryItem) -> void:
	pass


# Uninstalls the given library item
func uninstall(item: LibraryItem) -> void:
	pass


# Returns true if the given library item has an update available
func has_update(item: LibraryItem) -> bool:
	return false


func _exit_tree() -> void:
	LibraryManager.unregister_library(self)
