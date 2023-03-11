extends PlatformProvider
class_name PlatformGPDGen1


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using GPD Gen 1 platform configuration.")
	return load("res://core/platform/gpd_gen1_gamepad.tres")
