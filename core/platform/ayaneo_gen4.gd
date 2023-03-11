extends PlatformProvider
class_name PlatformAyaneoGen4


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using AYANEO Gen 4 platform configuration.")
	return load("res://core/platform/ayaneo_gen4_gamepad.tres")
