@icon("res://assets/editor-icons/platform.svg")
extends Resource
class_name PlatformProvider

## Base class that defines a particular platform
##
## A "platform" can be a particular set of hardware (i.e. a handheld PC), an
## OS platform, etc. Anything that requires special consideration for
## OpenGamepadUI to run correctly.

@export var name: String ## Name of the platform
@export var startup_actions: Array[PlatformAction] ## Actions to take upon startup
@export var shutdown_actions: Array[PlatformAction] ## Actions to take upon shutdown 
var logger := Log.get_logger("PlatformProvider", Log.LEVEL.INFO)


## Ready will be called after the scene tree has initialized. This should be
## overridden in the child class if the platform wants to make changes to the
## scene tree.
func ready(root: Window) -> void:
	pass
