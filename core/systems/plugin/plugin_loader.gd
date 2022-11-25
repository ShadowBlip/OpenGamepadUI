# Based on the mod loader by Harry Giel
# https://gitlab.com/Delta-V-Modding/Mods/-/blob/main/game/ModLoader.gd
extends Node
class_name PluginLoader

const PLUGIN_API_VERSION = "1.1.0"
const PLUGINS_DIR = "user://plugins"
const LOADED_PLUGINS_DIR = "res://plugins"
const REQUIRED_META = ["plugin.name", "plugin.version", "plugin.min-api-version", "entrypoint"]

signal plugin_loaded(name: String)
signal plugin_initialized(name: String)

var plugins: Dictionary = {}

func _init() -> void:
	print_debug("PluginLoader: Loading plugins")
	_load_plugins()
	print_debug("PluginLoader: Done loading plugins")
	print_debug("PluginLoader: Initializing plugins")
	_init_plugins()
	print_debug("PluginLoader: Done initializing plugins")


# Looks in the user plugins directory for plugin json files and loads them.
func _load_plugins() -> void:
	var dir = DirAccess.open(PLUGINS_DIR)
	if not dir:
		print_debug("PluginLoader: Unable to open plugin directory!")
		return
	
	# Iterate through all plugins
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# Skip any non-plugins
		if not file_name.ends_with(".json"):
			file_name = dir.get_next()
			continue
		
		# Read the plugin metadata
		var plugin_name = file_name.trim_suffix(".json")
		print_debug("PluginLoader: Found plugin: " + file_name)
		var meta = _load_plugin_meta("/".join([PLUGINS_DIR, file_name]))
		if meta == null:
			print_debug("PluginLoader: %s failed to load" % file_name)
			file_name = dir.get_next()
			continue
		
		# Validate the plugin metadata
		if not _is_valid_plugin_meta(meta):
			print_debug("PluginLoader: %s has invalid plugin JSON" % file_name)
			file_name = dir.get_next()
			continue
		
		# Ensure the plugin is compatible
		if not _is_compatible_version(meta["plugin.min-api-version"], PLUGIN_API_VERSION):
			print_debug("PluginLoader: %s is not compatible with this plugin API verion" % file_name)
			file_name = dir.get_next()
			continue
		
		# Load the plugin
		var plugin_file = plugin_name + ".zip"
		if not ProjectSettings.load_resource_pack("/".join([PLUGINS_DIR, plugin_file])):
			print_debug("PluginLoader: %s failed to load" % file_name)
		
		# Register the plugin
		plugins[plugin_name] = meta
		plugin_loaded.emit(plugin_name)

		file_name = dir.get_next()


# Initializes the loaded plugins
func _init_plugins() -> void:
	for name in plugins.keys():
		var meta = plugins[name]
		if not "entrypoint" in meta:
			print_debug("PluginLoader: %s has no entrypoint defined" % name)
			continue
		var plugin = load("/".join([LOADED_PLUGINS_DIR, name, meta["entrypoint"]]))
		if not plugin:
			print_debug("PluginLoader: Unable to load plugin '{0}'. Is the entrypoint correct?".format([name]))
			continue
		var instance: Plugin = plugin.new()
		instance.plugin_base = "/".join([LOADED_PLUGINS_DIR, name])
		add_child(instance)
		plugin_initialized.emit(name)


# Loads plugin metadata and returns it as a parsed dictionary. Returns null
# if there was an error parsing.
func _load_plugin_meta(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	return data


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
