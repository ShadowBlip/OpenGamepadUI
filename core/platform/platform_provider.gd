extends Resource
class_name PlatformProvider

@export var name: String
var logger := Log.get_logger("PlatformProvider", Log.LEVEL.DEBUG)


func get_handheld_gamepad() -> HandheldGamepad:
	return null
