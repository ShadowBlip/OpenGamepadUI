extends PlatformProvider
class_name PlatformAyaneoGen2


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using AYANEO Gen 2 platform configuration.")
	return load("res://core/platform/ayaneo_gen2_gamepad.tres")
