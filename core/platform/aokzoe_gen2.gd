extends PlatformProvider
class_name PlatformAOKZOEGen2


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using AOKZOE Gen2 platform configuration.")
	return load("res://core/platform/aokzoe_gen2_gamepad.tres")
