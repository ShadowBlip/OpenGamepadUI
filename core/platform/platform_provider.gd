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
## InputPlumber target device to emulate instead of the default one chosen for
## the current session. Leave empty to use the default. Set this for devices
## where the default target is a bad fit, such as handhelds without a dedicated
## Quick Access Menu button, where Steam ignores the guide+south chord on
## Steam Deck and Horipad targets and leaves the user no way to open the QAM.
@export var target_gamepad_override: String
var logger := Log.get_logger("PlatformProvider", Log.LEVEL.INFO)


## Ready will be called after the scene tree has initialized. This should be
## overridden in the child class if the platform wants to make changes to the
## scene tree.
func ready(root: Window) -> void:
	pass
