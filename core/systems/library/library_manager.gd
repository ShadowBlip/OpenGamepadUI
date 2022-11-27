extends Node
class_name LibraryManager


const REQUIRED_FIELDS: Array = ["library_id"]

signal library_registered(library: Library)

var _libraries: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var main: Main = get_parent()
	main.ready.connect(_on_parent_ready)


# Called when our parent is ready
func _on_parent_ready() -> void:
	var libraries = get_tree().get_nodes_in_group("library")
	for library in libraries:
		_register_library(library)
	get_installed()


# Returns a dictionary of all installed library items from every registered provider.
# The dictionary is in the form of:
#   {
#     "game-name": {
#	    "library-id": <LibraryItem>
#	  }
#   }
func get_installed() -> Dictionary:
	var library_items: Dictionary = {}
	for l in _libraries.values():
		var library: Library = l
		var items: Array = library.get_installed()
		for i in items:
			var item: LibraryItem = i
			if not item.name in library_items:
				library_items[item.name] = {}
			if not library.library_id in library_items[item.name]:
				library_items[item.name][library.library_id] = {}
			library_items[item.name][library.library_id] = item
			
	return library_items


# Returns the given library implementation by id
func get_library_by_id(id: String) -> Library:
	return _libraries[id]


# Returns a list of all registered libraries
func get_libraries() -> Array:
	return _libraries.values()


# Registers the given library with the library manager.
func _register_library(library: Library) -> void:
	if not _is_valid_library(library):
		push_error("Invalid library defined! Ensure you have all required properties set: ", ",".join(REQUIRED_FIELDS))
		return
	_libraries[library.library_id] = library
	print("Registered library: ", library.library_id)
	library_registered.emit(library)


# Validates the given library and returns true if it has the required properties
# set.
func _is_valid_library(library: Library) -> bool:
	for field in REQUIRED_FIELDS:
		var data = library.get(field)
		if data == "":
			return false
	return true
