@icon("res://assets/editor-icons/platform.svg")
extends Resource
class_name PlatformProvider

@export var name: String ## Name of the platform
@export var startup_actions: Array[PlatformAction] ## Actions to take upon startup
@export var shutdown_actions: Array[PlatformAction] ## Actions to take upon shutdown 
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
