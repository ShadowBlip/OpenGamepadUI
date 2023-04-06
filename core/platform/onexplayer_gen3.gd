extends PlatformProvider
class_name PlatformOneXPlayerGen3


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using OneXPlayer Gen 3 platform configuration.")
	return load("res://core/platform/onexplayer_gen3_gamepad.tres")
