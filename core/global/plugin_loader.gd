# Based on the mod loader by Harry Giel
# https://gitlab.com/Delta-V-Modding/Mods/-/blob/main/game/ModLoader.gd
@icon("res://assets/editor-icons/codesandbox-logo-fill.svg")
extends Resource
class_name PluginLoader

## Manage and load plugins 
##
## The PluginLoader is responsible for downloading, loading, and initializing 
## OpenGamepadUI plugins. The plugin system for OpenGamepadUI is inspired by 
## the modding system implemented by Delta-V. [br][br]
##
## The PluginLoader works by taking advantage of Godot's 
## [method ProjectSettings.load_resource_pack] method, which can allow us to 
## load Godot scripts and scenes from a zip file. The PluginLoader looks for zip 
## files in user://plugins, and parses the plugin.json file contained within 
## them. If the plugin metadata is valid, the loader loads the zip as a resource 
## pack.

const PLUGIN_STORE_URL = "https://raw.githubusercontent.com/ShadowBlip/OpenGamepadUI-plugins/main/plugins.json"
const PLUGIN_API_VERSION = "1.0.0"
const PLUGINS_DIR = "user://plugins"
const LOADED_PLUGINS_DIR = "res://plugins"
const REQUIRED_META = ["plugin.name", "plugin.version", "plugin.min-api-version", "entrypoint"]

#TODO: Document these.
signal plugin_loaded(name: String)
signal plugin_unloaded(name: String)
signal plugin_initialized(name: String)
signal plugin_uninitialized(name: String)
signal plugin_installed(id: String, status: int)
signal plugin_uninstalled(id: String, status: int)
signal plugin_enabled(name: String)
signal plugin_disabled(name: String)
signal plugins_reloaded()
signal plugin_upgradable(name: String, update_type: int)

var SettingsManager := load("res://core/global/settings_manager.tres") as SettingsManager
var parent: PluginManager
var logger := Log.get_logger("PluginLoader", Log.LEVEL.INFO)
## Dictionary of installed plugins on the root file system.
var plugins := {} # {plugin_id: {plugin.name: "name", plugin.id: "id", store.tags: ["quck_bar", "steam"], ...}
## Dictionary of instantiated plugins.
var plugin_nodes := {}
## Dictionary of available plugins in the defualt plugin store. Similair data
## struture to the plugins dict with some additonal fields.
var plugin_store_items := {} # {plugin_id: {plugin.name: "name", plugin.id: "id", store.tags: ["quick_bar", "steam"], ...}
## List of plugin_ids that are installed where a newer version of the plugin is
## available in the plugin store.
var plugins_upgradable := []
var plugin_filters : Array[Callable] = []

enum update_type{
	NEW,
	UPDATE,
	}

## Initializes the plugin loader. Loaded plugins will be added to the given 
## manager node.
func init(manager: PluginManager) -> void:
	parent = manager
	plugin_installed.connect(_on_install_plugin)
	plugin_uninstalled.connect(_on_install_plugin)
	_load_and_init_plugins()


# Reload plugins after a new one is installed
func _on_install_plugin(_plugin_id: String, status: int) -> void:
	# ignore failures, nothing will have changed.
	if status != OK:
		return
	_load_and_init_plugins()


# Loads and initializes all plugins
func _load_and_init_plugins() -> void:
	logger.info("Loading plugins")
	_load_plugins()
	logger.info("Done loading plugins")
	logger.info("Initializing plugins")
	_init_plugins(plugin_filters)
	logger.info("Done initializing plugins")
	plugins_reloaded.emit()


## Sets the given plugin to enabled
func enable_plugin(plugin_id: String) -> void:
	SettingsManager.set_value("plugins.enabled", plugin_id, true)


## Sets the given plugin to disabled
func disable_plugin(plugin_id: String) -> void:
	SettingsManager.set_value("plugins.enabled", plugin_id, false)


## Returns the parsed dictionary of plugin store items. Returns null if there
## is a failure.
func get_plugin_store_items() -> Variant:
	if not parent:
		logger.error("Plugin loader has not been initialized!")
		return
	var http: HTTPRequest = HTTPRequest.new()
	parent.add_child.call_deferred(http)
	await http.ready
	if http.request(PLUGIN_STORE_URL) != OK:
		logger.error("Error making http request to plugin store")
		parent.remove_child(http)
		http.queue_free()
		return null

	# Wait for the request signal to complete
	var args: Array = await http.request_completed
	var result: int = args[0]
	var response_code: int = args[1]
	var headers: PackedStringArray = args[2]
	var body: PackedByteArray = args[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		logger.error("Plugin store http request failed")
		parent.remove_child(http)
		http.queue_free()
		return null

	# Parse the results
	var items: Dictionary = JSON.parse_string(body.get_string_from_utf8())

	return items


## Downloads and installs the given plugin
func install_plugin(plugin_id: String, download_url: String, sha256: String) -> void:
	if not parent:
		logger.error("Plugin loader has not been initialized!")
		return
	# Build the request
	var http: HTTPRequest = HTTPRequest.new()
	parent.add_child.call_deferred(http)
	await http.ready
	if http.request(download_url) != OK:
		logger.error("Error making http request for plugin package: " + download_url)
		parent.remove_child(http)
		http.queue_free()
		plugin_installed.emit(plugin_id, FAILED)
		return

	# Wait for the request signal to complete
	# result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
	var args: Array = await http.request_completed
	var result: int = args[0]
	var response_code: int = args[1]
	var headers: PackedStringArray = args[2]
	var body: PackedByteArray = args[3]
	parent.remove_child(http)
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS:
		logger.error("Plugin couldn't be downloaded: " + download_url)
		plugin_installed.emit(plugin_id, FAILED)
		return

	# Now we have the body ;)
	var ctx = HashingContext.new()

	# Start a SHA-256 context.
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(body)

	# Get the computed hash.
	var res = ctx.finish()

	# Print the result as hex string and array.
	if res.hex_encode() != sha256:
		logger.error("sha256 hash does not match for the downloaded plugin archive. Contact the plugin maintainer.")
		plugin_installed.emit(plugin_id, FAILED)
		return

	# Install the plugin.
	var plugin_dir : String = ProjectSettings.get("OpenGamepadUI/plugin/directory")
	DirAccess.make_dir_recursive_absolute(plugin_dir)
	var file := FileAccess.open("/".join([plugin_dir, plugin_id + ".zip"]), FileAccess.WRITE_READ)
	file.store_buffer(body)
	file.close()
	plugin_installed.emit(plugin_id, OK)


## Unloads and uninstalls the given plugin. Returns OK if removed successfully.
func uninstall_plugin(plugin_id: String) -> int:
	# Unload the plugin
	unload_plugin(plugin_id)

	# Remove the plugin archive
	var plugin_dir: String = ProjectSettings.get("OpenGamepadUI/plugin/directory")
	var filename: String = "/".join([plugin_dir, plugin_id + ".zip"])
	var result := DirAccess.remove_absolute(filename)
	var extracted_dir := "/".join([PLUGINS_DIR, plugin_id])
	if DirAccess.dir_exists_absolute(extracted_dir):
		OS.move_to_trash(ProjectSettings.globalize_path(extracted_dir))
	plugin_uninstalled.emit(plugin_id, result)
	# Backwards compatibility
	return result


## Returns whether or not the given plugin is already extracted. This takes
## the parsed plugin metadata as an argument.
func is_extracted(meta: Dictionary) -> bool:
	var plugin_id: String = meta["plugin.id"]
	var plugin_version: String = meta["plugin.version"]
	
	if not DirAccess.dir_exists_absolute("/".join([PLUGINS_DIR, plugin_id])):
		return false
	
	var extracted_plugin_json := "/".join([PLUGINS_DIR, plugin_id, "plugins", plugin_id, "plugin.json"])
	if not FileAccess.file_exists(extracted_plugin_json):
		return false
		
	var meta_file := FileAccess.open(extracted_plugin_json, FileAccess.READ)
	var parsed = JSON.parse_string(meta_file.get_as_text())
	if parsed == null:
		return false
	var current_meta := parsed as Dictionary
	
	if not "plugin.version" in current_meta:
		return false
	if meta["plugin.version"] != current_meta["plugin.version"]:
		return false
	
	return true


## Extract the given plugin into the plugins directory
func extract_plugin(plugin_id: String, path: String) -> void:
	var reader := ZIPReader.new()
	if reader.open(path) != OK:
		logger.warn("Unable to open archive: " + path)
		return
	var files := reader.get_files()
	for file_path in files:
		# Filter out content we don't care about
		if file_path.begins_with(".godot/"):
			continue
		if file_path.ends_with(".gd"):
			continue
		if file_path.ends_with(".tscn.remap"):
			continue
		if file_path.ends_with(".import"):
			continue
		if file_path == "project.binary":
			continue
		
		# Read the contents of the file in the zip
		var content := reader.read_file(file_path)
		var file_path_arr := Array(file_path.split("/"))
		var filename := file_path_arr.pop_back() as String
		var dir := "/".join(file_path_arr)
		
		# Create the target directories
		var target_dir := "/".join([PLUGINS_DIR, plugin_id, dir])
		DirAccess.make_dir_recursive_absolute(target_dir)
		
		# Write the file contents
		var target_file := "/".join([PLUGINS_DIR, plugin_id, dir, filename])
		logger.info("Extracting plugin file for '" + plugin_id + "': " + target_file)
		var file := FileAccess.open(target_file, FileAccess.WRITE)
		file.store_buffer(content)


## Unloads the given plugin. Returns OK if successful.
func unload_plugin(plugin_id: String) -> int:
	if not plugin_id in plugins:
		logger.error("Cannot unload plugin {0} as it does not appear to be loaded".format([plugin_id]))
		return FAILED
	uninitialize_plugin(plugin_id)
	plugins.erase(plugin_id)
	plugin_unloaded.emit(plugin_id)
	return OK


## Uninitializes a plugin and calls its "unload" method
func uninitialize_plugin(plugin_id: String) -> int:
	if not parent:
		logger.error("Plugin loader has not been initialized!")
		return FAILED
	if not plugin_id in plugin_nodes:
		logger.error("Cannot uninitialize plugin {0} as it does not appear to be initialized".format([plugin_id]))
		return FAILED
	var instance: Plugin = plugin_nodes[plugin_id]
	instance.unload()
	parent.remove_child(instance)
	instance.queue_free()
	plugin_nodes.erase(plugin_id)
	logger.info("Uninitialized plugin: " + plugin_id)
	plugin_uninitialized.emit(plugin_id)
	return OK


## Returns true if the given plugin is installed.
func is_installed(plugin_id: String) -> bool:
	var plugin_dir: String = ProjectSettings.get("OpenGamepadUI/plugin/directory")
	var filename: String = "/".join([plugin_dir, plugin_id + ".zip"])
	return FileAccess.file_exists(filename)


## Returns true if the given plugin is loaded.
func is_loaded(plugin_id: String) -> bool:
	return plugin_id in plugins


## Returns true if the given plugin is initialized and running
func is_initialized(plugin_id: String) -> bool:
	return plugin_id in plugin_nodes


## Returns true if the given plugin is upgradable.
func is_upgradable(plugin_id: String) -> bool:
	return plugin_id in plugins_upgradable


## Returns the given plugin instance
func get_plugin(plugin_id: String) -> Plugin:
	if not plugin_id in plugin_nodes:
		return null
	return plugin_nodes[plugin_id]


## Returns the metadata for the given plugin
func get_plugin_meta(plugin_id: String) -> Dictionary:
	return plugins[plugin_id]


## Returns a list of plugin_ids that were loaded
func get_loaded_plugins() -> Array:
	return plugins.keys()


## Returns a list of plugin_ids that are initialized and running
func get_initialized_plugins() -> Array:
	return plugin_nodes.keys()


## Removes the upgradable flag from the given plugin, or returns
# false if no upgrade was available.
func set_plugin_upgraded(plugin_id: String) -> bool:
	if plugin_id in plugins_upgradable:
		plugins_upgradable.erase(plugin_id)
		return true
	return false


## Instances the given plugin and adds it to the scene tree
func initialize_plugin(plugin_id) -> int:
	if not parent:
		logger.error("PluginLoader has not been initialized!")
		return FAILED
	if is_initialized(plugin_id):
		return ERR_ALREADY_EXISTS
	if not plugin_id in plugins:
		logger.warn("Unable to initialize %s as it has not been loaded" % plugin_id)
		return FAILED
	var meta = plugins[plugin_id]

	if not "entrypoint" in meta:
		logger.warn("%s has no entrypoint defined" % plugin_id)
		return FAILED
	var plugin = load("/".join([LOADED_PLUGINS_DIR, plugin_id, meta["entrypoint"]]))
	if not plugin:
		logger.warn("Unable to load plugin '{0}'. Is the entrypoint correct?".format([plugin_id]))
		return FAILED
	var instance: Plugin = plugin.new()
	instance.name = plugin_id
	instance.plugin_base = "/".join([LOADED_PLUGINS_DIR, plugin_id])
	parent.add_child(instance)
	plugin_nodes[plugin_id] = instance
	plugin_initialized.emit(plugin_id)
	logger.info("Initialized plugin: " + plugin_id)
	return OK


# Looks in the user plugins directory for plugin json files and loads them.
func _load_plugins() -> void:
	var dir = DirAccess.open(PLUGINS_DIR)
	if not dir:
		logger.debug("Unable to open plugin directory!")
		return

	# Iterate through all plugins
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# Skip any non-plugins
		if not file_name.ends_with(".zip"):
			file_name = dir.get_next()
			continue

		# Read the plugin metadata
		logger.debug("Found plugin: " + file_name)
		var meta = _load_plugin_meta("/".join([PLUGINS_DIR, file_name]))
		if meta == null:
			logger.warning("%s failed to load" % file_name)
			file_name = dir.get_next()
			continue

		# Validate the plugin metadata
		if not _is_valid_plugin_meta(meta):
			logger.warning("%s has invalid plugin JSON" % file_name)
			file_name = dir.get_next()
			continue

		# Ensure the plugin is compatible
		if not _is_compatible_version(meta["plugin.min-api-version"], PLUGIN_API_VERSION):
			logger.warning("%s is not compatible with this plugin API verion" % file_name)
			file_name = dir.get_next()
			continue

		# Check if the plugin is already loaded
		if is_loaded(meta["plugin.id"]):

			# Check if we need to upgrade
			var existing = get_plugin_meta(meta["plugin.id"])
			if not SemanticVersion.is_greater(meta["plugin.version"], existing["plugin.version"]):
				file_name = dir.get_next()
				continue

			# Uninitialize and unload old version
			unload_plugin(meta["plugin.id"])

		# Extract the plugin to allow accessing plugin assets outside Godot
		if not is_extracted(meta):
			var extracted_dir := "/".join([PLUGINS_DIR, meta["plugin.id"]])
			if DirAccess.dir_exists_absolute(extracted_dir):
				OS.move_to_trash(ProjectSettings.globalize_path(extracted_dir))
			extract_plugin(meta["plugin.id"], "/".join([PLUGINS_DIR, file_name]))

		# Load the plugin, this will also replace the existing instance of the resource.
		# for an updated plugin.
		if not ProjectSettings.load_resource_pack("/".join([PLUGINS_DIR, file_name])):
			logger.warning("%s failed to load" % file_name)

		# Register the plugin
		var plugin_name: String = meta["plugin.id"]
		plugins[plugin_name] = meta
		plugin_loaded.emit(plugin_name)
		file_name = dir.get_next()


# Initializes the loaded plugins
func _init_plugins(filters: Array[Callable] = []) -> void:
	var all_plugins := plugins.duplicate()
	var plugin_ids: Array[String] = []
	if filters.size() == 0:
		plugin_ids.assign(all_plugins.keys())
	logger.debug("Filters to appy: " + str(filters.size()))
	for filter in filters:
		logger.debug("Applying filter " + str(filter))
		var ids_to_append: Array[String] = filter.call(all_plugins)
		for plugin_id in ids_to_append:
			if plugin_id not in plugin_ids:
				plugin_ids.append(plugin_id)
	for name in plugin_ids:
		if SettingsManager.get_value("plugins.enabled", name, true):
			initialize_plugin(name)


# Loads plugin metadata and returns it as a parsed dictionary. Returns null
# if there was an error parsing.
func _load_plugin_meta(path: String) -> Variant:

	# Open the archive
	var reader: ZIPReader = ZIPReader.new()
	var error := reader.open(path)
	if error != OK:
		logger.error("PluginLoader: Failed to open {0} with result {1}".format([path, error]))
		return null

	# Look for plugin.json
	var plugin_meta_file: String = ""
	var files: PackedStringArray = reader.get_files()
	for file in files:
		if file.begins_with("plugins/") and file.ends_with("/plugin.json"):
			plugin_meta_file = file
			break

	# Error if no plugin.json was found in the archive
	if plugin_meta_file == "":
		logger.error("PluginLoader: No plugin.json found in %s" % path)
		reader.close()
		return null

	# Extract the plugin.json
	var bytes: PackedByteArray = reader.read_file(plugin_meta_file)
	reader.close()
	var data: String = bytes.get_string_from_utf8()

	# Parse the plugin.json
	var meta = JSON.parse_string(data)
	return meta


# Ensures the given plugin metadata has all required fields
func _is_valid_plugin_meta(meta: Dictionary) -> bool:
	for field in REQUIRED_META:
		if not field in meta:
			return false
	return true 


# Returns whether or not the given semantic version string is greater than or
# equal to the target semantic version string, except if the target major
# version differs.
func _is_compatible_version(version: String, target: String) -> bool:
	return SemanticVersion.is_feature_compatible(version, target)


# Refreshes the pluign store database and reports if an updated plugin is available
func on_update_timeout() -> void:
	var new_store_items: Variant = await get_plugin_store_items()

	# First run, set the database
	if plugin_store_items == {}:
		plugin_store_items = new_store_items
		# Check if there are updates for installed plugins
		for plugin in new_store_items:
			_is_plugin_upgradable(plugin, new_store_items)

	# Do nothing if there are no updates
	if new_store_items == plugin_store_items:
		return

	# Check for updated plugins
	for plugin in new_store_items:
		# Check if plugin is new
		if _is_plugin_new(plugin):
			continue
		# Check if plugin has an update
		_is_plugin_upgradable(plugin, new_store_items)

	# Set the new database
	plugin_store_items = new_store_items


# Checks if a given plugin is installed and if it has a new version available
func _is_plugin_upgradable(plugin_id: String, store_db: Dictionary) -> bool:
	# Check if we've installed this before
	if plugin_id not in plugins:
		return false
	# Check if we've already found this is upgradable
	if plugin_id in plugins_upgradable:
		return false
	var current_version = plugins[plugin_id]["plugin.version"]
	var new_version = store_db[plugin_id]["plugin.version"]
	if SemanticVersion.is_greater(new_version, current_version):
		logger.info("Plugin update available: {0}.".format([plugin_id]))
		plugin_upgradable.emit(plugin_id, update_type.UPDATE)
		plugins_upgradable.append(plugin_id)
		return true
	return false


# Checks if a given plugin is already in the plugin database
func _is_plugin_new(plugin_id: String) -> bool:
	if plugin_id not in plugin_store_items:
		logger.info("New plugin available: {0}.".format([plugin_id]))
		plugin_upgradable.emit(plugin_id, update_type.NEW)
		return true
	return false


# Returns a list of all plugins with the given store.tags tag
func filter_by_tag(plugins: Dictionary, tag: String) -> Array[String]:
	logger.debug("Filtering by tag: " + tag)
	var filtered_ids: Array[String] = []
	for plugin in plugins.values():
		if not "store.tags" in plugin:
			continue
		logger.debug("Checking " + plugin["plugin.id"])
		var tags := plugin["store.tags"] as Array
		if tag in tags:
			logger.debug(plugin["plugin.id"] + " has the tag and will be loaded.")
			filtered_ids.append(plugin["plugin.id"])
			continue
		logger.debug(plugin["plugin.id"] + " will not be loaded. " + str(tags))
	return filtered_ids

# Sets the filters for the plugin list
func set_plugin_filters(filters: Array[Callable]) -> void:
	logger.debug("Setting plugin filters.")
	plugin_filters = filters
