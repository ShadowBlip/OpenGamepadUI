extends PlatformProvider
class_name PlatformGPDGen3


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using GPD Gen 3 platform configuration.")
	return load("res://core/platform/gpd_gen3_gamepad.tres")
