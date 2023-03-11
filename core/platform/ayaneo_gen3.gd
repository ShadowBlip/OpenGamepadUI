extends PlatformProvider
class_name PlatformAyaneoGen3


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using AYANEO Gen 3 platform configuration.")
	return load("res://core/platform/ayaneo_gen3_gamepad.tres")
