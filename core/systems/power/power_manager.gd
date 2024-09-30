extends Node
class_name PowerManager

## Manages power settings.
##
## The [PowerManager] class is responsible for loading a [UPowerInstance] and
## calling its 'process()' method each frame.

@export var instance: UPowerInstance = load("res://core/systems/power/power_manager.tres") as UPowerInstance

# Keep a reference to device instances so they are not cleaned up automatically
var _devices: Array[UPowerDevice]
var logger := Log.get_logger("PowerManager")


func _ready() -> void:
	var display_device := instance.get_display_device()
	_devices.push_back(display_device)
	if _devices.is_empty():
		logger.warn("UPower not detected.")


func _process(_delta: float) -> void:
	if not instance:
		return
	instance.process()
