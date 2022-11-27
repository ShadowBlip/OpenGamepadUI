extends Node
class_name LibraryManager

const REQUIRED_FIELDS: Array = ["library_id"]

signal library_registered(library: Library)
signal library_reloaded()

# Dictionary of registered library providers
var _libraries: Dictionary = {}
var _available_apps: Dictionary = {}
var _installed_apps: Dictionary = {}
var _app_by_category: Dictionary = {}
var _app_by_tag: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var main: Main = get_parent()
	main.ready.connect(_on_parent_ready)


# Called when our parent is ready
func _on_parent_ready() -> void:
	var libraries = get_tree().get_nodes_in_group("library")
	for library in libraries:
		_register_library(library)
	
	# Load the library items from each library provider
	reload_library()


# Returns a dictionary of all installed apps
func get_installed() -> Dictionary:
	return _installed_apps
	

# Returns a dictionary of all available apps
func get_available() -> Dictionary:
	return _available_apps


# Loads all library items from each provider and sorts them.
func reload_library():
	_available_apps = _load_library()
	_installed_apps = {}

	# Store all installed apps
	for name in _available_apps.keys():
		var game: Dictionary = _available_apps[name]
		for library_id in game.keys():
			var library_item: LibraryItem = game[library_id]
			if library_item.installed:
				if not name in _installed_apps:
					_installed_apps[name] = {}
				_installed_apps[name][library_id] = library_item
			# TODO: Sort by tags and category
	
	library_reloaded.emit()


# Returns a dictionary of all installed library items from every registered provider.
# The dictionary is in the form of:
#   {
#     "game-name": {
#	    "library-id": <LibraryItem>
#	  }
#   }
func _load_library() -> Dictionary:
	var library_items: Dictionary = {}
	for l in _libraries.values():
		var library: Library = l
		var items: Array = library.get_library_items()
		for i in items:
			var item: LibraryItem = i
			if not item.name in library_items:
				library_items[item.name] = {}
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
