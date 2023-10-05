extends Resource
class_name DisplayManager

## DisplayManager is responsible for managing display settings
##
## Global display manager for managing display settings

enum VALUE {
	ABSOLUTE,
	RELATIVE,
}

enum BRIGHTNESS_PROVIDER {
	NONE,
	STEAMOS,
}

signal brightness_changed

const backlight_path := "/sys/class/backlight"
const steamos_write_bin := "/usr/bin/steamos-polkit-helpers/steamos-priv-write"
const drm_path := "/sys/class/drm"

var logger := Log.get_logger("DisplayManager", Log.LEVEL.INFO)
var backlights := get_backlight_paths()
var brightness_provider := _get_brightness_provider()


## Returns true if OpenGamepadUI has access to adjust brightness
func supports_brightness() -> bool:
	brightness_provider = _get_brightness_provider()
	if brightness_provider == BRIGHTNESS_PROVIDER.NONE:
		logger.debug("No brightness setter found")
		return false
	backlights = get_backlight_paths()
	if backlights.size() == 0:
		logger.debug("No backlights found")
		return false
	return true


## Sets the brightness on all discovered backlights to the given value as a 
## percentage (e.g. 1.0 is 100% brightness)
func set_brightness(value: float, type: VALUE = VALUE.ABSOLUTE) -> int:
	if not supports_brightness():
		logger.debug("Failed to set brightness, no providers found")
		return FAILED
	value = minf(value, 1.0)
	value = maxf(value, 0.0)
	backlights = get_backlight_paths()
	
	# Set the brightness for all backlights
	for backlight_path in backlights:
		# Calculate the value based on whether this is an absolute or relative change
		var abs_value := value
		if type == VALUE.RELATIVE:
			abs_value = get_brightness(backlight_path) + value
			abs_value = minf(abs_value, 1.0)
			abs_value = maxf(abs_value, 0.0)
		var real_value := int(abs_value * get_max_brightness_value(backlight_path))
		
		# Use the preferred method of setting brightness
		var brightness_file := "/".join([backlight_path, "brightness"])
		logger.debug("Setting brightness on " + brightness_file + " to " + str(real_value))
		if brightness_provider == BRIGHTNESS_PROVIDER.STEAMOS:
			if _steamos_priv_write(brightness_file, real_value) != OK:
				return FAILED
			continue
		
		return FAILED
	
	brightness_changed.emit()
	
	return OK


## Returns the current brightness level for the given backlight as a percent
func get_brightness(backlight_path: String) -> float:
	var cur_brightness := get_brightness_value(backlight_path)
	var max_brightness := get_max_brightness_value(backlight_path)
	if cur_brightness == -1 or max_brightness == -1:
		return -1
	return float(cur_brightness) / max_brightness


## Returns the current brightness value for the given backlight
func get_brightness_value(backlight_path: String) -> int:
	var brightness_file := "/".join([backlight_path, "brightness"])
	var output := []
	var code := OS.execute("cat", [brightness_file], output)
	if code != OK:
		logger.debug("Unable to get current brightness: " + output[0])
		return -1
	var value := (output[0] as String).strip_edges()
	if value.is_valid_int():
		return value.to_int()
	logger.debug("Brightness is not a valid number: " + value)
	return -1


## Returns the maximum brightness for the given backlight
func get_max_brightness_value(backlight_path: String) -> int:
	var max_brightness_file := "/".join([backlight_path, "max_brightness"])
	var output := []
	var code := OS.execute("cat", [max_brightness_file], output)
	if code != OK:
		logger.debug("Unable to get max brightness: " + output[0])
		return -1
	var value := (output[0] as String).strip_edges()
	if value.is_valid_int():
		return value.to_int()
	logger.debug("Max brightness is not a valid number: " + value)
	return -1


## Returns a list of all detected backlight devices
func get_backlight_paths() -> PackedStringArray:
	var backlights := PackedStringArray()
	var backlight_dir := DirAccess.open(backlight_path)
	var devices := backlight_dir.get_directories()
	for device in devices:
		backlights.append("/".join([backlight_path, device]))
	logger.debug("Found backlights: " + str(backlights))
	return backlights


func _get_brightness_provider() -> BRIGHTNESS_PROVIDER:
	if FileAccess.file_exists(steamos_write_bin):
		logger.debug("Using SteamOS backlight writer")
		return BRIGHTNESS_PROVIDER.STEAMOS
	logger.debug("No backlight writer found")
	return BRIGHTNESS_PROVIDER.NONE


## Write a value using steamos polkit helper
func _steamos_priv_write(path: String, value: int) -> int:
	return OS.execute(steamos_write_bin, [path, str(value)])


# Get the drm adapter path
func get_drm_device_status_path(card_name: String) -> String:
	var file_prefix := "/".join([drm_path, card_name, "status"])
	return file_prefix


# Get the drm adapter name
func get_drm_device_names() -> PackedStringArray:
	var card_names := PackedStringArray()
	var card_dirs := DirAccess.get_directories_at(drm_path)
	for card_name in card_dirs:
		if not "card" in card_name:
			continue
		if not "-" in card_name:
			continue
		card_names.append(card_name)
	return card_names


# Get the drm adapter status
func get_drm_device_status(path: String, card: String) -> bool:
	var cmd := Command.new("cat", [path])
	var parts = card.split("-")
	var adapter = []
	if parts.size() > 1:
		adapter = parts[1]
	if await cmd.execute() != OK:
		print("Command failed with code", cmd.code)
	if "disconnected" in cmd.stdout:
		return false
	else:
		return true


# Get a list of all the connected displays
func show_available_adapters() -> PackedStringArray:
	var adapter_names = get_drm_device_names()
	var available_adapter_paths := []
	var connected_devices = []
	for name in adapter_names:
			available_adapter_paths.append(await get_drm_device_status_path(name))
			for adapter in available_adapter_paths:
				if await get_drm_device_status(adapter, name):
					connected_devices.append(name)
	return connected_devices
