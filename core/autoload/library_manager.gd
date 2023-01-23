@icon("res://assets/icons/trello.svg")
extends Node

const REQUIRED_FIELDS: Array = ["library_id"]

signal library_registered(library: Library)
signal library_reloaded()
signal library_launch_item_added(item: LibraryLaunchItem)
signal library_launch_item_removed(item: LibraryLaunchItem)

# Dictionary of registered library providers
# The dictionary is in the form of:
#   {
#     "library-id": <Library>
#   }
var _libraries: Dictionary = {}
# Mapping of all available apps from all library providers
# The dictionary is in the form of:
#   {
#     "game-name": <LibraryItem>
#   }
var _available_apps: Dictionary = {}
# Array of apps that are currently installed
var _installed_apps: PackedStringArray = []
var _app_by_category: Dictionary = {}
var _app_by_tag: Dictionary = {}
var logger := Log.get_logger("LibraryManager")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().ready.connect(_on_parent_ready)


# Called when our parent is ready
func _on_parent_ready() -> void:
	var libraries = get_tree().get_nodes_in_group("library")
	for library in libraries:
		_register_library(library)
	
	# Load the library items from each library provider
	reload_library()


# Returns a dictionary of all installed apps
func get_installed() -> Dictionary:
	var installed: Dictionary = {}
	for name in _installed_apps:
		installed[name] = _available_apps[name]
	return installed
	

# Returns a dictionary of all available apps
func get_available() -> Dictionary:
	return _available_apps


# Loads all library items from each provider and sorts them. This can take
# a while, so should be called asyncronously
func reload_library() -> void:
	_available_apps = await _load_library()
	_installed_apps = []

	# Store all installed apps
	for name in _available_apps.keys():
		var game: LibraryItem = _available_apps[name]
		for i in game.launch_items:
			var launch_item: LibraryLaunchItem = i
			if launch_item.installed:
				_installed_apps.append(name)
			# TODO: Sort by tags and category
	
	library_reloaded.emit()


# Add the given library launch item to the list of available apps.
func add_library_launch_item(library_id: String, item: LibraryLaunchItem) -> void:
	if not has_library(library_id):
		logger.warn("Unable to add library launch item. Library is not registered: " + library_id)
		return
	var library_items := get_available()
	var library: Library = get_library_by_id(library_id)
	if not item.name in library_items:
		library_items[item.name] = LibraryItem.new_from_launch_item(item)
	# Update the provider fields on the library item
	item._provider_id = library.library_id
	library_items[item.name].launch_items.push_back(item)
	
	_available_apps = library_items
	library_launch_item_added.emit(item)


# Remove the given library launch item from the list of available apps.
func remove_library_launch_item(library_id: String, name: String) -> void:
	if not has_library(library_id):
		logger.warn("Unable to remove {0} library launch item. Library is not registered: {1}".format([name, library_id]))
		return
	if not has_app(name):
		logger.warn("Unable to remove {0}. Item does not exist in library.".format([name]))
		return
	
	# Iterate backwards over the launch items and remove any matches
	var app := get_app_by_name(name)
	for i in range(app.launch_items.size(), 0, -1):
		var launch_item: LibraryLaunchItem = app.launch_items[i]
		if launch_item._provider_id == library_id:
			app.launch_items.remove_at(i)
			library_launch_item_removed.emit(launch_item)


# Returns a dictionary of all installed library items from every registered provider.
# The dictionary is in the form of:
#   {
#     "game-name": <LibraryItem>
#   }
func _load_library() -> Dictionary:
	var library_items: Dictionary = {}
	for l in get_libraries():
		var library: Library = l
		var items: Array = await library.get_library_launch_items()
		for i in items:
			var item: LibraryLaunchItem = i
			if not item.name in library_items:
				library_items[item.name] = LibraryItem.new_from_launch_item(item)
			# Update the provider fields on the library item
			item._provider_id = library.library_id
			library_items[item.name].launch_items.push_back(item)
			
	return library_items


# Returns true if the app with the given name exists in the library.
func has_app(name: String) -> bool:
	return name in _available_apps


# Returns the library item for the given app for all library providers
func get_app_by_name(name: String) -> LibraryItem:
	if not name in _available_apps:
		logger.warn("App with name {0} not found".format([name]))
		return null
	return _available_apps[name]


# Returns true if the library with the given id is registered
func has_library(id: String) -> bool:
	return id in _libraries


# Returns the given library implementation by id
func get_library_by_id(id: String) -> Library:
	return _libraries[id]


# Returns a list of all registered libraries
func get_libraries() -> Array:
	return _libraries.values()


# Registers the given library with the library manager.
func _register_library(library: Library) -> void:
	if not _is_valid_library(library):
		logger.error("Invalid library defined! Ensure you have all required properties set: " + ",".join(REQUIRED_FIELDS))
		return
	# Set library properties
	_libraries[library.library_id] = library
	logger.info("Registered library: " + library.library_id)
	library_registered.emit(library)


# Validates the given library and returns true if it has the required properties
# set.
func _is_valid_library(library: Library) -> bool:
	for field in REQUIRED_FIELDS:
		var data = library.get(field)
		if data == "":
			return false
	return true
