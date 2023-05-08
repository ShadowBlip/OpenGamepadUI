extends PlatformProvider
class_name PlatformAyaneoGen5


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using AYANEO Gen 5 platform configuration.")
	return load("res://core/platform/ayaneo_gen5_gamepad.tres")
