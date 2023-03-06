extends Resource
class_name HandheldGamepad

var active_keys: PackedInt64Array = []
var kb_device: InputDevice
var gamepad_device: ManagedGamepad

# Override below in device specific implementation
# Mapping of active_keys entry to list of InputDeviceEvent
# e.g. {[1, 2, 3]: [event.BTN_MODE, event.BTN_NORTH]}
var mapped_events: Dictionary = {[]: PackedByteArray[InputDeviceEvent]}
var kb_event_path: String # path of /dev/input/eventX
var kb_phys_path: String # Path of the device in sysfs ATTR{phys}
var kb_phys_name: String # Name of the device in sysfs ATTR{name}
var gamepad_phys_path: String # Path of the device in sysfs ATTR{phys}
var gamepad_phys_name: String # Name of the device in sysfs ATTR{name}

var _last_time := 0

var logger := Log.get_logger("HandheldGamepad", Log.LEVEL.DEBUG)

func process_input() -> void:
	# Calculate the amount of time that has passed since last invocation
	var current_time := Time.get_ticks_usec()
	var delta_us := current_time - _last_time
	_last_time = current_time
	var delta := delta_us / 1000000.0  # Convert to seconds

	# Only process input if we have a valid handle
	if not kb_device or not kb_device.is_open():
		return

	# Process all physical input events
	var events = kb_device.get_events()
	for event in events:
		if not event or not event is InputDeviceEvent:
			continue
		_process_event(event)
	_check_events()

# Called to handle an individual event. Must be overridden in the per-device
# implementation
func _process_event(event: InputDeviceEvent) -> void:
	pass


# Called after processing all events in the event loop. Checks if our current
# active_keys matches any of our mapped events.
func _check_events() -> void:
	pass


func get_active_keys() -> PackedInt64Array:
	return active_keys


## Opens the given physical device with exclusive access. Requres a UDEV rule
## that provides uaccess for input devices that detect as keyboard/mouse.
func open(path: String) -> int:
	kb_event_path = path
	kb_device = InputDevice.new()
	var result: int = kb_device.open(kb_event_path)
	if result != OK:
		logger.warn("Unable to open gamepad: " + kb_event_path)

	# Grab exclusive access over the physical device
	if not "--disable-grab-gamepad" in OS.get_cmdline_args():
		kb_device.grab(true)

	return result
