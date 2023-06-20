extends PlatformProvider
class_name PlatformAynGen1


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using Ayn Gen 1 platform configuration.")
	return load("res://core/platform/ayn_gen1_gamepad.tres")
