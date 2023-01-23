# Based on the mod loader by Harry Giel
# https://gitlab.com/Delta-V-Modding/Mods/-/blob/main/game/ModLoader.gd
@icon("res://assets/icons/codesandbox.svg")
extends Node

const PLUGIN_STORE_URL = "https://raw.githubusercontent.com/ShadowBlip/OpenGamepadUI-plugins/main/plugins.json"
const PLUGIN_API_VERSION = "1.0.0"
const PLUGINS_DIR = "user://plugins"
const LOADED_PLUGINS_DIR = "res://plugins"
const REQUIRED_META = ["plugin.name", "plugin.version", "plugin.min-api-version", "entrypoint"]

signal plugin_loaded(name: String)
signal plugin_initialized(name: String)
signal plugin_installed(id: String, status: int)

var logger := Log.get_logger("PluginLoader")
var plugins := {}
var plugin_nodes := {}

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


# Downloads and installs the given plugin
func install_plugin(plugin_id: String, download_url: String, sha256: String) -> void:
	# Build the request
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.request(download_url) != OK:
		logger.error("Error making http request for plugin package: " + download_url)
		remove_child(http)
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
	remove_child(http)
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
	
	plugin_installed.emit(plugin_id, OK)


# Unloads and uninstalls the given plugin. Returns OK if removed successfully.
func uninstall_plugin(plugin_id: String) -> int:
	# Unload the plugin
	unload_plugin(plugin_id)
	
	# Remove the plugin archive
	var plugin_dir: String = ProjectSettings.get("OpenGamepadUI/plugin/directory")
	var filename: String = "/".join([plugin_dir, plugin_id + ".zip"])
	return DirAccess.remove_absolute(filename)


# Unloads the given plugin. Returns OK if successful.
func unload_plugin(plugin_id: String) -> int:
	if not plugin_id in plugin_nodes:
		logger.error("Cannot unload plugin {0} as it does not appear to be loaded".format([plugin_id]))
		return FAILED
	var instance: Plugin = plugin_nodes[plugin_id]
	instance.unload()
	remove_child(instance)
	instance.queue_free()
	plugin_nodes.erase(plugin_id)
	plugins.erase(plugin_id)
	return OK


# Returns true if the given plugin is installed.
func is_installed(plugin_id: String) -> bool:
	var plugin_dir: String = ProjectSettings.get("OpenGamepadUI/plugin/directory")
	var filename: String = "/".join([plugin_dir, plugin_id + ".zip"])
	return FileAccess.file_exists(filename)
	

# Returns true if the given plugin is loaded.
func is_loaded(plugin_id: String) -> bool:
	return plugin_id in plugins


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
		plugin_nodes[name] = instance
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
