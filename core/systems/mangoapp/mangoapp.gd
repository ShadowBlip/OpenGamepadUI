extends Object
class_name MangoApp

const LOGGER_NAME := "MangoApp"
const LOG_LEVEL := Log.LEVEL.INFO
const MANGO_ENV := "MANGOHUD_CONFIGFILE"
const CONFIG_NONE := ["no_display"]
const CONFIG_FPS := ["fps"]
const CONFIG_DEFAULT := ["gpu_stats", "cpu_stats", "fps", "frametime", "frame_timing"]


# Sets the mangoconfig with the given options. A list of options can be found here:
# https://github.com/flightlessmango/MangoHud
static func set_config(options: PackedStringArray) -> void:
	var config_path := get_config_path()
	if config_path == "":
		var logger := Log.get_logger(LOGGER_NAME, LOG_LEVEL)
		logger.warn("No mangoapp config defined")
		return

	# Write the options to the config
	var file := FileAccess.open(config_path, FileAccess.WRITE_READ)
	for option in options:
		file.store_line(option)


# Loads the current mangoapp config and returns the currently set options
static func get_config() -> PackedStringArray:
	var config_path := get_config_path()
	if config_path == "":
		return PackedStringArray()
	if not FileAccess.file_exists(config_path):
		return PackedStringArray()

	var file := FileAccess.open(config_path, FileAccess.READ)
	var data := file.get_as_text(true)
	return data.split("\n", false)


# Returns whether or not mangoapp is available for use
static func exists() -> bool:
	var mango_config := OS.get_environment(MANGO_ENV)
	if mango_config == "":
		return false
	if OS.execute("which", ["mangoapp"]) != OK:
		return false
	return true


# Returns the path to the mangoapp configuration file
static func get_config_path() -> String:
	return OS.get_environment(MANGO_ENV)
