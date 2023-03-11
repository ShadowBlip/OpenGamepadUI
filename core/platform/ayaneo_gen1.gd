extends PlatformProvider
class_name PlatformAyaneoGen1


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using AYANEO Gen 1 platform configuration.")
	return load("res://core/platform/ayaneo_gen1_gamepad.tres")
