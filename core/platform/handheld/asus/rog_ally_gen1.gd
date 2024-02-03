extends HandheldPlatform
class_name ROGAllyPlatform

const GAMEPAD_ADDRESS_LIST : PackedStringArray =[
	'usb-0000:08:00.3-2/input0',
	'usb-0000:09:00.3-2/input0',
	'usb-0000:0a:00.3-2/input0',
	]


## Detects the phys_path of the gamepad. This changes depending on BIOS
## version and if some hardware is enabled.
func identify_controller_phys() -> void:
	# The asus-his driver needs some time to switch to gamepad mode after initializing. Hiding the
	# event file descriptors before this happens will cause the action to fail. Wait a moment.
	logger.debug("Waiting 5s for ROG Ally controller to be ready...")
	await OS.delay_msec(5000)

	var sysfs_devices := SysfsDevice.get_all()
	for sysfs_device in sysfs_devices:
		if sysfs_device.name != gamepad.name:
			continue
		logger.debug("Checking " + sysfs_device.phys_path + " as possible controller device.")
		if sysfs_device.phys_path in GAMEPAD_ADDRESS_LIST:
			gamepad = sysfs_device
			logger.debug("Found gamepad device: " + sysfs_device.phys_path)
			return
