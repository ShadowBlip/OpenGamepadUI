extends PlatformProvider
class_name PlatformAbernicGen1


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using Abernic Gen 1 platform configuration.")
	return load("res://core/platform/abernic_gen1_gamepad.tres")
