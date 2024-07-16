extends RefCounted
class_name MangoApp

const LOGGER_NAME := "MangoApp"
const LOG_LEVEL := Log.LEVEL.INFO
const MANGO_ENV := "MANGOHUD_CONFIGFILE"
const CONFIG_NONE := ["no_display"]
const CONFIG_FPS := ["fps_only"]
const CONFIG_MIN := [
	"horizontal",
	"legacy_layout=0",
	"table_columns=20",
	"battery",
	"cpu_stats",
	"gpu_stats",
	"ram",
	"fps",
	"frametime=0",
	"frame_timing=1",
	"hud_no_margin",
	"gpu_power",
	"cpu_power"
]
const CONFIG_DEFAULT := ["gpu_stats", "cpu_stats", "fps", "frametime", "frame_timing"]
const CONFIG_INSANE := [
	"legacy_layout=false",
	"gpu_stats",
	"gpu_temp",
	"gpu_core_clock",
	"gpu_mem_clock",
	"gpu_power",
	"gpu_load_change",
	"gpu_load_value=50,90",
	"gpu_load_color=FFFFFF,FFAA7F,CC0000",
	"gpu_text=GPU",
	"cpu_stats",
	"cpu_temp",
	"core_load",
	"cpu_power",
	"cpu_mhz",
	"cpu_load_change",
	"core_load_change",
	"cpu_load_value=50,90",
	"cpu_load_color=FFFFFF,FFAA7F,CC0000",
	"cpu_color=2e97cb",
	"cpu_text=CPU",
	"io_stats",
	"io_read",
	"io_write",
	"io_color=a491d3",
	"swap",
	"vram",
	"vram_color=ad64c1",
	"ram",
	"ram_color=c26693",
	"procmem",
	"procmem_shared",
	"procmem_virt",
	"fps",
	"engine_version",
	"engine_color=eb5b5b",
	"gpu_name",
	"gpu_color=2e9762",
	"vulkan_driver",
	"wine",
	"wine_color=eb5b5b",
	"frame_timing=1",
	"frametime_color=00ff00",
	"throttling_status",
	"resolution",
	"battery",
	"media_player_color=ffffff",
	"table_columns=3",
	"background_alpha=0.4",
	"font_size=24",
	"background_color=020202",
	"position=top-left",
	"text_color=ffffff",
	"round_corners=10"
]


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
