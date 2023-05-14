@icon("res://assets/icons/trello.svg")
extends Resource
class_name LibraryManager

## Unified interface to manage games from multiple sources
##
## The LibraryManager is responsible for managing any number of [Library] providers 
## and offers a unified interface to manage games from multiple sources. New game 
## library sources can be created in the core code base or in plugins by 
## implementing/extending the [Library] class and registering the provider 
## with the library manager.[br][br]
##
## With registered library providers, other systems can request library items 
## from the LibraryManager, and it will use all available sources to return a 
## unified library item:
##
##     [codeblock]
##     const LibraryManager := preload("res://core/global/library_manager.tres")
##     ...
##     # Return a dictionary of all installed games from every library provider
##     var installed_games := LibraryManager.get_installed()
##     [/codeblock]
##
## Games in the LibraryManager are stored as [LibraryItem] resources, which contains 
## information about each game. Each [LibraryItem] has a list of 
## [LibraryLaunchItems] which contains the data for how to launch that game 
## through a specific Library provider.

const REQUIRED_FIELDS: Array = ["library_id"]

signal library_registered(library: Library)
signal library_unregistered(library_id: String)
signal library_reloaded(first_load: bool)
signal library_loaded(library_id: String)
signal library_item_added(item: LibraryItem)
signal library_item_removed(item: LibraryItem)
signal library_launch_item_added(item: LibraryLaunchItem)
signal library_launch_item_removed(item: LibraryLaunchItem)
## DEPRECATED - Use InstallManager
signal item_installed(item: LibraryLaunchItem, success: bool)
## DEPRECATED - Use InstallManager
signal item_updated(item: LibraryLaunchItem, success: bool)
## DEPRECATED - Use InstallManager
signal item_uninstalled(item: LibraryLaunchItem, success: bool)
## DEPRECATED - Use InstallManager
signal item_progressed(item: LibraryLaunchItem, percent_completed: float)

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
var _sorted_apps_by_name: PackedStringArray = []
var _app_by_category: Dictionary = {}
var _app_by_tag: Dictionary = {}
var _app_by_library: Dictionary = {}
var _initialized := false
var logger := Log.get_logger("LibraryManager")


## DEPRECATED - Use InstallManager
## Installs the given library launch item using its provider
func install(item: LibraryLaunchItem) -> void:
	# Get the library provider for this launch item 
	var provider := get_library_by_id(item._provider_id)
	if not provider:
		logger.error("No provider to install item: " + item.name)
		return
	provider.install(item)


## DEPRECATED - Use InstallManager
## Updates the given library launch item using its provider
func update(item: LibraryLaunchItem) -> void:
	# Get the library provider for this launch item 
	var provider := get_library_by_id(item._provider_id)
	if not provider:
		logger.error("No provider to update item: " + item.name)
		return
	provider.update(item)


## DEPRECATED - Use InstallManager
## Uninstalls the given library launch item using its provider
func uninstall(item: LibraryLaunchItem) -> void:
	# Get the library provider for this launch item 
	var provider := get_library_by_id(item._provider_id)
	if not provider:
		logger.error("No provider to uninstall item: " + item.name)
		return
	provider.uninstall(item)


## Returns library items based on the given modifiers. A modifier is a [Callable]
## that takes an array of [LibraryItem] objects and returns an array of those 
## items that may be sorted or filtered out.[br][br]
##
##     [codeblock]
##     const LibraryManager := preload("res://core/global/library_manager.tres")
##     ...
##     var filter := func(apps: Array[LibraryItem]) -> Array[LibraryItem]:
##         return apps.filter(func(item: LibraryItem): not item.is_installed())
##     
##     # Return non-installed games
##     var not_installed := LibraryManager.get_library_items([filter])
##     [/codeblock]
##
func get_library_items(modifiers: Array[Callable] = [sort_by_name]) -> Array[LibraryItem]:
	var available_apps := get_available()
	var sorted: Array[LibraryItem] = []
	sorted.assign(available_apps.values())

	for modify in modifiers:
		sorted = modify.call(sorted)

	return sorted


## Sorts the given array of apps by name
func sort_by_name(apps: Array[LibraryItem]) -> Array[LibraryItem]:
	var sorter := func(a: LibraryItem, b: LibraryItem): return b.name > a.name
	var sorted := apps.duplicate()
	sorted.sort_custom(sorter)

	return sorted


## Filters the given array of apps by installed status
func filter_installed(apps: Array[LibraryItem]) -> Array[LibraryItem]:
	var filter := func(item: LibraryItem): return item.is_installed()
	return apps.filter(filter)


## Returns a dictionary of all installed apps
func get_installed() -> Dictionary:
	var installed: Dictionary = {}
	for name in _installed_apps:
		installed[name] = _available_apps[name]
	return installed
	

## Returns an dictionary of all available apps
func get_available() -> Dictionary:
	return _available_apps.duplicate()


## Returns whether or not the library has loaded for the first time
func is_initialized() -> bool:
	return _initialized


## Loads all library items from each provider and sorts them. This can take
## a while, so should be called asyncronously
func reload_library() -> void:
	for library in get_libraries():
		load_library(library.library_id)
	
	var first_load := !_initialized
	_initialized = true
	library_reloaded.emit(first_load)


## Add the given library launch item to the list of available apps.
func add_library_launch_item(library_id: String, item: LibraryLaunchItem) -> void:
	if not has_library(library_id):
		logger.warn("Unable to add library launch item. Library is not registered: " + library_id)
		return

	# Create a new library item if one does not exist.
	var is_new := false
	var library_item: LibraryItem
	if item.name in _available_apps:
		library_item = _available_apps[item.name]
	else:
		library_item = LibraryItem.new_from_launch_item(item)
		_available_apps[item.name] = library_item
		is_new = true

	# Update the provider fields on the library item
	item._provider_id = library_id
	library_item.launch_items.push_back(item)

	# Sort apps by installed
	if item.installed and not item.name in _installed_apps:
		var idx := _installed_apps.bsearch(item.name)
		_installed_apps.insert(idx, item.name)

	# Sort apps alphabetically 
	if is_new:
		var idx := _sorted_apps_by_name.bsearch(item.name)
		_sorted_apps_by_name.insert(idx, item.name)

	# Sort apps by provider
	if not library_id in _app_by_library:
		_app_by_library[library_id] = []
	_app_by_library[library_id].push_back(item.name)
	
	# Sort by category
	for category in item.categories:
		if not category in _app_by_category:
			_app_by_category[category] = []
		if is_new:
			var idx := _app_by_category[category].bsearch(item.name) as int
			_app_by_category[category].insert(idx, item.name)

	# Sort by tag
	for tag in item.tags:
		if not tag in _app_by_tag:
			_app_by_tag[tag] = []
		if is_new:
			var idx := _app_by_tag[tag].bsearch(item.name) as int
			_app_by_tag[tag].insert(idx, item.name)

	# Send signals to inform about library item
	if is_new:
		library_item_added.emit(library_item)
		library_item.added_to_library.emit()
	library_launch_item_added.emit(item)
	item.added_to_library.emit()


## Remove the given library launch item from the list of available apps.
func remove_library_launch_item(library_id: String, name: String) -> void:
	if not has_library(library_id):
		logger.warn("Unable to remove {0} library launch item. Library is not registered: {1}".format([name, library_id]))
		return
	if not has_app(name):
		logger.warn("Unable to remove {0}. Item does not exist in library.".format([name]))
		return
	
	# Iterate backwards over the launch items and remove any matches
	var app := get_app_by_name(name)
	var i := app.launch_items.size()
	while i > 0:
		var launch_item: LibraryLaunchItem = app.launch_items[i-1]
		if launch_item._provider_id == library_id:
			app.launch_items.remove_at(i-1)
			if library_id in _app_by_library:
				(_app_by_library[library_id] as Array).erase(name)
			library_launch_item_removed.emit(launch_item)
			launch_item.removed_from_library.emit()
		i -= 1
	
	# Remove the library item if no launch items exist for it
	if app.launch_items.size() == 0:
		# Erase from available apps
		_available_apps.erase(app.name)

		# Erase from installed apps
		var idx := _installed_apps.find(app.name)
		if idx != -1:
			_installed_apps.remove_at(idx)

		# Erase from sorted apps
		idx = _sorted_apps_by_name.find(app.name)
		if idx != -1:
			_sorted_apps_by_name.remove_at(idx)

		# Erase from categories
		for category in _app_by_category:
			idx = category.find(app.name)
			if idx != -1:
				category.remove_at(idx)

		# Erase from tags
		for tag in _app_by_tag:
			idx = tag.find(app.name)
			if idx != -1:
				tag.remove_at(idx)

		library_item_removed.emit(app)
		app.removed_from_library.emit()


## Loads the launch items from the given library
func load_library(library_id: String) -> void:
	var library := get_library_by_id(library_id)
	var items: Array = await library.get_library_launch_items()
	for i in items:
		var item: LibraryLaunchItem = i
		add_library_launch_item(library_id, item)


## Returns true if the app with the given name exists in the library.
func has_app(name: String) -> bool:
	return name in _available_apps


## Returns the library item for the given app for all library providers
func get_app_by_name(name: String) -> LibraryItem:
	if not name in _available_apps:
		logger.warn("App with name {0} not found".format([name]))
		return null
	return _available_apps[name]


## Returns an array of library items for the given library provider
func get_apps_by_library(library_id: String) -> Array[LibraryItem]:
	var apps: Array[LibraryItem] = []
	if not has_library(library_id):
		logger.warn("Unable to get apps from library {0}. Library is not registered.".format([library_id]))
		return apps
	var app_names := _app_by_library[library_id] as Array
	for name in app_names:
		apps.push_back(get_app_by_name(name))
	return apps


## Returns true if the library with the given id is registered
func has_library(id: String) -> bool:
	return id in _libraries


## Returns the given library implementation by id
func get_library_by_id(id: String) -> Library:
	if not id in _libraries:
		return null
	return _libraries[id]


## Returns a list of all registered libraries
func get_libraries() -> Array[Library]:
	var libraries: Array[Library] = []
	libraries.assign(_libraries.values())
	logger.debug("Got libraries: " + str(libraries))

	return libraries


## Registers the given library with the library manager.
func register_library(library: Library) -> void:
	if not _is_valid_library(library):
		logger.error("Invalid library defined! Ensure you have all required properties set: " + ",".join(REQUIRED_FIELDS))
		return
	# Set library properties
	_libraries[library.library_id] = library

	# Connect to library signals 
	library.install_completed.connect(_on_install_completed)
	library.uninstall_completed.connect(_on_uninstall_completed)
	library.update_completed.connect(_on_update_completed)
	library.install_progressed.connect(_on_install_progressed)
	
	# Load the library if the manager is already initialized
	if _initialized:
		load_library(library.library_id)
		
	logger.info("Registered library: " + library.library_id)
	library_registered.emit(library)


## Unregisters the given library with the library manager
func unregister_library(library: Library) -> void:
	if not library.library_id in _libraries:
		logger.warn("Library is already unregistered")
		return
	if library.library_id in _app_by_library:
		for app in _app_by_library[library.library_id]:
			remove_library_launch_item(library.library_id, app)
	_libraries.erase(library.library_id)
	logger.info("Unregistered library: " + library.library_id)
	library_unregistered.emit(library.library_id)


func _on_install_completed(item: LibraryLaunchItem, success: bool) -> void:
	item_installed.emit(item, success)


## DEPRECATED - Use InstallManager
func _on_update_completed(item: LibraryLaunchItem, success: bool) -> void:
	item_updated.emit(item, success)


func _on_uninstall_completed(item: LibraryLaunchItem, success: bool) -> void:
	item_uninstalled.emit(item, success)


## DEPRECATED - Use InstallManager
func _on_install_progressed(item: LibraryLaunchItem, percent_completed: float) -> void:
	item_progressed.emit(item, percent_completed)


# Validates the given library and returns true if it has the required properties
# set.
func _is_valid_library(library: Library) -> bool:
	for field in REQUIRED_FIELDS:
		var data = library.get(field)
		if data == "":
			return false
	return true
