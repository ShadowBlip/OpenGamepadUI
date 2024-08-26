@icon("res://addons/core/assets/icons/inputplumber.svg")
extends Node
class_name InputPlumber

## Manages routing input to and from InputPlumber.
##
## The InputPlumberManager class is responsible for handling dbus messages to and
## from the InputPlumber input manager daemon.

const DEFAULT_PROFILE := "res://assets/gamepad/profiles/default.json"
const DEFAULT_GLOBAL_PROFILE := "user://data/gamepad/profiles/global_default.json"
const PROFILES_DIR := "user://data/gamepad/profiles"

@export var instance: InputPlumberInstance = load("res://core/systems/input/input_plumber.tres")

# Keep a reference to dbus devices so they are not cleaned up automatically
var _dbus_devices := {}


func _ready() -> void:
	# Add listeners for any new devices
	var on_device_added := func(device: CompositeDevice):
		var dbus_devices := device.dbus_devices
		if dbus_devices.is_empty():
			return
		var dbus_device := dbus_devices[0]
		var dbus_path := device.dbus_path
		_dbus_devices[dbus_path] = dbus_device
	instance.composite_device_added.connect(on_device_added)
	
	# Add listeners when devices are removed
	var on_device_removed := func(dbus_path: String):
		if not _dbus_devices.has(dbus_path):
			return
		_dbus_devices.erase(dbus_path)
	instance.composite_device_removed.connect(on_device_removed)

	# Find all composite devices
	var devices := instance.get_composite_devices()
	for device in devices:
		on_device_added.call(device)


func _process(_delta: float) -> void:
	if not instance:
		return
	instance.process()
