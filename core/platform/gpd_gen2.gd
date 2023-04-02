extends PlatformProvider
class_name PlatformGPDGen2


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using GPD Gen 2 platform configuration.")
	return load("res://core/platform/gpd_gen2_gamepad.tres")
