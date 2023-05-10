extends Resource
class_name PlatformProvider

@export var name: String
var logger := Log.get_logger("PlatformProvider", Log.LEVEL.INFO)


## Ready will be called after the scene tree has initialized. This should be
## overridden in the child class if the platform wants to make changes to the
## scene tree.
func ready(root: Window) -> void:
	pass


## If implemented, return a HandheldGamepad implementation for hardware platforms
## with embedded controllers.
func get_handheld_gamepad() -> HandheldGamepad:
	logger.info("Platform not found. Using default configuration.")
	return null
