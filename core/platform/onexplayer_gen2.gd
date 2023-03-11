extends PlatformProvider
class_name PlatformOneXPlayerGen2


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using OneXPlayer Gen 2 platform configuration.")
	return load("res://core/platform/onexplayer_gen2_gamepad.tres")
