extends HandheldPlatform
class_name OrangePiPlatform

## Detects the phys_path of the gamepad. This changes depending on BIOS
## version and if some hardware is enabled.
func delay_for_devices() -> void:
	# The asus-his driver needs some time to switch to gamepad mode after initializing. Hiding the
	# event file descriptors before this happens will cause the action to fail. Wait a moment.
	logger.debug("Waiting 5s for OrangePi NEO input to be ready...")
	await OS.delay_msec(5000)
