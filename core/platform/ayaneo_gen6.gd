extends PlatformProvider
class_name PlatformAyaneoGen6


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using AYANEO Gen 6 platform configuration.")
	return load("res://core/platform/ayaneo_gen6_gamepad.tres")
