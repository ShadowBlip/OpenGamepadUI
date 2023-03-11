extends Resource
class_name PlatformProvider

@export var name: String
var logger := Log.get_logger("PlatformProvider", Log.LEVEL.DEBUG)


func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Platform not found. Using default configuration.")
	return null
