extends PlatformProvider
class_name PlatformAllyGen1


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using Ally Gen 1 platform configuration.")
	return load("res://core/platform/ally_gen1_gamepad.tres")
