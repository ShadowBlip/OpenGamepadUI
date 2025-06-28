extends Resource
class_name DisplayManager

## DisplayManager is responsible for managing display settings
##
## Global display manager for managing display settings

enum VALUE {
	ABSOLUTE,
	RELATIVE,
}

signal brightness_changed

var logger := Log.get_logger("DisplayManager", Log.LEVEL.INFO)
var brightness_provider := _get_backlight_provider()
var backlights := get_backlight_paths()


## Returns true if OpenGamepadUI has access to adjust brightness
func supports_brightness() -> bool:
	if brightness_provider == null:
		logger.debug("No brightness setter found")
		return false
	backlights = get_backlight_paths()
	if backlights.size() == 0:
		logger.debug("No backlights found")
		return false
	return true


## Sets the brightness on all discovered backlights to the given value as a 
## percentage (e.g. 1.0 is 100% brightness)
func set_brightness(value: float, type: VALUE = VALUE.ABSOLUTE, backlight: String = "") -> int:
	if not supports_brightness():
		logger.debug("Failed to set brightness, no providers found")
		return FAILED

	var err := brightness_provider.set_brightness(value, type, backlight)
	if err == OK:
		brightness_changed.emit()

	return err


## Returns the current brightness level for the given backlight as a percent
func get_brightness(backlight_path: String) -> float:
	if brightness_provider == null:
		return -1.0
	return brightness_provider.get_brightness(backlight_path)


## Returns the current brightness value for the given backlight
func get_brightness_value(backlight_path: String) -> int:
	if brightness_provider == null:
		return -1
	return brightness_provider.get_brightness_value(backlight_path)


## Returns the maximum brightness for the given backlight
func get_max_brightness_value(backlight_path: String) -> int:
	if brightness_provider == null:
		return -1
	return brightness_provider.get_max_brightness_value(backlight_path)


## Returns a list of all detected backlight devices
func get_backlight_paths() -> PackedStringArray:
	if brightness_provider == null:
		return PackedStringArray()
	return brightness_provider.get_backlights()


func _get_backlight_provider() -> BacklightProvider:
	if OS.execute("which", ["brightnessctl"]) == OK:
		logger.debug("Using brightnessctl backlight provider")
		return BrightnessctlBacklight.new()
	if FileAccess.file_exists("/usr/bin/steamos-polkit-helpers/steamos-priv-write"):
		logger.debug("Using SteamOS backlight writer")
		return SteamOsBacklight.new()
	logger.debug("No backlight writer found")
	return null


## Interface for controlling backlights (e.g. screen brightness)
class BacklightProvider:
	## Returns all available backlights
	func get_backlights() -> PackedStringArray:
		return PackedStringArray()

	## Returns the maximum raw brightness value of the given backlight. If
	## No backlight is passed, then this should return the value for the "main"
	## display. Returns -1 if there is an error fetching the value.
	func get_max_brightness_value(_backlight: String = "") -> int:
		return -1

	## Returns the current raw brightness value of the given backlight. If no
	## backlight is passed, then this should return the value for the "main"
	## display. Returns -1 if there is an error fetching the value.
	func get_brightness_value(_backlight: String = "") -> int:
		return -1

	## Returns the current brightness level for the given backlight as a percent.
	## Returns -1 if there is an error fetching the value
	func get_brightness(_backlight: String = "") -> float:
		return -1.0

	## Sets the brightness for the given backlight to the given value as a 
	## percentage (e.g. 1.0 is 100% brightness). If no backlight is specified,
	## this should set the value on _all_ discovered backlights. Returns OK
	## if set successfully.
	func set_brightness(_value: float, _type: VALUE = VALUE.ABSOLUTE, _backlight: String = "") -> int:
		return ERR_METHOD_NOT_FOUND


## SteamOS implementation of backlight control
class SteamOsBacklight extends BacklightProvider:
	const backlight_path_base := "/sys/class/backlight"
	const steamos_write_bin := "/usr/bin/steamos-polkit-helpers/steamos-priv-write"
	var logger := Log.get_logger("SteamOsBacklight", Log.LEVEL.INFO)

	func get_backlights() -> PackedStringArray:
		var backlights := PackedStringArray()
		var backlight_dir := DirAccess.open(backlight_path_base)
		var devices := backlight_dir.get_directories()
		for device in devices:
			backlights.append("/".join([backlight_path_base, device]))
		self.logger.debug("Found backlights: " + str(backlights))
		return backlights

	func set_brightness(value: float, type: VALUE = VALUE.ABSOLUTE, backlight: String = "") -> int:
		value = minf(value, 1.0)
		value = maxf(value, 0.0)
		var backlights := PackedStringArray()
		if backlight.is_empty():
			backlights = self.get_backlights()
		else:
			backlights.push_back(backlight)

		# Set the brightness for all backlights
		for backlight_path in backlights:
			# Calculate the value based on whether this is an absolute or relative change
			var abs_value := value
			if type == VALUE.RELATIVE:
				abs_value = self.get_brightness(backlight_path) + value
				abs_value = minf(abs_value, 1.0)
				abs_value = maxf(abs_value, 0.0)
			var real_value := int(abs_value * self.get_max_brightness_value(backlight_path))
			
			# Use the preferred method of setting brightness
			var brightness_file := "/".join([backlight_path, "brightness"])
			self.logger.debug("Setting brightness on " + brightness_file + " to " + str(real_value))
			if self._steamos_priv_write(brightness_file, real_value) != OK:
				return FAILED

		return OK

	func get_brightness(backlight_path: String = "") -> float:
		var cur_brightness := self.get_brightness_value(backlight_path)
		var max_brightness := self.get_max_brightness_value(backlight_path)
		if cur_brightness == -1 or max_brightness == -1:
			return -1
		return float(cur_brightness) / max_brightness

	func get_brightness_value(backlight_path: String = "") -> int:
		var brightness_file := "/".join([backlight_path, "brightness"])
		var output := []
		var code := OS.execute("cat", [brightness_file], output)
		if code != OK:
			logger.debug("Unable to get current brightness: " + output[0])
			return -1
		var value := (output[0] as String).strip_edges()
		if value.is_valid_int():
			return value.to_int()
		self.logger.debug("Brightness is not a valid number: " + value)
		return -1

	func get_max_brightness_value(backlight_path: String = "") -> int:
		var max_brightness_file := "/".join([backlight_path, "max_brightness"])
		var output := []
		var code := OS.execute("cat", [max_brightness_file], output)
		if code != OK:
			self.logger.debug("Unable to get max brightness: " + output[0])
			return -1
		var value := (output[0] as String).strip_edges()
		if value.is_valid_int():
			return value.to_int()
		self.logger.debug("Max brightness is not a valid number: " + value)
		return -1

	## Write a value using steamos polkit helper
	func _steamos_priv_write(path: String, value: int) -> int:
		return OS.execute(steamos_write_bin, [path, str(value)])


## Brightnessctl implementation of backlight control
class BrightnessctlBacklight extends BacklightProvider:
	var logger := Log.get_logger("BrightnessctlBacklight", Log.LEVEL.INFO)

	func _exec(args: Array[String]) -> Command:
		self.logger.debug("Executing command:", "brightnessctl", args)
		var cmd := Command.create("brightnessctl", args)
		cmd.execute_blocking()
		self.logger.debug("Output:", cmd.stdout, cmd.stderr)
		return cmd

	func _get_info(backlight: String = "") -> PackedStringArray:
		var args: Array[String] = ["--machine", "--class", "backlight", "info"]
		if not backlight.is_empty():
			args.push_front(backlight)
			args.push_front("--device")
		var cmd := _exec(args)
		if cmd.code != OK:
			return PackedStringArray()

		var lines := cmd.stdout.split("\n", false)
		if lines.is_empty():
			return PackedStringArray()

		# Example Output: amdgpu_bl1,backlight,128,50%,255
		var parts := lines[0].split(",", false)
		return parts

	func get_backlights() -> PackedStringArray:
		# brightnessctl -l -c backlight -m
		# Output: amdgpu_bl1,backlight,128,50%,255
		var backlights := PackedStringArray()
		var cmd := self._exec(["--list", "--class", "backlight", "--machine"])
		if cmd.code != OK:
			return backlights

		var lines := cmd.stdout.split("\n", false)
		for line in lines:
			var parts := line.split(",")
			if parts.is_empty():
				continue
			backlights.push_back(parts[0])

		self.logger.debug("Found backlights: " + str(backlights))
		return backlights

	func set_brightness(value: float, type: VALUE = VALUE.ABSOLUTE, backlight: String = "") -> int:
		value = minf(value, 1.0)
		value = maxf(value, -1.0)
		value = value * 100.0
		var backlights := PackedStringArray()
		if backlight.is_empty():
			backlights = self.get_backlights()
		else:
			backlights.push_back(backlight)

		# Set the brightness for all backlights
		for backlight_name in backlights:
			var value_str := str(value) + "%"
			if type == VALUE.RELATIVE:
				if value > 0.0:
					value_str = "+" + value_str
				else:
					value_str = value_str + "-"

			self.logger.debug("Setting brightness on " + backlight_name + " to " + value_str)
			var cmd := _exec(["--device", backlight_name, "set", value_str])
			if cmd.code != OK:
				return FAILED

		return OK

	func get_brightness(backlight: String = "") -> float:
		var info := self._get_info(backlight)
		if info.size() < 4:
			return -1.0

		# Example Output: amdgpu_bl1,backlight,128,50%,255
		var cur_brightness := info[3]
		cur_brightness = cur_brightness.replace("%", "")
		if not cur_brightness.is_valid_int():
			return -1.0

		return cur_brightness.to_float() / 100.0


	func get_brightness_value(backlight: String = "") -> int:
		var info := self._get_info(backlight)
		if info.size() < 4:
			return -1

		# Example Output: amdgpu_bl1,backlight,128,50%,255
		var cur_brightness := info[2]
		if not cur_brightness.is_valid_int():
			return -1

		return cur_brightness.to_int()

	func get_max_brightness_value(backlight: String = "") -> int:
		var info := self._get_info(backlight)
		if info.size() < 5:
			return -1

		# Example Output: amdgpu_bl1,backlight,128,50%,255
		var max_brightness := info[4]
		if not max_brightness.is_valid_int():
			return -1

		return max_brightness.to_int()
