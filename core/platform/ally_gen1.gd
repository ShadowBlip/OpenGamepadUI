extends PlatformProvider
class_name PlatformAllyGen1

@export var thermal_policy_path: String = "/sys/devices/platform/asus-nb-wmi/throttle_thermal_policy"

func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Using Ally Gen 1 platform configuration.")
	return load("res://core/platform/ally_gen1_gamepad.tres")
