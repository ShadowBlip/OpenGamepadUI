extends Node
class_name Library
@icon("res://assets/icons/book-open.svg")

# Unique identifier for the library
@export var library_id: String
# Optional store that this library is linked to
@export var store_id: String
# Icon for library provider
@export var library_icon: Texture2D

var _cache_dir: String = "/".join(["user://cache/library", library_id])
var logger := Log.get_logger("Library")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("library")
	_cache_dir = "/".join(["user://cache/library", library_id])


# Returns an array of available library launch items
func get_library_launch_items() -> Array:
	return []
	

# Installs the given library item
func install(item: LibraryItem):
	pass
	

# Uninstalls the given library item
func uninstall(item: LibraryItem):
	pass


# Create the cache directory if it doesn't exist
func _ensure_cache_dir() -> int:
	var err: int = DirAccess.make_dir_recursive_absolute(_cache_dir)
	if err != OK:
		logger.error("Unable to create cache directory!")
	return err


# Saves the given data as JSON to the given file in the cache directory.
func save_cache_json(filename: String, data: Variant) -> int:
	if _ensure_cache_dir() != OK:
		return ERR_CANT_CREATE
	var cache_file: String = "/".join([_cache_dir, filename])
	var file: FileAccess = FileAccess.open(cache_file, FileAccess.WRITE_READ)
	file.store_string(JSON.stringify(data))
	file.flush()
	return OK
	
	
# Loads data from the given cache file
func load_cache_json(filename: String) -> Variant:
	if _ensure_cache_dir() != OK:
		return null
	
	var cache_file: String = "/".join([_cache_dir, filename])
	if not FileAccess.file_exists(cache_file):
		return null
	
	# Read our persistent data and parse it
	var file: FileAccess = FileAccess.open(cache_file, FileAccess.READ)
	var data: String = file.get_as_text()
	return JSON.parse_string(data)
