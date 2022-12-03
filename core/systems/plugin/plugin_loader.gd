# Based on the mod loader by Harry Giel
# https://gitlab.com/Delta-V-Modding/Mods/-/blob/main/game/ModLoader.gd
extends Node
class_name PluginLoader
@icon("res://assets/icons/codesandbox.svg")

const PLUGIN_STORE_URL = "https://raw.githubusercontent.com/ShadowBlip/OpenGamepadUI-plugins/main/plugins.json"
const PLUGIN_API_VERSION = "1.0.0"
const PLUGINS_DIR = "user://plugins"
const LOADED_PLUGINS_DIR = "res://plugins"
const REQUIRED_META = ["plugin.name", "plugin.version", "plugin.min-api-version", "entrypoint"]

signal plugin_loaded(name: String)
signal plugin_initialized(name: String)

var logger := Log.get_logger("PluginLoader")
var plugins := {}

func _init() -> void:
	logger.info("Loading plugins")
	_load_plugins()
	logger.info("Done loading plugins")
	logger.info("Initializing plugins")
	_init_plugins()
	logger.info("Done initializing plugins")


# Returns the parsed dictionary of plugin store items. Returns null if there
# is a failure.
func get_plugin_store_items() -> Variant:
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.request(PLUGIN_STORE_URL) != OK:
		logger.error("Error making http request to plugin store")
		remove_child(http)
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
		remove_child(http)
		http.queue_free()
		return null
	
	# Parse the results
	var items: Dictionary = JSON.parse_string(body.get_string_from_utf8())

	return items


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
		
		# Load the plugin
		if not ProjectSettings.load_resource_pack("/".join([PLUGINS_DIR, file_name])):
			logger.warning("%s failed to load" % file_name)
		
		# Register the plugin
		var plugin_name: String = meta["plugin.id"]
		plugins[plugin_name] = meta
		plugin_loaded.emit(plugin_name)

		file_name = dir.get_next()


# Initializes the loaded plugins
func _init_plugins() -> void:
	for name in plugins.keys():
		var meta = plugins[name]
		if not "entrypoint" in meta:
			logger.warning("%s has no entrypoint defined" % name)
			continue
		var plugin = load("/".join([LOADED_PLUGINS_DIR, name, meta["entrypoint"]]))
		if not plugin:
			logger.warning("Unable to load plugin '{0}'. Is the entrypoint correct?".format([name]))
			continue
		var instance: Plugin = plugin.new()
		instance.plugin_base = "/".join([LOADED_PLUGINS_DIR, name])
		add_child(instance)
		plugin_initialized.emit(name)


# Loads plugin metadata and returns it as a parsed dictionary. Returns null
# if there was an error parsing.
func _load_plugin_meta(path: String) -> Variant:
	# Open the archive
	var reader: ZIPReader = ZIPReader.new()
	reader.open(path)
	
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
	var version_list = version.split(".")
	var target_list = target.split(".")
	
	# Ensure the given versions are valid semver
	if not _is_valid_semver(version_list) or not _is_valid_semver(target_list):
		return false
	
	# Compare major versions
	if version_list[0] != target_list[0]:
		return false
	
	# Compare minor versions
	if int(version_list[0]) < int(target_list[0]):
		return false
	
	return true


# Returns whether or not the given version array is a valid semver
func _is_valid_semver(version: Array) -> bool:
	if len(version) != 3:
		return false
	for i in version:
		var v: String = i
		if not v.is_valid_int():
			return false
	return true
