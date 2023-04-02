extends PlatformProvider
class_name PlatformAOKZOEGen1


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using AOKZOE Gen 1 platform configuration.")
	return load("res://core/platform/aokzoe_gen1_gamepad.tres")
