extends PlatformProvider
class_name PlatformOneXPlayerGen1

func get_handheld_gamepad() -> HandheldGamepad:
	return load("res://core/platform/onexplayer_gen1_gamepad.tres")
