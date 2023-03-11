extends PlatformProvider
class_name PlatformOneXPlayerGen1

func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using OneXPlayer Gen1 platform configuration.")
	return load("res://core/platform/onexplayer_gen1_gamepad.tres")
